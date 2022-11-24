; section for initilized variables with variables
section .data
	errorMessage db "Invalid", 000Ah, 00h

; section for uninitialized variables without values
section .bss
%define MAXN 127
	inputLine: resb MAXN
	operand1: resb MAXN
	operand2: resb MAXN
	res: resb MAXN+1

; section for code
section .text
global _start

_start:
	mov eax, operand1
	call reset
	mov eax, operand2
	call reset

	call input
	cmp ebx, 43 ; operator == '+'
	je addtion
	cmp ebx, 42 ; operator == '*'
	je multiply
	cmp ebx, 113 ; operator == 'q'
	je .quit
	call reportError
	jmp _start
	.quit:
		mov eax, 1
		mov ebx, 0
		int 80h ; exit(1: eax, 0: ebx)

; strlen(str: eax)->len: eax
strlen:
	push ebx
	mov ebx, eax
	.nextChar:
		cmp BYTE[ebx], 0
		jz .rett
		inc ebx
		jmp .nextChar
	.rett:
		sub ebx, eax
		mov eax, ebx
		pop ebx
		ret

reportError:
	push eax
	mov eax, errorMessage
	call puts
	pop eax
	ret

; puts(str: eax)
puts:
	pusha
	mov ecx, eax
	call strlen ; strlen(str: eax)->len: eax
	mov edx, eax ; edx=len
	mov ebx, 1
	mov eax, 4
	int 80h ; print(4: eax, 1: ebx, str: ecx, len: edx)
	popa
	ret

; getline(str: eax, len: ebx)
; input a line and store the string into str
getline:
	pusha
	mov edx, ebx
	mov ecx, eax
	mov ebx, 1
	mov eax, 3
	int 80h ; getline(3: eax, 1: ebx, str: ecx, len: edx)
	popa
	ret

; parseInput(numPtr: eax, str: ecx)
parseInput:
	.nextChar:
		cmp BYTE[ecx], 48 ; '0' = 48
		jl .rett
		cmp BYTE[ecx], 57 ; '9' = 57
		jg .rett

		mov dl, BYTE[ecx]
		mov BYTE[eax], dl
		inc eax
		inc ecx
		jmp .nextChar
	.rett:
		ret

; input a line and store string into operand1 and operand2, store operator in ebx, esi at the tail of operand1, edi at the tail of operand2
input:
	mov eax, inputLine
	mov ebx, MAXN
	call getline ; getline(str: eax, len: ebx)

	mov ecx, inputLine

	mov eax, operand1
	call parseInput ; parseInput(numPtr: eax, str: ecx)

	xor ebx, ebx
	mov bl, BYTE[ecx] ; copy operator into ebx
	inc ecx

	mov eax, operand2
	call parseInput ; parseInput(numPtr: eax, str: ecx)
	inc ecx

	mov eax, operand1 ; get len of the first number
	call strlen ; esi: ptr of num1, eax: len of first number
	mov esi, eax
	add esi, operand1 ; esi: the tailptr of operand1
	sub esi, 1

	mov eax, operand2 ; get len of the second number
	call strlen ; edi: ptr of num2
	mov edi, eax
	add edi, operand2 ; edi: the tailptr of operand2
	sub edi, 1

	ret

; carryDigit()->carry: ecx
carryDigit:
	mov ecx, 1
	sub al, 10
	ret

