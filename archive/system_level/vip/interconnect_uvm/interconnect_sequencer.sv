class interconnect_sequencer extends uvm_sequencer #(interconnect_item);
  `uvm_component_utils(interconnect_sequencer)
  function new(string n, uvm_component p); super.new(n, p); endfunction
endclass
