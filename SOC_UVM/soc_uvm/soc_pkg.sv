/* ==============================================================================
 * Project        : RISC-V VeeR EL2 SoC with Hardware Arithmetic Accelerator
 * Subsystem      : SoC-Level UVM Verification Environment
 * File           : soc_pkg.sv
 * Description    : SoC-level UVM Package compiling soc_config, soc_virtual_sequencer,
 *                  soc_virtual_sequence, soc_env, and soc_test.
 * ============================================================================== */

`ifndef SOC_PKG_SV
`define SOC_PKG_SV

package soc_pkg;
  import uvm_pkg::*;
  `include "uvm_macros.svh"

  // Import all six peripheral VIP packages
  import uart_pkg::*;
  import gpio_pkg::*;
  import spi_pkg::*;
  import timer_pkg::*;
  import arithmetic_accelerator_pkg::*;
  import dma_pkg::*;

  // Include SoC-level verification components
  `include "soc_config.sv"
  `include "soc_virtual_sequencer.sv"
  `include "soc_virtual_sequence.sv"
  `include "soc_env.sv"
  `include "soc_test.sv"
  `include "uart_connectivity_test.sv"

endpackage : soc_pkg

`endif // SOC_PKG_SV
