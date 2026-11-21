/* ==============================================================================
 * Project        : RISC-V VeeR EL2 SoC with Hardware Arithmetic Accelerator
 * VIP            : GPIO VIP
 * File           : gpio_agent.sv
 * Description    : GPIO UVM Agent integrating driver, monitor, and sequencer.
 * ============================================================================== */

`ifndef GPIO_AGENT_SV
`define GPIO_AGENT_SV

class gpio_agent extends uvm_agent;
  gpio_driver    drv;
  gpio_monitor   mon;
  gpio_sequencer seqr;

  uvm_analysis_port #(gpio_item) ap;

  `uvm_component_utils(gpio_agent)

  function new(string name, uvm_component parent);
    super.new(name, parent);
  endfunction

  virtual function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    drv  = gpio_driver::type_id::create("drv", this);
    mon  = gpio_monitor::type_id::create("mon", this);
    seqr = gpio_sequencer::type_id::create("seqr", this);
  endfunction

  virtual function void connect_phase(uvm_phase phase);
    super.connect_phase(phase);
    drv.seq_item_port.connect(seqr.seq_item_export);
    ap = mon.ap;
  endfunction

endclass

`endif // GPIO_AGENT_SV
