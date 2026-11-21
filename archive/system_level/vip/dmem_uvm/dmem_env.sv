class dmem_env extends uvm_env;
  dmem_agent agent;
  dmem_scoreboard sb;
  `uvm_component_utils(dmem_env)
  function new(string n, uvm_component p); super.new(n, p); endfunction
  function void build_phase(uvm_phase phase);
    agent = dmem_agent::type_id::create("agent", this);
    sb = dmem_scoreboard::type_id::create("sb", this);
  endfunction
endclass
