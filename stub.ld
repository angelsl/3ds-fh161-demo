OUTPUT_FORMAT("elf32-littlearm", "elf32-bigarm", "elf32-littlearm")
OUTPUT_ARCH(arm)
ENTRY(_start)

SECTIONS
{
    . = 0x08006000;
    __start__ = ABSOLUTE(.);

    .text.start : ALIGN(4) { *(.text.start) }
    .text       : ALIGN(4) { *(.text*) }
    .rodata     : ALIGN(4) { *(.rodata*) }
    .data       : ALIGN(4) { *(.data*) }
    .bss        : ALIGN(4) { __bss_start = .; *(.bss* COMMON); __bss_end = .;}

    . = ALIGN(4);

    __end__ = ABSOLUTE(.);
    __code_size__ = __end__ - __start__;
    __stack_top__    = 0x28000000;
    __stack_bottom__ = __stack_top__ - 0x800000;
    __heap_start__   = 0x20000000;
    __heap_end__     = __stack_bottom__;
}
