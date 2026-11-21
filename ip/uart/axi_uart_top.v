`timescale 1ns / 1ps

/* -----------------------------------------------------------------------------
 * Project        : AXI-lite UART IP Core
 * File           : axi_uart_top.v
 * Description    : AXI4-Lite UART Slave Module
 *                  Updated and modified according to Project Specification:
 *                  - Pure single-clock synchronous design (clk, rst_n active-low)
 *                  - Standard 19-signal AXI4-Lite slave interface (no ID ports)
 *                  - Decoupled AW and W handshakes (AW/W in any order or together)
 *                  - 12-bit address decode (4 KB window), SLVERR for invalid offsets
 *                  - Register map per Section 9, Page 16 of Project Specification:
 *                      0x00 UART_CTRL   : [0] enable, [1] irq enable, [15:4] baud divisor
 *                      0x04 UART_STATUS : [0] tx_ready, [1] rx_valid, [2] overrun
 *                      0x08 UART_TXDATA : [7:0] byte to transmit (write-only)
 *                      0x0C UART_RXDATA : [7:0] received byte (read-only)
 *                  - Non-blocking FIFO operations: immediate SLVERR on full TX or empty RX
 *                  - Interrupt irq_uart asserted on (tx_empty | rx_valid) when enabled
 *                  - Write strobe (wstrb) support preserving untouched bytes
 * ------------------------------------------------------------------------------*/

`default_nettype none

