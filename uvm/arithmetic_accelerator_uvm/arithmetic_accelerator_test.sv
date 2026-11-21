class arithmetic_accelerator_test extends uvm_test;
  arithmetic_accelerator_env env;
  `uvm_component_utils(arithmetic_accelerator_test)
  function new(string n, uvm_component p); super.new(n, p); endfunction
  function void build_phase(uvm_phase phase);
    env = arithmetic_accelerator_env::type_id::create("env", this);
  endfunction
endclass
