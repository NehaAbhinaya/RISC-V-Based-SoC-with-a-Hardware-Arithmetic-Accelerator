`timescale 1ns / 1ps

/* -------------------------------------------------------------------------------
 * Project        : RISC-V SoC with Hardware Arithmetic Accelerator
 * File           : axil_interconnect.v
 * Description    : Parameterized S-Master x M-Slave AXI4-Lite Interconnect Core
 *                  - Round-robin arbitration over masters
 *                  - Flattened bus interface for masters and slaves
 *                  - Per-slave address decoding and permission checking
 *                  - Internal DECERR generation for unmapped or forbidden accesses
 *                  - Single transaction in flight at a time
 *                  - Active-high synchronous reset 'rst'
 * -------------------------------------------------------------------------------*/

`default_nettype none

module axil_interconnect #(
  parameter S_COUNT    = 3,
  parameter M_COUNT    = 8,
  parameter DATA_WIDTH = 32,
  parameter ADDR_WIDTH = 32,
  parameter STRB_WIDTH = DATA_WIDTH / 8
)(
  input wire clk,
  input wire rst,

  // Flattened Master-facing ports (Slave interface of interconnect)
  input  wire [S_COUNT*ADDR_WIDTH-1:0] s_axil_awaddr,
  input  wire [S_COUNT*3-1:0]          s_axil_awprot,
  input  wire [S_COUNT-1:0]            s_axil_awvalid,
  output reg  [S_COUNT-1:0]            s_axil_awready,

  input  wire [S_COUNT*DATA_WIDTH-1:0] s_axil_wdata,
  input  wire [S_COUNT*STRB_WIDTH-1:0] s_axil_wstrb,
  input  wire [S_COUNT-1:0]            s_axil_wvalid,
  output reg  [S_COUNT-1:0]            s_axil_wready,

  output reg  [S_COUNT*2-1:0]          s_axil_bresp,
  output reg  [S_COUNT-1:0]            s_axil_bvalid,
  input  wire [S_COUNT-1:0]            s_axil_bready,

  input  wire [S_COUNT*ADDR_WIDTH-1:0] s_axil_araddr,
  input  wire [S_COUNT*3-1:0]          s_axil_arprot,
  input  wire [S_COUNT-1:0]            s_axil_arvalid,
  output reg  [S_COUNT-1:0]            s_axil_arready,

  output reg  [S_COUNT*DATA_WIDTH-1:0] s_axil_rdata,
  output reg  [S_COUNT*2-1:0]          s_axil_rresp,
  output reg  [S_COUNT-1:0]            s_axil_rvalid,
  input  wire [S_COUNT-1:0]            s_axil_rready,

  // Flattened Slave-facing ports (Master interface of interconnect)
  output reg  [M_COUNT*ADDR_WIDTH-1:0] m_axil_awaddr,
  output reg  [M_COUNT*3-1:0]          m_axil_awprot,
  output reg  [M_COUNT-1:0]            m_axil_awvalid,
  input  wire [M_COUNT-1:0]            m_axil_awready,

  output reg  [M_COUNT*DATA_WIDTH-1:0] m_axil_wdata,
  output reg  [M_COUNT*STRB_WIDTH-1:0] m_axil_wstrb,
  output reg  [M_COUNT-1:0]            m_axil_wvalid,
  input  wire [M_COUNT-1:0]            m_axil_wready,

  input  wire [M_COUNT*2-1:0]          m_axil_bresp,
  input  wire [M_COUNT-1:0]            m_axil_bvalid,
  output reg  [M_COUNT-1:0]            m_axil_bready,

  output reg  [M_COUNT*ADDR_WIDTH-1:0] m_axil_araddr,
  output reg  [M_COUNT*3-1:0]          m_axil_arprot,
  output reg  [M_COUNT-1:0]            m_axil_arvalid,
  input  wire [M_COUNT-1:0]            m_axil_arready,

  input  wire [M_COUNT*DATA_WIDTH-1:0] m_axil_rdata,
  input  wire [M_COUNT*2-1:0]          m_axil_rresp,
  input  wire [M_COUNT-1:0]            m_axil_rvalid,
  output reg  [M_COUNT-1:0]            m_axil_rready,

  // Configuration Table Inputs
  input wire [M_COUNT*ADDR_WIDTH-1:0] m_base_addr,
  input wire [M_COUNT*32-1:0]         m_addr_mask,
  input wire [M_COUNT*S_COUNT-1:0]    m_connect_read,
  input wire [M_COUNT*S_COUNT-1:0]    m_connect_write
);

  localparam RESP_OKAY   = 2'b00;
  localparam RESP_SLVERR = 2'b10;
  localparam RESP_DECERR = 2'b11;

  localparam S_BITS = $clog2(S_COUNT);
  localparam M_BITS = $clog2(M_COUNT);

  localparam STATE_IDLE      = 3'b000;
  localparam STATE_DECODE    = 3'b001;
  localparam STATE_WRITE_AW  = 3'b010;
  localparam STATE_WRITE_W   = 3'b011;
  localparam STATE_WRITE_B   = 3'b100;
  localparam STATE_READ      = 3'b101;
  localparam STATE_DECERR_B  = 3'b110;
  localparam STATE_DECERR_R  = 3'b111;

  reg [2:0] state;

  reg [S_BITS:0] current_master;
  reg [M_BITS:0] current_slave;
  reg            is_write;

  reg [ADDR_WIDTH-1:0] latched_addr;
  reg [2:0]            latched_prot;
  reg [DATA_WIDTH-1:0] latched_data;
  reg [STRB_WIDTH-1:0] latched_strb;

  reg aw_captured;
  reg w_captured;

  // Arbitration logic
  reg [S_BITS:0] grant_master;
  reg            grant_valid;
  reg            grant_is_write;

  integer i, j;

  // Address decode and permission check
  reg [M_BITS:0] decoded_slave;
  reg            addr_matched;
  reg            permission_ok;

  always @(*) begin
    decoded_slave = 0;
    addr_matched  = 1'b0;
    permission_ok = 1'b0;

    for (j = 0; j < M_COUNT; j = j + 1) begin
      if ((latched_addr & m_addr_mask[j*32 +: 32]) == (m_base_addr[j*ADDR_WIDTH +: ADDR_WIDTH] & m_addr_mask[j*32 +: 32])) begin
        decoded_slave = j;
        addr_matched  = 1'b1;
        if (is_write)
          permission_ok = m_connect_write[j*S_COUNT + current_master];
        else
          permission_ok = m_connect_read[j*S_COUNT + current_master];
      end
    end
  end

  // Round-robin arbitration across masters
  reg [S_BITS:0] last_master;
  integer m_idx;

  always @(*) begin
    grant_master   = 0;
    grant_valid    = 1'b0;
    grant_is_write = 1'b0;

    for (i = 0; i < S_COUNT; i = i + 1) begin
      m_idx = (last_master + 1 + i) % S_COUNT;
      // Give write priority over read for same master, round-robin through masters
      if (s_axil_awvalid[m_idx] && !grant_valid) begin
        grant_master   = m_idx;
        grant_valid    = 1'b1;
        grant_is_write = 1'b1;
      end else if (s_axil_arvalid[m_idx] && !grant_valid) begin
        grant_master   = m_idx;
        grant_valid    = 1'b1;
        grant_is_write = 1'b0;
      end
    end
  end

  // State Machine
  always @(posedge clk) begin
    if (rst) begin
      state          <= STATE_IDLE;
      last_master    <= 0;
      current_master <= 0;
      current_slave  <= 0;
      is_write       <= 1'b0;
      latched_addr   <= 0;
      latched_prot   <= 0;
      latched_data   <= 0;
      latched_strb   <= 0;
      aw_captured    <= 1'b0;
      w_captured     <= 1'b0;

      s_axil_awready <= {S_COUNT{1'b0}};
      s_axil_wready  <= {S_COUNT{1'b0}};
      s_axil_bvalid  <= {S_COUNT{1'b0}};
      s_axil_bresp   <= {S_COUNT*2{1'b0}};
      s_axil_arready <= {S_COUNT{1'b0}};
      s_axil_rvalid  <= {S_COUNT{1'b0}};
      s_axil_rresp   <= {S_COUNT*2{1'b0}};
      s_axil_rdata   <= {S_COUNT*DATA_WIDTH{1'b0}};

      m_axil_awvalid <= {M_COUNT{1'b0}};
      m_axil_wvalid  <= {M_COUNT{1'b0}};
      m_axil_bready  <= {M_COUNT{1'b0}};
      m_axil_arvalid <= {M_COUNT{1'b0}};
      m_axil_rready  <= {M_COUNT{1'b0}};
      m_axil_awaddr  <= {M_COUNT*ADDR_WIDTH{1'b0}};
      m_axil_awprot  <= {M_COUNT*3{1'b0}};
      m_axil_wdata   <= {M_COUNT*DATA_WIDTH{1'b0}};
      m_axil_wstrb   <= {M_COUNT*STRB_WIDTH{1'b0}};
      m_axil_araddr  <= {M_COUNT*ADDR_WIDTH{1'b0}};
      m_axil_arprot  <= {M_COUNT*3{1'b0}};
    end else begin
      case (state)
        STATE_IDLE: begin
          s_axil_bvalid  <= {S_COUNT{1'b0}};
          s_axil_rvalid  <= {S_COUNT{1'b0}};
          m_axil_awvalid <= {M_COUNT{1'b0}};
          m_axil_wvalid  <= {M_COUNT{1'b0}};
          m_axil_bready  <= {M_COUNT{1'b0}};
          m_axil_arvalid <= {M_COUNT{1'b0}};
          m_axil_rready  <= {M_COUNT{1'b0}};

          if (grant_valid) begin
            last_master    <= grant_master;
            current_master <= grant_master;
            is_write       <= grant_is_write;

            if (grant_is_write) begin
              s_axil_awready[grant_master] <= 1'b1;
              s_axil_wready[grant_master]  <= 1'b1;
              latched_addr <= s_axil_awaddr[grant_master*ADDR_WIDTH +: ADDR_WIDTH];
              latched_prot <= s_axil_awprot[grant_master*3 +: 3];
              latched_data <= s_axil_wdata[grant_master*DATA_WIDTH +: DATA_WIDTH];
              latched_strb <= s_axil_wstrb[grant_master*STRB_WIDTH +: STRB_WIDTH];
              aw_captured  <= s_axil_awvalid[grant_master];
              w_captured   <= s_axil_wvalid[grant_master];
              state        <= STATE_DECODE;
            end else begin
              s_axil_arready[grant_master] <= 1'b1;
              latched_addr <= s_axil_araddr[grant_master*ADDR_WIDTH +: ADDR_WIDTH];
              latched_prot <= s_axil_arprot[grant_master*3 +: 3];
              state        <= STATE_DECODE;
            end
          end
        end

        STATE_DECODE: begin
          s_axil_awready <= {S_COUNT{1'b0}};
          s_axil_wready  <= {S_COUNT{1'b0}};
          s_axil_arready <= {S_COUNT{1'b0}};

          if (!addr_matched || !permission_ok) begin
            // Address violation or unmapped -> DECERR
            if (is_write)
              state <= STATE_DECERR_B;
            else
              state <= STATE_DECERR_R;
          end else begin
            current_slave <= decoded_slave;
            if (is_write) begin
              // Forward AW first to slave
              m_axil_awaddr[decoded_slave*ADDR_WIDTH +: ADDR_WIDTH] <= latched_addr;
              m_axil_awprot[decoded_slave*3 +: 3]                   <= latched_prot;
              m_axil_awvalid[decoded_slave]                         <= 1'b1;
              state <= STATE_WRITE_AW;
            end else begin
              // Forward AR to slave
              m_axil_araddr[decoded_slave*ADDR_WIDTH +: ADDR_WIDTH] <= latched_addr;
              m_axil_arprot[decoded_slave*3 +: 3]                   <= latched_prot;
              m_axil_arvalid[decoded_slave]                         <= 1'b1;
              m_axil_rready[decoded_slave]                          <= 1'b1;
              state <= STATE_READ;
            end
          end
        end

        STATE_WRITE_AW: begin
          if (m_axil_awready[current_slave] && m_axil_awvalid[current_slave]) begin
            m_axil_awvalid[current_slave] <= 1'b0;
            // Now forward W
            m_axil_wdata[current_slave*DATA_WIDTH +: DATA_WIDTH] <= latched_data;
            m_axil_wstrb[current_slave*STRB_WIDTH +: STRB_WIDTH] <= latched_strb;
            m_axil_wvalid[current_slave]                         <= 1'b1;
            m_axil_bready[current_slave]                         <= 1'b1;
            state <= STATE_WRITE_W;
          end
        end

        STATE_WRITE_W: begin
          if (m_axil_wready[current_slave] && m_axil_wvalid[current_slave]) begin
            m_axil_wvalid[current_slave] <= 1'b0;
            state <= STATE_WRITE_B;
          end
        end

        STATE_WRITE_B: begin
          if (m_axil_bvalid[current_slave] && m_axil_bready[current_slave]) begin
            m_axil_bready[current_slave] <= 1'b0;
            // Forward B to master
            s_axil_bresp[current_master*2 +: 2] <= m_axil_bresp[current_slave*2 +: 2];
            s_axil_bvalid[current_master]       <= 1'b1;
            state <= STATE_IDLE;
          end
        end

        STATE_READ: begin
          if (m_axil_arready[current_slave] && m_axil_arvalid[current_slave]) begin
            m_axil_arvalid[current_slave] <= 1'b0;
          end
          if (m_axil_rvalid[current_slave] && m_axil_rready[current_slave]) begin
            m_axil_rready[current_slave] <= 1'b0;
            s_axil_rdata[current_master*DATA_WIDTH +: DATA_WIDTH] <= m_axil_rdata[current_slave*DATA_WIDTH +: DATA_WIDTH];
            s_axil_rresp[current_master*2 +: 2]                   <= m_axil_rresp[current_slave*2 +: 2];
            s_axil_rvalid[current_master]                         <= 1'b1;
            state <= STATE_IDLE;
          end
        end

        STATE_DECERR_B: begin
          s_axil_bresp[current_master*2 +: 2] <= RESP_DECERR;
          s_axil_bvalid[current_master]       <= 1'b1;
          state <= STATE_IDLE;
        end

        STATE_DECERR_R: begin
          s_axil_rdata[current_master*DATA_WIDTH +: DATA_WIDTH] <= {DATA_WIDTH{1'b0}};
          s_axil_rresp[current_master*2 +: 2]                   <= RESP_DECERR;
          s_axil_rvalid[current_master]                         <= 1'b1;
          state <= STATE_IDLE;
        end

        default: state <= STATE_IDLE;
      endcase
    end
  end

endmodule

`default_nettype wire
