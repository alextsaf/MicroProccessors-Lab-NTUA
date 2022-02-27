.org 0x0				;code always starts at 0x0
rjmp reset
.org 0x4				;INT1 address is 0x4
rjmp ISR1

reset:
ldi r24 , low(RAMEND)	;initialize stack pointer
out SPL , r24
ldi r24 , high(RAMEND)
out SPH , r24
ldi r24 ,( 1 << ISC10) | ( 1 << ISC11) ;interrupt starts at positive edge
out MCUCR,r24
ldi r24,( 1 << INT1)	;enable INT1 interrupt
out GICR,r24

ser r26
out DDRC , r26			;port C for output
out DDRB , r26			;port B for output
clr r26
out DDRA , r26			;port A for input

sei						 ;enable interrupts

loop:					;counter copied from ex2.1 (changed the port)
out PORTC , r26			;counter's loop
ldi r24 , low(100)
ldi r25 , high(100)
rcall wait_msec     ; delay 100ms
inc r26
rjmp loop

ISR1:
cli ;Disbale interrupts
in r28, PINA		;check PA7, PA6
andi r28, 0xC0
cpi r28,0xC0		;compare with 1100 0000
brne skip			;if PA7 and PA6 are set, increase the counter
in r27, PORTB
inc r27       
out PORTB, r27
skip:
reti
