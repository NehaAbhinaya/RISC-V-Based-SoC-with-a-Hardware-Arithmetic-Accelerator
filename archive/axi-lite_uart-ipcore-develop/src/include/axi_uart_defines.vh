/* -----------------------------------------------------------------------------
 * Project        : AXI-lite UART IP Core
 * File           : axi_uart_defines.vh
 * Description    : AXI4-Lite UART parameter definitions (Updated per Project Spec)
 * Organization   : BSC; CIC-IPN
 * ------------------------------------------------------------------------------*/

`ifndef _AXI_UART_DEFINES_H_
`define _AXI_UART_DEFINES_H_

`define _AXI_UART_DATA_WIDTH_ 32
`define _AXI_UART_ADDR_WIDTH_ 12
`define _AXI_UART_FIFO_DEPTH_ 16
`define _AXI_UART_DIV_WIDTH_  16
`define _AXI_UART_RESP_WIDTH_ 2

// AXI4-Lite standard response encodings
`define _AXI_RESP_OKAY_       2'b00
`define _AXI_RESP_EXOKAY_     2'b01
`define _AXI_RESP_SLVERR_     2'b10
`define _AXI_RESP_DECERR_     2'b11

`endif
