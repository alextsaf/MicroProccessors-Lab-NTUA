.include"m16def.inc"

.DEF A = r16	;definition of registers
.DEF B = r17
.DEF C = r18
.DEF D = r19
.DEF input = r20
.DEF F0 = r21
.DEF E = r22	;ancillary register

start:
ser r24
out DDRB, r24	;set PORTB as output
clr r24
out DDRC, r24	;set PORTC as input


in input, PINC
mov A, input	;A = 1st LSB 
lsr input
mov B, input	;B = 2nd LSB
lsr input
mov C, input	;C = 3rd LSB
lsr input
mov D, input	;D = 4th LSB

FO:
mov F0, A		;F0=A
com F0			;F0=A'
and F0, B		;F0=A'B

mov E, B		;E=B
com E			;E=B'
and E, C		;E=B'C
and E, D		;E=B'CD

or F0, E		;F0=(A'B + B'CD)
com F0			;F0=(A'B + B'CD)'
andi F0, 1		;mask for 1st LSB

F1:
and A, C		;A=AC
or B, D			;B=B+D
and A, B		;A=(AC)(B+D)=F1
lsl A
andi A, 2		;mask for 2nd LSB
or F0, A		;F0+F1
out PORTB, F0	;output

rjmp start


