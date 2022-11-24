global _main
extern _printf
section .text

_main:
    push message
    call _printf    ;调用C的printf
    add esp,4
    ret
    
message:
    db  'hello.asm',18,0