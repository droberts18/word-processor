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
negOne WORD -1
posOne WORD 1
zero WORD 0

.code
asmMain proc C
	INVOKE GetStdHandle, STD_OUTPUT_HANDLE
	mov outHandle, eax
	mov esi, 0
	
	L1:
		call getch
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

			cmp cursorPos.X, 0
			cmovle bx,zero ; if x <= 0, don't move cursor/buffer at all
			add cursorPos.X, bx
			movsx ebx,bx
			add esi, ebx ; move buffer position as well

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