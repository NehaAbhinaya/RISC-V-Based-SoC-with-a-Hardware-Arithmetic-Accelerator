class soc_top_test extends uvm_test;
  soc_top_env env;
  `uvm_component_utils(soc_top_test)
  function new(string n, uvm_component p); super.new(n, p); endfunction
  function void build_phase(uvm_phase phase);
    env = soc_top_env::type_id::create("env", this);
  endfunction
endclass
