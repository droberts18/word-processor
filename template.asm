; A word processor designed by Geoff Rich and Drew Roberts
; ---------------------------------------------------------

INCLUDE Irvine32.inc

getche PROTO C

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
		call getche
		mov buffer[esi], al
		add esi, 1
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