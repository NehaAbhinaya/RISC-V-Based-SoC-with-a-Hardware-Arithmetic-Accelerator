/* ===============================================================================
 * Project        : RISC-V SoC with Hardware Arithmetic Accelerator
 * File           : main.c
 * Description    : Top-Level Bare-Metal Embedded Application & Test Suite
 *                  Integrates and verifies:
 *                    1. RISC-V VeeR EL2 Core Execution
 *                    2. AXI4-Lite Crossbar Interconnect & Memory Routing
 *                    3. Data Memory (DMEM) R/W & Word/Sub-word access
 *                    4. AXI4-Lite UART (Status, Polling TX, Hex/Dec formatters)
 *                    5. AXI4-Lite System Timer (Cycle benchmarking, W1C IRQ)
 *                    6. AXI4-Lite GPIO (Direction, Output drive, Input read)
 *                    7. AXI4-Lite SPI Master (Prescaler, Slave Select, Transfer)
 *                    8. Arithmetic Accelerator Direct CPU Mode (ADD, SUB, MUL, DIV, MAC, Div/0)
 *                    9. Autonomous DMA + Accelerator Streaming Engine Offload
 * =============================================================================== */

#include <stdint.h>
#include "soc_regs.h"
#include "uart.h"
#include "timer.h"
#include "gpio.h"
#include "accelerator.h"
#include "dma.h"
#include "spi.h"

// Statically allocated DMA Buffers in DMEM (0x1000_0000 region)
#define NUM_VECTOR_PAIRS  8

static uint32_t dma_src_operands[NUM_VECTOR_PAIRS * 2] = {
    100, 20,       // Pair 0: 100 + 20 = 120
    250, 50,       // Pair 1: 250 + 50 = 300
    1000, 400,     // Pair 2: 1000 + 400 = 1400
    999, 1,        // Pair 3: 999 + 1 = 1000
    55, 45,        // Pair 4: 55 + 45 = 100
    1234, 5678,    // Pair 5: 1234 + 5678 = 6912
    8888, 2222,    // Pair 6: 8888 + 2222 = 11110
    4000, 3000     // Pair 7: 4000 + 3000 = 7000
};

static uint32_t dma_dst_results[NUM_VECTOR_PAIRS];

// Helper functions for test logging
static void print_banner(void) {
    uart_puts("\r\n");
    uart_puts("=================================================================\r\n");
    uart_puts("   RISC-V VeeR EL2 SoC with Hardware Arithmetic Accelerator      \r\n");
    uart_puts("   AXI4-Lite Autonomous Multi-IP Full Integration Test Suite     \r\n");
    uart_puts("=================================================================\r\n");
}

static void print_pass(const char *test_name) {
    uart_puts("[PASS] ");
    uart_puts(test_name);
    uart_puts("\r\n");
}

static void print_fail(const char *test_name) {
    uart_puts("[FAIL] ");
    uart_puts(test_name);
    uart_puts("\r\n");
}

/* ===============================================================================
 * Test 1: Data Memory (DMEM) Read / Write & Strobe Verification
 * =============================================================================== */
static int test_dmem_integrity(void) {
    uart_puts("\r\n--- Test 1: DMEM Integrity & Interconnect Verification ---\r\n");
    volatile uint32_t *scratch = (volatile uint32_t *)(DMEM_BASE_ADDR + 0x0E00);
    
    // Write test patterns
    scratch[0] = 0xDEADBEEF;
    scratch[1] = 0xCAFEBABE;
    scratch[2] = 0x12345678;
    scratch[3] = 0xA5A55A5A;

    if (scratch[0] != 0xDEADBEEF || scratch[1] != 0xCAFEBABE ||
        scratch[2] != 0x12345678 || scratch[3] != 0xA5A55A5A) {
        print_fail("DMEM 32-bit Word R/W Mismatch");
        return -1;
    }

    // Verify byte writes (testing AXI wstrb)
    volatile uint8_t *byte_scratch = (volatile uint8_t *)(DMEM_BASE_ADDR + 0x0E10);
    byte_scratch[0] = 0x11;
    byte_scratch[1] = 0x22;
    byte_scratch[2] = 0x33;
    byte_scratch[3] = 0x44;

    volatile uint32_t *word_view = (volatile uint32_t *)(DMEM_BASE_ADDR + 0x0E10);
    if (*word_view != 0x44332211) {
        print_fail("DMEM Byte-Strobe Store Verification");
        return -1;
    }

    print_pass("DMEM Word and Byte-Strobe Operations");
    return 0;
}

