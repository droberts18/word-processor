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
; takes color input after caret is pressed
TakeColorInput proc
	pushad
	blueT:
		cmp eax, 62h
		jne greenT
		mov eax, lightCyan
		call SetTextColor
		jmp finish

	greenT:
		cmp eax, 67h
		jne redT
		mov eax, green
		call SetTextColor
		jmp finish

	redT:
		cmp eax, 72h
		jne lightGrayT
		mov eax, lightRed
		call SetTextColor
		jmp finish

	lightGrayT:
		cmp eax, 6Ch
		jne finish
		mov eax, lightGray
		call SetTextColor

	finish: 
		popad
		ret
TakeColorInput endp

; writes the current line to file and resets the buffer
MakeNewLine proc
	call Crlf
	inc lineCount
	mov eax, fileHandle
	mov edx, OFFSET buffer
	mov ecx, lineLength+2 ; allow for crlf at end of buffer
	call WriteToFile
	call ResetBuffer
	ret
MakeNewLine endp

; resets the buffer to hold all spaces
ResetBuffer proc
	pushad
	mov ecx, lineLength
	mov esi, 0
	L2:
		mov buffer[esi], 20h
		inc esi
		loop L2
	popad
	ret
ResetBuffer endp


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

		newline:
			cmp eax, 0Dh
			jne caret
			call MakeNewLine			
			mov esi, 0
			jmp L1

		caret:
			cmp eax, 5Eh ; caret key
			jne backspace
			mov cursorInfo.dwSize, 100
			INVOKE SetConsoleCursorInfo, outHandle, ADDR cursorInfo
			call getch
			cmp eax, 5Eh ; caret again - return to normal functioning
			je L1

			cmp eax, 73h ; s - save and quit
			je save
			call TakeColorInput ; otherwise check for colors
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
		
	call MakeNewLine
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