    org 07c00h             ; 告诉编译程序加载到 7c00 处
    mov ax, cs
    mov ds, ax
    mov es, ax
    call DispStr           ; 调用显示字符串例程
    jmp $                  ; 无限循环
DispStr:
    mov ax, BootMessage
    mov bp, ax             ; ES : BP = 串地址
    mov cx, 16             ; CX = 串长度
    mov ax, 01301h         ; AH = 13 , AL = 01h
    mov bx, 000ch          ; 页号为 0 (BH = 0) 黑底红字 (BL = 0Ch, 高亮)
    mov dl, 0	
    int 10h                ; 10h 号中断
    ret

BootMessage:
    db "Hello, OS World!" 
times 510-($-$$) db 0      ; $-$$ 表示本行距离程序开始处的相对距离
                           ; 用 0 填充剩下的空间，使生成二进制恰好 512 字节
dw 0xaa55                  ; 结束标志
