class arithmetic_accelerator_env extends uvm_env;
  arithmetic_accelerator_agent agent;
  arithmetic_accelerator_scoreboard sb;
  `uvm_component_utils(arithmetic_accelerator_env)
  function new(string n, uvm_component p); super.new(n, p); endfunction
  function void build_phase(uvm_phase phase);
    agent = arithmetic_accelerator_agent::type_id::create("agent", this);
    sb = arithmetic_accelerator_scoreboard::type_id::create("sb", this);
  endfunction
endclass