module axi_uart_top (
  // Clock and Reset
  input  wire        clk,
  input  wire        rst_n,

  // AXI4-Lite Write Address Channel
  input  wire [31:0] awaddr,
  input  wire [2:0]  awprot,
  input  wire        awvalid,
  output reg         awready,

  // AXI4-Lite Write Data Channel
  input  wire [31:0] wdata,
  input  wire [3:0]  wstrb,
  input  wire        wvalid,
  output reg         wready,

  // AXI4-Lite Write Response Channel
  output reg  [1:0]  bresp,
  output reg         bvalid,
  input  wire        bready,

  // AXI4-Lite Read Address Channel
  input  wire [31:0] araddr,
  input  wire [2:0]  arprot,
  input  wire        arvalid,
  output reg         arready,

  // AXI4-Lite Read Data Channel
  output reg  [31:0] rdata,
  output reg  [1:0]  rresp,
  output reg         rvalid,
  input  wire        rready,

  // UART External Interface Pins
  output wire        uart_tx,
  input  wire        uart_rx,

  // Interrupt Output to PIC
  output wire        irq_uart
);

  /* Includes */
  `include "axi_uart_defines.vh"
  `include "axi_uart.vh"

  /* Local Parameters */
  localparam FIFO_DEPTH     = `_AXI_UART_FIFO_DEPTH_;
  localparam FIFO_ADDR_BITS = $clog2(FIFO_DEPTH);
  localparam DATA_WIDTH     = `_DATA_WIDTH_UART_;

  /* Registers */
  reg [31:0] uart_ctrl;
  reg        overrun_flag;

  /* FIFO and Controller Internal Signals */
  wire [FIFO_ADDR_BITS+3:0] tx_status;
  wire [FIFO_ADDR_BITS+3:0] rx_status;

  wire tx_has_data  = tx_status[FIFO_ADDR_BITS+3];
  wire tx_fifo_full = tx_status[FIFO_ADDR_BITS+2];
  wire tx_ready     = ~tx_fifo_full;

  wire rx_has_data  = rx_status[FIFO_ADDR_BITS+3];
  wire rx_fifo_full = rx_status[FIFO_ADDR_BITS+2];
  wire rx_valid     = rx_has_data;

  reg        tx_fifo_push;
  reg  [7:0] tx_fifo_din;
  wire [7:0] tx_fifo_dout;
  wire       tx_fifo_pull;

  wire       rx_fifo_push;
  wire [7:0] rx_fifo_din;
  wire [7:0] rx_fifo_dout;
  reg        rx_fifo_pull;

  wire       ctrl_en;
  wire       ctrl_irq_en;
  wire [15:0] baud_divisor;

  assign ctrl_en      = uart_ctrl[`_UART_CTRL_EN_BIT_];
  assign ctrl_irq_en  = uart_ctrl[`_UART_CTRL_IRQ_EN_BIT_];
  assign baud_divisor = (uart_ctrl[15:4] == 12'd0) ? {4'h0, `_UART_DEFAULT_DIVISOR_} : {4'h0, uart_ctrl[15:4]};

  /* Helper function for write strobes */
  function [31:0] apply_wstrb;
    input [31:0] orig_val;
    input [31:0] new_val;
    input [3:0]  strb;
    begin
      apply_wstrb[ 7: 0] = strb[0] ? new_val[ 7: 0] : orig_val[ 7: 0];
      apply_wstrb[15: 8] = strb[1] ? new_val[15: 8] : orig_val[15: 8];
      apply_wstrb[23:16] = strb[2] ? new_val[23:16] : orig_val[23:16];
      apply_wstrb[31:24] = strb[3] ? new_val[31:24] : orig_val[31:24];
    end
  endfunction

  /* -------------------------------------------------------------------------
   * AXI4-Lite Write Channel FSM (Decoupled AW and W)
   * -------------------------------------------------------------------------*/
  localparam WR_IDLE    = 2'b00;
  localparam WR_EXECUTE = 2'b01;
  localparam WR_RESP    = 2'b10;

  reg [1:0]  wr_state;
  reg [11:0] awaddr_latched;
  reg [31:0] wdata_latched;
  reg [3:0]  wstrb_latched;
  reg        aw_received;
  reg        w_received;

  always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      wr_state       <= WR_IDLE;
      awready        <= 1'b1;
      wready         <= 1'b1;
      bvalid         <= 1'b0;
      bresp          <= `_AXI_RESP_OKAY_;
      awaddr_latched <= 12'h0;
      wdata_latched  <= 32'h0;
      wstrb_latched  <= 4'h0;
      aw_received    <= 1'b0;
      w_received     <= 1'b0;
      tx_fifo_push   <= 1'b0;
      tx_fifo_din    <= 8'h0;
      uart_ctrl      <= `_UART_CTRL_INIT_;
    end else begin
      tx_fifo_push <= 1'b0;

      case (wr_state)
        WR_IDLE: begin
          if (awvalid && awready) begin
            awaddr_latched <= awaddr[11:0];
            aw_received    <= 1'b1;
            awready        <= 1'b0;
          end
          if (wvalid && wready) begin
            wdata_latched  <= wdata;
            wstrb_latched  <= wstrb;
            w_received     <= 1'b1;
            wready         <= 1'b0;
          end

          if ((aw_received || (awvalid && awready)) && (w_received || (wvalid && wready))) begin
            aw_received <= 1'b0;
            w_received  <= 1'b0;
            awready     <= 1'b0;
            wready      <= 1'b0;
            wr_state    <= WR_EXECUTE;
          end
        end

        WR_EXECUTE: begin
          case (awaddr_latched)
            `_UART_CTRL_: begin
              uart_ctrl <= apply_wstrb(uart_ctrl, wdata_latched, wstrb_latched);
              bresp     <= `_AXI_RESP_OKAY_;
              bvalid    <= 1'b1;
              wr_state  <= WR_RESP;
            end

            `_UART_TXDATA_: begin
              // Non-blocking FIFO write: if TX FIFO is full, return SLVERR
              if (tx_fifo_full) begin
                bresp    <= `_AXI_RESP_SLVERR_;
                bvalid   <= 1'b1;
                wr_state <= WR_RESP;
              end else begin
                tx_fifo_din  <= wdata_latched[7:0];
                tx_fifo_push <= 1'b1;
                bresp        <= `_AXI_RESP_OKAY_;
                bvalid       <= 1'b1;
                wr_state     <= WR_RESP;
              end
            end

            // Read-only registers or unmapped offsets -> Return SLVERR
            `_UART_STATUS_,
            `_UART_RXDATA_: begin
              bresp    <= `_AXI_RESP_SLVERR_;
              bvalid   <= 1'b1;
              wr_state <= WR_RESP;
            end

            default: begin
              // Any offset not mapped or > 0x0C returns SLVERR
              bresp    <= `_AXI_RESP_SLVERR_;
              bvalid   <= 1'b1;
              wr_state <= WR_RESP;
            end
          endcase
        end

        WR_RESP: begin
          if (bready && bvalid) begin
            bvalid   <= 1'b0;
            awready  <= 1'b1;
            wready   <= 1'b1;
            wr_state <= WR_IDLE;
          end
        end

        default: wr_state <= WR_IDLE;
      endcase
    end
  end

  /* -------------------------------------------------------------------------
   * AXI4-Lite Read Channel FSM
   * -------------------------------------------------------------------------*/
  localparam RD_IDLE = 1'b0;
  localparam RD_RESP = 1'b1;

  reg rd_state;

  always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      rd_state     <= RD_IDLE;
      arready      <= 1'b1;
      rvalid       <= 1'b0;
      rdata        <= 32'h0;
      rresp        <= `_AXI_RESP_OKAY_;
      rx_fifo_pull <= 1'b0;
      overrun_flag <= 1'b0;
    end else begin
      rx_fifo_pull <= 1'b0;

      // Track Overrun condition: byte received while RX FIFO is full
      if (rx_fifo_push && rx_fifo_full) begin
        overrun_flag <= 1'b1;
      end

      case (rd_state)
        RD_IDLE: begin
          if (arvalid && arready) begin
            arready <= 1'b0;

            case (araddr[11:0])
              `_UART_CTRL_: begin
                rdata    <= uart_ctrl;
                rresp    <= `_AXI_RESP_OKAY_;
                rvalid   <= 1'b1;
                rd_state <= RD_RESP;
              end

              `_UART_STATUS_: begin
                rdata        <= {29'h0, overrun_flag, rx_valid, tx_ready};
                rresp        <= `_AXI_RESP_OKAY_;
                rvalid       <= 1'b1;
                overrun_flag <= 1'b0; // Reading STATUS clears sticky overrun
                rd_state     <= RD_RESP;
              end

              `_UART_RXDATA_: begin
                // Non-blocking FIFO read: if RX FIFO is empty, return SLVERR immediately
                if (!rx_valid) begin
                  rdata    <= 32'h0;
                  rresp    <= `_AXI_RESP_SLVERR_;
                  rvalid   <= 1'b1;
                  rd_state <= RD_RESP;
                end else begin
                  rdata        <= {24'h0, rx_fifo_dout};
                  rresp        <= `_AXI_RESP_OKAY_;
                  rvalid       <= 1'b1;
                  rx_fifo_pull <= 1'b1;
                  rd_state     <= RD_RESP;
                end
              end

              // Write-only registers or unmapped offsets -> Return SLVERR
              `_UART_TXDATA_: begin
                rdata    <= 32'h0;
                rresp    <= `_AXI_RESP_SLVERR_;
                rvalid   <= 1'b1;
                rd_state <= RD_RESP;
              end

              default: begin
                // Any unmapped offset or > 0x0C returns SLVERR
                rdata    <= 32'h0;
                rresp    <= `_AXI_RESP_SLVERR_;
                rvalid   <= 1'b1;
                rd_state <= RD_RESP;
              end
            endcase
          end
        end

        RD_RESP: begin
          if (rready && rvalid) begin
            rvalid   <= 1'b0;
            arready  <= 1'b1;
            rd_state <= RD_IDLE;
          end
        end

        default: rd_state <= RD_IDLE;
      endcase
    end
  end

  /* -------------------------------------------------------------------------
   * Interrupt Output Generation (to PIC)
   * Asserted on TX empty or RX valid when UART_CTRL[1] (irq enable) is set
   * -------------------------------------------------------------------------*/
  wire tx_empty = ~tx_has_data;
  assign irq_uart = ctrl_irq_en & (tx_empty | rx_valid);

  /* -------------------------------------------------------------------------
   * Transmit FIFO (AXI Bus -> UART Transmitter)
   * -------------------------------------------------------------------------*/
  axi_internal_fifo #(
    .FIFO_SIZE    (FIFO_DEPTH),
    .DATA_SIZE    (DATA_WIDTH),
    .INDEX_LENGTH (FIFO_ADDR_BITS),
    .PORT_EN      (3'b111)  // load | full | available_space
  ) u_tx_fifo (
    .clk_i    (clk),
    .arstn_i  (rst_n),
    .rst_i    (1'b0),
    .push_i   (tx_fifo_push),
    .pull_i   (tx_fifo_pull),
    .data_i   (tx_fifo_din),
    .data_o   (tx_fifo_dout),
    .status_o (tx_status)
  );

  /* -------------------------------------------------------------------------
   * Receive FIFO (UART Receiver -> AXI Bus)
   * -------------------------------------------------------------------------*/
  axi_internal_fifo #(
    .FIFO_SIZE    (FIFO_DEPTH),
    .DATA_SIZE    (DATA_WIDTH),
    .INDEX_LENGTH (FIFO_ADDR_BITS),
    .PORT_EN      (3'b111)  // load | full | available_space
  ) u_rx_fifo (
    .clk_i    (clk),
    .arstn_i  (rst_n),
    .rst_i    (1'b0),
    .push_i   (rx_fifo_push),
    .pull_i   (rx_fifo_pull),
    .data_i   (rx_fifo_din),
    .data_o   (rx_fifo_dout),
    .status_o (rx_status)
  );

  /* -------------------------------------------------------------------------
   * UART Controller Core (Transmitter and Receiver Modules)
   * -------------------------------------------------------------------------*/
  uart_controller #(
    .DATA_UART (DATA_WIDTH),
    .DATA_SIZE (32),
    .DIV_SIZE  (16)
  ) u_uart_controller (
    .clk_i                  (clk),
    .rstn_i                 (rst_n),
    .uart_en_i              (ctrl_en),
    .uart_stop_bits_i       (1'b0), // 1 stop bit
    .uart_parity_bit_i      (1'b0), // no parity
    .uart_parity_bit_mode_i (1'b0), // odd
    .uart_baudrate_div_i    (baud_divisor),

    // Receiver interface
    .uart_rx_i              (uart_rx),
    .rx_data_o              (rx_fifo_din),
    .rx_push_o              (rx_fifo_push),

    // Transmitter interface
    .uart_tx_o              (uart_tx),
    .tx_load_i              (tx_has_data),
    .tx_data_i              (tx_fifo_dout),
    .tx_pull_o              (tx_fifo_pull)
  );

endmodule

`default_nettype wire
