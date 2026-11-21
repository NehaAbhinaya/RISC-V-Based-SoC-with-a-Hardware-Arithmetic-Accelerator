class riscv_core_env extends uvm_env;
  riscv_core_agent agent;
  riscv_core_scoreboard sb;
  `uvm_component_utils(riscv_core_env)
  function new(string n, uvm_component p); super.new(n, p); endfunction
  function void build_phase(uvm_phase phase);
    agent = riscv_core_agent::type_id::create("agent", this);
    sb = riscv_core_scoreboard::type_id::create("sb", this);
  endfunction
endclass
