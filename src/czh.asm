SECTION .data
inStr       times 100 db 0
outStr      times 100 db 0
a           times 100 dd 0
b           times 100 dd 0
c           times 100 dd 0
invalidStr            db 'Invalid', 0Ah, 00h

SECTION .bss
tmp         resd 1
op          resb 1              ; op = 0, '+'; op = 1, '*'
isLen       resd 1
osLen       resd 1
aLen        resd 1
bLen        resd 1
cLen        resd 1
endFlag     resb 1
isDigitRet  resb 1
isOpRet     resb 1
aEnd        resd 1
bEnd        resd 1
cEnd        resd 1
ai          resd 1
bi          resd 1
addEndFlag  resb 1
mulEndFlag  resb 1


;; inStr -> a op b = c -> outStr

SECTION .text
global  _start
 
_start:
mainLoop:
  call    read                

  mov     Byte[endFlag], 0
  cmp     Byte[inStr], 113      ; 'q' = 113, exit
  jz      mainExit

  add     eax, inStr
  mov     Byte[eax], 0          ; inStr[isLen] = '\0'

  ;mov     eax, inStr
  ;call    print                ; print(inStr)

  call    parse
  cmp     Byte[endFlag], 1
  jz      invalidHandler
  cmp     Byte[op], 0
  jz      addHandler
  cmp     Byte[op], 1
  jz      mulHandler

addHandler:
  call    doAdd
  call    genOutStr
  mov     eax, outStr
  jmp     outPut
mulHandler:
  call    doMul
  call    genOutStr
  mov     eax, outStr
  jmp     outPut

invalidHandler:
  mov     eax, invalidStr
  jmp     outPut                ; useless

outPut:
  ;; assume outputStr in eax has been prepared yet
  call    print  
  jmp     mainLoop

mainExit:
  mov     ebx, 0
  mov     eax, 1
  int     80h      


;; Function
;; parse: parse inStr -> a op b with endFlag = 0 or endFlag = 1
;;     [0 - 9]        + / *        \n(0Ah)    
;; 0 -----------> 1 ---------> 2 ---------> (accept)
;;               / \          / \
;;              /   \        /   \
;;              \   /        \   /
;;               \/           \/
;;            [0 - 9]      [0 - 9]
parse:
  pusha
  mov     Byte[endFlag], 0      ; endFlag = false

  mov     eax, inStr            ; eax = inStr[i]
  mov     ebx, 0                ; ebx = current state id
transfer:
  cmp     ebx, 0                ; if cur == 0
  jz      case0                 
  cmp     ebx, 1                ; if cur == 1
  jz      case1
  cmp     ebx, 2                ; if cur == 2
  jz      case2
  jmp     reject                ; assert(cur >= 0 && cur <= 3)
case0:
  call    isDigit
  cmp     Byte[isDigitRet], 1
  jnz     reject  
  mov     ebx, 1   
  jmp     nxtChar
case1:
  call    isDigit
  cmp     Byte[isDigitRet], 1
  jz      nxtChar
  call    isOp
  cmp     Byte[isOpRet], 1
  jnz     reject
  mov     ebx, 2
  jmp     nxtChar
case2:
  call    isDigit
  cmp     Byte[isDigitRet], 1
  jz      nxtChar
  cmp     Byte[eax], 0Ah        ; inStr[i] == '\n' ? 
  jz      accept
  jmp     reject
nxtChar:
  add     eax, 1
  jmp     transfer

accept:
;; reverse a, b
  mov     eax, inStr
getRendLoop:                    ; find inclusive rend of inStr
  cmp     Byte[eax], 0Ah        ; '\n' = 10
  jz      getRendExit
  add     eax, 1
  jmp     getRendLoop
getRendExit:
  sub     eax, 1                ; --eax, now eax = rend()
  mov     ebx, b       
                                
                                ; init
  mov     Dword[aLen], 0        ; aLen = 0
  mov     Dword[bLen], 0        ; bLen = 0
  mov     Byte[op], 0           ; op = 0
