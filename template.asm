; A word processor designed by Geoff Rich and Drew Roberts
; ---------------------------------------------------------

INCLUDE Irvine32.inc

getche PROTO C
getch PROTO C

lineLength = 50

.data
buffer BYTE lineLength DUP(?)
name1 BYTE "thisname", 0
fileHandle HANDLE ?

.code
asmMain proc C
	mov esi, 0
	mov ecx, lineLength
	
	L1:
		push ecx
		call getch
		cmp eax, 0e0h ; placed in buffer when arrow key pressed
		jne checkcharbound
			call getch ; additional char needs to be flushed out
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
		pop ecx
		loop L1

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