#include "accelerator.h"

uint32_t accel_compute_direct(uint8_t opcode, uint32_t a, uint32_t b, uint8_t *error_flag) {
    ACCEL_OPERAND_A_REG = a;
    ACCEL_OPERAND_B_REG = b;

    // Trigger direct mode start pulse with specified opcode
    ACCEL_CTRL_REG = (opcode & 0x07) | ACCEL_CTRL_START;

    // Wait until done
    while (ACCEL_STATUS_REG & ACCEL_STATUS_BUSY)
        ;

    uint32_t status = ACCEL_STATUS_REG;
    if (error_flag) {
        *error_flag = (status & ACCEL_STATUS_ERROR) ? 1 : 0;
    }

    return ACCEL_RESULT_REG;
}

void accel_config_stream(uint8_t opcode, uint16_t op_count, uint8_t irq_en) {
    ACCEL_OPCOUNT_REG = op_count;
    ACCEL_IRQ_EN_REG  = irq_en ? 1 : 0;
    // Set opcode without start bit (DMA will stream the operands)
    ACCEL_CTRL_REG    = (opcode & 0x07);
}

uint32_t accel_get_status(void) {
    return ACCEL_STATUS_REG;
}

void accel_soft_reset(void) {
    ACCEL_CTRL_REG = ACCEL_CTRL_RESET;
}