; add the string in operand1 and operand2 and store the sum into sum
addtion:
	mov ecx, 0 ; ecx = carry
	mov edx, res
	add edx, MAXN ; edx: the end of sum
	xor eax, eax
	mov al, 10
	mov BYTE[edx], al ; add LF at the end of sum
	.nextDigit:
		cmp esi, operand1 ; esi = current digit of operand1
		jl .restDigits2
		cmp edi, operand2 ; edi = current digit of operand2
		jl .restDigits1

		xor eax, eax
		add al, BYTE[esi]
		add al, BYTE[edi]
		sub al, 48
		add al, cl ; add carry
		mov ecx, 0 ; reset carry
		dec esi
		dec edi
		dec edx ; current digit of sum

		cmp al, 57 ; check if overflow occurs, '9'=57
		jle .nextDigit.notOverflow ; if not overflow, continue the loop
		call carryDigit ; if overflow, call sub digit
		.nextDigit.notOverflow:
			mov BYTE[edx], al
			jmp .nextDigit
	.restDigits1:
		cmp esi, operand1
		jl .tryCarry

		xor eax, eax
		add al, BYTE[esi] ; add by digits
		add al, cl ; add carry
		mov ecx, 0
		dec esi ; move ptr2
		dec edx ; move result ptr

		cmp al, 57 ; check if overflow occurs, '9'=57
		jle .restDigits1.notOverflow ; if not overflow, continue the loop
		call carryDigit ; if overflow, call sub digit
		.restDigits1.notOverflow:
			mov BYTE[edx], al
			jmp .restDigits1
	.restDigits2:
		cmp edi, operand2
		jl .tryCarry

		xor eax, eax
		add al, BYTE[edi] ; add by digits
		add al, cl ; add carry
		mov ecx, 0
		dec edi ; move ptr2
		dec edx ; move result ptr
		
		cmp al, 57 ; check if overflow occurs, '9'=57
		jle .restDigits2.notOverflow ; if not overflow, continue the loop
		call carryDigit ; if overflow, call sub digit
		.restDigits2.notOverflow:
			mov BYTE[edx], al
			jmp .restDigits2
	.tryCarry:
		cmp ecx, 1
		jne .output
		mov al, 49 ; '1' = 49
		dec edx
		mov BYTE[edx], al
	.output:
		mov eax, edx
		call puts
		jmp _start

; multiply operand1 and operand2, product at res[edx]
multiply:
	mov edx, res
	add edx, MAXN ; edx: ptr of result
	mov ecx, 0
	xor eax, eax
	mov al, 10
	mov BYTE[edx], al ; append LF at the back of product
	dec edx

	mov eax, operand1 ; get len of the first number
	call strlen ; esi: tailptr of num1
	mov esi, eax
	add esi, operand1
	sub esi, 1

	mov eax, operand2 ; get len of the second number
	call strlen ; edi: tailptr of num2
	mov edi, eax
	add edi, operand2
	sub edi, 1
	.outterLoop:
		cmp edi, operand2 ; operand1 multiplies operand2[edi] into product[edx]
		jl .multOutput
		call innerLoop
		dec edi
		dec edx
		jmp .outterLoop
	.multOutput:
		mov edx, eax
		call num2Str
	.outputNext:
		cmp BYTE[edx], 48
		jnz .print_mul
		mov ecx, res
		add ecx, (MAXN - 1)
		cmp edx, ecx
		je .print_mul
		inc edx
		jmp .outputNext
	.print_mul:
		mov eax, edx
		call puts
		jmp _start

; num2Str(eax, edx): array of number to string
num2Str:
	push edx
	push eax
	.nextDigit:
		mov eax, res
		add eax, MAXN
		cmp edx, eax ; need to num2Str
		jge .rett
		add BYTE[edx], 48
		inc edx
		jmp .nextDigit
	.rett:
		pop eax
		pop edx
		ret

; reset(arrayHead: eax): reset str with length of MAXN start at eax
reset:
	push eax
	push ebx
	mov ebx, eax
	add ebx, 255
	.nextDigit:
		cmp eax, ebx
		jge .rett ; till the end
		mov BYTE[eax], 0
		inc eax
		jmp .nextDigit
	.rett:
		pop ebx
		pop eax
		ret

; innerLoop(first_string_ptr: esi, ebx, mul_result_ptr: edx)->headOfProduct: eax
innerLoop:
	push esi
	push ebx
	push edx

	.multiplyNextDigit:
		cmp esi, operand1 ; mul by digits
		jl .finish
		xor eax, eax
		xor ebx, ebx
		add al, BYTE[esi]
		sub al, 48
		add bl, BYTE[edi] ; add by digits
		sub bl, 48
		mul bl
		add BYTE[edx], al ; accumulate result into product[edx]
		mov al, BYTE[edx] ; check if overflow
		mov ah, 0
		mov bl, 10
		div bl ; ah=remainder, al=quotient
		mov BYTE[edx], ah
		dec esi ; move ptr1
		dec edx ; move result ptr
		add BYTE[edx], al
		jmp .multiplyNextDigit

	.finish:
		mov eax, edx
		pop edx
		pop ebx
		pop esi
		ret
