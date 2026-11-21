class soc_top_agent extends uvm_agent;
  soc_top_driver drv;
  soc_top_monitor mon;
  soc_top_sequencer seqr;
  `uvm_component_utils(soc_top_agent)
  function new(string n, uvm_component p); super.new(n, p); endfunction
  function void build_phase(uvm_phase phase);
    drv = soc_top_driver::type_id::create("drv", this);
    mon = soc_top_monitor::type_id::create("mon", this);
    seqr = soc_top_sequencer::type_id::create("seqr", this);
  endfunction
  function void connect_phase(uvm_phase phase);
    drv.seq_item_port.connect(seqr.seq_item_export);
  endfunction
endclass