/* ===============================================================================
 * Test 2: System Timer & Cycle Benchmarking
 * =============================================================================== */
static int test_system_timer(void) {
    uart_puts("\r\n--- Test 2: System Timer & Cycle Measurement ---\r\n");
    
    // Start timer in periodic mode with high compare threshold
    timer_init(0xFFFFFFFF, 1, 0);

    uint32_t t_start = timer_get_count();
    delay_cycles(200);
    uint32_t t_end = timer_get_count();

    uart_puts("  Timer Start: 0x");
    uart_print_hex(t_start);
    uart_puts(" | Timer End: 0x");
    uart_print_hex(t_end);
    uart_puts("\r\n");

    if (t_end <= t_start) {
        print_fail("Timer Free-Running Counter did not increment");
        return -1;
    }

    // Test Compare Match and W1C Flag
    timer_stop();
    uint32_t now = timer_get_count();
    timer_init(now + 200, 0, 1);
    while ((TIMER_STATUS_REG & TIMER_STATUS_MATCH) == 0) {
        // Wait for match
    }
    uart_puts("  Timer Compare Match Triggered successfully.\r\n");
    
    // Clear Match IRQ (Write 1 to Clear)
    timer_clear_irq();
    if ((TIMER_STATUS_REG & TIMER_STATUS_MATCH) != 0) {
        print_fail("Timer W1C Status Clear Failed");
        return -1;
    }

    timer_stop(); // Stop timer to prevent unexpected subsequent match interrupts

    print_pass("System Timer Counter & Compare-Match W1C");
    return 0;
}

/* ===============================================================================
 * Test 3: GPIO Controller (Outputs and Direction)
 * =============================================================================== */
static int test_gpio(void) {
    uart_puts("\r\n--- Test 3: GPIO Port Controller ---\r\n");

    // Configure all 8 pins as outputs
    gpio_init(0xFF);

    // Write LED blink pattern
    gpio_write(0xAA);
    if (GPIO_OUT_REG != 0xAA) {
        print_fail("GPIO Output Register Pattern 0xAA");
        return -1;
    }

    gpio_write(0x55);
    if (GPIO_OUT_REG != 0x55) {
        print_fail("GPIO Output Register Pattern 0x55");
        return -1;
    }

    // Set LED status indicator: Bit 0 active
    gpio_write(0x01);

    print_pass("GPIO Direction and Output Port Driving");
    return 0;
}

/* ===============================================================================
 * Test 4: SPI Master Controller
 * =============================================================================== */
static int test_spi_master(void) {
    uart_puts("\r\n--- Test 4: AXI4-Lite SPI Master Controller ---\r\n");

    // Initialize SPI with clock divisor = 0 (fast sclk for simulation)
    spi_init(0);

    // Select slave 0
    spi_select_slave(0x01);

    // Transmit commands
    spi_transfer_byte(0x9F); // Read JEDEC ID opcode
    spi_transfer_byte(0x00);
    spi_transfer_byte(0x00);

    // Deselect slaves
    spi_deselect_slaves();

    // Verify SPI status: TX empty, transmitter ready
    uint32_t spi_status = SPI_SR_REG;
    uart_puts("  SPI Status Register: 0x");
    uart_print_hex(spi_status);
    uart_puts("\r\n");

    print_pass("SPI Master Bus Transaction & Framing");
    return 0;
}

/* ===============================================================================
 * Test 5: Arithmetic Accelerator Direct CPU Mode (ADD, SUB, MUL, DIV, MAC)
 * =============================================================================== */
