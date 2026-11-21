class riscv_core_test extends uvm_test;
  riscv_core_env env;
  `uvm_component_utils(riscv_core_test)
  function new(string n, uvm_component p); super.new(n, p); endfunction
  function void build_phase(uvm_phase phase);
    env = riscv_core_env::type_id::create("env", this);
  endfunction
endclass
