/* ==============================================================================
 * Project        : RISC-V VeeR EL2 SoC with Hardware Arithmetic Accelerator
 * Subsystem      : SoC-Level UVM Verification Environment
 * File           : soc_virtual_sequencer.sv
 * Description    : SoC-level Virtual Sequencer coordinating all six VIP sequencers.
 * ============================================================================== */

`ifndef SOC_VIRTUAL_SEQUENCER_SV
`define SOC_VIRTUAL_SEQUENCER_SV

class soc_virtual_sequencer extends uvm_sequencer;
  `uvm_component_utils(soc_virtual_sequencer)

  // --------------------------------------------------------------------------
  // Sub-sequencer Handles to All Six VIP Sequencers
  // --------------------------------------------------------------------------
  uart_pkg::uart_sequencer                                     uart_seqr;
  gpio_pkg::gpio_sequencer                                     gpio_seqr;
  spi_pkg::spi_sequencer                                       spi_seqr;
  timer_pkg::timer_sequencer                                   timer_seqr;
  arithmetic_accelerator_pkg::arithmetic_accelerator_sequencer accel_seqr;
  dma_pkg::dma_sequencer                                       dma_seqr;

  // --------------------------------------------------------------------------
  // Constructor
  // --------------------------------------------------------------------------
  function new(string name = "soc_virtual_sequencer", uvm_component parent = null);
    super.new(name, parent);
  endfunction

  virtual function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    `uvm_info(get_type_name(), "Building soc_virtual_sequencer", UVM_HIGH)
  endfunction

endclass : soc_virtual_sequencer

`endif // SOC_VIRTUAL_SEQUENCER_SV
