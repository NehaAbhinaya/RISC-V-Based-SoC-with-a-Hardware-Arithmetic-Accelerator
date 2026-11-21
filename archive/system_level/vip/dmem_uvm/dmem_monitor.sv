class dmem_monitor extends uvm_monitor;
  virtual dmem_if vif;
  uvm_analysis_port #(dmem_item) ap;
  `uvm_component_utils(dmem_monitor)
  function new(string n, uvm_component p); super.new(n, p); ap = new("ap", this); endfunction
  function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    void'(uvm_config_db#(virtual dmem_if)::get(this, "", "vif", vif));
  endfunction
endclass