parseLoop:
findB:
  call    isDigit
  cmp     Byte[isDigitRet], 0   ; find op
  jz      findOp
  mov     ecx, 0                ; set 0 for higher bits in ecx   
  mov     cl, Byte[eax]         ; set value for lower bits in ecx(cl)
  sub     ecx, 48               ; ecx -= '0'
  mov     Dword[ebx], ecx       ; b[i] = ecx
  add     ebx, 4                ; i = i + 1
  add     Dword[bLen], 4        ; bLen++
  sub     eax, 1                ; inStr[j], j--
  jmp     findB
findOp:
  cmp     Byte[eax], 43         ; (inStr[j] = op) == '+' ? 
  jz      findOpEnd
  mov     Byte[op], 1           ; op = 1, otherwise op = 0
findOpEnd:
  sub     eax, 1                ; j--
  mov     ebx, a                ; ebx = a
findA:
  mov     ecx, 0
  mov     cl, Byte[eax]
  sub     ecx, 48               ; ecx -= '0'
  mov     Dword[ebx], ecx       ; a[i] = ecx
  add     ebx, 4                ; i = i + 1
  add     Dword[aLen], 4        ; ++aLen

  cmp     eax, inStr
  jz      acceptEnd
  sub     eax, 1                ; j--
  jmp     findA

acceptEnd:
  ;; ---- Debug ----
  ; mov     eax, a
  ; mov     eax, b
  ;; ---- Debug End ----
  popa
  ret

reject:
  mov   Byte[endFlag], 1
  popa
  ret   


;; Function
;; isDigit(Byte[eax]) -> isDigitRet 1 / 0 = True / False
;; judge whether a char \in ['0', '9']
isDigit:
  pusha
  mov   Byte[isDigitRet], 1     ; isDigitRet = true
  mov   ebx, 48                 ; ebx = '0' = 48
isDigitLoop:
  cmp   ebx, 58                 ; ebx < '9' + 1 = 58
  jz    isDigitReject
  cmp   Byte[eax], bl           ; Byte[eax] == el ? 
  jz    isDigitAccept
  add   ebx, 1
  jmp   isDigitLoop
isDigitReject:
  mov   Byte[isDigitRet], 0
isDigitAccept:
  popa
  ret


;; Function
;; isOp([eax]) -> isOpRet 1 / 0 = True / False
;; judge whether a char \in {'+', '*'}
isOp:
  pusha
  mov   Byte[isOpRet], 1        ; isOpRet = true
  cmp   Byte[eax], 43           ; '+' = 43
  jz    isOpAccept
  cmp   Byte[eax], 42           ; '*' = 42
  jz    isOpAccept
  jmp   isOpReject  
isOpReject:
  mov   Byte[isOpRet], 0        ; isOpRet = false          
isOpAccept:
  popa
  ret


;; Function
doAdd:
;; TODO: test doAdd()
  pusha

  mov     eax, a                ; 
  add     eax, Dword[aLen]      ;
  mov     Dword[aEnd], eax      ; aEnd = a + aLen
  mov     eax, b
  add     eax, Dword[bLen]
  mov     Dword[bEnd], eax      ; bEnd = b + bLen

  mov     eax, a
  mov     ebx, b
  mov     ecx, c
  mov     Dword[cLen], 0        ; cLen = 0
addLoop:
  mov     Byte[addEndFlag], 1   ; addEndFlag = true
  mov     Dword[ai], 0          ; default set a[i] = 0
  mov     Dword[bi], 0          ; default set b[i] = 0
judgeA:
  cmp     eax, Dword[aEnd]      ; if i < aLen
  jb      setA
  jmp     judgeB                ; goto judgeB
setA:
  mov     Byte[addEndFlag], 0   ; addEndFlag = false
  mov     edx, Dword[eax]
  mov     Dword[ai], edx        ; a[i] = real a[i]
judgeB:
  cmp     ebx, Dword[bEnd]      ; if i < bLen
  jb      setB
  jmp     addSingle
setB:
  mov     Byte[addEndFlag], 0   ; addEndFlag = false
  mov     edx, Dword[ebx]       
  mov     Dword[bi], edx        ; b[i] = real b[i]
addSingle:
  cmp     Byte[addEndFlag], 1   ; if addEndFlag == true
  jz      addEnd                ; goto addEnd
  mov     edx, Dword[ai]
  add     edx, Dword[bi]        ; edx = ai + bi
  mov     Dword[ecx], edx       ; c[i] = edx
  add     eax, 4                ; a[i], i = i + 1
  add     ebx, 4                ; b[i], i = i + 1
  add     ecx, 4                ; c[i], i = i + 1
  mov     edx, Dword[cLen]      ; 
  add     edx, 4                ; 
  mov     Dword[cLen], edx      ; cLen += 4
  jmp     addLoop  
