class gpio_item extends uvm_sequence_item;

  rand bit [7:0] gpio_in;
  bit [7:0] gpio_out;
  bit irq_gpio;
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

  `uvm_object_utils(gpio_item)

  function new(string name="gpio_item"); super.new(name); endfunction
endclass
