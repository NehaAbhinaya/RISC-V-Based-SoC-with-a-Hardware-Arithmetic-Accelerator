/* ==============================================================================
 * Project        : RISC-V VeeR EL2 SoC with Hardware Arithmetic Accelerator
 * VIP            : Timer VIP
 * File           : timer_agent.sv
 * Description    : Timer UVM Agent integrating driver, monitor, and sequencer.
 * ============================================================================== */

`ifndef TIMER_AGENT_SV
`define TIMER_AGENT_SV

class timer_agent extends uvm_agent;
  timer_driver    drv;
  timer_monitor   mon;
  timer_sequencer seqr;

  uvm_analysis_port #(timer_item) ap;

  `uvm_component_utils(timer_agent)

  function new(string name, uvm_component parent);
    super.new(name, parent);
  endfunction

  virtual function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    drv  = timer_driver::type_id::create("drv", this);
    mon  = timer_monitor::type_id::create("mon", this);
    seqr = timer_sequencer::type_id::create("seqr", this);
  endfunction

  virtual function void connect_phase(uvm_phase phase);
    super.connect_phase(phase);
    drv.seq_item_port.connect(seqr.seq_item_export);
    ap = mon.ap;
  endfunction

endclass

`endif // TIMER_AGENT_SV
