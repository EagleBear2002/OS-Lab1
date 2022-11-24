; section for initilized variables with variables
section .data
    message1 db "Please input x and y: ", 0h
    message2 db "Sum: ", 0h
    message4 db "Product: ", 0h

; section for uninitialized variables without values
section .bss
    input_string: resb 255
    first_string: resb 255
    second_string: resb 255
    add_result: resb 255
    mul_result: resb 255
    add_ptr: resb 1

; section for code
section .text
global _start

; strlen(str: eax)->len: eax
strlen:
    push ebx
    mov ebx, eax
    .next:
        cmp BYTE[ebx], 0
        jz .finish
        inc ebx
        jmp .next
    .finish:
        sub ebx, eax
        mov eax, ebx
        pop ebx
    ret

; endl(ch: eax)->
endl:
    push eax
    mov eax, 0Ah
    call putchar
    pop eax
    ret

; puts(str: eax)
puts:
    push edx
    push ecx
    push ebx
    push eax

    mov ecx, eax
    ; strlen(str: eax)->len: eax
    call strlen
    mov edx, eax ; edx=len
    mov ebx, 1
    mov eax, 4
    int 80h ; print(4: eax, 1: ebx, str: ecx, len: edx)

    pop eax
    pop ebx
    pop ecx
    pop edx
    ret

; putchar(ch: esp)
putchar:
    push edx
    push ecx
    push ebx
    push eax

    mov eax, 4
    mov ebx, 1
    mov ecx, esp
    mov edx, 1
    int 80h ; print(4: eax, 1: ebx, str: esp, len: edx)

    pop eax
    pop ebx
    pop ecx
    pop edx

    ret

; getline(str: eax, len: ebx)
getline:
    push edx
    push ecx
    push ebx
    push eax

    mov edx, ebx
    mov ecx, eax
    mov ebx, 1
    mov eax, 3
    int 80h ; getline(3: eax, 1: ebx, str: ecx, len: edx)

    pop eax
    pop ebx
    pop ecx
    pop edx

    ret

; subdigit()->carry: ecx
sub_digit:
    mov ecx, 1
    sub al, 10
    ret

; parse_input(numPtr: eax, str: ecx)
parse_input:
    .loop:
        cmp BYTE[ecx], 32 ; ' '=32
        jz .rett
        cmp BYTE[ecx], 10 ; LF=10
        jz .rett
        mov dl, BYTE[ecx]
        mov BYTE[eax], dl
        inc eax
        inc ecx
        jmp .loop

    .rett:
        inc ecx
        ret