addEnd:

  mov     eax, c
  add     eax, Dword[cLen]      ; 
  mov     Dword[cEnd], eax      ; cEnd = c + cLen
  mov     eax, c                ;
carryLoop:
  cmp     eax, Dword[cEnd]      ; if i < cEnd
  jnb     carryEnd              ; 
  mov     ebx, eax
  add     ebx, 4                ; eax = i, ebx = i + 1
carryCheck:
  cmp     Dword[eax], 10        ; if c[i] < 10
  jb      doCarry
  cmp     ebx, Dword[cEnd]      ; if i < cLen
  jb      doCarry               ;
                                ; if c[i] >= 10 && i >= cLen(ebx >= cEnd)
  mov     ecx, Dword[cLen]      ; lengthen c
  add     ecx, 4                ; 
  mov     Dword[cLen], ecx      ; cLen += 1
  mov     ecx, Dword[cEnd]
  add     ecx, 4
  mov     Dword[cEnd], ecx      ; cEnd += 4
  mov     ecx, cEnd
  sub     ecx, 4                
  mov     Dword[ecx], 0         ; c[cLen - 1] = 0
doCarry:
  cmp     Dword[eax], 10        ; if c[i] < 10
  jb      doCarryEnd
  mov     ecx, Dword[eax]
  sub     ecx, 10
  mov     Dword[eax], ecx       ; c[i] -= 10
  mov     ecx, Dword[ebx]
  add     ecx, 1
  mov     Dword[ebx], ecx       ; c[i + 1]++
  jmp     doCarry
doCarryEnd:
  add     eax, 4                ; i++
  jmp     carryLoop
carryEnd:
  ; mov     eax, c               ; to debug
  popa
  ret


;; Function
doMul:
;; TODO: test doMul()
  pusha
  
  mov     eax, c
  add     eax, Dword[aLen]
  add     eax, Dword[bLen]
  sub     eax, 4
  mov     Dword[cEnd], eax      ; cEnd = c + aLen + bLen - 4(1)
  mov     eax, Dword[aLen]
  add     eax, Dword[bLen]
  sub     eax, 4
  mov     Dword[cLen], eax      ; cLen = aLen + bLen - 1

  mov     eax, c
clearLoop:
  cmp     eax, Dword[cEnd]      ; if i >= cEnd
  jnb     clearEnd              ; goto clearEnd
  mov     Dword[eax], 0         ; c[i] = 0
  add     eax, 4                ; i += 1
  jmp     clearLoop             ; 
clearEnd: 
  
  mov     eax, a                ; 
  add     eax, Dword[aLen]      ;
  mov     Dword[aEnd], eax      ; aEnd = a + aLen
  mov     eax, b
  add     eax, Dword[bLen]
  mov     Dword[bEnd], eax      ; bEnd = b + bLen

  mov     eax, a
mulLoopA:                       ; for i in range(0, aLen)
  cmp     eax, Dword[aEnd]      ; if i >= aEnd
  jnb     mulEnd                ; goto mulEnd
  mov     ebx, b                ; ebx = b
mulLoopB:                       ; for j in range(0, bLen)
  cmp     ebx, Dword[bEnd]      ; if j >= bEnd
  jnb     nxtA                  ; goto mulLoopA
  mov     ecx, Dword[eax]       ; ecx = a[i]
  push    eax                   ; first push(save) eax, for its use in edx:eax = mul src
  mov     eax, Dword[ebx]       ; eax = b[j]
  mul     ecx                   ; a[i] * b[j]
                                ; edx:eax = eax * ecx, here assert edx == 0, result is in eax
  mov     ecx, eax              ; now result is in ecx
  pop     eax                   ; load previous eax
  mov     edx, c
  add     edx, eax
  sub     edx, a
  add     edx, ebx
  sub     edx, b                ; edx = c + (eax - a) + (ebx - b), here Dword[edx] = c[i + j]
  add     Dword[edx], ecx

  add     ebx, 4                ; j++
  jmp     mulLoopB
