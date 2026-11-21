/* ==============================================================================
 * Project        : RISC-V VeeR EL2 SoC with Hardware Arithmetic Accelerator
 * VIP            : SPI VIP
 * File           : spi_pkg.sv
 * Description    : SPI VIP Package.
 * ============================================================================== */

`ifndef SPI_PKG_SV
`define SPI_PKG_SV

package spi_pkg;
  import uvm_pkg::*;
  `include "uvm_macros.svh"

  `include "spi_item.sv"
  `include "spi_sequencer.sv"
  `include "spi_seq.sv"
  `include "spi_driver.sv"
  `include "spi_monitor.sv"
  `include "spi_scoreboard.sv"
  `include "spi_agent.sv"
  `include "spi_env.sv"
  `include "spi_test.sv"
endpackage

`endif // SPI_PKG_SV
