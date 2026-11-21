`timescale 1ns / 1ps

/* -------------------------------------------------------------------------------
 * Project        : RISC-V SoC with Hardware Arithmetic Accelerator
 * File           : soc_timer.v
 * Description    : AXI4-Lite Timer Peripheral Module (Section 10, Page 16)
 *                  - Registers:
 *                      0x00 TIMER_CTRL    : [0] enable, [1] periodic, [2] irq enable
 *                      0x04 TIMER_COUNT   : Free-running 32-bit counter
 *                      0x08 TIMER_COMPARE : Compare / reload threshold
 *                      0x0C TIMER_STATUS  : [0] match flag (R/W1C)
 *                  - Generates irq_timer on compare match
 * -------------------------------------------------------------------------------*/

`default_nettype none

module soc_timer (
  input wire clk,
  input wire rst_n,

  // AXI4-Lite Slave Interface (m03)
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

  // Interrupt Output to PIC
  output wire        irq_timer
);

  localparam AXI_OKAY   = 2'b00;
  localparam AXI_SLVERR = 2'b10;

  reg [31:0] timer_ctrl;
  reg [31:0] timer_count;
  reg [31:0] timer_compare;
  reg        timer_match_status;

  wire timer_en       = timer_ctrl[0];
  wire timer_periodic = timer_ctrl[1];
  wire timer_irq_en   = timer_ctrl[2];

  assign irq_timer = timer_irq_en & timer_match_status;

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
      wr_state           <= WR_IDLE;
      awready            <= 1'b1;
      wready             <= 1'b1;
      bvalid             <= 1'b0;
      bresp              <= AXI_OKAY;
      awaddr_latched     <= 12'h0;
      wdata_latched      <= 32'h0;
      wstrb_latched      <= 4'h0;
      aw_recv            <= 1'b0;
      w_recv             <= 1'b0;
      timer_ctrl         <= 32'h0;
      timer_count        <= 32'h0;
      timer_compare      <= 32'h0;
      timer_match_status <= 1'b0;
    end else begin
      // Timer counting logic
      if (timer_en) begin
        if (timer_count == timer_compare && timer_compare != 32'h0) begin
          timer_match_status <= 1'b1;
          if (timer_periodic)
            timer_count <= 32'h0;
          else
            timer_count <= timer_count + 1;
        end else begin
          timer_count <= timer_count + 1;
        end
      end

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
            12'h000: begin // TIMER_CTRL
              timer_ctrl <= apply_wstrb(timer_ctrl, wdata_latched, wstrb_latched);
              bresp      <= AXI_OKAY;
              bvalid     <= 1'b1;
              wr_state   <= WR_RESP;
            end

            12'h008: begin // TIMER_COMPARE
              timer_compare <= apply_wstrb(timer_compare, wdata_latched, wstrb_latched);
              bresp         <= AXI_OKAY;
              bvalid        <= 1'b1;
              wr_state      <= WR_RESP;
            end

            12'h00C: begin // TIMER_STATUS (W1C)
              if (wstrb_latched[0] && wdata_latched[0])
                timer_match_status <= 1'b0;
              bresp    <= AXI_OKAY;
              bvalid   <= 1'b1;
              wr_state <= WR_RESP;
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
          12'h000: begin rdata <= timer_ctrl;          rresp <= AXI_OKAY; end
          12'h004: begin rdata <= timer_count;         rresp <= AXI_OKAY; end
          12'h008: begin rdata <= timer_compare;       rresp <= AXI_OKAY; end
          12'h00C: begin rdata <= {31'h0, timer_match_status}; rresp <= AXI_OKAY; end
          default: begin rdata <= 32'h0;               rresp <= AXI_SLVERR; end
        endcase
      end else if (rvalid && rready) begin
        rvalid  <= 1'b0;
        arready <= 1'b1;
      end
    end
  end

endmodule

`default_nettype wire
