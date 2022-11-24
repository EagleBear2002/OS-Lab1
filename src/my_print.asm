;Section to store uninitialized variables
section .data
    ; string: db 'Hello World', 0Ah
    string: db 'myprint.asm', 0Ah ; string[12]=0Ah=10=LF, string[13]=0
    length: equ 13

section .bss
    var: resb 1

section .text
    global _start:

_start:
    mov eax, 4
    mov ebx, 1
    mov ecx, string
    mov edx, length
    int 80h ; print(4: eax, 1: ebx, msg: ecx, len: edx), print string begin at str with length of len

    ;System Call to exit
    mov eax, 1
    mov ebx, 0
    int 80h ; exit(1: eax, 0: ebx)