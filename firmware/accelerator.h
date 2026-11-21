#ifndef ACCELERATOR_H
#define ACCELERATOR_H

#include <stdint.h>
#include "soc_regs.h"

// Direct Mode Computation
uint32_t accel_compute_direct(uint8_t opcode, uint32_t a, uint32_t b, uint8_t *error_flag);

// Stream Mode Configuration (for DMA transfer)
void     accel_config_stream(uint8_t opcode, uint16_t op_count, uint8_t irq_en);
uint32_t accel_get_status(void);
void     accel_soft_reset(void);

#endif // ACCELERATOR_H
