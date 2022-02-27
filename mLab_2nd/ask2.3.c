/*
 * GccApplication1.c
 *
 * Created: 10/31/2021 12:29:53 PM
 * Author : alex
 */

#include <avr/io.h>
#include <avr/interrupt.h>

char ret;
int counter;

void INT0_Enable(void){
	MCUCR = (1<<ISC01)|(1<<ISC00); //Positive edge enabling
	GICR = (1<<INT0); // INT0 enabling
	asm("sei");	// Enable Interrupts
}


ISR(INT0_vect){
	asm("cli");
	counter = 0x00;
	ret = PINB;
	for(int i = 0; i < 8; i++){	//Counting the number of 1's in PINB
		if ((ret & 0x01) == 0x01) counter = counter + 0x01;
		ret = ret>>1;
	}
	//If PA2 is ON, we display the counter in binary form
	if((PINA & 0x04) == 0x04){
		PORTC = counter;
	}
	//Else, we display the same number of consecutive 1's
	//starting from the LSB
	else{
		ret = 0x00;
		for (int i = 0; i < counter; i++){
		ret = ret + 0x01;
		ret = ret << 1;
	}
	//Bringing the first 1 back to the LSB
	PORTC = ret >> 1;
	}
	asm("sei");
}


int main(void)
{
	DDRA = 0x00;	//Input
	DDRB = 0x00;	//Input
	DDRC = 0xFF;	//Output
	INT0_Enable();

    while (1){
			ret = 0x00; //Do nothing
			continue;
		}
}
