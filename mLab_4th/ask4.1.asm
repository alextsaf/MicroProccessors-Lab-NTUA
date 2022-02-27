.DSEG
_tmp_: .byte 2

.CSEG
.include "m16def.inc"

;variables to make it easier

;b0 -> login_flag, b1-> gas_detected, b2-> alarm_flag, b3 -> gas_clear
;login_flag = 1 when the team goes in the room
;gas_detected = 1 when CO > 70ppm. Used in ADC int handler
;alarm_flag changes between 0-1 everytime the timer is called. Used for blinking
;gas_clear = 1 when the CO msr returns to normal
.def flags = r16
.def output = r17
.def lcd_message = r18 ;0x01 = gas_detected, 0x02 = clear

.org 0x00
rjmp start

.org 0x10
rjmp ISR_TIMER1_OVF

.org 0x1C
rjmp ADC_ISR

start:
	ldi r24, low(RAMEND) ;initialize stack pointer
	out SPL, r24
	ldi r24, high(RAMEND)
	out SPH, r24
	ser r24
	out DDRB, r24 ;output
	out DDRD, r24 ;output
	ldi r24, 0xF0
	out DDRC, r24 ;output and input
	rcall ADC_init
	ldi r24 ,(1<<TOIE1) ;EI
	out TIMSK ,r24
	ldi r24 ,(1<<CS12) | (0<<CS11) | (1<<CS10) ; CK/1024
	out TCCR1B ,r24
	;0xFCF3 = 64755
	ldi r24, 0xFC
	out TCNT1H, r24
	ldi r24, 0xF3
	out TCNT1L, r24
	clr lcd_message
	clr flags

;team 80, searching for '8' (r24 = 0x20) and '0' (r24 = 0x02) input

sei

read1:
	andi flags, 0x0C	;keep alarm_flag and gas_clear as they are
	;rcall lcd_init_sim ;reset the display
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

	ldi r20, 0x08 ; 8 time counter
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
	ldi lcd_message, 0x11 ;no permission to display other message


welcome:
	ori output, 0x80 ;turn on the MSB
	ori flags, 0x01 ;login_flag
	out PORTB, output
	rcall scan_keypad_rising_edge_sim ; read and ignore
	ldi r24,low(3900) ;compensate for other delays
	ldi r25,high(3900)
	rcall wait_msec
  rcall scan_keypad_rising_edge_sim ; read and ignore
	andi output, 0x7F; turn off PB7
	andi flags, 0x0C
	out PORTB, output ;turn off the LED
	rcall lcd_init_sim ;erase welcome message
	ldi lcd_message, 0x00 ;allow other message
	rjmp read1 ;start again

wrong:
	ori output, 0x80
	out PORTB, output
	rcall scan_keypad_rising_edge_sim ; read and ignore
	ldi r24,low(450) ; 4x2x500ms delays
	ldi r25,high(450)
	rcall wait_msec ;500ms
	dec r20
	andi output, 0x7F	; turn off PB7
	out PORTB, output
	rcall scan_keypad_rising_edge_sim ; read and ignore
	ldi r24,low(450) ; 4x2x500ms delays
	ldi r25,high(450); 450 + commands in the loop
	rcall wait_msec
	dec r20
	brne wrong
	rjmp read1 ;start again

lcd_alarm:
	;display message
	rcall lcd_init_sim
	ldi r24,'G'
	rcall lcd_data_sim
	ldi r24,'A'
	rcall lcd_data_sim
	ldi r24,'S'
	rcall lcd_data_sim
	ldi r24,' '
	rcall lcd_data_sim
	ldi r24,'D'
	rcall lcd_data_sim
	ldi r24,'E'
	rcall lcd_data_sim
	ldi r24,'T'
	rcall lcd_data_sim
	ldi r24,'E'
	rcall lcd_data_sim
	ldi r24,'C'
	rcall lcd_data_sim
	ldi r24,'T'
	rcall lcd_data_sim
	ldi r24,'E'
	rcall lcd_data_sim
	ldi r24,'D'
	rcall lcd_data_sim
	ldi lcd_message, 0x01 ;indicate the alarm message is displayed
	ret

