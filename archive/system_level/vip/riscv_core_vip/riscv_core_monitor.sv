class riscv_core_monitor extends uvm_monitor;
  virtual riscv_core_if vif;
  uvm_analysis_port #(riscv_core_item) ap;
  `uvm_component_utils(riscv_core_monitor)
  function new(string n, uvm_component p); super.new(n, p); ap = new("ap", this); endfunction
  function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    void'(uvm_config_db#(virtual riscv_core_if)::get(this, "", "vif", vif));
  endfunction
endclass
