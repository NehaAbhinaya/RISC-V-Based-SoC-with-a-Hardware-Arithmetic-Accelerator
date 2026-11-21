#include "spi.h"

void spi_init(uint32_t prescaler_div) {
    // Soft reset
    SPI_SRR_REG = 0x0A;

    // Set clock divider
    SPI_RCLK_REG = prescaler_div;

    // Enable SPI, Master mode, Loopback mode disabled
    SPI_CR_REG = 0x00000006U; // [1] SPE=1, [2] Master=1
}

void spi_select_slave(uint32_t slave_mask) {
    SPI_SSR_REG = ~slave_mask; // Active-low
}

void spi_deselect_slaves(void) {
    SPI_SSR_REG = 0xFFFFFFFFU;
}

uint8_t spi_transfer_byte(uint8_t tx_byte) {
    // Push byte to transmit FIFO
    SPI_DTR_REG = tx_byte;

    // Wait until receive FIFO has data
    while (SPI_SR_REG & 0x01) // Bit 0 is RX_EMPTY
        ;

    return (uint8_t)(SPI_DRR_REG & 0xFF);
}
