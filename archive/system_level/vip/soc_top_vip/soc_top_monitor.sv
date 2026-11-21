class soc_top_monitor extends uvm_monitor;
  virtual soc_top_if vif;
  uvm_analysis_port #(soc_top_item) ap;
  `uvm_component_utils(soc_top_monitor)
  function new(string n, uvm_component p); super.new(n, p); ap = new("ap", this); endfunction
  function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    void'(uvm_config_db#(virtual soc_top_if)::get(this, "", "vif", vif));
  endfunction
endclass
