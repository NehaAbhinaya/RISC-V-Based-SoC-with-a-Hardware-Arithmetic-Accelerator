/* -------------------------------------------------------------------------------
 * Project        : AXI-lite SPI IP Core
 * File           : axi_spi_defines.vh
 * Description    : AXI4-Lite SPI parameters defines (Updated per Project Specification)
 * Organization   : BSC; CIC-IPN
 * -------------------------------------------------------------------------------*/

`ifndef _AXI_SPI_DEFINES_H_
`define _AXI_SPI_DEFINES_H_

`define _AXI_SPI_DATA_WIDTH_  32
`define _AXI_SPI_ADDR_WIDTH_  12
`define _AXI_SPI_FIFO_DEPTH_  32
`define _AXI_SPI_RESP_WIDTH_  2

// AXI4-Lite standard response encodings
`define _AXI_RESP_OKAY_       2'b00
`define _AXI_RESP_EXOKAY_     2'b01
`define _AXI_RESP_SLVERR_     2'b10
`define _AXI_RESP_DECERR_     2'b11

`endif
