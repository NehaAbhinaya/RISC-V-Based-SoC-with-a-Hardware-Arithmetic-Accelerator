class arithmetic_accelerator_monitor extends uvm_monitor;
  virtual arithmetic_accelerator_if vif;
  uvm_analysis_port #(arithmetic_accelerator_item) ap;
  `uvm_component_utils(arithmetic_accelerator_monitor)
  function new(string n, uvm_component p); super.new(n, p); ap = new("ap", this); endfunction
  function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    void'(uvm_config_db#(virtual arithmetic_accelerator_if)::get(this, "", "vif", vif));
  endfunction
endclass
