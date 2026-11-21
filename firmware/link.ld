/* ===============================================================================
 * Project        : RISC-V SoC with Hardware Arithmetic Accelerator
 * File           : link.ld
 * Description    : Linker script mapping to AXI4-Lite IMEM (64K) and DMEM (64K)
 * =============================================================================== */

OUTPUT_ARCH("riscv")
ENTRY(_start)

MEMORY
{
    rom (rx)  : ORIGIN = 0x00000000, LENGTH = 64K
    ram (rwx) : ORIGIN = 0x10000000, LENGTH = 64K
}

SECTIONS
{
    /* Code and read-only constants in Instruction Memory (ROM) */
    .text :
    {
        . = ALIGN(4);
        KEEP(*(.text.init))
        *(.text .text.*)
        *(.rodata .rodata.*)
        *(.srodata .srodata.*)
        . = ALIGN(4);
        _etext = .;
    } > rom

    _sidata = LOADADDR(.data);

    /* Initialized data placed in RAM, loaded from ROM */
    .data :
    {
        . = ALIGN(4);
        _sdata = .;
        __global_pointer$ = . + 0x800;
        *(.data .data.*)
        *(.sdata .sdata.*)
        . = ALIGN(4);
        _edata = .;
    } > ram AT > rom

    /* Zero-initialized data placed in RAM */
    .bss :
    {
        . = ALIGN(4);
        __bss_start = .;
        *(.bss .bss.*)
        *(.sbss .sbss.*)
        *(COMMON)
        . = ALIGN(4);
        _end = .;
    } > ram

    /* Stack Top placed at highest word of DMEM */
    _stack_top = ORIGIN(ram) + LENGTH(ram) - 4;

    /DISCARD/ :
    {
        *(.note.gnu.build-id)
        *(.comment)
        *(.riscv.attributes)
    }
}
