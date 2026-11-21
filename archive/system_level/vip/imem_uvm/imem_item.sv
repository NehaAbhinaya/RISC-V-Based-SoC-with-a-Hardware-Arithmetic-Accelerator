class imem_item extends uvm_sequence_item;

  rand bit [31:0] araddr;
  rand bit [2:0] arprot;
  rand bit arvalid;
  bit arready;
  bit [31:0] rdata;
  bit [1:0] rresp;
  bit rvalid;
  rand bit rready;

  `uvm_object_utils(imem_item)

  function new(string name="imem_item"); super.new(name); endfunction
endclass
