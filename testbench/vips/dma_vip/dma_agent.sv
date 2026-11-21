/* ==============================================================================
 * Project        : RISC-V VeeR EL2 SoC with Hardware Arithmetic Accelerator
 * VIP            : DMA VIP
 * File           : dma_agent.sv
 * Description    : DMA UVM Agent integrating driver, monitor, and sequencer.
 * ============================================================================== */

`ifndef DMA_AGENT_SV
`define DMA_AGENT_SV

class dma_agent extends uvm_agent;
  dma_driver    drv;
  dma_monitor   mon;
  dma_sequencer seqr;

  uvm_analysis_port #(dma_item) ap;

  `uvm_component_utils(dma_agent)

  function new(string name, uvm_component parent);
    super.new(name, parent);
  endfunction

  virtual function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    drv  = dma_driver::type_id::create("drv", this);
    mon  = dma_monitor::type_id::create("mon", this);
    seqr = dma_sequencer::type_id::create("seqr", this);
  endfunction

  virtual function void connect_phase(uvm_phase phase);
    super.connect_phase(phase);
    drv.seq_item_port.connect(seqr.seq_item_export);
    ap = mon.ap;
  endfunction

endclass

`endif // DMA_AGENT_SV
