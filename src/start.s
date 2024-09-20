	.text
	.global _start
_start:
	ldr		x0, =stack_base
	mov		sp, x0
	mov		x29, #0
	bl		main
	wfi
