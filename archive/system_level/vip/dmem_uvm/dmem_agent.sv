class dmem_agent extends uvm_agent;
  dmem_driver drv;
  dmem_monitor mon;
  dmem_sequencer seqr;
  `uvm_component_utils(dmem_agent)
  function new(string n, uvm_component p); super.new(n, p); endfunction
  function void build_phase(uvm_phase phase);
    drv = dmem_driver::type_id::create("drv", this);
    mon = dmem_monitor::type_id::create("mon", this);
    seqr = dmem_sequencer::type_id::create("seqr", this);
  endfunction
  function void connect_phase(uvm_phase phase);
    drv.seq_item_port.connect(seqr.seq_item_export);
  endfunction
endclass
