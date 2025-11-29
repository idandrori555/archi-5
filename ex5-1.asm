org 100h

jmp start

PROC mystery
push bp
mov bp, sp
mov ax, [bp+6]
imul ax
mov dx, ax
mov ax, [bp+4]
shl ax, 2
imul [bp+8]
sub dx, ax
mov ax, dx
pop bp
ret
ENDP mystery

start:
push 3 ; c
push 3 ; b
push 1 ; a

; stdcall
call mystery
add sp, 6

end:
xor ah, ah
int 16h
ret
