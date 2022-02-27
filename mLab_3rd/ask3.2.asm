;
; AssemblerApplication1.asm
;
; Created: 11/23/2021 11:01:55 AM
; Author : alex
;


; Replace with your application code

.DSEG
_tmp_: .byte 2

.CSEG
.include "m16def.inc"

.org 0x00
rjmp start

start:
	ldi r24, low(RAMEND) ;initialize stack pointer
	out SPL, r24
	ldi r24, high(RAMEND)
	out SPH, r24
	ser r24
	out DDRD, r24 ;input
	ldi r24, 0xF0
	out DDRC, r24 ;output and inout
;team 80, searching for '8' (r24 = 0x20) and '0' (r24 = 0x02) input

read1:
	rcall lcd_init_sim ;reset the display
	rcall scan_keypad_rising_edge_sim ;scan
	rcall keypad_to_ascii_sim ;match to ascii
	cpi r24, 0x00 ;did any button get pressed
	breq read1 ; if not, read again

	mov r21, r24 ; tempotarily store r24, to check for '8' later

read2:
	rcall scan_keypad_rising_edge_sim ;scan
	rcall keypad_to_ascii_sim ;match to ascii
	cpi r24, 0x00 ;did any button get pressed
	breq read2 ; if not, read again

	cpi r21, '8' ; 1st digit must be '8'
	brne wrong
	cpi r24, '0' ; 2nd digit must be '0'
	brne wrong

access:
;display the message
	rcall lcd_init_sim
	ldi r24,'W'
	rcall lcd_data_sim
	ldi r24,'E'
	rcall lcd_data_sim
	ldi r24,'L'
	rcall lcd_data_sim
	ldi r24,'C'
	rcall lcd_data_sim
	ldi r24,'O'
	rcall lcd_data_sim
	ldi r24,'M'
	rcall lcd_data_sim
	ldi r24,'E'
	rcall lcd_data_sim
	ldi r24,' '
	rcall lcd_data_sim
	ldi r24,'8'
	rcall lcd_data_sim
	ldi r24,'0'
	rcall lcd_data_sim
	ser r20 ;turn on the LED's
	out PORTB, r20
	ldi r20, 0x08 ; 8 time counter
	ldi r24,low(500) ; 8x500ms delays
	ldi r25,high(500)

welcome:
	rcall scan_keypad_rising_edge_sim ; read and ignore
	rcall wait_msec
	dec r20
	brne welcome	;loop
	rcall scan_keypad_rising_edge_sim ; read and ignore
	clr r20
	out PORTB, r20 ;turn off the LED's
	rjmp read1 ;start again

wrong:
;display the message
	rcall lcd_init_sim
	ldi r24,'A'
	rcall lcd_data_sim
	ldi r24,'L'
	rcall lcd_data_sim
	ldi r24,'A'
	rcall lcd_data_sim
	ldi r24,'R'
	rcall lcd_data_sim
	ldi r24,'M'
	rcall lcd_data_sim
	ldi r24,' '
	rcall lcd_data_sim
	ldi r24,'O'
	rcall lcd_data_sim
	ldi r24,'N'
	rcall lcd_data_sim
	ldi r20, 0x04

alarm:
	ser r21 ;turn on
	out PORTB, r21
	rcall scan_keypad_rising_edge_sim ; read and ignore
	ldi r24,low(500) ; 4x2x500ms delays
	ldi r25,high(500)
	rcall wait_msec ;500ms
	clr r21 ;turn off
	out PORTB, r21
	rcall scan_keypad_rising_edge_sim ; read and ignore
	ldi r24,low(500) ; 4x2x500ms delays
	ldi r25,high(500)
	rcall wait_msec
	dec r20
	cpi r20, 0x00
	brne alarm
	rjmp read1 ;start again

; Calls Given in the PDF (Copied and Pasted)
scan_row_sim:
	out PORTC, r25
	push r24
	push r25
	ldi r24,low(500)
	ldi r25,high(500)
	rcall wait_usec
	pop r25
	pop r24
	nop
	nop
	in r24, PINC
	andi r24 ,0x0f
	ret


scan_keypad_sim:
	push r26
	push r27
	ldi r25 , 0x10
	rcall scan_row_sim
	swap r24
	mov r27, r24
	ldi r25 ,0x20
	rcall scan_row_sim
	add r27, r24
	ldi r25 , 0x40
	rcall scan_row_sim
	swap r24
	mov r26, r24
	ldi r25 ,0x80
	rcall scan_row_sim
	add r26, r24
	movw r24, r26
	clr r26
	out PORTC,r26
	pop r27
	pop r26
	ret

scan_keypad_rising_edge_sim:
	push r22
	push r23
	push r26
	push r27
	rcall scan_keypad_sim
	push r24
	push r25
	ldi r24 ,15
	ldi r25 ,0
	rcall wait_msec
	rcall scan_keypad_sim
	pop r23
	pop r22
	and r24 ,r22
	and r25 ,r23
	ldi r26 ,low(_tmp_)
	ldi r27 ,high(_tmp_)
	ld r23 ,X+
	ld r22 ,X
	st X ,r24
	st -X ,r25
	com r23
	com r22
	and r24 ,r22
	and r25 ,r23
	pop r27
	pop r26
	pop r23
	pop r22
	ret

