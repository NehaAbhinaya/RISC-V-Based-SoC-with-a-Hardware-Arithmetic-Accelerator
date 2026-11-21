#include "dma.h"

void dma_start(uint32_t src_addr, uint32_t dst_addr, uint32_t length, uint8_t irq_en) {
    DMA_SRC_ADDR_REG = src_addr;
    DMA_DST_ADDR_REG = dst_addr;
    DMA_LENGTH_REG   = length;

    // Issue start with optional IRQ enable
    DMA_CTRL_REG = DMA_CTRL_START | (irq_en ? DMA_CTRL_IRQ_EN : 0);
}

int dma_is_busy(void) {
    return (DMA_STATUS_REG & DMA_STATUS_BUSY) != 0;
}

int dma_is_done(void) {
    return (DMA_STATUS_REG & DMA_STATUS_DONE) != 0;
}

uint32_t dma_get_status(void) {
    return DMA_STATUS_REG;
}

uint32_t dma_get_err_addr(void) {
    return DMA_ERR_ADDR_REG;
}

void dma_wait_done(void) {
    while ((DMA_STATUS_REG & (DMA_STATUS_DONE | DMA_STATUS_BUS_ERR)) == 0)
        ;
}
