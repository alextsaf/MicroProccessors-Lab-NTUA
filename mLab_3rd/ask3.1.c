/*
 * GccApplication1.c
 *
 * Created: 11/23/2021 1:58:22 PM
 * Author : alex
 */

#include <avr/io.h>


char ram[2], key[2], digit[2];

//translated from assembly. 1 us delay
void wait_usec(int j){
	for(int i = 0; i < j; i++){
		asm("nop");
		asm("nop");
		asm("nop");
		asm("nop");
	}
}

//also tranlated from assembly. 1ms delay
void wait_msec(int j){
	for (int i = 0; i < j; i++){
		wait_usec(1000);
	}
}

//Scan a row of the keypad for input
//input: row of choice
//output: row's status
char scan_row(char c){
	PORTC = c;
	wait_usec(500);
	asm("nop");
	asm("nop");
	return (PINC & 0x0f);
}

//swap the 4 MSB with the 4 LSB of a variable
char swap(char word){
	return ((word & 0x0f) << 4 | (word & 0xf0) >> 4);
}

//scan the whole keypad's status.
//input: none
//output: none
//The keypad's status is stored in key[1] and key[2]
void scan_keypad(){
	char ret;

	ret = scan_row(0x10); //1st line
	key[1] = swap(ret);

	ret = scan_row(0x20); //2nd line
	key[1] += ret;

	ret = scan_row(0x40); //3rd line
	key[0] = swap(ret);

	ret = scan_row(0x80); //4th line
	key[0] += ret;
}

//scan the keypad for recently pressed buttons
//input: none
//output: none
void scan_keypad_rising_edge(){
	char ret[2];

	scan_keypad(); //scan and store
	ret[0] = key[0];
	ret[1] = key[1];

	wait_msec(15); //prevent sparkling

	scan_keypad();

	key[0] &= ret[0]; //check if the button is indeed pressed
	key[1] &= ret[1];

	ret[0] = ram[0];  //restore the last call's pressed buttons
	ret[1] = ram[1];

	ram[0] = key[0];  //store this call's pressed buttons
	ram[1] = key[1];

	key[0] &= ~ret[0]; //check if the button is newly pressed
	key[1] &= ~ret[1];
}


//match the button pressed, to it's ascii char,
//according to the manual
char keypad_to_ascii(){
	if (key[0] & 0x01) return '*';

	if (key[0] & 0x02) return '0';

	if (key[0] & 0x04) return '#';

	if (key[0] & 0x08) return 'D';

	if (key[0] & 0x10) return '7';

	if (key[0] & 0x20) return '8';

	if (key[0] & 0x40) return '9';

	if (key[0] & 0x80) return 'C';

	if (key[1] & 0x01) return '4';

	if (key[1] & 0x02) return '5';

	if (key[1] & 0x04) return '6';

	if (key[1] & 0x08) return 'B';

	if (key[1] & 0x10) return '1';

	if (key[1] & 0x20) return '2';

	if (key[1] & 0x40) return '3';

	if (key[1] & 0x80) return 'A';

	return 0;
}

//if the password is wrong
//we flash the LED's for 4s
void fail(){
	for (int i = 0; i < 4; i++){
		PORTB = 0xFF;
		wait_msec(480);
		scan_keypad_rising_edge(); //read and ignore
		PORTB = 0x00;
		wait_msec(480);
		scan_keypad_rising_edge(); //read and ignore
	}
}


//if we login successfully
//we turn on the LED's for 4s
void login(){
	PORTB = 0xff;
	for (int i = 0; i < 10; i++){
		wait_msec(380);
		scan_keypad_rising_edge(); //read and ignore
	}
}

int main(void){
	DDRB = 0xff; //output
	DDRC = 0xf0; //input and output

    while (1){
		ram[0] = 0; //initialize rmemory and PORTB
		ram[1] = 0;
		PORTB = 0x00;

		while(1){ //wait for the first digit
			scan_keypad_rising_edge();
			if ((digit[0] = keypad_to_ascii()) != 0) break;
		}

		while(1){ //wait for the second digit
			scan_keypad_rising_edge();
			if ((digit[1] = keypad_to_ascii()) != 0) break;
		}
		//if we get '80', we login
		if ((digit[0] == '8') && (digit[1] == '0')){
			login();
		}
		else {
			fail();
		}
    }
}
