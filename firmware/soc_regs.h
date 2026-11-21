#ifndef SOC_REGS_H
#define SOC_REGS_H

#include <stdint.h>

/* ===============================================================================
 * RISC-V SoC with Hardware Arithmetic Accelerator
 * Memory-Mapped Registers & Base Addresses (AXI4-Lite Interconnect Map)
 * =============================================================================== */

// Base Addresses
#define IMEM_BASE_ADDR        0x00000000UL  // 64 KB Instruction Memory (Read-Only)
#define DMEM_BASE_ADDR        0x10000000UL  // 64 KB Data Memory (Read/Write)
#define UART_BASE_ADDR        0x40000000UL  // 4 KB UART Controller
#define TIMER_BASE_ADDR       0x40001000UL  // 4 KB Timer Controller
#define GPIO_BASE_ADDR        0x40002000UL  // 4 KB GPIO Controller
#define ACCEL_BASE_ADDR       0x40003000UL  // 4 KB Arithmetic Accelerator
#define DMA_BASE_ADDR         0x40004000UL  // 4 KB DMA Controller
#define SPI_BASE_ADDR         0x40005000UL  // 4 KB SPI Controller

// MMIO Access Helper Macros
#define REG32(addr)           (*(volatile uint32_t *)((uintptr_t)(addr)))
#define REG16(addr)           (*(volatile uint16_t *)((uintptr_t)(addr)))
#define REG8(addr)            (*(volatile uint8_t *)((uintptr_t)(addr)))

/* ===============================================================================
 * 1. UART Controller Registers (0x4000_0000)
 * =============================================================================== */
#define UART_CTRL_REG         REG32(UART_BASE_ADDR + 0x00) // Control: [15:0] Divisor, [8] RX_IE, [7] TX_IE, [0] EN
#define UART_STATUS_REG       REG32(UART_BASE_ADDR + 0x04) // Status: [0] TX_READY, [1] RX_VALID, [2] TX_EMPTY, [3] RX_FULL, [4] OVERRUN
#define UART_TXDATA_REG       REG32(UART_BASE_ADDR + 0x08) // Transmit Data Register (Write-Only, [7:0])
#define UART_RXDATA_REG       REG32(UART_BASE_ADDR + 0x0C) // Receive Data Register (Read-Only, [7:0])

#define UART_STATUS_TX_READY  (1U << 0)
#define UART_STATUS_RX_VALID  (1U << 1)
#define UART_STATUS_TX_EMPTY  (1U << 2)
#define UART_STATUS_RX_FULL   (1U << 3)
#define UART_STATUS_OVERRUN   (1U << 4)

/* ===============================================================================
 * 2. Timer Controller Registers (0x4000_1000)
 * =============================================================================== */
#define TIMER_CTRL_REG        REG32(TIMER_BASE_ADDR + 0x00) // Control: [0] EN, [1] PERIODIC, [2] IRQ_EN
#define TIMER_COUNT_REG       REG32(TIMER_BASE_ADDR + 0x04) // 32-bit Free-running Counter (Read-Only)
#define TIMER_COMPARE_REG     REG32(TIMER_BASE_ADDR + 0x08) // 32-bit Compare Threshold (Read/Write)
#define TIMER_STATUS_REG      REG32(TIMER_BASE_ADDR + 0x0C) // Match Status: [0] MATCH (R/W1C)

#define TIMER_CTRL_ENABLE     (1U << 0)
#define TIMER_CTRL_PERIODIC   (1U << 1)
#define TIMER_CTRL_IRQ_EN     (1U << 2)
#define TIMER_STATUS_MATCH    (1U << 0)

/* ===============================================================================
 * 3. GPIO Controller Registers (0x4000_2000)
 * =============================================================================== */
#define GPIO_DIR_REG          REG32(GPIO_BASE_ADDR + 0x00) // Direction: 1 = Output, 0 = Input
#define GPIO_OUT_REG          REG32(GPIO_BASE_ADDR + 0x04) // Output Values
#define GPIO_IN_REG           REG32(GPIO_BASE_ADDR + 0x08) // Input Pin Values (Read-Only)
#define GPIO_INT_EN_REG       REG32(GPIO_BASE_ADDR + 0x0C) // Interrupt Enable Mask per Bit
#define GPIO_INT_STATUS_REG   REG32(GPIO_BASE_ADDR + 0x10) // Interrupt Pending Flags (R/W1C)

/* ===============================================================================
 * 4. Arithmetic Accelerator Registers (0x4000_3000)
 * =============================================================================== */
