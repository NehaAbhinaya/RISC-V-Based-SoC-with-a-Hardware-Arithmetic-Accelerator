#ifndef DMA_H
#define DMA_H

#include <stdint.h>
#include "soc_regs.h"

void     dma_start(uint32_t src_addr, uint32_t dst_addr, uint32_t length, uint8_t irq_en);
int      dma_is_busy(void);
int      dma_is_done(void);
uint32_t dma_get_status(void);
uint32_t dma_get_err_addr(void);
void     dma_wait_done(void);

#endif // DMA_H
