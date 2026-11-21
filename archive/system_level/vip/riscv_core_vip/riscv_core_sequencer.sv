class riscv_core_sequencer extends uvm_sequencer #(riscv_core_item);
  `uvm_component_utils(riscv_core_sequencer)
  function new(string n, uvm_component p); super.new(n, p); endfunction
endclass
