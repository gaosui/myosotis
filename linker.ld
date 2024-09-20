ENTRY(_start);

SECTIONS {
	. = 0x40100000;

	.text : { *(.text*) }
	.rodata : { *(.rodata*) }
	.data : { *(.data*) }

	. = ALIGN(16);
	heap_base = .;
	. += 0x1000000;
	stack_base = .;
}
