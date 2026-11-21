#ifndef TIMER_H
#define TIMER_H

#include <stdint.h>

void     timer_init(uint32_t compare_val, uint8_t periodic, uint8_t irq_en);
uint32_t timer_get_count(void);
void     timer_clear_irq(void);
void     timer_stop(void);
void     delay_cycles(uint32_t cycles);

#endif // TIMER_H
