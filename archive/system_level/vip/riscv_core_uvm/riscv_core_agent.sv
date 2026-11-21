class riscv_core_agent extends uvm_agent;
  riscv_core_driver drv;
  riscv_core_monitor mon;
  riscv_core_sequencer seqr;
  `uvm_component_utils(riscv_core_agent)
  function new(string n, uvm_component p); super.new(n, p); endfunction
  function void build_phase(uvm_phase phase);
    drv = riscv_core_driver::type_id::create("drv", this);
    mon = riscv_core_monitor::type_id::create("mon", this);
    seqr = riscv_core_sequencer::type_id::create("seqr", this);
  endfunction
  function void connect_phase(uvm_phase phase);
    drv.seq_item_port.connect(seqr.seq_item_export);
  endfunction
endclass
