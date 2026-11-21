/* -------------------------------------------------------------------------------
 * Project        : AXI-lite SPI IP Core
 * File           : axi_spi.vh
 * Description    : AXI4-Lite SPI Header file (Updated per Project Specification)
 * Organization   : BSC; CIC-IPN
 * -------------------------------------------------------------------------------*/

`ifndef _AXI_SPI_H_
`define _AXI_SPI_H_

/* axi spi register map (12-bit offsets within 4 KB window) */
`define _SPI_GIER_    12'h01C
`define _SPI_ISR_     12'h020
`define _SPI_IER_     12'h028
`define _SPI_RCLK_    12'h030
`define _SPI_SRR_     12'h040
`define _SPI_CR_      12'h060
`define _SPI_SR_      12'h064
`define _SPI_DTR_     12'h068
`define _SPI_DRR_     12'h06C
`define _SPI_SSR_     12'h070
`define _SPI_TFOR_    12'h074
`define _SPI_RFOR_    12'h078

/* axi spi parameters (reset values) */
`define _SPI_CR_INIT_   32'h00000180
`define _SPI_SR_INIT_   32'h00000005  // RX empty (bit 0), TX empty (bit 2)
`define _SPI_SSR_INIT_  32'hffffffff
`define _SPI_TFOR_INIT_ 32'h00000000
`define _SPI_RFOR_INIT_ 32'h00000000
`define _SPI_GIER_INIT_ 32'h00000000
`define _SPI_ISR_INIT_  32'h00000000
`define _SPI_IER_INIT_  32'h00000000
`define _SPI_RCLK_INIT_ 32'h00000004

/* axi spi soft reset register magic value */
`define _SPI_SRR_VALUE_ 32'h0000000A

/* axi spi parameters */
`define _DATA_WIDTH_SPI_  8
`define _SPI_RATIO_GRADE_ 3

/* axi spi control register bits */
`define _CR_LSB_FIRST_BIT_      9
`define _CR_RX_FIFO_RESET_BIT_  6
`define _CR_TX_FIFO_RESET_BIT_  5
`define _CR_CPHA_BIT_           4
`define _CR_CPOL_BIT_           3
`define _CR_MASTER_BIT_         2
`define _CR_SPI_ENABLE_BIT_     1

/* axi spi status register bits */
`define _SR_RX_EMPTY_BIT_       0
`define _SR_RX_FULL_BIT_        1
`define _SR_TX_EMPTY_BIT_       2
`define _SR_TX_FULL_BIT_        3
`define _SR_MODF_BIT_           4
`define _SR_SMOD_SEL_BIT_       5

/* Interrupt bits (ISR / IER) */
`define _INT_MODF_BIT_          0
`define _INT_RX_AVAIL_BIT_      1
`define _INT_TX_EMPTY_BIT_      2

`endif
