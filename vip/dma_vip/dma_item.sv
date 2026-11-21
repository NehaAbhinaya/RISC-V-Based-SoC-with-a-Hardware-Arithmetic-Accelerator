/* ==============================================================================
 * Project        : RISC-V VeeR EL2 SoC with Hardware Arithmetic Accelerator
 * VIP            : DMA VIP
 * File           : dma_item.sv
 * Description    : Transaction item for DMA VIP supporting slave configuration
 *                  registers (SRC, DST, LEN, CTRL), master memory operations,
 *                  and streaming accelerator interfaces.
 * ============================================================================== */

`ifndef DMA_ITEM_SV
`define DMA_ITEM_SV

class dma_item extends uvm_sequence_item;

  bit             irq_dma;
  bit             dma_op_valid;
  bit [31:0]      dma_op_data_a;
  bit [31:0]      dma_op_data_b;
  rand bit        dma_op_ready;
  rand bit        dma_res_valid;
  rand bit [31:0] dma_res_data;
  bit             dma_res_ready;
  bit             dma_last;

  // Configuration Slave Port (s_axil_*)
  rand bit [31:0] s_axil_awaddr;
  rand bit [2:0]  s_axil_awprot;
  rand bit        s_axil_awvalid;
  bit             s_axil_awready;
  rand bit [31:0] s_axil_wdata;
  rand bit [3:0]  s_axil_wstrb;
  rand bit        s_axil_wvalid;
  bit             s_axil_wready;
  bit [1:0]       s_axil_bresp;
  bit             s_axil_bvalid;
  rand bit        s_axil_bready;
  rand bit [31:0] s_axil_araddr;
  rand bit [2:0]  s_axil_arprot;
  rand bit        s_axil_arvalid;
  bit             s_axil_arready;
  bit [31:0]      s_axil_rdata;
  bit [1:0]       s_axil_rresp;
  bit             s_axil_rvalid;
  rand bit        s_axil_rready;

  // Master Port to Fabric (m_axil_*)
  bit [31:0]      m_axil_awaddr;
  bit [2:0]       m_axil_awprot;
  bit             m_axil_awvalid;
  rand bit        m_axil_awready;
  bit [31:0]      m_axil_wdata;
  bit [3:0]       m_axil_wstrb;
  bit             m_axil_wvalid;
  rand bit        m_axil_wready;
  rand bit [1:0]  m_axil_bresp;
  rand bit        m_axil_bvalid;
  bit             m_axil_bready;
  bit [31:0]      m_axil_araddr;
  bit [2:0]       m_axil_arprot;
  bit             m_axil_arvalid;
  rand bit        m_axil_arready;
  rand bit [31:0] m_axil_rdata;
  rand bit [1:0]  m_axil_rresp;
  rand bit        m_axil_rvalid;
  bit             m_axil_rready;

  // Functional protocol fields
  rand bit [31:0] src_addr;
  rand bit [31:0] dst_addr;
  rand bit [15:0] transfer_len;
  rand bit [31:0] ctrl_reg;
  bit             done_flag;
  rand bit        is_dma_config;
  rand bit        is_write;

  `uvm_object_utils_begin(dma_item)
    `uvm_field_int(irq_dma,        UVM_ALL_ON)
    `uvm_field_int(s_axil_awaddr,  UVM_ALL_ON)
    `uvm_field_int(s_axil_wdata,   UVM_ALL_ON)
    `uvm_field_int(s_axil_araddr,  UVM_ALL_ON)
    `uvm_field_int(s_axil_rdata,   UVM_ALL_ON)
    `uvm_field_int(src_addr,       UVM_ALL_ON)
    `uvm_field_int(dst_addr,       UVM_ALL_ON)
    `uvm_field_int(transfer_len,   UVM_ALL_ON)
    `uvm_field_int(ctrl_reg,       UVM_ALL_ON)
    `uvm_field_int(done_flag,      UVM_ALL_ON)
    `uvm_field_int(is_dma_config,  UVM_ALL_ON)
    `uvm_field_int(is_write,       UVM_ALL_ON)
  `uvm_object_utils_end

  function new(string name="dma_item");
    super.new(name);
    s_axil_wstrb   = 4'hF;
    s_axil_bready  = 1'b1;
    s_axil_rready  = 1'b1;
    m_axil_awready = 1'b1;
    m_axil_wready  = 1'b1;
    m_axil_arready = 1'b1;
    is_dma_config  = 1'b0;
    is_write       = 1'b0;
  endfunction

endclass

`endif // DMA_ITEM_SV
