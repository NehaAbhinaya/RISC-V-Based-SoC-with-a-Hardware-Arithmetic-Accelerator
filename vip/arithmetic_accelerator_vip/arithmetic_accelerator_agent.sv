/* ==============================================================================
 * Project        : RISC-V VeeR EL2 SoC with Hardware Arithmetic Accelerator
 * VIP            : Arithmetic Accelerator VIP
 * File           : arithmetic_accelerator_agent.sv
 * Description    : Arithmetic Accelerator UVM Agent integrating driver, monitor, and sequencer.
 * ============================================================================== */

`ifndef ARITHMETIC_ACCELERATOR_AGENT_SV
`define ARITHMETIC_ACCELERATOR_AGENT_SV

class arithmetic_accelerator_agent extends uvm_agent;
  arithmetic_accelerator_driver    drv;
  arithmetic_accelerator_monitor   mon;
  arithmetic_accelerator_sequencer seqr;

  uvm_analysis_port #(arithmetic_accelerator_item) ap;

  `uvm_component_utils(arithmetic_accelerator_agent)

  function new(string name, uvm_component parent);
    super.new(name, parent);
  endfunction

  virtual function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    drv  = arithmetic_accelerator_driver::type_id::create("drv", this);
    mon  = arithmetic_accelerator_monitor::type_id::create("mon", this);
    seqr = arithmetic_accelerator_sequencer::type_id::create("seqr", this);
  endfunction

  virtual function void connect_phase(uvm_phase phase);
    super.connect_phase(phase);
    drv.seq_item_port.connect(seqr.seq_item_export);
    ap = mon.ap;
  endfunction

endclass

`endif // ARITHMETIC_ACCELERATOR_AGENT_SV
