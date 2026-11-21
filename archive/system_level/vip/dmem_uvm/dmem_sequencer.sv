class dmem_sequencer extends uvm_sequencer #(dmem_item);
  `uvm_component_utils(dmem_sequencer)
  function new(string n, uvm_component p); super.new(n, p); endfunction
endclass
