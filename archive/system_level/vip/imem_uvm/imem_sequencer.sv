class imem_sequencer extends uvm_sequencer #(imem_item);
  `uvm_component_utils(imem_sequencer)
  function new(string n, uvm_component p); super.new(n, p); endfunction
endclass
