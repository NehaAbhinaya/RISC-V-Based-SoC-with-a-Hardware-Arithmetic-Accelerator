class riscv_core_scoreboard extends uvm_scoreboard;
  `uvm_component_utils(riscv_core_scoreboard)
  function new(string n, uvm_component p); super.new(n, p); endfunction
endclass
