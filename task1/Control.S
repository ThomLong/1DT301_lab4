@
@ Assembler program to flash three LEDs connected to the
@ Raspberry Pi GPIO writing to the registers directly.
@
@

#include "hardware/regs/addressmap.h"
#include "hardware/regs/sio.h"
#include "hardware/regs/io_bank0.h"
#include "hardware/regs/pads_bank0.h"

	.EQU	LED_PIN1, 0
	.EQU	BUTTON_ON, 1
	.EQU	BUTTON_OFF, 2

.thumb_func
.global main	        @ Provide program starting address

	.align  4	@ necessary alignment
main:
@ Init each of the three pins and set them to output
	MOV	R0, #LED_PIN1		
	BL	gpioinit
	MOV	R0, #BUTTON_ON
	BL	gpioinit
	MOV	R0, #BUTTON_OFF
	BL	gpioinit

loop:
	MOV R0, #BUTTON_ON
	BL gpio_get
	CMP R0, #1
	BEQ turn_on
	B	loop

turn_on:
	MOV R0, #LED_PIN1	
	MOV R1, #1
	BL gpio_on
	MOV R0, #BUTTON_OFF
	BL  gpio_get
	CMP R0, #1
	BEQ turn_off
	B	turn_on 

turn_off:
	MOV R0, #LED_PIN1
	MOV R1, #0
	BL  gpio_off
	B	loop 

@ Initialize the GPIO to SIO. r0 = pin to init.
gpioinit:
@ Initialize the GPIO	
	MOV	R3, #1
	LSL	R3, R0	@ shift over to pin position
	LDR	R2, gpiobase	@ address we want	
	STR	R3, [R2, #SIO_GPIO_OE_SET_OFFSET]
	STR	R3, [R2, #SIO_GPIO_OUT_CLR_OFFSET]

@ Enable input and output for the pin
	LDR	R2, padsbank0
	LSL	R3, R0, #2	@ pin * 4 for register address
	ADD	R2, R3		@ Actual set of registers for pin
	MOV	R1, #PADS_BANK0_GPIO0_IE_BITS
	LDR	R4, setoffset
	ORR	R2, R4
	STR	R1, [R2, #PADS_BANK0_GPIO0_OFFSET]

@ Set the function number to SIO.
	LSL	R0, #3		@ each GPIO has 8 bytes of registers
	LDR	R2, iobank0	@ address we want
	ADD	R2, R0		@ add the offset for the pin number
	MOV	R1, #IO_BANK0_GPIO3_CTRL_FUNCSEL_VALUE_SIO_3
	STR	R1, [R2, #IO_BANK0_GPIO0_CTRL_OFFSET]
	BX	LR

@ Turn on a GPIO pin.
gpio_on:
	MOV	R3, #1
	LSL	R3, R0	@ shift over to pin position
	LDR	R2, gpiobase	@ address we want
	STR	R3, [R2, #SIO_GPIO_OUT_SET_OFFSET]
	BX	LR

@ Turn off a GPIO pin.
gpio_off:
	MOV	R3, #1
	LSL	R3, R0	@ shift over to pin position
	LDR	R2, gpiobase	@ address we want
	STR	R3, [R2, #SIO_GPIO_OUT_CLR_OFFSET]
	BX	LR

@ Get signal from button
gpio_get:
	MOV R3, #1
	LSL R3, R0 @ shift over to pin position
	LDR R2, gpiobase
	LDR R1, [R2, #SIO_GPIO_IN_OFFSET]
	AND R3, R3, R1
	LSR R3, R3, R0
	MOV R0, R3
	BX LR

	      	.align  4	@ necessary alignment
gpiobase:	.word	SIO_BASE     @ base of the GPIO registers
iobank0:	.word	IO_BANK0_BASE @ base of io config registers
padsbank0:	.word	PADS_BANK0_BASE
setoffset:	.word	REG_ALIAS_SET_BITS