_start:
    .input:
        mov eax, message1
        ; puts(str: eax)
        call puts

        mov eax, input_string
        mov ebx, 255
        ; getline(str: eax, len: ebx)
        call getline

        mov ecx, input_string

        mov eax, first_string
        ; parse_input(numPtr: eax, str: ecx)
        call parse_input

        mov eax, second_string
        ; parse_input(numPtr: eax, str: ecx)
        call parse_input

    .after_input:
        mov ecx, 0
        mov edx, add_result
        add edx, 255
        ; edx: the end of add_result
        xor eax, eax
        mov al, 10
        mov BYTE[edx], al
        ; add LF at the end of add_result

        mov eax, first_string       ; get len of the first number
        call strlen
        ; esi: ptr of num1
        ; eax: len of first number
        mov esi, eax
        add esi, first_string
        ; esi: the tailptr of first_string
        sub esi, 1

        mov eax, second_string      ; get len of the second number
        call strlen
        ; edi: ptr of num2
        mov edi, eax
        add edi, second_string
        ; edi: the tailptr of second_string
        sub edi, 1

    .loopAdd:
        cmp esi, first_string
        jl .rest_second_digits
        cmp edi, second_string
        jl .rest_first_digits
        xor eax, eax
        add al, BYTE[esi]
        sub al, 48
        add al, BYTE[edi]           ; add by digits
        add al, cl                  ; add carry
        mov ecx, 0                  ; reset carry
        dec esi                     ; move ptr1
        dec edi                     ; move ptr2
        dec edx                     ; move result ptr
        cmp al, 57                  ; check if overflow occurs, '9'=57
        mov BYTE[edx], al
        jle .loopAdd                ; if not overflow, continue the loop
        call sub_digit              ; if overflow, call sub digit
        mov BYTE[edx], al
        jmp .loopAdd

    .rest_first_digits:
        cmp esi, first_string
        jl .after_add
        xor eax, eax
        add al, BYTE[esi]           ; add by digits
        add al, cl                  ; add carry
        mov ecx, 0
        dec esi                     ; move ptr2
        dec edx                     ; move result ptr
        mov BYTE[edx], al
        cmp al, 57
        jle .rest_first_digits      ; if not overflow
        call sub_digit              ; if overflow
        mov BYTE[edx], al
        jmp .rest_first_digits

    .rest_second_digits:
        cmp edi, second_string
        jl .after_add
        xor eax, eax
        add al,     BYTE[edi]           ; add by digits
        add al, cl                  ; add carry
        mov ecx, 0
        dec edi                     ; move ptr2
        dec edx                     ; move result ptr
        mov BYTE[edx], al
        cmp al, 57
        jle .rest_second_digits
        call sub_digit
        mov BYTE[edx], al
        jmp .rest_second_digits

    .after_add:
        cmp ecx, 1
        jz .add_carry               ; if ecx=1, add_carry
        jmp .output_add

    .add_carry:
        mov al, 49                  ; '1' = 49
        dec edx
        mov BYTE[edx], al
        jmp .output_add

    .output_add:
        mov eax, message2
        ; puts(str: eax)
        call puts

        mov eax, edx
        call puts

    .start_mul:
        mov edx, mul_result
        add edx, 255                ; edx: ptr of result
        mov ecx, 0
        xor eax, eax
        mov al, 10
        mov BYTE[edx], al           ; ppend LF at the back of mul_result
        dec edx

        mov eax, first_string       ; get len of the first number
        call strlen                 ; esi: tailptr of num1
        mov esi, eax
        add esi, first_string
        sub esi, 1

        mov eax, second_string      ; get len of the second number
        call strlen                 ; edi: tailptr of num2
        mov edi, eax
        add edi, second_string
        sub edi, 1

    .outter_loopMul:
        cmp edi, second_string       ; mul by digits
        jl .mul_output
        call inner_loopMul
        dec edi
        dec edx
        jmp .outter_loopMul

    .mul_output:
        mov edx, eax
        mov eax, message4
        call puts
        call num2Str

    .output_loop:
        cmp BYTE[edx], 48
        jnz .print_mul
        xor ecx, ecx
        add ecx, mul_result
        add ecx, 254
        cmp edx, ecx
        je .print_mul
        add edx, 1
        jmp .output_loop

    .print_mul:
        mov eax, edx
        call puts
    
    ;System Call to exit
    mov eax, 1
    mov ebx, 0
    int 80h ; exit(1: eax, 0: ebx)

; num2Str(eax, array_head: edx): array of number to string
num2Str:
    push edx
    push eax
    .loop:
        mov eax, mul_result
        add eax, 255
        cmp edx, eax                ;need to num2Str
        jge .finish
        add BYTE[edx], 48
        inc edx
        jmp .loop
    .finish:
        pop eax
        pop edx 
        ret

; inner_loopMul(first_string_ptr: esi, ebx, mul_result_ptr: edx)
inner_loopMul:
    push esi
    push ebx
    push edx

    .loop:
        cmp esi, first_string       ; mul by digits
        jl .finish
        xor eax, eax
        xor ebx, ebx
        add al, BYTE[esi]           ; 
        sub al, 48
        add bl, BYTE[edi]           ; add by digits
        sub bl, 48
        mul bl
        add BYTE[edx], al           ; accumulate result into mul_result[edx]
        mov al, BYTE[edx]           ; check if overflow
        mov ah, 0
        mov bl, 10
        div bl                      ; ah=remainder, al=quotient
        mov BYTE[edx], ah
        dec esi                     ; move ptr1
        dec edx                     ; move result ptr
        add BYTE[edx], al
        jmp .loop

    .finish:
        mov eax, edx
        pop edx
        pop ebx
        pop esi
        ret
