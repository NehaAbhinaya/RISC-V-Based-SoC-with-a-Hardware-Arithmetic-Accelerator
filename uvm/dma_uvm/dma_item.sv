class dma_item extends uvm_sequence_item;

  bit irq_dma;
  bit dma_op_valid;
  bit [31:0] dma_op_data_a;
  bit [31:0] dma_op_data_b;
  rand bit dma_op_ready;
  rand bit dma_res_valid;
  rand bit [31:0] dma_res_data;
  bit dma_res_ready;
  bit dma_last;
  rand bit [31:0] s_axil_awaddr;
  rand bit [2:0] s_axil_awprot;
  rand bit s_axil_awvalid;
  bit s_axil_awready;
  rand bit [31:0] s_axil_wdata;
  rand bit [3:0] s_axil_wstrb;
  rand bit s_axil_wvalid;
  bit s_axil_wready;
  bit [1:0] s_axil_bresp;
  bit s_axil_bvalid;
  rand bit s_axil_bready;
  rand bit [31:0] s_axil_araddr;
  rand bit [2:0] s_axil_arprot;
  rand bit s_axil_arvalid;
  bit s_axil_arready;
  bit [31:0] s_axil_rdata;
  bit [1:0] s_axil_rresp;
  bit s_axil_rvalid;
  rand bit s_axil_rready;
  bit [31:0] m_axil_awaddr;
  bit [2:0] m_axil_awprot;
  bit m_axil_awvalid;
  rand bit m_axil_awready;
  bit [31:0] m_axil_wdata;
  bit [3:0] m_axil_wstrb;
  bit m_axil_wvalid;
  rand bit m_axil_wready;
  rand bit [1:0] m_axil_bresp;
  rand bit m_axil_bvalid;
  bit m_axil_bready;
  bit [31:0] m_axil_araddr;
  bit [2:0] m_axil_arprot;
  bit m_axil_arvalid;
  rand bit m_axil_arready;
  rand bit [31:0] m_axil_rdata;
  rand bit [1:0] m_axil_rresp;
  rand bit m_axil_rvalid;
  bit m_axil_rready;

  `uvm_object_utils(dma_item)

  function new(string name="dma_item"); super.new(name); endfunction
endclass