keypad_to_ascii_sim:
	push r26
	push r27
	movw r26 ,r24
	ldi r24 ,'*'
	sbrc r26 ,0
	rjmp return_ascii
	ldi r24 ,'0'
	sbrc r26 ,1
	rjmp return_ascii
	ldi r24 ,'#'
	sbrc r26 ,2
	rjmp return_ascii
	ldi r24 ,'D'
	sbrc r26 ,3
	rjmp return_ascii
	ldi r24 ,'7'
	sbrc r26 ,4
	rjmp return_ascii
	ldi r24 ,'8'
	sbrc r26 ,5
	rjmp return_ascii
	ldi r24 ,'9'
	sbrc r26 ,6
	rjmp return_ascii
	ldi r24 ,'C'
	sbrc r26 ,7
	rjmp return_ascii
	ldi r24 ,'4'
	sbrc r27 ,0
	rjmp return_ascii
	ldi r24 ,'5'
	sbrc r27 ,1
	rjmp return_ascii
	ldi r24 ,'6'
	sbrc r27 ,2
	rjmp return_ascii
	ldi r24 ,'B'
	sbrc r27 ,3
	rjmp return_ascii
	ldi r24 ,'1'
	sbrc r27 ,4
	rjmp return_ascii
	ldi r24 ,'2'
	sbrc r27 ,5
	rjmp return_ascii
	ldi r24 ,'3'
	sbrc r27 ,6
	rjmp return_ascii
	ldi r24 ,'A'
	sbrc r27 ,7
	rjmp return_ascii
	clr r24
	rjmp return_ascii

return_ascii:
	pop r27
	pop r26
	ret

write_2_nibbles_sim:
	push r24
	push r25
	ldi r24 ,low(6000)
	ldi r25 ,high(6000)
	rcall wait_usec
	pop r25
	pop r24
	push r24
	in r25, PIND
	andi r25, 0x0f
	andi r24, 0xf0
	add r24, r25
	out PORTD, r24
	sbi PORTD, PD3
	cbi PORTD, PD3
	push r24
	push r25
	ldi r24 ,low(6000)
	ldi r25 ,high(6000)
	rcall wait_usec
	pop r25
	pop r24
	pop r24
	swap r24
	andi r24 ,0xf0
	add r24, r25
	out PORTD, r24
	sbi PORTD, PD3
	cbi PORTD, PD3
	ret

lcd_data_sim:
	push r24
	push r25
	sbi PORTD, PD2
	rcall write_2_nibbles_sim
	ldi r24 ,43
	ldi r25 ,0
	rcall wait_usec
	pop r25
	pop r24
	ret

lcd_command_sim:
	push r24
	push r25
	cbi PORTD, PD2
	rcall write_2_nibbles_sim
	ldi r24, 39
	ldi r25, 0
	rcall wait_usec
	pop r25
	pop r24
	ret

lcd_init_sim:
	push r24 push r25
	ldi r24, 40
	ldi r25, 0
	rcall wait_msec
	ldi r24, 0x30
	out PORTD, r24
	sbi PORTD, PD3
	cbi PORTD, PD3
	ldi r24, 39
	ldi r25, 0
	rcall wait_usec
	push r24
	push r25
	ldi r24,low(1000)
	ldi r25,high(1000)
	rcall wait_usec
	pop r25
	pop r24
	ldi r24, 0x30
	out PORTD, r24
	sbi PORTD, PD3
	cbi PORTD, PD3
	ldi r24,39
	ldi r25,0
	rcall wait_usec
	push r24
	push r25
	ldi r24 ,low(1000)
	ldi r25 ,high(1000)
	rcall wait_usec
	pop r25
	pop r24
	ldi r24,0x20
	out PORTD, r24
	sbi PORTD, PD3
	cbi PORTD, PD3
	ldi r24,39
	ldi r25,0
	rcall wait_usec
	push r24
	push r25
	ldi r24 ,low(1000)
	ldi r25 ,high(1000)
	rcall wait_usec
	pop r25
	pop r24
	ldi r24,0x28
	rcall lcd_command_sim
	ldi r24,0x0c
	rcall lcd_command_sim
	ldi r24,0x01
	rcall lcd_command_sim
	ldi r24, low(1530)
	ldi r25, high(1530)
	rcall wait_usec
	ldi r24 ,0x06
	rcall lcd_command_sim
	pop r25
	pop r24
	ret


wait_msec:
	push r24
	push r25
	ldi r24 , low(998)
	ldi r25 , high(998)
	rcall wait_usec
	pop r25
	pop r24
	sbiw r24 , 1
	brne wait_msec
	ret

wait_usec:
	sbiw r24 ,1
	nop
	nop
	nop
	nop
	brne wait_usec
	ret
