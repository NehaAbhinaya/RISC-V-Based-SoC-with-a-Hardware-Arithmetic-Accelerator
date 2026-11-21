class arithmetic_accelerator_agent extends uvm_agent;
  arithmetic_accelerator_driver drv;
  arithmetic_accelerator_monitor mon;
  arithmetic_accelerator_sequencer seqr;
  `uvm_component_utils(arithmetic_accelerator_agent)
  function new(string n, uvm_component p); super.new(n, p); endfunction
  function void build_phase(uvm_phase phase);
    drv = arithmetic_accelerator_driver::type_id::create("drv", this);
    mon = arithmetic_accelerator_monitor::type_id::create("mon", this);
    seqr = arithmetic_accelerator_sequencer::type_id::create("seqr", this);
  endfunction
  function void connect_phase(uvm_phase phase);
    drv.seq_item_port.connect(seqr.seq_item_export);
  endfunction
endclass
