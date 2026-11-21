class interconnect_agent extends uvm_agent;
  interconnect_driver drv;
  interconnect_monitor mon;
  interconnect_sequencer seqr;
  `uvm_component_utils(interconnect_agent)
  function new(string n, uvm_component p); super.new(n, p); endfunction
  function void build_phase(uvm_phase phase);
    drv = interconnect_driver::type_id::create("drv", this);
    mon = interconnect_monitor::type_id::create("mon", this);
    seqr = interconnect_sequencer::type_id::create("seqr", this);
  endfunction
  function void connect_phase(uvm_phase phase);
    drv.seq_item_port.connect(seqr.seq_item_export);
  endfunction
endclass
