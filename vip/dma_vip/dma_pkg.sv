/* ==============================================================================
 * Project        : RISC-V VeeR EL2 SoC with Hardware Arithmetic Accelerator
 * VIP            : DMA VIP
 * File           : dma_pkg.sv
 * Description    : DMA VIP Package.
 * ============================================================================== */

`ifndef DMA_PKG_SV
`define DMA_PKG_SV

package dma_pkg;
  import uvm_pkg::*;
  `include "uvm_macros.svh"

  `include "dma_item.sv"
  `include "dma_sequencer.sv"
  `include "dma_seq.sv"
  `include "dma_driver.sv"
  `include "dma_monitor.sv"
  `include "dma_scoreboard.sv"
  `include "dma_agent.sv"
  `include "dma_env.sv"
  `include "dma_test.sv"
endpackage

`endif // DMA_PKG_SV
