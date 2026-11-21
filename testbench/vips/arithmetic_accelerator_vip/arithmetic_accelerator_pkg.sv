/* ==============================================================================
 * Project        : RISC-V VeeR EL2 SoC with Hardware Arithmetic Accelerator
 * VIP            : Arithmetic Accelerator VIP
 * File           : arithmetic_accelerator_pkg.sv
 * Description    : Arithmetic Accelerator VIP Package.
 * ============================================================================== */

`ifndef ARITHMETIC_ACCELERATOR_PKG_SV
`define ARITHMETIC_ACCELERATOR_PKG_SV

package arithmetic_accelerator_pkg;
  import uvm_pkg::*;
  `include "uvm_macros.svh"

  `include "arithmetic_accelerator_item.sv"
  `include "arithmetic_accelerator_sequencer.sv"
  `include "arithmetic_accelerator_seq.sv"
  `include "arithmetic_accelerator_driver.sv"
  `include "arithmetic_accelerator_monitor.sv"
  `include "arithmetic_accelerator_scoreboard.sv"
  `include "arithmetic_accelerator_agent.sv"
  `include "arithmetic_accelerator_env.sv"
  `include "arithmetic_accelerator_test.sv"
endpackage

`endif // ARITHMETIC_ACCELERATOR_PKG_SV
