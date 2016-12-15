/*
 * Only used to call assember processes and provide access to conio functions 
 * Last Revised: 12/15/16
 * Written By: Geoff Rich and Drew Roberts
 */

#include <conio.h>
using namespace std;

extern "C" void asmMain();

int main() {
	asmMain();
	return 0;
}