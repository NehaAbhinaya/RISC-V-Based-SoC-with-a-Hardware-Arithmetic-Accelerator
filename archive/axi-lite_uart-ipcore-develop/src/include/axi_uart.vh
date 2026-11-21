/* -----------------------------------------------------------------------------
 * Project        : AXI-lite UART IP Core
 * File           : axi_uart.vh
 * Description    : AXI4-Lite UART Header file (Updated per Project Specification)
 *                  Register map (base 0x4000_0000, 12-bit offsets):
 *                  0x00 UART_CTRL   : [0] enable, [1] irq enable, [15:4] baud divisor
 *                  0x04 UART_STATUS : [0] tx_ready, [1] rx_valid, [2] overrun
 *                  0x08 UART_TXDATA : [7:0] byte to transmit (write-only)
 *                  0x0C UART_RXDATA : [7:0] received byte (read-only)
 * ------------------------------------------------------------------------------*/

`ifndef _AXI_UART_H_
`define _AXI_UART_H_

/* Register Offsets (12-bit decoded within 4 KB window) */
`define _UART_CTRL_     12'h000
`define _UART_STATUS_   12'h004
`define _UART_TXDATA_   12'h008
`define _UART_RXDATA_   12'h00C

/* UART Control Register Bit Fields */
`define _UART_CTRL_EN_BIT_          0
`define _UART_CTRL_IRQ_EN_BIT_      1
`define _UART_CTRL_DIVISOR_LSB_     4
`define _UART_CTRL_DIVISOR_MSB_     15

/* UART Status Register Bit Fields */
`define _UART_STATUS_TX_READY_BIT_  0
`define _UART_STATUS_RX_VALID_BIT_  1
`define _UART_STATUS_OVERRUN_BIT_   2

/* Default Initial Values */
`define _DATA_WIDTH_UART_           8
`define _UART_DEFAULT_DIVISOR_      12'd16  // Fast default for simulation / 115200 at clock
`define _UART_CTRL_INIT_            32'h00000101 // divisor=16 (12'h010 shifted by 4 = 16'h0100), enable=1

`endif
