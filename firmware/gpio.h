#ifndef GPIO_H
#define GPIO_H

#include <stdint.h>

void    gpio_init(uint8_t dir_mask);
void    gpio_write(uint8_t val);
uint8_t gpio_read(void);
void    gpio_enable_irq(uint8_t pin_mask);
void    gpio_clear_irq(uint8_t pin_mask);

#endif // GPIO_H
