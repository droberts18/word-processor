; A word processor designed by Geoff Rich and Drew Roberts
; ---------------------------------------------------------

INCLUDE Irvine32.inc

getche PROTO C
getch PROTO C

lineLength = 50

.data
buffer BYTE lineLength DUP(20h), 0Dh, 0Ah
name1 BYTE "thisname", 0
fileHandle HANDLE ?
outHandle HANDLE ?
consoleInfo CONSOLE_SCREEN_BUFFER_INFO < > 
cursorPos COORD < >
cursorInfo CONSOLE_CURSOR_INFO <25,1>
negOne WORD -1
posOne WORD 1
backspaceStr BYTE 08h," ",08h,0
commands BYTE "^s = SAVE, ^b = BLUE, ^g = GREEN, ^r = RED, ^l = LIGHT GRAY(DEFAULT)", 0
format BYTE "------------------------------------------------------", 0
lineCount BYTE 0

.code
asmMain proc C
	call Crlf
	mov edx, OFFSET name1
	call CreateOutputFile
	mov fileHandle, eax

	INVOKE GetStdHandle, STD_OUTPUT_HANDLE
	mov outHandle, eax
	mov esi, 0
	
	mov edx, OFFSET commands
	call WriteString
	call Crlf
	mov edx, OFFSET format
	call WriteString
	call Crlf

	L1:
		mov cursorInfo.dwSize, 25
		INVOKE SetConsoleCursorInfo, outHandle, ADDR cursorInfo
		call getch

		cmp eax, 0Dh
		je newLine

		cmp eax, 5Eh ; caret key
		jne backspace

		mov cursorInfo.dwSize, 100
		INVOKE SetConsoleCursorInfo, outHandle, ADDR cursorInfo
		call getch
		cmp eax, 5Eh
		je L1

		cmp eax, 73h
		je save

		cmp eax, 62h
		je blueT

		cmp eax, 67h
		je greenT

		cmp eax, 72h
		je redT

		cmp eax, 6Ch
		je lightGrayT

		blueT:
			mov eax, lightCyan
			call SetTextColor
			jmp L1

		greenT:
			mov eax, green
			call SetTextColor
			jmp L1

		redT:
			mov eax, lightRed
			call SetTextColor
			jmp L1

		lightGrayT:
			mov eax, lightGray
			call SetTextColor
			jmp L1

		backspace:
			cmp eax, 08h ; backspace
			jne arrowkeys
				mov buffer[esi], 20h
				dec esi
				mov edx, OFFSET backspaceStr
				call WriteString
				jmp zerocheckesi

		arrowkeys:
		cmp eax, 0e0h ; placed in buffer when arrow key pressed
		jne checkcharbound
			INVOKE GetConsoleScreenBufferInfo, outHandle, ADDR consoleInfo
			mov ax, consoleInfo.dwCursorPosition.X
			mov cursorPos.X, ax
			mov ax, consoleInfo.dwCursorPosition.Y
			mov cursorPos.Y, ax

			call getch ; additional char needs to be flushed out
			mov ebx, 0 ; ebx holds amount to move cursor
			cmp eax, 04bh ; left arrow
			cmove bx, negOne
			cmp eax, 04dh ; right arrow
			cmove bx, posOne

			add cursorPos.X, bx
			movsx ebx,bx
			add esi, ebx ; move buffer position as well

			INVOKE SetConsoleCursorPosition, outHandle, cursorPos
			jmp zerocheckesi

		checkcharbound:
		cmp eax, 20h ; lower ascii bound of printable characters
		jl endofloop
		cmp eax, 7eh ; upper ascii bound of printable characters
		jg endofloop
			call WriteChar
			mov buffer[esi], al
			add esi, 1

		zerocheckesi:
			cmp esi, 0
			jg endofloop
			xor esi,esi
		
		endofloop:
			cmp esi, lineLength
			jl L1

	newLine:
		call Crlf
		inc lineCount
		

	mov eax, fileHandle
	mov edx, OFFSET buffer
	mov ecx, lineLength+2
	call WriteToFile
	mov ecx, lineLength
	mov esi, 0
	L2:
		mov buffer[esi], 20h
		inc esi
		loop L2

	mov esi, 0
	jmp L1

	save:
		mov eax, fileHandle
		mov edx, OFFSET buffer
		mov ecx, lineLength+2
		call WriteToFile
		call CloseFile

	ret
asmMain endp
end