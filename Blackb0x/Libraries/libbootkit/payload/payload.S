.syntax unified
.text

.pool

.global _start
.code 16
_start:
	LDR R0, LOADADDR
	LDR R1, IMAGEADDR
	LDR R2, IMAGESIZE
	LDR R4, memmove
	BLX R4

    LDR R4, platform_get_boot_trampoline
	BLX R4

	MOV R5, R0

	MOV R0, #0x0
	LDR R4, platform_bootprep
	BLX R4

	LDR R4, usb_quiesce_no_free
	BLX R4

	LDR R4, timer_stop_all
	BLX R4

    LDR R4, interrupt_mask_all
    BLX R4

	LDR R4, clocks_quiesce
	BLX R4

	LDR R4, enter_critical_section
	BLX R4

	LDR R4, arch_cpu_quiesce
	BLX R4

	LDR R0, LOADADDR
	MOV R1, #0x0
	MOV R2, #0x0
	MOV R3, #0x0

	BLX R5

	loop:
		B loop

LOADADDR:
	.long 0xDEAD0001

IMAGEADDR:
	.long 0xDEAD0002

IMAGESIZE:
	.long 0xDEAD0003

memmove:
	.long 0xDEAD0004

platform_get_boot_trampoline:
	.long 0xDEAD0005

platform_bootprep:
	.long 0xDEAD0006

usb_quiesce_no_free:
	.long 0xDEAD0007

interrupt_mask_all:
	.long 0xDEAD0008

timer_stop_all:
	.long 0xDEAD0009

clocks_quiesce:
	.long 0xDEAD000A

enter_critical_section:
	.long 0xDEAD000B

arch_cpu_quiesce:
	.long 0xDEAD000C
