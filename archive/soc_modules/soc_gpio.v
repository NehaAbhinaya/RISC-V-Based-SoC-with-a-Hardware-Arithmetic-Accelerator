`timescale 1ns / 1ps

/* -------------------------------------------------------------------------------
 * Project        : RISC-V SoC with Hardware Arithmetic Accelerator
 * File           : soc_gpio.v
 * Description    : AXI4-Lite GPIO Peripheral Module (Section 11, Pages 16-17)
 *                  - Registers:
 *                      0x00 GPIO_DIR        : Output-enable mask
 *                      0x04 GPIO_OUT        : Drives external gpio_out
 *                      0x08 GPIO_IN         : Reads external gpio_in
 *                      0x0C GPIO_INT_EN     : Per-bit edge-interrupt enable
 *                      0x10 GPIO_INT_STATUS : Latched edge flags (R/W1C)
 *                  - Generates irq_gpio on detected input edges
 * -------------------------------------------------------------------------------*/

`default_nettype none

module soc_gpio #(
  parameter N = 8
)(
  input wire clk,
  input wire rst_n,

  // AXI4-Lite Slave Interface (m04)
  input  wire [31:0] awaddr,
  input  wire [2:0]  awprot,
  input  wire        awvalid,
  output reg         awready,

  input  wire [31:0] wdata,
  input  wire [3:0]  wstrb,
  input  wire        wvalid,
  output reg         wready,

  output reg  [1:0]  bresp,
  output reg         bvalid,
  input  wire        bready,

  input  wire [31:0] araddr,
  input  wire [2:0]  arprot,
  input  wire        arvalid,
  output reg         arready,

  output reg  [31:0] rdata,
  output reg  [1:0]  rresp,
  output reg         rvalid,
  input  wire        rready,

  // External GPIO Pins
  input  wire [N-1:0] gpio_in,
  output wire [N-1:0] gpio_out,

  // Interrupt Output to PIC
  output wire        irq_gpio
);

  localparam AXI_OKAY   = 2'b00;
  localparam AXI_SLVERR = 2'b10;

  reg [N-1:0] gpio_dir_reg;
  reg [N-1:0] gpio_out_reg;
  reg [N-1:0] gpio_int_en_reg;
  reg [N-1:0] gpio_int_status_reg;

  // Assign outputs
  assign gpio_out = gpio_out_reg & gpio_dir_reg;
  assign irq_gpio = |(gpio_int_status_reg & gpio_int_en_reg);

  // Edge detection on gpio_in
  reg [N-1:0] gpio_in_d;
  always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      gpio_in_d <= {N{1'b0}};
    end else begin
      gpio_in_d <= gpio_in;
    end
  end

  wire [N-1:0] gpio_edge = gpio_in & ~gpio_in_d;

  // Helper function for write strobes
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

  // AXI4-Lite Write Channel
  localparam WR_IDLE = 2'b00;
  localparam WR_EXEC = 2'b01;
  localparam WR_RESP = 2'b10;
  reg [1:0]  wr_state;
  reg [11:0] awaddr_latched;
  reg [31:0] wdata_latched;
  reg [3:0]  wstrb_latched;
  reg        aw_recv;
  reg        w_recv;

  always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      wr_state            <= WR_IDLE;
      awready             <= 1'b1;
      wready              <= 1'b1;
      bvalid              <= 1'b0;
      bresp               <= AXI_OKAY;
      awaddr_latched      <= 12'h0;
      wdata_latched       <= 32'h0;
      wstrb_latched       <= 4'h0;
      aw_recv             <= 1'b0;
      w_recv              <= 1'b0;
      gpio_dir_reg        <= {N{1'b0}};
      gpio_out_reg        <= {N{1'b0}};
      gpio_int_en_reg     <= {N{1'b0}};
      gpio_int_status_reg <= {N{1'b0}};
    end else begin
      // Latch edges
      gpio_int_status_reg <= gpio_int_status_reg | gpio_edge;

      case (wr_state)
        WR_IDLE: begin
          if (awvalid && awready) begin
            awaddr_latched <= awaddr[11:0];
            aw_recv        <= 1'b1;
            awready        <= 1'b0;
          end
          if (wvalid && wready) begin
            wdata_latched  <= wdata;
            wstrb_latched  <= wstrb;
            w_recv         <= 1'b1;
            wready         <= 1'b0;
          end

          if ((aw_recv || (awvalid && awready)) && (w_recv || (wvalid && wready))) begin
            aw_recv  <= 1'b0;
            w_recv   <= 1'b0;
            awready  <= 1'b0;
            wready   <= 1'b0;
            wr_state <= WR_EXEC;
          end
        end

        WR_EXEC: begin
          case (awaddr_latched)
            12'h000: begin // GPIO_DIR
              gpio_dir_reg <= apply_wstrb({{(32-N){1'b0}}, gpio_dir_reg}, wdata_latched, wstrb_latched);
              bresp        <= AXI_OKAY;
              bvalid       <= 1'b1;
              wr_state     <= WR_RESP;
            end

            12'h004: begin // GPIO_OUT
              gpio_out_reg <= apply_wstrb({{(32-N){1'b0}}, gpio_out_reg}, wdata_latched, wstrb_latched);
              bresp        <= AXI_OKAY;
              bvalid       <= 1'b1;
              wr_state     <= WR_RESP;
            end

            12'h00C: begin // GPIO_INT_EN
              gpio_int_en_reg <= apply_wstrb({{(32-N){1'b0}}, gpio_int_en_reg}, wdata_latched, wstrb_latched);
              bresp           <= AXI_OKAY;
              bvalid          <= 1'b1;
              wr_state        <= WR_RESP;
            end

            12'h010: begin // GPIO_INT_STATUS (W1C)
              gpio_int_status_reg <= gpio_int_status_reg & ~apply_wstrb({32{1'b0}}, wdata_latched, wstrb_latched);
              bresp               <= AXI_OKAY;
              bvalid              <= 1'b1;
              wr_state            <= WR_RESP;
            end

            default: begin
              bresp    <= AXI_SLVERR;
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

  // AXI4-Lite Read Channel
  always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      arready <= 1'b1;
      rvalid  <= 1'b0;
      rdata   <= 32'h0;
      rresp   <= AXI_OKAY;
    end else begin
      if (arvalid && arready) begin
        arready <= 1'b0;
        rvalid  <= 1'b1;
        case (araddr[11:0])
          12'h000: begin rdata <= {{(32-N){1'b0}}, gpio_dir_reg};        rresp <= AXI_OKAY; end
          12'h004: begin rdata <= {{(32-N){1'b0}}, gpio_out_reg};        rresp <= AXI_OKAY; end
          12'h008: begin rdata <= {{(32-N){1'b0}}, gpio_in};             rresp <= AXI_OKAY; end
          12'h00C: begin rdata <= {{(32-N){1'b0}}, gpio_int_en_reg};     rresp <= AXI_OKAY; end
          12'h010: begin rdata <= {{(32-N){1'b0}}, gpio_int_status_reg}; rresp <= AXI_OKAY; end
          default: begin rdata <= 32'h0;                                 rresp <= AXI_SLVERR; end
        endcase
      end else if (rvalid && rready) begin
        rvalid  <= 1'b0;
        arready <= 1'b1;
      end
    end
  end

endmodule

`default_nettype wire
