/* ==============================================================================
 * Project        : RISC-V VeeR EL2 SoC with Hardware Arithmetic Accelerator
 * Subsystem      : SoC-Level UVM Verification Environment
 * File           : dma_if.sv
 * Description    : SystemVerilog interface for DMA VIP integration with soc_top.
 * ============================================================================== */

`ifndef DMA_IF_SV
`define DMA_IF_SV

interface dma_if;
  logic clk;
  logic rst_n;

  // Interrupt line
  logic irq_dma;

  // Dedicated Streaming Interface to Accelerator
  logic        dma_op_valid;
  logic [31:0] dma_op_data_a;
  logic [31:0] dma_op_data_b;
  logic        dma_op_ready;
  logic        dma_res_valid;
  logic [31:0] dma_res_data;
  logic        dma_res_ready;
  logic        dma_last;

  // AXI4-Lite Slave Configuration Interface (m06 @ 0x4000_4000)
  logic [31:0] s_axil_awaddr;
  logic [2:0]  s_axil_awprot;
  logic        s_axil_awvalid;
  logic        s_axil_awready;
  logic [31:0] s_axil_wdata;
  logic [3:0]  s_axil_wstrb;
  logic        s_axil_wvalid;
  logic        s_axil_wready;
  logic [1:0]  s_axil_bresp;
  logic        s_axil_bvalid;
  logic        s_axil_bready;
  logic [31:0] s_axil_araddr;
  logic [2:0]  s_axil_arprot;
  logic        s_axil_arvalid;
  logic        s_axil_arready;
  logic [31:0] s_axil_rdata;
  logic [1:0]  s_axil_rresp;
  logic        s_axil_rvalid;
  logic        s_axil_rready;

  // AXI4-Lite Fabric Master Interface (s02 to Interconnect)
  logic [31:0] m_axil_awaddr;
  logic [2:0]  m_axil_awprot;
  logic        m_axil_awvalid;
  logic        m_axil_awready;
  logic [31:0] m_axil_wdata;
  logic [3:0]  m_axil_wstrb;
  logic        m_axil_wvalid;
  logic        m_axil_wready;
  logic [1:0]  m_axil_bresp;
  logic        m_axil_bvalid;
  logic        m_axil_bready;
  logic [31:0] m_axil_araddr;
  logic [2:0]  m_axil_arprot;
  logic        m_axil_arvalid;
  logic        m_axil_arready;
  logic [31:0] m_axil_rdata;
  logic [1:0]  m_axil_rresp;
  logic        m_axil_rvalid;
  logic        m_axil_rready;

endinterface : dma_if

typedef virtual dma_if dma_vif;

`endif // DMA_IF_SV
