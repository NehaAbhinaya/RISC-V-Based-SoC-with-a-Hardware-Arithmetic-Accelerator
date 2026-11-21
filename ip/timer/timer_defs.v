/* -------------------------------------------------------------------------------
 * Project        : RISC-V SoC with Hardware Arithmetic Accelerator
 * File           : timer_defs.v
 * Description    : Register Offset Definitions for Timer Peripheral (Section 10)
 * -------------------------------------------------------------------------------*/

`ifndef _TIMER_DEFS_V_
`define _TIMER_DEFS_V_

`define TIMER_CTRL        12'h000
`define TIMER_COUNT       12'h004
`define TIMER_COMPARE     12'h008
`define TIMER_STATUS      12'h00C

// Bit definitions
`define TIMER_CTRL_EN     0
`define TIMER_CTRL_PERIOD 1
`define TIMER_CTRL_IRQ_EN 2

`define TIMER_STATUS_MATCH 0

`endif
