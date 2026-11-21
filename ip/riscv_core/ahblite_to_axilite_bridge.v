`timescale 1ns / 1ps

/* -------------------------------------------------------------------------------
 * Project        : RISC-V SoC with Hardware Arithmetic Accelerator
 * File           : ahblite_to_axilite_bridge.v
 * Description    : AHB-Lite to AXI4-Lite Protocol & Width Bridge (Section 2, Pages 8-9)
 *                  - Translates AHB-Lite slave transactions to AXI4-Lite master
 *                  - Width conversion:
 *                      - 64-bit AHB reads become two sequential 32-bit AXI4-Lite reads
 *                        (low word at haddr, high word at haddr+4)
 *                      - 32-bit/sub-word AHB stores map to 32-bit AXI4-Lite with wstrb
 *                      - 64-bit AHB stores execute two sequential 32-bit writes
 *                  - Absorbs AHB address/data pipelining by de-asserting hready
 *                  - Maps AXI4-Lite SLVERR and DECERR to AHB-Lite two-cycle hresp error
 *                  - Drives awprot/arprot appropriately (3'b100 for fetch, 3'b000 for data)
 * -------------------------------------------------------------------------------*/

`default_nettype none

module ahblite_to_axilite_bridge #(
  parameter IS_FETCH = 0 // 1 = Instruction Fetch (read-only), 0 = LSU (read/write)
)(
  input wire clk,
  input wire rst_n,

  // =========================================================================
  // AHB-Lite Slave Interface (from VeeR EL2 Core)
  // =========================================================================
  input  wire [31:0] haddr,
  input  wire [1:0]  htrans, // 2'b00 IDLE, 2'b10 NONSEQ, 2'b11 SEQ
  input  wire [2:0]  hsize,  // 3'b000 Byte, 3'b001 Halfword, 3'b010 Word, 3'b011 Doubleword
  input  wire [3:0]  hprot,
  input  wire        hwrite,
  input  wire [63:0] hwdata,
  output reg  [63:0] hrdata,
  output reg         hready,
  output reg         hresp,

  // =========================================================================
  // AXI4-Lite Master Interface (to Interconnect Fabric)
  // =========================================================================
  output reg  [31:0] axil_awaddr,
  output wire [2:0]  axil_awprot,
  output reg         axil_awvalid,
  input  wire        axil_awready,

  output reg  [31:0] axil_wdata,
  output reg  [3:0]  axil_wstrb,
  output reg         axil_wvalid,
  input  wire        axil_wready,

  input  wire [1:0]  axil_bresp,
  input  wire        axil_bvalid,
  output reg         axil_bready,

  output reg  [31:0] axil_araddr,
  output wire [2:0]  axil_arprot,
  output reg         axil_arvalid,
  input  wire        axil_arready,

  input  wire [31:0] axil_rdata,
  input  wire [1:0]  axil_rresp,
  input  wire        axil_rvalid,
  output reg         axil_rready
);

  localparam AXI_OKAY = 2'b00;

  assign axil_awprot = IS_FETCH ? 3'b100 : 3'b000;
  assign axil_arprot = IS_FETCH ? 3'b100 : 3'b000;

  // AHB Transfer Encodings
  localparam TRANS_IDLE   = 2'b00;
  localparam TRANS_BUSY   = 2'b01;
  localparam TRANS_NONSEQ = 2'b10;
  localparam TRANS_SEQ    = 2'b11;

  // Bridge States
  localparam ST_IDLE       = 3'b000;
  localparam ST_RD_L       = 3'b001;
  localparam ST_RD_H       = 3'b010;
  localparam ST_WR_L       = 3'b011;
  localparam ST_WR_H       = 3'b100;
  localparam ST_ERR1       = 3'b101;
  localparam ST_ERR2       = 3'b110;

  reg [2:0]  state;
  reg [31:0] addr_reg;
  reg [2:0]  size_reg;
  reg        write_reg;
  reg        is_64bit;
  reg [31:0] rdata_l_reg;
  reg        aw_done;
  reg        w_done;

  wire ahb_req = (htrans == TRANS_NONSEQ) || (htrans == TRANS_SEQ);

  // Compute write strobes for sub-word or word store
  function [3:0] get_wstrb;
    input [2:0] sz;
    input [2:0] byte_offset; // [2:0] of addr
    begin
      case (sz)
        3'b000: get_wstrb = 4'b0001 << byte_offset[1:0]; // Byte
        3'b001: get_wstrb = byte_offset[1] ? 4'b1100 : 4'b0011; // Halfword
        default: get_wstrb = 4'b1111; // Word or Doubleword
      endcase
    end
  endfunction

  always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      state        <= ST_IDLE;
      hready       <= 1'b1;
      hresp        <= 1'b0;
      hrdata       <= 64'h0;
      axil_awaddr  <= 32'h0;
      axil_awvalid <= 1'b0;
      axil_wdata   <= 32'h0;
      axil_wstrb   <= 4'h0;
      axil_wvalid  <= 1'b0;
      axil_bready  <= 1'b0;
      axil_araddr  <= 32'h0;
      axil_arvalid <= 1'b0;
      axil_rready  <= 1'b0;
      addr_reg     <= 32'h0;
      size_reg     <= 3'h0;
      write_reg    <= 1'b0;
      is_64bit     <= 1'b0;
      rdata_l_reg  <= 32'h0;
      aw_done      <= 1'b0;
      w_done       <= 1'b0;
    end else begin
      case (state)
        ST_IDLE: begin
          hresp   <= 1'b0;
          hready  <= 1'b1;
          aw_done <= 1'b0;
          w_done  <= 1'b0;

          if (ahb_req) begin
            addr_reg  <= haddr;
            size_reg  <= hsize;
            write_reg <= hwrite;
            is_64bit  <= (hsize == 3'b011);
            hready    <= 1'b0; // Stall AHB core while AXI transaction executes

            if (!hwrite) begin
              // Read transaction: Issue first 32-bit AXI Read (8-byte aligned if 64-bit)
              if (hsize == 3'b011)
                axil_araddr  <= {haddr[31:3], 3'b000};
              else
                axil_araddr  <= {haddr[31:2], 2'b00};
              axil_arvalid <= 1'b1;
              axil_rready  <= 1'b1;
              state        <= ST_RD_L;
            end else begin
              // Write transaction: wait for AHB data phase (next cycle)
              // We capture hwdata on the next clock
              state        <= ST_WR_L;
            end
          end
        end

        // -------------------------------------------------------------------
        // Read Channel Sequence
        // -------------------------------------------------------------------
        ST_RD_L: begin
          if (axil_arvalid && axil_arready) axil_arvalid <= 1'b0;
          if (axil_rvalid && axil_rready) begin
            axil_rready <= 1'b0;
            if (axil_rresp != AXI_OKAY) begin
              state <= ST_ERR1;
            end else begin
              rdata_l_reg <= axil_rdata;
              if (is_64bit) begin
                // Issue second 32-bit read for upper word (offset + 4)
                axil_araddr  <= {addr_reg[31:3], 3'b000} + 4;
                axil_arvalid <= 1'b1;
                axil_rready  <= 1'b1;
                state        <= ST_RD_H;
              end else begin
                // Single 32-bit read complete
                hrdata <= (addr_reg[2]) ? {axil_rdata, 32'h0} : {32'h0, axil_rdata};
                hready <= 1'b1;
                state  <= ST_IDLE;
              end
            end
          end
        end

        ST_RD_H: begin
          if (axil_arvalid && axil_arready) axil_arvalid <= 1'b0;
          if (axil_rvalid && axil_rready) begin
            axil_rready <= 1'b0;
            if (axil_rresp != AXI_OKAY) begin
              state <= ST_ERR1;
            end else begin
              hrdata <= {axil_rdata, rdata_l_reg};
              hready <= 1'b1;
              state  <= ST_IDLE;
            end
          end
        end

        // -------------------------------------------------------------------
        // Write Channel Sequence
        // -------------------------------------------------------------------
        ST_WR_L: begin
          // Issue write to AXI (only assert valid until accepted)
          if (!aw_done) begin
            if (is_64bit)
              axil_awaddr  <= {addr_reg[31:3], 3'b000};
            else
              axil_awaddr  <= {addr_reg[31:2], 2'b00};
            axil_awvalid <= 1'b1;
          end
          if (!w_done) begin
            if (is_64bit) begin
              axil_wdata   <= hwdata[31:0];
              axil_wstrb   <= 4'hF;
            end else begin
              axil_wdata   <= (addr_reg[2]) ? hwdata[63:32] : hwdata[31:0];
              axil_wstrb   <= get_wstrb(size_reg, addr_reg[2:0]);
            end
            axil_wvalid  <= 1'b1;
          end
          axil_bready  <= 1'b1;

          // Wait for AXI handshake
          if (axil_awvalid && axil_awready) begin
            axil_awvalid <= 1'b0;
            aw_done      <= 1'b1;
          end
          if (axil_wvalid && axil_wready) begin
            axil_wvalid  <= 1'b0;
            w_done       <= 1'b1;
          end
          if (axil_bvalid && axil_bready) begin
            axil_bready <= 1'b0;
            if (axil_bresp != AXI_OKAY) begin
              state <= ST_ERR1;
            end else begin
              if (is_64bit) begin
                aw_done <= 1'b0;
                w_done  <= 1'b0;
                state   <= ST_WR_H;
              end else begin
                hready <= 1'b1;
                state  <= ST_IDLE;
              end
            end
          end
        end

        ST_WR_H: begin
          if (!aw_done) begin
            axil_awaddr  <= {addr_reg[31:3], 3'b000} + 4;
            axil_awvalid <= 1'b1;
          end
          if (!w_done) begin
            axil_wdata   <= hwdata[63:32];
            axil_wstrb   <= 4'hF;
            axil_wvalid  <= 1'b1;
          end
          axil_bready  <= 1'b1;

          if (axil_awvalid && axil_awready) begin
            axil_awvalid <= 1'b0;
            aw_done      <= 1'b1;
          end
          if (axil_wvalid && axil_wready) begin
            axil_wvalid  <= 1'b0;
            w_done       <= 1'b1;
          end
          if (axil_bvalid && axil_bready) begin
            axil_bready <= 1'b0;
            if (axil_bresp != AXI_OKAY) begin
              state <= ST_ERR1;
            end else begin
              hready <= 1'b1;
              state  <= ST_IDLE;
            end
          end
        end

        // -------------------------------------------------------------------
        // Two-cycle AHB Error Response (hresp=1, hready=0 -> hresp=1, hready=1)
        // -------------------------------------------------------------------
        ST_ERR1: begin
          hresp  <= 1'b1;
          hready <= 1'b0;
          state  <= ST_ERR2;
        end

        ST_ERR2: begin
          hresp  <= 1'b1;
          hready <= 1'b1;
          state  <= ST_IDLE;
        end

        default: state <= ST_IDLE;
      endcase
    end
  end

endmodule

`default_nettype wire
