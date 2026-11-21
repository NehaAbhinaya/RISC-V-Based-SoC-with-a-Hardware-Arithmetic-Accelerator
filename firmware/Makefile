# ===============================================================================
# Project        : RISC-V SoC with Hardware Arithmetic Accelerator
# File           : Makefile
# Description    : Build script for Bare-Metal SoC Firmware
# ===============================================================================

# Auto-detect RISC-V GCC toolchain
TOOLCHAIN_BIN := /home/student/riscv-toolchain/usr/bin
ifneq ($(wildcard $(TOOLCHAIN_BIN)/riscv64-linux-gnu-gcc),)
    PATH := $(TOOLCHAIN_BIN):$(PATH)
    export PATH
endif

CROSS_COMPILE ?= $(shell if command -v riscv32-unknown-elf-gcc >/dev/null 2>&1; then echo riscv32-unknown-elf-; \
                         elif command -v riscv64-linux-gnu-gcc >/dev/null 2>&1; then echo riscv64-linux-gnu-; \
                         elif [ -f $(TOOLCHAIN_BIN)/riscv64-linux-gnu-gcc ]; then echo $(TOOLCHAIN_BIN)/riscv64-linux-gnu-; \
                         else echo riscv64-unknown-elf-; fi)
CC            := $(CROSS_COMPILE)gcc
AS            := $(CROSS_COMPILE)as
OBJCOPY       := $(CROSS_COMPILE)objcopy
OBJDUMP       := $(CROSS_COMPILE)objdump
PYTHON        := python3

# Target architecture: RV32IMC + Zicsr (matching VeeR EL2 configuration)
ARCH_FLAGS    := -march=rv32imc_zicsr -mabi=ilp32
CFLAGS        := $(ARCH_FLAGS) -O2 -Wall -Wextra -ffreestanding -nostdlib -I.
ASFLAGS       := $(ARCH_FLAGS)
LDFLAGS       := -T link.ld -nostdlib -Wl,--gc-sections -Wl,--build-id=none

SRCS_C        := main.c uart.c timer.c gpio.c accelerator.c dma.c spi.c
SRCS_S        := startup.s
OBJS          := $(SRCS_S:.s=.o) $(SRCS_C:.c=.o)

TARGET        := soc_firmware

.PHONY: all clean hex dis

all: $(TARGET).elf $(TARGET).bin $(TARGET).hex $(TARGET).dis

$(TARGET).elf: $(OBJS) link.ld
	$(CC) $(CFLAGS) $(LDFLAGS) $(OBJS) -o $@

%.o: %.c
	$(CC) $(CFLAGS) -c $< -o $@

%.o: %.s
	$(CC) $(CFLAGS) -c $< -o $@

$(TARGET).bin: $(TARGET).elf
	$(OBJCOPY) -O binary $< $@

$(TARGET).hex: $(TARGET).bin bin2hex.py
	$(PYTHON) bin2hex.py $(TARGET).bin $(TARGET).hex 16384
	cp -f $(TARGET).hex ../$(TARGET).hex 2>/dev/null || true
	cp -f $(TARGET).hex ../top/$(TARGET).hex 2>/dev/null || true

$(TARGET).dis: $(TARGET).elf
	$(OBJDUMP) -d -S $< > $@

clean:
	rm -f $(OBJS) $(TARGET).elf $(TARGET).bin $(TARGET).hex $(TARGET).dis
