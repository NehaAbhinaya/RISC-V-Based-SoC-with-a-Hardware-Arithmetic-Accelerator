`timescale 1ns / 1ps

/* -------------------------------------------------------------------------------
 * Project        : RISC-V SoC with Hardware Arithmetic Accelerator
 * File           : arithmetic_accelerator.v
 * Description    : Arithmetic Accelerator Module (Section 6, Pages 10-12)
 *                  - Operations: ADD, SUB, MUL, DIV, MAC
 *                  - Dual-interface:
 *                      1. AXI4-Lite Slave Port (Register access, m05, 0x4000_3000)
 *                      2. Dedicated Streaming Interface (to/from DMA Controller)
 *                  - Direct mode test registers (ACC_OPERAND_A, ACC_OPERAND_B, ACC_RESULT)
 *                  - Pipelined datapath with dma_op_ready and dma_res_valid
 *                  - Divide-by-zero detection (sets ACC_STATUS.error, returns 32'hFFFFFFFF)
 *                  - MAC accumulator support (ACC_ACC_REG)
 *                  - Interrupt output irq_acc on job completion
 * -------------------------------------------------------------------------------*/

`default_nettype none

module arithmetic_accelerator (
  input wire clk,
  input wire rst_n,

  // AXI4-Lite Slave Interface (m05)
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

  // Dedicated Streaming Interface (to DMA Controller)
  input  wire        dma_op_valid,
  input  wire [31:0] dma_op_data_a,
  input  wire [31:0] dma_op_data_b,
  output wire        dma_op_ready,

  output reg         dma_res_valid,
  output reg  [31:0] dma_res_data,
  input  wire        dma_res_ready,
  input  wire        dma_last,

  // Interrupt Output to PIC
  output wire        irq_acc
);

  localparam AXI_OKAY   = 2'b00;
  localparam AXI_SLVERR = 2'b10;

  // Opcodes
  localparam OP_ADD = 3'b000;
  localparam OP_SUB = 3'b001;
  localparam OP_MUL = 3'b010;
  localparam OP_DIV = 3'b011;
  localparam OP_MAC = 3'b100;

  // Registers
  reg [2:0]  acc_opcode;
  reg        acc_start;
  reg        acc_busy;
  reg        acc_done;
  reg        acc_error;
  reg [15:0] acc_opcount;
  reg [31:0] acc_operand_a;
  reg [31:0] acc_operand_b;
  reg [31:0] acc_result;
  reg [63:0] acc_mac_reg;
  reg        acc_irq_en;

  assign irq_acc = acc_irq_en & acc_done;

  // Streaming control
  reg in_dma_mode;
  reg res_pending;
  assign dma_op_ready = in_dma_mode & (~res_pending | dma_res_ready);

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

  // Compute ALU function
  function [32:0] compute_alu; // [32] = error
    input [2:0]  op;
    input [31:0] a;
    input [31:0] b;
    input [63:0] mac_acc;
    begin
      case (op)
        OP_ADD: compute_alu = {1'b0, a + b};
        OP_SUB: compute_alu = {1'b0, a - b};
        OP_MUL: compute_alu = {1'b0, a * b};
        OP_DIV: begin
          if (b == 32'h0)
            compute_alu = {1'b1, 32'hFFFFFFFF};
          else
            compute_alu = {1'b0, a / b};
        end
        OP_MAC: compute_alu = {1'b0, mac_acc[31:0] + (a * b)};
        default: compute_alu = {1'b0, 32'h0};
      endcase
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
      wr_state       <= WR_IDLE;
      awready        <= 1'b1;
      wready         <= 1'b1;
      bvalid         <= 1'b0;
      bresp          <= AXI_OKAY;
      awaddr_latched <= 12'h0;
      wdata_latched  <= 32'h0;
      wstrb_latched  <= 4'h0;
      aw_recv        <= 1'b0;
      w_recv         <= 1'b0;
      acc_opcode     <= 3'b000;
      acc_start      <= 1'b0;
      acc_opcount    <= 16'h0;
      acc_operand_a  <= 32'h0;
      acc_operand_b  <= 32'h0;
      acc_mac_reg    <= 64'h0;
      acc_irq_en     <= 1'b0;
    end else begin
      acc_start <= 1'b0;

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
            12'h000: begin // ACC_CTRL
              if (wstrb_latched[0]) begin
                acc_opcode <= wdata_latched[2:0];
                acc_start  <= wdata_latched[3];
                if (wdata_latched[4]) begin // Soft reset
                  acc_mac_reg   <= 64'h0;
                  acc_operand_a <= 32'h0;
                  acc_operand_b <= 32'h0;
                end
              end
              bresp    <= AXI_OKAY;
              bvalid   <= 1'b1;
              wr_state <= WR_RESP;
            end

            12'h008: begin // ACC_OPCOUNT
              acc_opcount <= apply_wstrb({16'h0, acc_opcount}, wdata_latched, wstrb_latched);
              bresp       <= AXI_OKAY;
              bvalid      <= 1'b1;
              wr_state    <= WR_RESP;
            end

            12'h00C: begin // ACC_OPERAND_A
              acc_operand_a <= apply_wstrb(acc_operand_a, wdata_latched, wstrb_latched);
              bresp         <= AXI_OKAY;
              bvalid        <= 1'b1;
              wr_state      <= WR_RESP;
            end

            12'h010: begin // ACC_OPERAND_B
              acc_operand_b <= apply_wstrb(acc_operand_b, wdata_latched, wstrb_latched);
              bresp         <= AXI_OKAY;
              bvalid        <= 1'b1;
              wr_state      <= WR_RESP;
            end

            12'h018: begin // ACC_ACC_REG
              acc_mac_reg[31:0] <= apply_wstrb(acc_mac_reg[31:0], wdata_latched, wstrb_latched);
              bresp             <= AXI_OKAY;
              bvalid            <= 1'b1;
              wr_state          <= WR_RESP;
            end

            12'h01C: begin // ACC_IRQ_EN
              if (wstrb_latched[0]) acc_irq_en <= wdata_latched[0];
              bresp    <= AXI_OKAY;
              bvalid   <= 1'b1;
              wr_state <= WR_RESP;
            end

            default: begin
              // Read-only or > 0x1C returns SLVERR per specification
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
          12'h000: begin rdata <= {29'h0, acc_opcode}; rresp <= AXI_OKAY; end
          12'h004: begin rdata <= {29'h0, acc_error, acc_done, acc_busy}; rresp <= AXI_OKAY; end
          12'h008: begin rdata <= {16'h0, acc_opcount}; rresp <= AXI_OKAY; end
          12'h00C: begin rdata <= acc_operand_a; rresp <= AXI_OKAY; end
          12'h010: begin rdata <= acc_operand_b; rresp <= AXI_OKAY; end
          12'h014: begin rdata <= acc_result;    rresp <= AXI_OKAY; end
          12'h018: begin rdata <= acc_mac_reg[31:0]; rresp <= AXI_OKAY; end
          12'h01C: begin rdata <= {31'h0, acc_irq_en}; rresp <= AXI_OKAY; end
          default: begin rdata <= 32'h0; rresp <= AXI_SLVERR; end // Offsets > 0x1C return SLVERR
        endcase
      end else if (rvalid && rready) begin
        rvalid  <= 1'b0;
        arready <= 1'b1;
      end
    end
  end

  // Direct Mode Execution & DMA Streaming Datapath
  reg [32:0] alu_out;

  always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      acc_busy      <= 1'b0;
      acc_done      <= 1'b0;
      acc_error     <= 1'b0;
      acc_result    <= 32'h0;
      dma_res_valid <= 1'b0;
      dma_res_data  <= 32'h0;
      res_pending   <= 1'b0;
      in_dma_mode   <= 1'b1;
    end else begin
      // Direct mode trigger
      if (acc_start) begin
        acc_busy   <= 1'b1;
        acc_done   <= 1'b0;
        alu_out    = compute_alu(acc_opcode, acc_operand_a, acc_operand_b, acc_mac_reg);
        acc_result <= alu_out[31:0];
        acc_error  <= alu_out[32];
        if (acc_opcode == OP_MAC) acc_mac_reg <= acc_mac_reg + (acc_operand_a * acc_operand_b);
        acc_busy   <= 1'b0;
        acc_done   <= 1'b1;
      end

      // If pending result was accepted by DMA, clear res_pending and valid
      if (dma_res_valid && dma_res_ready) begin
        dma_res_valid <= 1'b0;
        res_pending   <= 1'b0;
      end

      // DMA streaming execution
      if (dma_op_valid && dma_op_ready) begin
        acc_busy      <= 1'b1;
        alu_out       = compute_alu(acc_opcode, dma_op_data_a, dma_op_data_b, acc_mac_reg);
        dma_res_data  <= alu_out[31:0];
        dma_res_valid <= 1'b1;
        res_pending   <= 1'b1;
        if (alu_out[32]) acc_error <= 1'b1;
        if (acc_opcode == OP_MAC) acc_mac_reg <= acc_mac_reg + (dma_op_data_a * dma_op_data_b);

        if (dma_last) begin
          acc_busy <= 1'b0;
          acc_done <= 1'b1;
        end
      end
    end
  end

endmodule

`default_nettype wire