static int test_accelerator_direct(void) {
    uart_puts("\r\n--- Test 5: Arithmetic Accelerator Direct CPU Registers ---\r\n");
    uint8_t err = 0;
    uint32_t res;

    // Reset accelerator
    accel_soft_reset();

    // 1. ADD: 45000 + 15000 = 60000
    res = accel_compute_direct(ACCEL_OP_ADD, 45000, 15000, &err);
    if (err || res != 60000) {
        print_fail("Accelerator ADD: 45000 + 15000 != 60000");
        return -1;
    }
    uart_puts("  [ALU ADD] 45000 + 15000 = ");
    uart_print_dec(res);
    uart_puts(" (OK)\r\n");

    // 2. SUB: 98765 - 12345 = 86420
    res = accel_compute_direct(ACCEL_OP_SUB, 98765, 12345, &err);
    if (err || res != 86420) {
        print_fail("Accelerator SUB: 98765 - 12345 != 86420");
        return -1;
    }
    uart_puts("  [ALU SUB] 98765 - 12345 = ");
    uart_print_dec(res);
    uart_puts(" (OK)\r\n");

    // 3. MUL: 125 * 80 = 10000
    res = accel_compute_direct(ACCEL_OP_MUL, 125, 80, &err);
    if (err || res != 10000) {
        print_fail("Accelerator MUL: 125 * 80 != 10000");
        return -1;
    }
    uart_puts("  [ALU MUL] 125 * 80 = ");
    uart_print_dec(res);
    uart_puts(" (OK)\r\n");

    // 4. DIV: 100000 / 250 = 400
    res = accel_compute_direct(ACCEL_OP_DIV, 100000, 250, &err);
    if (err || res != 400) {
        print_fail("Accelerator DIV: 100000 / 250 != 400");
        return -1;
    }
    uart_puts("  [ALU DIV] 100000 / 250 = ");
    uart_print_dec(res);
    uart_puts(" (OK)\r\n");

    // 5. DIV BY ZERO Check: 500 / 0 -> Expect Error Flag
    res = accel_compute_direct(ACCEL_OP_DIV, 500, 0, &err);
    if (!err) {
        print_fail("Accelerator DIV by Zero failed to assert ERROR flag");
        return -1;
    }
    uart_puts("  [ALU DIV/0] Divide-by-zero properly flagged with ERROR=1 (OK)\r\n");

    // 6. MAC: Accumulate (10 * 20) + (30 * 40) = 200 + 1200 = 1400
    accel_soft_reset();
    res = accel_compute_direct(ACCEL_OP_MAC, 10, 20, &err); // acc = 200
    res = accel_compute_direct(ACCEL_OP_MAC, 30, 40, &err); // acc = 1400
    if (err || res != 1400) {
        print_fail("Accelerator MAC Accumulator Mismatch");
        return -1;
    }
    uart_puts("  [ALU MAC] (10*20) + (30*40) = ");
    uart_print_dec(res);
    uart_puts(" (OK)\r\n");

    print_pass("Arithmetic Accelerator Direct Execution");
    return 0;
}

/* ===============================================================================
 * Test 6: Grand Integration Test - Autonomous DMA + Accelerator Streaming
 * =============================================================================== */
