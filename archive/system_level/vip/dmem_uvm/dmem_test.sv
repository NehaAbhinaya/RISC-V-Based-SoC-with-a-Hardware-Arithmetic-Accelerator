class dmem_test extends uvm_test;
  dmem_env env;
  `uvm_component_utils(dmem_test)
  function new(string n, uvm_component p); super.new(n, p); endfunction
  function void build_phase(uvm_phase phase);
    env = dmem_env::type_id::create("env", this);
  endfunction
endclass
