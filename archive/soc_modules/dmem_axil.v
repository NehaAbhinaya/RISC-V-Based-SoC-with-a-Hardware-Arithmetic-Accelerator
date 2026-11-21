`timescale 1ns / 1ps

/* -------------------------------------------------------------------------------
 * Project        : RISC-V SoC with Hardware Arithmetic Accelerator
 * File           : dmem_axil.v
 * Description    : AXI4-Lite Data Memory (Section 5, Page 10)
 *                  - 64 KB capacity (16K x 32-bit words)
 *                  - Single AXI4-Lite slave port used by LSU and DMA via fabric
 *                  - Byte strobes mandatory (sub-word stores from firmware)
 *                  - Addr decode using low 16 bits [15:2]
 * -------------------------------------------------------------------------------*/

`default_nettype none

module dmem_axil #(
  parameter MEM_SIZE_BYTES = 64 * 1024,
  parameter WORDS          = MEM_SIZE_BYTES / 4
)(
  input wire clk,
  input wire rst_n,

  // AXI4-Lite Write Interface
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

  // AXI4-Lite Read Interface
  input  wire [31:0] araddr,
  input  wire [2:0]  arprot,
  input  wire        arvalid,
  output reg         arready,

  output reg  [31:0] rdata,
  output reg  [1:0]  rresp,
  output reg         rvalid,
  input  wire        rready
);

  localparam AXI_OKAY = 2'b00;

  // 16K x 32-bit Memory Array
  reg [31:0] mem [0:WORDS-1];

  integer init_j;
  initial begin
    for (init_j = 0; init_j < WORDS; init_j = init_j + 1) begin
      mem[init_j] = 32'h00000000;
    end
  end

  // Write Channel FSM (Decoupled AW and W)
  localparam WR_IDLE = 2'b00;
  localparam WR_EXEC = 2'b01;
  localparam WR_RESP = 2'b10;

  reg [1:0]  wr_state;
  reg [15:0] awaddr_latched;
  reg [31:0] wdata_latched;
  reg [3:0]  wstrb_latched;
  reg        aw_recv;
  reg        w_recv;

  always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      wr_state       <= WR_IDLE;
      awready        <= 1'b1;
      wready         <= 1'b1;
      bvalid         <= 1'b0;
      bresp          <= AXI_OKAY;
      awaddr_latched <= 16'h0;
      wdata_latched  <= 32'h0;
      wstrb_latched  <= 4'h0;
      aw_recv        <= 1'b0;
      w_recv         <= 1'b0;
    end else begin
      case (wr_state)
        WR_IDLE: begin
          if (awvalid && awready) begin
            awaddr_latched <= awaddr[15:0];
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
          // Perform byte-strobe write
          if (wstrb_latched[0]) mem[awaddr_latched[15:2]][ 7: 0] <= wdata_latched[ 7: 0];
          if (wstrb_latched[1]) mem[awaddr_latched[15:2]][15: 8] <= wdata_latched[15: 8];
          if (wstrb_latched[2]) mem[awaddr_latched[15:2]][23:16] <= wdata_latched[23:16];
          if (wstrb_latched[3]) mem[awaddr_latched[15:2]][31:24] <= wdata_latched[31:24];

          bresp    <= AXI_OKAY;
          bvalid   <= 1'b1;
          wr_state <= WR_RESP;
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

  // Read Channel
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
        rresp   <= AXI_OKAY;
        rdata   <= mem[araddr[15:2]];
      end else if (rvalid && rready) begin
        rvalid  <= 1'b0;
        arready <= 1'b1;
      end
    end
  end

endmodule

`default_nettype wire