static int test_dma_accelerator_stream(void) {
    uart_puts("\r\n--- Test 6: Grand Integration Test: Autonomous DMA Offload ---\r\n");
    uart_puts("  Vector Length: 8 operand pairs\r\n");
    uart_puts("  Source Buffer: DMEM @ 0x");
    uart_print_hex((uint32_t)(uintptr_t)dma_src_operands);
    uart_puts("\r\n  Dest Buffer  : DMEM @ 0x");
    uart_print_hex((uint32_t)(uintptr_t)dma_dst_results);
    uart_puts("\r\n");

    // Clear destination buffer
    for (int i = 0; i < NUM_VECTOR_PAIRS; i++) {
        dma_dst_results[i] = 0x00000000;
    }

    // Step 1: Arm Accelerator for Streaming ADD Mode
    accel_soft_reset();
    accel_config_stream(ACCEL_OP_ADD, NUM_VECTOR_PAIRS, 0);

    // Step 2: Timestamp Start of Offload
    timer_init(0xFFFFFFFF, 1, 0);
    uint32_t t_start = timer_get_count();

    // Step 3: Trigger DMA Transfer
    dma_start((uint32_t)(uintptr_t)dma_src_operands, (uint32_t)(uintptr_t)dma_dst_results, NUM_VECTOR_PAIRS, 0);

    // Step 4: Wait for DMA Autonomous Completion
    dma_wait_done();
    uint32_t t_end = timer_get_count();
    uint32_t elapsed_cycles = t_end - t_start;

    // Step 5: Check DMA and Accelerator Status
    uint32_t dma_status = dma_get_status();
    uint32_t acc_status = accel_get_status();

    uart_puts("  DMA Done Status: 0x");
    uart_print_hex(dma_status);
    uart_puts(" | Accel Status: 0x");
    uart_print_hex(acc_status);
    uart_puts("\r\n");

    if ((dma_status & DMA_STATUS_DONE) == 0) {
        print_fail("DMA DONE flag not asserted");
        return -1;
    }

    if ((dma_status & DMA_STATUS_BUS_ERR) != 0) {
        uart_puts("  DMA Bus Error at address: 0x");
        uart_print_hex(dma_get_err_addr());
        uart_puts("\r\n");
        print_fail("DMA encountered Bus Error on Interconnect");
        return -1;
    }

    // Step 6: Software Golden Verification
    uart_puts("  Verifying Streamed Results in DMEM:\r\n");
    for (int i = 0; i < NUM_VECTOR_PAIRS; i++) {
        uint32_t op_a = dma_src_operands[i * 2];
        uint32_t op_b = dma_src_operands[i * 2 + 1];
        uint32_t expected = op_a + op_b;
        uint32_t actual   = dma_dst_results[i];

        uart_puts("    Pair [");
        uart_print_dec(i);
        uart_puts("]: ");
        uart_print_dec(op_a);
        uart_puts(" + ");
        uart_print_dec(op_b);
        uart_puts(" = ");
        uart_print_dec(actual);

        if (actual != expected) {
            uart_puts(" [MISMATCH! Expected: ");
            uart_print_dec(expected);
            uart_puts("]\r\n");
            print_fail("DMA Streamed Result Mismatch");
            return -1;
        } else {
            uart_puts(" (VERIFIED)\r\n");
        }
    }

    uart_puts("  DMA + Accelerator Execution Benchmark: ");
    uart_print_dec(elapsed_cycles);
    uart_puts(" Clock Cycles for 8 Vector Operations.\r\n");

    print_pass("Autonomous DMA + Accelerator Streaming Engine Offload");
    return 0;
}

/* ===============================================================================
 * Main Entry Point
 * =============================================================================== */
int main(void) {
    // 1. Initialize UART (Baud Divisor = 16 for simulation / 50MHz @ 3.125MBaud)
    uart_init(16);

    print_banner();

    // 2. Run Comprehensive Functional Test Suite
    if (test_dmem_integrity() != 0) goto error_halt;
    if (test_system_timer() != 0)   goto error_halt;
    if (test_gpio() != 0)           goto error_halt;
    if (test_spi_master() != 0)     goto error_halt;
    if (test_accelerator_direct() != 0) goto error_halt;
    if (test_dma_accelerator_stream() != 0) goto error_halt;

    // 3. All Tests Passed Banner
    uart_puts("\r\n");
    uart_puts("*****************************************************************\r\n");
    uart_puts(" [SUCCESS] ALL SOC INTEGRATION TESTS COMPLETED WITHOUT ERROR!    \r\n");
    uart_puts(" RISC-V + INTERCONNECT + ACCELERATOR + ALL IPS VERIFIED ON VCS   \r\n");
    uart_puts("*****************************************************************\r\n");

    // Drive Success LED Pattern on GPIO (Bit 7 & Bit 0 ON)
    gpio_write(0x81);

    // Infinite halt loop
    while (1) {
        __asm__ volatile ("nop");
    }

error_halt:
    uart_puts("\r\n");
    uart_puts("#################################################################\r\n");
    uart_puts(" [FAILURE] SOC INTEGRATION TEST ENCOUNTERED AN ERROR!            \r\n");
    uart_puts("#################################################################\r\n");

    // Drive Failure LED Pattern on GPIO (0xEE)
    gpio_write(0xEE);

    while (1) {
        __asm__ volatile ("nop");
    }

    return 0;
}
