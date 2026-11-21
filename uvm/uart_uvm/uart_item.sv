class uart_item extends uvm_sequence_item;

  bit uart_tx;
  rand bit uart_rx;
  bit irq_uart;
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

  `uvm_object_utils(uart_item)

  function new(string name="uart_item"); super.new(name); endfunction
endclass