#define ACCEL_CTRL_REG        REG32(ACCEL_BASE_ADDR + 0x00) // [2:0] Opcode, [3] Start, [4] Soft Reset
#define ACCEL_STATUS_REG      REG32(ACCEL_BASE_ADDR + 0x04) // [0] Busy, [1] Done, [2] Error
#define ACCEL_OPCOUNT_REG     REG32(ACCEL_BASE_ADDR + 0x08) // [15:0] Multi-pair / DMA Stream Operation Count
#define ACCEL_OPERAND_A_REG   REG32(ACCEL_BASE_ADDR + 0x0C) // Direct Mode Operand A
#define ACCEL_OPERAND_B_REG   REG32(ACCEL_BASE_ADDR + 0x10) // Direct Mode Operand B
#define ACCEL_RESULT_REG      REG32(ACCEL_BASE_ADDR + 0x14) // Direct Mode Result (Read-Only)
#define ACCEL_MAC_ACC_REG     REG32(ACCEL_BASE_ADDR + 0x18) // MAC Accumulator Register
#define ACCEL_IRQ_EN_REG      REG32(ACCEL_BASE_ADDR + 0x1C) // [0] Interrupt Enable

// Accelerator Opcodes
#define ACCEL_OP_ADD          0U
#define ACCEL_OP_SUB          1U
#define ACCEL_OP_MUL          2U
#define ACCEL_OP_DIV          3U
#define ACCEL_OP_MAC          4U

#define ACCEL_CTRL_START      (1U << 3)
#define ACCEL_CTRL_RESET      (1U << 4)
#define ACCEL_STATUS_BUSY     (1U << 0)
#define ACCEL_STATUS_DONE     (1U << 1)
#define ACCEL_STATUS_ERROR    (1U << 2)

/* ===============================================================================
 * 5. DMA Controller Registers (0x4000_4000)
 * =============================================================================== */
#define DMA_SRC_ADDR_REG      REG32(DMA_BASE_ADDR + 0x00) // Source Memory Address in DMEM
#define DMA_DST_ADDR_REG      REG32(DMA_BASE_ADDR + 0x04) // Destination Memory Address in DMEM
#define DMA_LENGTH_REG        REG32(DMA_BASE_ADDR + 0x08) // Number of Operand Pairs / Results
#define DMA_CTRL_REG          REG32(DMA_BASE_ADDR + 0x0C) // [0] Start, [1] IRQ_EN, [2] Abort
#define DMA_STATUS_REG        REG32(DMA_BASE_ADDR + 0x10) // [0] Busy, [1] Done, [2] Bus Error, [3] Overflow
#define DMA_ERR_ADDR_REG      REG32(DMA_BASE_ADDR + 0x14) // Address of Bus Error (Read-Only)

#define DMA_CTRL_START        (1U << 0)
#define DMA_CTRL_IRQ_EN       (1U << 1)
#define DMA_CTRL_ABORT        (1U << 2)
#define DMA_STATUS_BUSY       (1U << 0)
#define DMA_STATUS_DONE       (1U << 1)
#define DMA_STATUS_BUS_ERR    (1U << 2)

/* ===============================================================================
 * 6. SPI Controller Registers (0x4000_5000)
 * =============================================================================== */
#define SPI_DGIER_REG         REG32(SPI_BASE_ADDR + 0x1C) // Global Interrupt Enable ([31] GIE)
#define SPI_IPISR_REG         REG32(SPI_BASE_ADDR + 0x20) // IP Interrupt Status
#define SPI_IPIER_REG         REG32(SPI_BASE_ADDR + 0x28) // IP Interrupt Enable
#define SPI_SRR_REG           REG32(SPI_BASE_ADDR + 0x40) // Software Reset Register (write 0x0A)
#define SPI_RCLK_REG          REG32(SPI_BASE_ADDR + 0x30) // SCLK Frequency Prescaler Divisor
#define SPI_CR_REG            REG32(SPI_BASE_ADDR + 0x60) // Control: [0] Loop, [1] SPE, [2] Master, [3] CPOL, [4] CPHA
#define SPI_SR_REG            REG32(SPI_BASE_ADDR + 0x64) // Status: [0] RX_EMPTY, [1] RX_FULL, [2] TX_EMPTY, [3] TX_FULL
#define SPI_DTR_REG           REG32(SPI_BASE_ADDR + 0x68) // Data Transmit Register
#define SPI_DRR_REG           REG32(SPI_BASE_ADDR + 0x6C) // Data Receive Register
#define SPI_SSR_REG           REG32(SPI_BASE_ADDR + 0x70) // Slave Select Register (Active-Low)

#endif // SOC_REGS_H
