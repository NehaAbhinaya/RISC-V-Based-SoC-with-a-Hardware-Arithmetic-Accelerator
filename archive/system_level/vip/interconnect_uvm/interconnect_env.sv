class interconnect_env extends uvm_env;
  interconnect_agent agent;
  interconnect_scoreboard sb;
  `uvm_component_utils(interconnect_env)
  function new(string n, uvm_component p); super.new(n, p); endfunction
  function void build_phase(uvm_phase phase);
    agent = interconnect_agent::type_id::create("agent", this);
    sb = interconnect_scoreboard::type_id::create("sb", this);
  endfunction
endclass
