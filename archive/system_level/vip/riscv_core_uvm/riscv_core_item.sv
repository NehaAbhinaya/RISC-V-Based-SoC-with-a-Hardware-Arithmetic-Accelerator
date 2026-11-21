class riscv_core_item extends uvm_sequence_item;

  rand bit [5:0] extintsrc_req;
  bit irq_core;
  bit [31:0] ifu_araddr;
  bit [2:0] ifu_arprot;
  bit ifu_arvalid;
  rand bit ifu_arready;
  rand bit [31:0] ifu_rdata;
  rand bit [1:0] ifu_rresp;
  rand bit ifu_rvalid;
  bit ifu_rready;
  bit [31:0] lsu_awaddr;
  bit [2:0] lsu_awprot;
  bit lsu_awvalid;
  rand bit lsu_awready;
  bit [31:0] lsu_wdata;
  bit [3:0] lsu_wstrb;
  bit lsu_wvalid;
  rand bit lsu_wready;
  rand bit [1:0] lsu_bresp;
  rand bit lsu_bvalid;
  bit lsu_bready;
  bit [31:0] lsu_araddr;
  bit [2:0] lsu_arprot;
  bit lsu_arvalid;
  rand bit lsu_arready;
  rand bit [31:0] lsu_rdata;
  rand bit [1:0] lsu_rresp;
  rand bit lsu_rvalid;
  bit lsu_rready;
  bit [31:0] rv_trace_insn;
  bit [31:0] rv_trace_address;
  bit rv_trace_valid;

  `uvm_object_utils(riscv_core_item)

  function new(string name="riscv_core_item"); super.new(name); endfunction
endclass
