`timescale 1ns / 1ps

/* -------------------------------------------------------------------------------
 * Project        : AXI-lite SPI IP Core
 * File           : axi_spi_top.v
 * Description    : AXI4-Lite SPI Slave Module
 *                  Updated and modified according to Project Specification:
 *                  - Pure single-clock synchronous design (clk, rst_n active-low)
 *                  - Standard 19-signal AXI4-Lite slave interface (no ID ports)
 *                  - Decoupled AW and W handshakes (AW/W in any order or together)
 *                  - 12-bit address decode (4 KB window), SLVERR for invalid offsets
 *                  - Full write strobe (wstrb) support with per-byte preserve
 *                  - Non-blocking FIFO operations: immediate SLVERR on full TX or empty RX
 *                  - Complete Interrupt Generation: GIER, ISR, IER, and irq_spi output
 *                  - Soft reset via SPI_SRR (0x0000000A)
 * -------------------------------------------------------------------------------*/

`default_nettype none

module axi_spi_top (
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

  // SPI External Interface Pins
  output wire        spi_sclk,
  output wire        spi_cs_n,
  output wire        spi_mosi,
  input  wire        spi_miso,

  // Interrupt Output to PIC
  output wire        irq_spi
);

  /* Includes */
  `include "axi_spi_defines.vh"
  `include "axi_spi.vh"

  /* Local parameters */
  localparam DATA_WIDTH_SPI   = `_DATA_WIDTH_SPI_;
  localparam SPI_RATIO_GRADE  = `_SPI_RATIO_GRADE_;
  localparam FIFO_DEPTH       = `_AXI_SPI_FIFO_DEPTH_;
  localparam FIFO_ADDR        = $clog2(FIFO_DEPTH);

  /* Internal Registers */
  reg [31:0] spi_control_reg;
  reg [31:0] spi_slave_select_reg;
  reg [31:0] spi_global_interrupt_en_reg;
  reg [31:0] spi_interrupt_status_reg;
  reg [31:0] spi_interrupt_enable_reg;
  reg [SPI_RATIO_GRADE-1:0] spi_ratio_reg;
  reg        soft_reset;

  /* Controller Interconnect Signals */
  wire [31:0]              spi_status_reg;
  wire                     spi_tx_fifo_full_comb; // Direct combinational TX full flag
  wire [31:0]              spi_tx_fifo_occupancy_reg;
  wire [31:0]              spi_rx_fifo_occupancy_reg;
  reg                      spi_tx_fifo_req;
  reg  [DATA_WIDTH_SPI-1:0] spi_tx_fifo_data;
  wire                     spi_tx_fifo_ack;
  reg                      spi_rx_fifo_req;
  wire [DATA_WIDTH_SPI-1:0] spi_rx_fifo_data;
  wire                     spi_rx_fifo_resp;
  reg                      spi_rx_fifo_ack;

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
  localparam WR_IDLE     = 2'b00;
  localparam WR_EXECUTE  = 2'b01;
  localparam WR_WAIT_ACK = 2'b10;
  localparam WR_RESP     = 2'b11;

  reg [1:0]  wr_state;
  reg [11:0] awaddr_latched;
  reg [31:0] wdata_latched;
  reg [3:0]  wstrb_latched;
  reg        aw_received;
  reg        w_received;

  always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      wr_state                      <= WR_IDLE;
      awready                       <= 1'b1;
      wready                        <= 1'b1;
      bvalid                        <= 1'b0;
      bresp                         <= `_AXI_RESP_OKAY_;
      awaddr_latched                <= 12'h0;
      wdata_latched                 <= 32'h0;
      wstrb_latched                 <= 4'h0;
      aw_received                   <= 1'b0;
      w_received                    <= 1'b0;
      spi_tx_fifo_req               <= 1'b0;
      spi_tx_fifo_data              <= {DATA_WIDTH_SPI{1'b0}};
      spi_control_reg               <= `_SPI_CR_INIT_;
      spi_slave_select_reg          <= `_SPI_SSR_INIT_;
      spi_global_interrupt_en_reg   <= `_SPI_GIER_INIT_;
      spi_interrupt_status_reg      <= `_SPI_ISR_INIT_;
      spi_interrupt_enable_reg      <= `_SPI_IER_INIT_;
      spi_ratio_reg                 <= (`_SPI_RCLK_INIT_ & ((1<<SPI_RATIO_GRADE)-1));
      soft_reset                    <= 1'b0;
    end else begin
      // Default auto-clearing / single-cycle pulses
      spi_tx_fifo_req <= 1'b0;
      soft_reset      <= 1'b0;
      // Auto-clear self-clearing FIFO reset bits in Control Register
      spi_control_reg[`_CR_TX_FIFO_RESET_BIT_] <= 1'b0;
      spi_control_reg[`_CR_RX_FIFO_RESET_BIT_] <= 1'b0;

      // Update ISR bits from hardware events
      if (spi_status_reg[`_SR_TX_EMPTY_BIT_]) begin
        spi_interrupt_status_reg[`_INT_TX_EMPTY_BIT_] <= 1'b1;
      end
      if (!spi_status_reg[`_SR_RX_EMPTY_BIT_]) begin
        spi_interrupt_status_reg[`_INT_RX_AVAIL_BIT_] <= 1'b1;
      end
      if (spi_status_reg[`_SR_MODF_BIT_]) begin
        spi_interrupt_status_reg[`_INT_MODF_BIT_] <= 1'b1;
      end

      case (wr_state)
        WR_IDLE: begin
          // Capture AW
          if (awvalid && awready) begin
            awaddr_latched <= awaddr[11:0];
            aw_received    <= 1'b1;
            awready        <= 1'b0;
          end
          // Capture W
          if (wvalid && wready) begin
            wdata_latched  <= wdata;
            wstrb_latched  <= wstrb;
            w_received     <= 1'b1;
            wready         <= 1'b0;
          end

          // Check if both AW and W are captured (either this cycle or already captured)
          if ((aw_received || (awvalid && awready)) && (w_received || (wvalid && wready))) begin
            aw_received <= 1'b0;
            w_received  <= 1'b0;
            awready     <= 1'b0;
            wready      <= 1'b0;
            wr_state    <= WR_EXECUTE;
          end
        end

        WR_EXECUTE: begin
          // Execute register write based on decoded 12-bit address
          case (awaddr_latched)
            `_SPI_GIER_: begin
              spi_global_interrupt_en_reg <= apply_wstrb(spi_global_interrupt_en_reg, wdata_latched, wstrb_latched);
              bresp                       <= `_AXI_RESP_OKAY_;
              bvalid                      <= 1'b1;
              wr_state                    <= WR_RESP;
            end

            `_SPI_ISR_: begin
              // Toggle on write per specification
              spi_interrupt_status_reg <= spi_interrupt_status_reg ^ apply_wstrb(32'h0, wdata_latched, wstrb_latched);
              bresp                    <= `_AXI_RESP_OKAY_;
              bvalid                   <= 1'b1;
              wr_state                 <= WR_RESP;
            end

            `_SPI_IER_: begin
              spi_interrupt_enable_reg <= apply_wstrb(spi_interrupt_enable_reg, wdata_latched, wstrb_latched);
              bresp                    <= `_AXI_RESP_OKAY_;
              bvalid                   <= 1'b1;
              wr_state                 <= WR_RESP;
            end

            `_SPI_RCLK_: begin
              spi_ratio_reg <= apply_wstrb({{(32-SPI_RATIO_GRADE){1'b0}}, spi_ratio_reg}, wdata_latched, wstrb_latched);
              bresp         <= `_AXI_RESP_OKAY_;
              bvalid        <= 1'b1;
              wr_state      <= WR_RESP;
            end

            `_SPI_SRR_: begin
              if (wdata_latched == `_SPI_SRR_VALUE_) begin
                soft_reset                  <= 1'b1;
                spi_control_reg             <= `_SPI_CR_INIT_;
                spi_slave_select_reg        <= `_SPI_SSR_INIT_;
                spi_global_interrupt_en_reg <= `_SPI_GIER_INIT_;
                spi_interrupt_status_reg    <= `_SPI_ISR_INIT_;
                spi_interrupt_enable_reg    <= `_SPI_IER_INIT_;
                spi_ratio_reg               <= (`_SPI_RCLK_INIT_ & ((1<<SPI_RATIO_GRADE)-1));
              end
              bresp  <= `_AXI_RESP_OKAY_;
              bvalid <= 1'b1;
              wr_state <= WR_RESP;
            end

            `_SPI_CR_: begin
              spi_control_reg <= apply_wstrb(spi_control_reg, wdata_latched, wstrb_latched);
              bresp           <= `_AXI_RESP_OKAY_;
              bvalid          <= 1'b1;
              wr_state        <= WR_RESP;
            end

            `_SPI_DTR_: begin
              // Non-blocking FIFO write: if TX FIFO is full (comb), return SLVERR immediately
              if (spi_tx_fifo_full_comb) begin
                bresp    <= `_AXI_RESP_SLVERR_;
                bvalid   <= 1'b1;
                wr_state <= WR_RESP;
              end else begin
                spi_tx_fifo_data <= wdata_latched[DATA_WIDTH_SPI-1:0];
                spi_tx_fifo_req  <= 1'b1;
                wr_state         <= WR_WAIT_ACK;
              end
            end

            `_SPI_SSR_: begin
              spi_slave_select_reg <= apply_wstrb(spi_slave_select_reg, wdata_latched, wstrb_latched);
              bresp                <= `_AXI_RESP_OKAY_;
              bvalid               <= 1'b1;
              wr_state             <= WR_RESP;
            end

            // Read-only registers or unknown offsets -> Return SLVERR
            `_SPI_SR_,
            `_SPI_DRR_,
            `_SPI_TFOR_,
            `_SPI_RFOR_: begin
              bresp    <= `_AXI_RESP_SLVERR_;
              bvalid   <= 1'b1;
              wr_state <= WR_RESP;
            end

            default: begin
              // Any offset not mapped or > 0x7F returns SLVERR
              bresp    <= `_AXI_RESP_SLVERR_;
              bvalid   <= 1'b1;
              wr_state <= WR_RESP;
            end
          endcase
        end

        WR_WAIT_ACK: begin
          // Wait for TX FIFO push acknowledge
          spi_tx_fifo_req <= 1'b0;
          if (spi_tx_fifo_ack) begin
            // FIFO accepted the push
            bresp    <= `_AXI_RESP_OKAY_;
            bvalid   <= 1'b1;
            wr_state <= WR_RESP;
          end else if (spi_tx_fifo_full_comb) begin
            // FIFO was full at push time: reject with SLVERR (non-blocking)
            bresp    <= `_AXI_RESP_SLVERR_;
            bvalid   <= 1'b1;
            wr_state <= WR_RESP;
          end
          // else: keep waiting for ack (FIFO will eventually accept)
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
  localparam RD_IDLE     = 2'b00;
  localparam RD_WAIT_ACK = 2'b01;
  localparam RD_RESP     = 2'b10;

  reg [1:0]  rd_state;
  reg [11:0] araddr_latched;

  always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      rd_state        <= RD_IDLE;
      arready         <= 1'b1;
      rvalid          <= 1'b0;
      rdata           <= 32'h0;
      rresp           <= `_AXI_RESP_OKAY_;
      araddr_latched  <= 12'h0;
      spi_rx_fifo_req <= 1'b0;
      spi_rx_fifo_ack <= 1'b0;
    end else begin
      spi_rx_fifo_req <= 1'b0;
      spi_rx_fifo_ack <= 1'b0;

      case (rd_state)
        RD_IDLE: begin
          if (arvalid && arready) begin
            araddr_latched <= araddr[11:0];
            arready        <= 1'b0;

            case (araddr[11:0])
              `_SPI_GIER_: begin
                rdata    <= spi_global_interrupt_en_reg;
                rresp    <= `_AXI_RESP_OKAY_;
                rvalid   <= 1'b1;
                rd_state <= RD_RESP;
              end

              `_SPI_ISR_: begin
                rdata    <= spi_interrupt_status_reg;
                rresp    <= `_AXI_RESP_OKAY_;
                rvalid   <= 1'b1;
                rd_state <= RD_RESP;
              end

              `_SPI_IER_: begin
                rdata    <= spi_interrupt_enable_reg;
                rresp    <= `_AXI_RESP_OKAY_;
                rvalid   <= 1'b1;
                rd_state <= RD_RESP;
              end

              `_SPI_RCLK_: begin
                rdata    <= {{(32-SPI_RATIO_GRADE){1'b0}}, spi_ratio_reg};
                rresp    <= `_AXI_RESP_OKAY_;
                rvalid   <= 1'b1;
                rd_state <= RD_RESP;
              end

              `_SPI_CR_: begin
                rdata    <= spi_control_reg;
                rresp    <= `_AXI_RESP_OKAY_;
                rvalid   <= 1'b1;
                rd_state <= RD_RESP;
              end

              `_SPI_SR_: begin
                rdata    <= spi_status_reg;
                rresp    <= `_AXI_RESP_OKAY_;
                rvalid   <= 1'b1;
                rd_state <= RD_RESP;
              end

              `_SPI_DRR_: begin
                // Non-blocking FIFO read: if RX FIFO is empty, return SLVERR immediately
                if (spi_status_reg[`_SR_RX_EMPTY_BIT_]) begin
                  rdata    <= 32'h0;
                  rresp    <= `_AXI_RESP_SLVERR_;
                  rvalid   <= 1'b1;
                  rd_state <= RD_RESP;
                end else begin
                  spi_rx_fifo_req <= 1'b1;
                  rd_state        <= RD_WAIT_ACK;
                end
              end

              `_SPI_SSR_: begin
                rdata    <= spi_slave_select_reg;
                rresp    <= `_AXI_RESP_OKAY_;
                rvalid   <= 1'b1;
                rd_state <= RD_RESP;
              end

              `_SPI_TFOR_: begin
                rdata    <= spi_tx_fifo_occupancy_reg;
                rresp    <= `_AXI_RESP_OKAY_;
                rvalid   <= 1'b1;
                rd_state <= RD_RESP;
              end

              `_SPI_RFOR_: begin
                rdata    <= spi_rx_fifo_occupancy_reg;
                rresp    <= `_AXI_RESP_OKAY_;
                rvalid   <= 1'b1;
                rd_state <= RD_RESP;
              end

              // Write-only registers return OKAY with 0 data to prevent bus faults on container reads
              `_SPI_SRR_,
              `_SPI_DTR_: begin
                rdata    <= 32'h0;
                rresp    <= `_AXI_RESP_OKAY_;
                rvalid   <= 1'b1;
                rd_state <= RD_RESP;
              end

              default: begin
                // Any offset not mapped or > 0x7F returns SLVERR and 0 data
                rdata    <= 32'h0;
                rresp    <= `_AXI_RESP_SLVERR_;
                rvalid   <= 1'b1;
                rd_state <= RD_RESP;
              end
            endcase
          end
        end

        RD_WAIT_ACK: begin
          if (spi_rx_fifo_resp) begin
            rdata           <= {{(32-DATA_WIDTH_SPI){1'b0}}, spi_rx_fifo_data};
            rresp           <= `_AXI_RESP_OKAY_;
            rvalid          <= 1'b1;
            spi_rx_fifo_ack <= 1'b1;
            rd_state        <= RD_RESP;
          end else begin
            // Non-blocking fallback
            rdata           <= {{(32-DATA_WIDTH_SPI){1'b0}}, spi_rx_fifo_data};
            rresp           <= `_AXI_RESP_OKAY_;
            rvalid          <= 1'b1;
            spi_rx_fifo_ack <= 1'b1;
            rd_state        <= RD_RESP;
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
   * Interrupt Generation
   * -------------------------------------------------------------------------*/
  wire gie = spi_global_interrupt_en_reg[31] | spi_global_interrupt_en_reg[0];
  assign irq_spi = gie & (|(spi_interrupt_status_reg & spi_interrupt_enable_reg));

  /* -------------------------------------------------------------------------
   * Instantiation of SPI Controller Core
   * -------------------------------------------------------------------------*/
  axi_spi_ctrl #(
    .SPI_RATIO_GRADE  (SPI_RATIO_GRADE),
    .DATA_WIDTH       (DATA_WIDTH_SPI),
    .REG_WIDTH        (32),
    .FIFO_DEPTH       (FIFO_DEPTH),
    .FIFO_ADDR        (FIFO_ADDR),
    .SR_RX_EMPTY_BIT  (`_SR_RX_EMPTY_BIT_),
    .SR_RX_FULL_BIT   (`_SR_RX_FULL_BIT_),
    .SR_TX_EMPTY_BIT  (`_SR_TX_EMPTY_BIT_),
    .SR_TX_FULL_BIT   (`_SR_TX_FULL_BIT_),
    .SR_MODF_BIT      (`_SR_MODF_BIT_),
    .SR_SMOD_SEL_BIT  (`_SR_SMOD_SEL_BIT_)
  ) u_axi_spi_ctrl (
    .clk_i                    (clk),
    .arst_n_i                 (rst_n),
    .soft_rst_i               (soft_reset),

    .slave_select_i           (spi_slave_select_reg[0]),
    .control_lsb_i            (spi_control_reg[`_CR_LSB_FIRST_BIT_]),
    .control_rx_fifo_reset_i  (spi_control_reg[`_CR_RX_FIFO_RESET_BIT_]),
    .control_tx_fifo_reset_i  (spi_control_reg[`_CR_TX_FIFO_RESET_BIT_]),
    .control_cpha_i           (spi_control_reg[`_CR_CPHA_BIT_]),
    .control_cpol_i           (spi_control_reg[`_CR_CPOL_BIT_]),
    .control_master_i         (spi_control_reg[`_CR_MASTER_BIT_]),
    .control_spi_enable_i     (spi_control_reg[`_CR_SPI_ENABLE_BIT_]),
    .status_o                 (spi_status_reg),
    .tx_full_comb_o           (spi_tx_fifo_full_comb),
    .spi_ratio_i              (spi_ratio_reg),

    .tx_req_i                 (spi_tx_fifo_req),
    .tx_data_i                (spi_tx_fifo_data),
    .tx_ack_o                 (spi_tx_fifo_ack),
    .tx_occupancy_o           (spi_tx_fifo_occupancy_reg),

    .rx_req_i                 (spi_rx_fifo_req),
    .rx_data_o                (spi_rx_fifo_data),
    .rx_resp_o                (spi_rx_fifo_resp),
    .rx_ack_i                 (spi_rx_fifo_ack),
    .rx_occupancy_o           (spi_rx_fifo_occupancy_reg),

    .spi_clk_o                (spi_sclk),
    .spi_cs_n_o               (spi_cs_n),
    .spi_mosi_o               (spi_mosi),
    .spi_miso_i               (spi_miso)
  );

endmodule

`default_nettype wire
