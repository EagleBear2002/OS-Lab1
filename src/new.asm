SECTION .data
    msg db 'Hello, brave new world!', 0Ah

SECTION .text
global _start

_start:
    mov eax, msg
    call strlen
    mov edx, eax ; edx=len
    mov ecx, msg ; ecx=msg
    mov ebx, 1
    mov eax, 4
    int 80h ; print(4: eax, 1: ebx, msg: ecx, len: edx)
    mov ebx, 0
    mov eax, 1
    int 80h ; exit(1: eax, 0: ebx)

; strlen(str: eax)->len: eax
strlen:
    push ebx
    mov ebx, eax
nextchar:
    cmp byte[eax], 0
    jz finished
    inc eax
    jmp nextchar
finished:
    sub eax, ebx
    pop ebx
    ret 