lcd_clear:
	rcall lcd_init_sim
	ldi r24,'C'
	rcall lcd_data_sim
	ldi r24,'L'
	rcall lcd_data_sim
	ldi r24,'E'
	rcall lcd_data_sim
	ldi r24,'A'
	rcall lcd_data_sim
	ldi r24,'R'
	rcall lcd_data_sim
	andi flags, 0x07 ; unset gas_clear
	ldi lcd_message, 0x02 ;indicate the clear message is displayed
	ret

ISR_TIMER1_OVF:
	push r24
  push r25
	in r24, ADCSRA	;load ADCSRA and change the ADSC bit
	ori r24, (1<<ADSC) ;begin conversion
	out ADCSRA, r24
	ldi r24, 0xFC ;reset the timer
	out TCNT1H, r24
	ldi r24, 0xF3
	out TCNT1L, r24
	mov r24, flags	;complement the alarm_flag bit
	andi flags, 0x09 ;clear alarm_flag
	com r24
	andi r24, 0x04 ;isolate alarm_flag
	or flags, r24
  pop r25
  pop r24
	reti

;Thresholds decided:
;0-31, 32-63, 64-127, 128-255, 256-383, 384-511, 512-767
;easier to find the hex values, as they are powers of 2
ADC_ISR:
	push r24
	push r25
	push r26 ;used to store CO state

	in r24, ADCL
	in r25, ADCH
	andi r25, 0x03 ;keep the 2 LSB's
	cpi r25, 0x00
	breq less_than_256 ;if r25 is zero, we are below 256
	ori flags, 0x02 ;gas_detected
	cpi r25, 0x02 ;512 ?
	brlo check
	rjmp seven
	check:
		cpi r24, 0x80 ;384 ?
		brlo five
		rjmp six
	less_than_256:
		cpi r24, 0x20 ;<32 ?
		brlo one
		cpi r24, 0x40 ;<64 ?
		brlo two
		cpi r24, 0x80 ;<128 ?
		brlo three
		rjmp four		;<256
	one:
		ldi r26, 0x01
		rjmp leds_ok
	two:
		ldi r26, 0x03
		rjmp leds_ok
	three:
		ldi r26, 0x07
		rjmp leds_ok
	four:
		ldi r26, 0x0F
		rjmp flags_ok
	five:
		ldi r26, 0x1F
		rjmp flags_ok
	six:
		ldi r26, 0x3F
		rjmp flags_ok
	seven:
		ldi r26, 0x7F
		rjmp flags_ok

	leds_ok:
		cpi r24, 205	; check if CO > 70ppm
		brlo flags_ok
		ori flags, 0x02 ;gas_detected

	flags_ok:
		andi output, 0x80 ; isolate MSB
		sbrc flags, 0 ;login_flag
		rjmp login
		sbrs flags, 1 ;gas_detected
		rjmp normal_gas
		rjmp over70

	over70:
		sbrs lcd_message, 0 ;if gas_detected is diplayed, don't call again
		rcall lcd_alarm
		ori flags, 0x08 ;set gas_clear
		sbrc flags, 2 ;alarm_flag
		or output, r26 ;add the CO msr only when alarm_flag is set (alternating every 100ms)
		rjmp exit

	login:
		or output, r26 ;always show without blinking
		rjmp exit

	normal_gas:
		sbrc flags, 3 ;gas_clear
		rcall lcd_clear	;display to lcd, and clear flag
		or output, r26	;add the CO msr

	exit:
		out PORTB, output
		andi flags, 0x0D ;clear the gas_detected flag
		pop r26
		pop r25
		pop r24
		reti

; Calls Given in the PDF (Copied and Pasted)
; No need to check
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

ADC_init:
  ldi r24,(1<<REFS0) ; Vref: Vcc
  out ADMUX,r24      ;MUX4:0 = 00000 for A0.
  ;ADC is Enabled (ADEN=1)
  ;ADC Interrupts are Enabled (ADIE=1)
  ;Set Prescaler CK/128 = 62.5Khz (ADPS2:0=111)
  ldi r24,(1<<ADEN)|(1<<ADIE)|(1<<ADPS2)|(1<<ADPS1)|(1<<ADPS0)
  out ADCSRA,r24
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
