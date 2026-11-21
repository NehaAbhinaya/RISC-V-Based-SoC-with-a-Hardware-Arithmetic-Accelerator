#include "timer.h"
#include "soc_regs.h"

void timer_init(uint32_t compare_val, uint8_t periodic, uint8_t irq_en) {
    TIMER_COMPARE_REG = compare_val;
    TIMER_CTRL_REG = TIMER_CTRL_ENABLE |
                     (periodic ? TIMER_CTRL_PERIODIC : 0) |
                     (irq_en ? TIMER_CTRL_IRQ_EN : 0);
}

uint32_t timer_get_count(void) {
    return TIMER_COUNT_REG;
}

void timer_clear_irq(void) {
    TIMER_STATUS_REG = TIMER_STATUS_MATCH; // Write 1 to Clear
}

void timer_stop(void) {
    TIMER_CTRL_REG = 0;
}

void delay_cycles(uint32_t cycles) {
    uint32_t start = timer_get_count();
    while ((timer_get_count() - start) < cycles)
        ;
}
