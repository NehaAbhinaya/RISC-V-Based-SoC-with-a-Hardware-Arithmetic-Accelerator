/* ==============================================================================
 * Project        : RISC-V VeeR EL2 SoC with Hardware Arithmetic Accelerator
 * VIP            : UART VIP
 * File           : uart_agent.sv
 * Description    : UART UVM Agent integrating driver, monitor, and sequencer.
 * ============================================================================== */

`ifndef UART_AGENT_SV
`define UART_AGENT_SV

class uart_agent extends uvm_agent;
  uart_driver    drv;
  uart_monitor   mon;
  uart_sequencer seqr;

  uvm_analysis_port #(uart_item) ap;

  `uvm_component_utils(uart_agent)

  function new(string name, uvm_component parent);
    super.new(name, parent);
  endfunction

  virtual function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    drv  = uart_driver::type_id::create("drv", this);
    mon  = uart_monitor::type_id::create("mon", this);
    seqr = uart_sequencer::type_id::create("seqr", this);
  endfunction

  virtual function void connect_phase(uvm_phase phase);
    super.connect_phase(phase);
    drv.seq_item_port.connect(seqr.seq_item_export);
    ap = mon.ap;
  endfunction

endclass

`endif // UART_AGENT_SV
