`timescale 1ns / 1ps

/* -------------------------------------------------------------------------------
 * Project        : RISC-V SoC with Hardware Arithmetic Accelerator
 * File           : dma_controller.v
 * Description    : Autonomous DMA Controller (Section 7, Pages 12-13)
 *                  - Dual AXI4-Lite interfaces:
 *                      1. Slave Port (m06, 0x4000_4000) for configuration
 *                      2. Master Port (s02) for fabric data movement
 *                  - Dedicated streaming interface to Arithmetic Accelerator
 *                  - Reads operand pairs (A, B) from Data Memory over fabric
 *                  - Streams pairs into Accelerator
 *                  - Receives results and writes them back to Data Memory over fabric
 *                  - Aborts on bus error (non-OKAY bresp/rresp), logging DMA_ERR_ADDR
 *                  - Raises irq_dma on job completion or error
 * -------------------------------------------------------------------------------*/

`default_nettype none

module dma_controller (
  input wire clk,
  input wire rst_n,

  // =========================================================================
  // AXI4-Lite Slave Interface (m06 Configuration)
  // =========================================================================
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

  // =========================================================================
  // AXI4-Lite Master Interface (s02 Data Movement)
  // =========================================================================
  output reg  [31:0] m_awaddr,
  output wire [2:0]  m_awprot,
  output reg         m_awvalid,
  input  wire        m_awready,

  output reg  [31:0] m_wdata,
  output wire [3:0]  m_wstrb,
  output reg         m_wvalid,
  input  wire        m_wready,

  input  wire [1:0]  m_bresp,
  input  wire        m_bvalid,
  output reg         m_bready,

  output reg  [31:0] m_araddr,
  output wire [2:0]  m_arprot,
  output reg         m_arvalid,
  input  wire        m_arready,

  input  wire [31:0] m_rdata,
  input  wire [1:0]  m_rresp,
  input  wire        m_rvalid,
  output reg         m_rready,

  // =========================================================================
  // Dedicated Streaming Interface (to/from Accelerator)
  // =========================================================================
  output reg         dma_op_valid,
  output reg  [31:0] dma_op_data_a,
  output reg  [31:0] dma_op_data_b,
  input  wire        dma_op_ready,

  input  wire        dma_res_valid,
  input  wire [31:0] dma_res_data,
  output reg         dma_res_ready,
  output reg         dma_last,

  // Interrupt Output to PIC
  output wire        irq_dma
);

  localparam AXI_OKAY   = 2'b00;
  localparam AXI_SLVERR = 2'b10;

  assign m_awprot = 3'b000;
  assign m_arprot = 3'b000;
  assign m_wstrb  = 4'hF; // Single-beat full-word writes

  // Configuration Registers
  reg [31:0] dma_src_addr;
  reg [31:0] dma_dst_addr;
  reg [31:0] dma_length;
  reg        dma_start;
  reg        dma_irq_en;
  reg        dma_abort;
  reg        dma_busy;
  reg        dma_done;
  reg        dma_bus_error;
  reg        dma_fifo_overflow;
  reg [31:0] dma_err_addr;

  assign irq_dma = dma_irq_en & (dma_done | dma_bus_error);

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

  // Slave Configuration Write FSM
  localparam S_WR_IDLE = 2'b00;
  localparam S_WR_EXEC = 2'b01;
  localparam S_WR_RESP = 2'b10;
  reg [1:0]  s_wr_state;
  reg [11:0] awaddr_latched;
  reg [31:0] wdata_latched;
  reg [3:0]  wstrb_latched;
  reg        aw_recv;
  reg        w_recv;

  always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      s_wr_state        <= S_WR_IDLE;
      awready           <= 1'b1;
      wready            <= 1'b1;
      bvalid            <= 1'b0;
      bresp             <= AXI_OKAY;
      awaddr_latched    <= 12'h0;
      wdata_latched     <= 32'h0;
      wstrb_latched     <= 4'h0;
      aw_recv           <= 1'b0;
      w_recv            <= 1'b0;
      dma_src_addr      <= 32'h0;
      dma_dst_addr      <= 32'h0;
      dma_length        <= 32'h0;
      dma_start         <= 1'b0;
      dma_irq_en        <= 1'b0;
      dma_abort         <= 1'b0;
    end else begin
      dma_start <= 1'b0;

      case (s_wr_state)
        S_WR_IDLE: begin
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
            aw_recv    <= 1'b0;
            w_recv     <= 1'b0;
            awready    <= 1'b0;
            wready     <= 1'b0;
            s_wr_state <= S_WR_EXEC;
          end
        end

        S_WR_EXEC: begin
          case (awaddr_latched)
            12'h000: begin
              dma_src_addr <= apply_wstrb(dma_src_addr, wdata_latched, wstrb_latched);
              bresp        <= AXI_OKAY;
              bvalid       <= 1'b1;
              s_wr_state   <= S_WR_RESP;
            end

            12'h004: begin
              dma_dst_addr <= apply_wstrb(dma_dst_addr, wdata_latched, wstrb_latched);
              bresp        <= AXI_OKAY;
              bvalid       <= 1'b1;
              s_wr_state   <= S_WR_RESP;
            end

            12'h008: begin
              dma_length <= apply_wstrb(dma_length, wdata_latched, wstrb_latched);
              bresp      <= AXI_OKAY;
              bvalid     <= 1'b1;
              s_wr_state <= S_WR_RESP;
            end

            12'h00C: begin
              if (wstrb_latched[0]) begin
                dma_start  <= wdata_latched[0];
                dma_irq_en <= wdata_latched[1];
                dma_abort  <= wdata_latched[2];
              end
              bresp      <= AXI_OKAY;
              bvalid     <= 1'b1;
              s_wr_state <= S_WR_RESP;
            end

            default: begin
              // Read-only or unmapped
              bresp      <= AXI_SLVERR;
              bvalid     <= 1'b1;
              s_wr_state <= S_WR_RESP;
            end
          endcase
        end

        S_WR_RESP: begin
          if (bready && bvalid) begin
            bvalid     <= 1'b0;
            awready    <= 1'b1;
            wready     <= 1'b1;
            s_wr_state <= S_WR_IDLE;
          end
        end

        default: s_wr_state <= S_WR_IDLE;
      endcase
    end
  end

  // Slave Configuration Read FSM
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
          12'h000: begin rdata <= dma_src_addr; rresp <= AXI_OKAY; end
          12'h004: begin rdata <= dma_dst_addr; rresp <= AXI_OKAY; end
          12'h008: begin rdata <= dma_length;   rresp <= AXI_OKAY; end
          12'h00C: begin rdata <= {29'h0, dma_abort, dma_irq_en, dma_start}; rresp <= AXI_OKAY; end
          12'h010: begin rdata <= {28'h0, dma_fifo_overflow, dma_bus_error, dma_done, dma_busy}; rresp <= AXI_OKAY; end
          12'h014: begin rdata <= dma_err_addr; rresp <= AXI_OKAY; end
          default: begin rdata <= 32'h0;        rresp <= AXI_SLVERR; end
        endcase
      end else if (rvalid && rready) begin
        rvalid  <= 1'b0;
        arready <= 1'b1;
      end
    end
  end

  // =========================================================================
  // Master Engine FSM (Operand Fetch -> Stream -> Writeback)
  // =========================================================================
  localparam M_IDLE       = 3'b000;
  localparam M_READ_A     = 3'b001;
  localparam M_READ_B     = 3'b010;
  localparam M_STREAM_OP  = 3'b011;
  localparam M_RECV_RES   = 3'b100;
  localparam M_WRITE_RES  = 3'b101;
  localparam M_ERROR      = 3'b110;

  reg [2:0]  m_state;
  reg [31:0] current_src;
  reg [31:0] current_dst;
  reg [15:0] pair_count;
  reg [31:0] operand_a_val;
  reg [31:0] operand_b_val;
  reg [31:0] result_val;

  always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      m_state           <= M_IDLE;
      dma_busy          <= 1'b0;
      dma_done          <= 1'b0;
      dma_bus_error     <= 1'b0;
      dma_fifo_overflow <= 1'b0;
      dma_err_addr      <= 32'h0;
      m_araddr          <= 32'h0;
      m_arvalid         <= 1'b0;
      m_rready          <= 1'b0;
      m_awaddr          <= 32'h0;
      m_awvalid         <= 1'b0;
      m_wdata           <= 32'h0;
      m_wvalid          <= 1'b0;
      m_bready          <= 1'b0;
      dma_op_valid      <= 1'b0;
      dma_op_data_a     <= 32'h0;
      dma_op_data_b     <= 32'h0;
      dma_res_ready     <= 1'b0;
      dma_last          <= 1'b0;
      current_src       <= 32'h0;
      current_dst       <= 32'h0;
      pair_count        <= 16'h0;
    end else begin
      case (m_state)
        M_IDLE: begin
          dma_op_valid <= 1'b0;
          dma_last     <= 1'b0;
          if (dma_start && (dma_length > 0)) begin
            dma_busy          <= 1'b1;
            dma_done          <= 1'b0;
            dma_bus_error     <= 1'b0;
            dma_fifo_overflow <= 1'b0;
            current_src       <= dma_src_addr;
            current_dst       <= dma_dst_addr;
            pair_count        <= 16'h0;

            // Start reading operand A
            m_araddr  <= dma_src_addr;
            m_arvalid <= 1'b1;
            m_rready  <= 1'b1;
            m_state   <= M_READ_A;
          end
        end

        M_READ_A: begin
          if (m_arvalid && m_arready) m_arvalid <= 1'b0;
          if (m_rvalid && m_rready) begin
            m_rready      <= 1'b0;
            operand_a_val <= m_rdata;

            if (m_rresp != AXI_OKAY) begin
              dma_err_addr <= current_src;
              m_state      <= M_ERROR;
            end else begin
              // Start reading operand B
              current_src <= current_src + 4;
              m_araddr    <= current_src + 4;
              m_arvalid   <= 1'b1;
              m_rready    <= 1'b1;
              m_state     <= M_READ_B;
            end
          end
        end

        M_READ_B: begin
          if (m_arvalid && m_arready) m_arvalid <= 1'b0;
          if (m_rvalid && m_rready) begin
            m_rready      <= 1'b0;
            operand_b_val <= m_rdata;

            if (m_rresp != AXI_OKAY) begin
              dma_err_addr <= current_src;
              m_state      <= M_ERROR;
            end else begin
              current_src   <= current_src + 4;
              dma_op_data_a <= operand_a_val;
              dma_op_data_b <= m_rdata;
              dma_op_valid  <= 1'b1;
              dma_last      <= (pair_count == dma_length - 1);
              dma_res_ready <= 1'b1;
              m_state       <= M_STREAM_OP;
            end
          end
        end

        M_STREAM_OP: begin
          if (dma_op_valid && dma_op_ready) begin
            dma_op_valid  <= 1'b0;
            dma_res_ready <= 1'b1;
            m_state       <= M_RECV_RES;
          end
        end

        M_RECV_RES: begin
          if (dma_res_valid && dma_res_ready) begin
            dma_res_ready <= 1'b0;
            result_val    <= dma_res_data;

            // Start writing result to memory
            m_awaddr  <= current_dst;
            m_awvalid <= 1'b1;
            m_wdata   <= dma_res_data;
            m_wvalid  <= 1'b1;
            m_bready  <= 1'b1;
            m_state   <= M_WRITE_RES;
          end
        end

        M_WRITE_RES: begin
          if (m_awvalid && m_awready) m_awvalid <= 1'b0;
          if (m_wvalid && m_wready)   m_wvalid  <= 1'b0;
          if (m_bvalid && m_bready) begin
            m_bready <= 1'b0;
            if (m_bresp != AXI_OKAY) begin
              dma_err_addr <= current_dst;
              m_state      <= M_ERROR;
            end else begin
              current_dst <= current_dst + 4;
              pair_count  <= pair_count + 1;

              if (pair_count + 1 >= dma_length) begin
                dma_busy <= 1'b0;
                dma_done <= 1'b1;
                m_state  <= M_IDLE;
              end else begin
                // Read next pair
                m_araddr  <= current_src;
                m_arvalid <= 1'b1;
                m_rready  <= 1'b1;
                m_state   <= M_READ_A;
              end
            end
          end
        end

        M_ERROR: begin
          dma_bus_error <= 1'b1;
          dma_busy      <= 1'b0;
          m_arvalid     <= 1'b0;
          m_awvalid     <= 1'b0;
          m_wvalid      <= 1'b0;
          dma_op_valid  <= 1'b0;
          m_state       <= M_IDLE;
        end

        default: m_state <= M_IDLE;
      endcase
    end
  end

endmodule

`default_nettype wire
