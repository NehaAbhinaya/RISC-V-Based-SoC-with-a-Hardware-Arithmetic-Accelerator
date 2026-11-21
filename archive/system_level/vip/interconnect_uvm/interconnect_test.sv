class interconnect_test extends uvm_test;
  interconnect_env env;
  `uvm_component_utils(interconnect_test)
  function new(string n, uvm_component p); super.new(n, p); endfunction
  function void build_phase(uvm_phase phase);
    env = interconnect_env::type_id::create("env", this);
  endfunction
endclass
