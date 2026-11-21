class imem_test extends uvm_test;
  imem_env env;
  `uvm_component_utils(imem_test)
  function new(string n, uvm_component p); super.new(n, p); endfunction
  function void build_phase(uvm_phase phase);
    env = imem_env::type_id::create("env", this);
  endfunction
endclass
