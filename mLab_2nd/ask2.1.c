#include <avr/io.h>

char A, B, C, D, F0, F1;

int main(void)
{
	DDRB = 0xFF;
	DDRC = 0x00;


	while (1){

		//Isolating the bits
		A = PINC & 0x01;
		B = PINC & 0x02;
		C = PINC & 0x04;
		D = PINC & 0x08;

		//Bringing the bit to the LSB
		B = B >> 1;
		C = C >> 2;
		D = D >> 3;

		F0 = !((!A)&B)|((!B)&C&D);
		F1 = (A&C)&(B+D);
		F1 = F1 << 1; //2nd LSB

		PORTB = F1|F0;
	}
}
