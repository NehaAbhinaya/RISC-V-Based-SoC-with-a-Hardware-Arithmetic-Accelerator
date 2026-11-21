/* -------------------------------------------------------------------------------
 * Project        : RISC-V SoC with Hardware Arithmetic Accelerator
 * File           : gpio_defs.v
 * Description    : Register Offset Definitions for GPIO Peripheral (Section 11)
 * -------------------------------------------------------------------------------*/

`ifndef _GPIO_DEFS_V_
`define _GPIO_DEFS_V_

`define GPIO_DIR        12'h000
`define GPIO_OUT        12'h004
`define GPIO_IN         12'h008
`define GPIO_INT_EN     12'h00C
`define GPIO_INT_STATUS 12'h010

`endif
