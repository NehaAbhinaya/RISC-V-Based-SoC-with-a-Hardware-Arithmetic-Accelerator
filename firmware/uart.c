#include "uart.h"
#include "soc_regs.h"

void uart_init(uint16_t baud_divisor) {
    // Enable UART transmitter and receiver with given baud divisor in bits [15:4]
    UART_CTRL_REG = (((uint32_t)baud_divisor & 0x0FFFU) << 4) | 0x00000001U;
}

void uart_putc(char c) {
    // Wait until TX ready / not full
    while (!(UART_STATUS_REG & UART_STATUS_TX_READY))
        ;
    UART_TXDATA_REG = (uint8_t)c;
}

void uart_puts(const char *str) {
    while (*str) {
        if (*str == '\n') {
            uart_putc('\r');
        }
        uart_putc(*str++);
    }
}

int uart_has_char(void) {
    return (UART_STATUS_REG & UART_STATUS_RX_VALID) != 0;
}

char uart_getc(void) {
    while (!uart_has_char())
        ;
    return (char)(UART_RXDATA_REG & 0xFF);
}

void uart_print_hex(uint32_t val) {
    const char hex_chars[] = "0123456789ABCDEF";
    for (int i = 7; i >= 0; i--) {
        uint8_t nibble = (val >> (i * 4)) & 0x0F;
        uart_putc(hex_chars[nibble]);
    }
}

void uart_print_dec(uint32_t val) {
    char buf[12];
    int i = 0;
    if (val == 0) {
        uart_putc('0');
        return;
    }
    while (val > 0) {
        buf[i++] = (char)('0' + (val % 10));
        val /= 10;
    }
    while (i > 0) {
        uart_putc(buf[--i]);
    }
}
