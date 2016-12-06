; A word processor designed by Geoff Rich and Drew Roberts
; ---------------------------------------------------------

INCLUDE Irvine32.inc

getche PROTO C
getch PROTO C

lineLength = 50			; constant for number of chars in line
numOfHeadingLines = 2	; number of header lines initially written to console
tabSize = 3				; number of spaces equivalent to tab

.data
buffer BYTE lineLength DUP(20h), 0Dh, 0Ah	; holds each individual line
filename BYTE "thisname", 0					; name of file to read/write
fileHandle HANDLE ?
outHandle HANDLE ?

; receives info about the console/cursor
consoleInfo CONSOLE_SCREEN_BUFFER_INFO < > 
cursorPos COORD < >
cursorInfo CONSOLE_CURSOR_INFO <25,1>
windowHeight WORD ?

; used for move optimizations
negOne WORD -1
posOne WORD 1

backspaceStr BYTE 08h," ",08h,0 ; written when backspace key pressed

; header lines
commands BYTE "^s = SAVE, ^b = BLUE, ^g = GREEN, ^r = RED, ^l = LIGHT GRAY(DEFAULT)", 0
format BYTE "------------------------------------------------------", 0

lineCount BYTE 0
bytesRead DWORD ? ; used when reading from file

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

; sets file pointer position based on current value of line count
; so that the file pointer is set to the beginning of whatever line we're on
SetFilePointerPosition proc
	pushad
	mov ebx, lineLength + 2
	mov eax, 0
	mov al, lineCount
	mul ebx
	INVOKE SetFilePointer, fileHandle, eax, NULL, FILE_BEGIN
	popad
	ret
SetFilePointerPosition endp

; writes the current line to file and resets the buffer
MakeNewLine proc
	call Crlf
	call SetFilePointerPosition
	inc lineCount
	mov eax, fileHandle
	mov edx, OFFSET buffer
	mov ecx, lineLength+2 ; allow for crlf at end of buffer
	call WriteToFile
	call ResetBuffer
	call SetFilePointerPosition
	INVOKE ReadFile, fileHandle, ADDR buffer, lineLength, ADDR bytesRead, NULL
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

; writes a tab to the screen (see tabSize constant)
; if the end of the line is reached, it stops printing spaces
; receives: ESI = current line position
; returns: updated value of ESI
MakeTab proc
	push ecx
	push eax
	mov ecx, tabSize
	tabs:
		mov eax, 20h
		call WriteChar
		mov buffer[esi], al
		inc esi
		cmp esi, lineLength
		jge finish
		loop tabs
	finish: 
	pop ecx
	pop eax
	ret
MakeTab endp

asmMain proc C
	call Crlf
	INVOKE CreateFile, ADDR filename, GENERIC_READ + GENERIC_WRITE, 0, 0, OPEN_EXISTING, FILE_ATTRIBUTE_NORMAL, 0
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
			jne tabKey
			call MakeNewLine			
			mov esi, 0
			jmp L1

		tabKey:
			cmp eax, 09h
			jne caret
			call MakeTab

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
			; get cursor info and height of window
			INVOKE GetConsoleScreenBufferInfo, outHandle, ADDR consoleInfo
			mov ax, consoleInfo.dwCursorPosition.X
			mov cursorPos.X, ax
			mov ax, consoleInfo.dwCursorPosition.Y
			mov cursorPos.Y, ax
			mov ax, consoleInfo.srWindow.Bottom
			mov windowHeight, ax

			call getch ; additional char needs to be flushed out
			mov ebx, 0 ; ebx holds amount to move cursor on the x axis
			cmp eax, 04bh ; left arrow
			jne checkright
				mov bx, negOne
				cmp cursorPos.X, 0
				jne checkright			; if we're already on the left
				mov eax, 048h			; act like the up arrow was pressed
				mov bx, 0
				cmp cursorPos.Y, numOfHeadingLines + 1
				je checkright			; if we're not on the top line
				mov bx, lineLength - 1	; move the cursor to the end of the line
			checkright:
			cmp eax, 04dh ; right arrow
			cmove bx, posOne

			add cursorPos.X, bx
			movsx ebx,bx
			add esi, ebx ; move buffer position as well

			mov ebx,0
			cmp eax, 048h ; up arrow
			cmove bx, negOne
			cmp eax, 050h ; down arrow
			cmove bx, posOne

			add cursorPos.Y, bx

			checkcursormin:
			; prevent cursor from moving up into the heading
			cmp cursorPos.Y, numOfHeadingLines + 1
			jge checkcursormax
			mov cursorPos.Y, numOfHeadingLines + 1
			xor bx, bx

			checkcursormax:
			; prevent cursor from moving down too far
			mov ax, windowHeight
			cmp cursorPos.Y, ax
			jle finishCursor
			mov cursorPos.Y, ax
			xor bx, bx

			finishcursor:
			; set before changing lineCount so it writes to the start of current line
			call SetFilePointerPosition
			movsx ebx, bx
			add lineCount, bl

			; set the cursor position
			INVOKE SetConsoleCursorPosition, outHandle, cursorPos
			; save the current line to file
			mov eax, fileHandle
			mov edx, OFFSET buffer
			mov ecx, lineLength + 2
			call WriteToFile

			; read the new line into the buffer
			call ResetBuffer
			call SetFilePointerPosition
			INVOKE ReadFile, fileHandle, ADDR buffer, lineLength, ADDR bytesRead, NULL
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
		call SetFilePointerPosition
		mov eax, fileHandle
		mov edx, OFFSET buffer
		mov ecx, lineLength+2
		call WriteToFile
		call CloseFile

	ret
asmMain endp
end