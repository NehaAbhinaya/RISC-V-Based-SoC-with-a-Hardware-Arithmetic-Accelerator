class imem_env extends uvm_env;
  imem_agent agent;
  imem_scoreboard sb;
  `uvm_component_utils(imem_env)
  function new(string n, uvm_component p); super.new(n, p); endfunction
  function void build_phase(uvm_phase phase);
    agent = imem_agent::type_id::create("agent", this);
    sb = imem_scoreboard::type_id::create("sb", this);
  endfunction
endclass
