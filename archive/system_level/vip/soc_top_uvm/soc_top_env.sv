class soc_top_env extends uvm_env;
  soc_top_agent agent;
  soc_top_scoreboard sb;
  `uvm_component_utils(soc_top_env)
  function new(string n, uvm_component p); super.new(n, p); endfunction
  function void build_phase(uvm_phase phase);
    agent = soc_top_agent::type_id::create("agent", this);
    sb = soc_top_scoreboard::type_id::create("sb", this);
  endfunction
endclass
