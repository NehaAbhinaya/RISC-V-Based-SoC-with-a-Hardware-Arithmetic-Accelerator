class arithmetic_accelerator_sequencer extends uvm_sequencer #(arithmetic_accelerator_item);
  `uvm_component_utils(arithmetic_accelerator_sequencer)
  function new(string n, uvm_component p); super.new(n, p); endfunction
endclass