nxtA:
  add     eax, 4                ; i++
  jmp     mulLoopA
mulEnd:

  mov     eax, c
  add     eax, Dword[cLen]      ; 
  mov     Dword[cEnd], eax      ; cEnd = c + cLen
  mov     eax, c                ;
mulCarryLoop:
  cmp     eax, Dword[cEnd]      ; if i < cEnd
  jnb     mulCarryEnd              ; 
  mov     ebx, eax
  add     ebx, 4                ; eax = i, ebx = i + 1
mulCarryCheck:
  cmp     Dword[eax], 10        ; if c[i] < 10
  jb      mulDoCarry
  cmp     ebx, Dword[cEnd]      ; if i < cLen
  jb      mulDoCarry               ;
                                ; if c[i] >= 10 && i >= cLen(ebx >= cEnd)
  mov     ecx, Dword[cLen]      ; lengthen c
  add     ecx, 4                ; 
  mov     Dword[cLen], ecx      ; cLen += 1
  mov     ecx, Dword[cEnd]
  add     ecx, 4
  mov     Dword[cEnd], ecx      ; cEnd += 4
  mov     ecx, cEnd
  sub     ecx, 4                
  mov     Dword[ecx], 0         ; c[cLen - 1] = 0
mulDoCarry:
  cmp     Dword[eax], 10        ; if c[i] < 10
  jb      mulDoCarryEnd
  mov     ecx, Dword[eax]
  sub     ecx, 10
  mov     Dword[eax], ecx       ; c[i] -= 10
  mov     ecx, Dword[ebx]
  add     ecx, 1
  mov     Dword[ebx], ecx       ; c[i + 1]++
  jmp     mulDoCarry
mulDoCarryEnd:
  add     eax, 4                ; i++
  jmp     mulCarryLoop
mulCarryEnd:
  ; mov     eax, c              ; to debug

  mov     eax, c
  add     eax, Dword[cLen]       
  sub     eax, 4                ; eax = c[rbegin()]
eraseLoop:
  cmp     eax, c
  je      eraseEnd
  cmp     Dword[eax], 0         ; if c[cLen] != 0
  jne     eraseEnd
  sub     eax, 4
  jmp     eraseLoop
eraseEnd:
  sub     eax, c
  add     eax, 4
  mov     Dword[cLen], eax      ; cLen = eax + 4
  popa
  ret

;; Function
genOutStr:
;; TODO: test genOutStr()
  pusha
  mov     eax, c
  add     eax, Dword[cLen]
  mov     Dword[cEnd], eax      ; cEnd = c + cLen
  mov     eax, outStr
  mov     ebx, c
  add     ebx, Dword[cLen]
  sub     ebx, 4
genOutStrLoop:
  cmp     ebx, c                ; if i < 0
  jb      genOutStrEnd          ; goto genOutStrEnd
  mov     ecx, Dword[ebx]       ; ecx = c[i]
  add     ecx, 48               ; ecx += '0'
  mov     Byte[eax], cl         ; outStr[i] = (lower 8 bits of) eax
  add     eax, 1
  sub     ebx, 4                ; i = i - 1
  jmp     genOutStrLoop
genOutStrEnd:
  mov     Byte[eax], 0Ah        ; outStr[len] = '\n'
  add     eax, 1
  mov     Byte[eax], 0          ; outStr[len + 1] = '\0'
  popa
  ret


;; Function
;; write(eax) to stdout -> none
;; write a single char into stdout
write:
  pusha
  mov     ecx, eax
  mov     eax, 4
  mov     ebx, 1
  mov     edx, 1
  int     80h
  popa
  ret

;; Function
;; print(eax) to stdout -> none
;; print a string ending with '\0' 10h or '\n' 0ah
print:
  pusha 
printLoop:
  cmp     Byte[eax], 00h
  jz      printLoopEnd
  call    write
  add     eax, 1
  jmp     printLoop
printLoopEnd:
  popa
  ret

;; Function
;; read(inStr) from stdin -> eax
read:
  pusha
  mov     eax, 3
  mov     ebx, 0
  mov     ecx, inStr
  mov     edx, 100
  int     80h

  mov     Dword[tmp], eax
  mov     Dword[isLen], eax
  mov     Byte[inStr + eax], 00h
  popa
  mov     eax, Dword[tmp]
  ret