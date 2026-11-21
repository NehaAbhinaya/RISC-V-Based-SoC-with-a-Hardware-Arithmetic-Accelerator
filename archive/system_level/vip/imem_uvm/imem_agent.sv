class imem_agent extends uvm_agent;
  imem_driver drv;
  imem_monitor mon;
  imem_sequencer seqr;
  `uvm_component_utils(imem_agent)
  function new(string n, uvm_component p); super.new(n, p); endfunction
  function void build_phase(uvm_phase phase);
    drv = imem_driver::type_id::create("drv", this);
    mon = imem_monitor::type_id::create("mon", this);
    seqr = imem_sequencer::type_id::create("seqr", this);
  endfunction
  function void connect_phase(uvm_phase phase);
    drv.seq_item_port.connect(seqr.seq_item_export);
  endfunction
endclass
