class soc_top_item extends uvm_sequence_item;

  bit uart_tx;
  rand bit uart_rx;
  bit spi_sclk;
  bit spi_cs_n;
  bit spi_mosi;
  rand bit spi_miso;
  rand bit [7:0] gpio_in;
  bit [7:0] gpio_out;
  bit [5:0] pic_interrupts;
  bit irq_core;
  bit [31:0] rv_trace_insn;
  bit [31:0] rv_trace_address;
  bit rv_trace_valid;
  rand bit ext_host_en;
  rand bit [31:0] ext_lsu_awaddr;
  rand bit [2:0] ext_lsu_awprot;
  rand bit ext_lsu_awvalid;
  bit ext_lsu_awready;
  rand bit [31:0] ext_lsu_wdata;
  rand bit [3:0] ext_lsu_wstrb;
  rand bit ext_lsu_wvalid;
  bit ext_lsu_wready;
  bit [1:0] ext_lsu_bresp;
  bit ext_lsu_bvalid;
  rand bit ext_lsu_bready;
  rand bit [31:0] ext_lsu_araddr;
  rand bit [2:0] ext_lsu_arprot;
  rand bit ext_lsu_arvalid;
  bit ext_lsu_arready;
  bit [31:0] ext_lsu_rdata;
  bit [1:0] ext_lsu_rresp;
  bit ext_lsu_rvalid;
  rand bit ext_lsu_rready;

  `uvm_object_utils(soc_top_item)

  function new(string name="soc_top_item"); super.new(name); endfunction
endclass
