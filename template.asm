; A word processor designed by Geoff Rich and Drew Roberts
; ---------------------------------------------------------

INCLUDE Irvine32.inc

getche PROTO C
getch PROTO C

lineLength = 50

.data
buffer BYTE lineLength DUP(20h)
name1 BYTE "thisname", 0
fileHandle HANDLE ?
outHandle HANDLE ?
consoleInfo CONSOLE_SCREEN_BUFFER_INFO < > 
cursorPos COORD < >

.code
asmMain proc C
	INVOKE GetStdHandle, STD_OUTPUT_HANDLE
	mov outHandle, eax
	mov esi, 0
	
	L1:
		call getch
		cmp eax, 0e0h ; placed in buffer when arrow key pressed
		jne checkcharbound
			call getch ; additional char needs to be flushed out
			cmp eax, 04bh ; left arrow
			jne endofloop
				; if left arrow, move cursor left
				INVOKE GetConsoleScreenBufferInfo, outHandle, ADDR consoleInfo
				mov ax, consoleInfo.dwCursorPosition.X
				mov cursorPos.X, ax
				cmp cursorPos.X, 0
				jle cursorY ; if zero or less, don't move the cursor back
					dec cursorPos.X
					dec esi ; move buffer position back as well

				cursorY:
				mov ax, consoleInfo.dwCursorPosition.Y
				mov cursorPos.Y, ax

				INVOKE SetConsoleCursorPosition, outHandle, cursorPos
				jmp endofloop

		checkcharbound:
		cmp eax, 20h ; lower ascii bound of printable characters
		jl endofloop
		cmp eax, 7eh ; upper ascii bound of printable characters
		jg endofloop
			call WriteChar
			mov buffer[esi], al
			add esi, 1
		
		endofloop:
			cmp esi, lineLength
			jl L1

	call Crlf
	mov edx, OFFSET name1
	call CreateOutputFile
	mov fileHandle, eax
	
	mov edx, OFFSET buffer
	mov ecx, lineLength
	call WriteToFile
	call CloseFile

	ret
asmMain endp
end