#ifndef UART_H
#define UART_H

#include <stdint.h>

void uart_init(uint16_t baud_divisor);
void uart_putc(char c);
void uart_puts(const char *str);
int  uart_has_char(void);
char uart_getc(void);
void uart_print_hex(uint32_t val);
void uart_print_dec(uint32_t val);

#endif // UART_H
