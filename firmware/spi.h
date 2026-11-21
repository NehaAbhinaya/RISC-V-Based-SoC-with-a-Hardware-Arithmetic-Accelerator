#ifndef SPI_H
#define SPI_H

#include <stdint.h>
#include "soc_regs.h"

void    spi_init(uint32_t prescaler_div);
uint8_t spi_transfer_byte(uint8_t tx_byte);
void    spi_select_slave(uint32_t slave_mask);
void    spi_deselect_slaves(void);

#endif // SPI_H
