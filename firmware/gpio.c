#include "gpio.h"
#include "soc_regs.h"

void gpio_init(uint8_t dir_mask) {
    GPIO_DIR_REG = dir_mask; // 1 = Output, 0 = Input
}

void gpio_write(uint8_t val) {
    GPIO_OUT_REG = val;
}

uint8_t gpio_read(void) {
    return (uint8_t)(GPIO_IN_REG & 0xFF);
}

void gpio_enable_irq(uint8_t pin_mask) {
    GPIO_INT_EN_REG = pin_mask;
}

void gpio_clear_irq(uint8_t pin_mask) {
    GPIO_INT_STATUS_REG = pin_mask; // Write 1 to Clear
}
