org 100h

jmp start
 
P equ 7
Q equ 2

totient dw 0x0 ; totient
pub_key dw 0x4

; stdcall
; calculates totient
; returns (a-1)(b-1)
PROC calc_totient
    push bp
    mov bp, sp
    
    mov ax, [bp + 4]
    dec ax ; ax - 1
    
    mov bx, [bp + 6]
    dec bx ; bx - 1
    
    mul bx ; (ax-1)(bx-1)

    pop bp
    ret 4
ENDP calc_totient

; stdcall
; does modulus on 2 numbers
; returns a % b
PROC modulus
    push bp
    mov bp, sp
    
    mov ax, [bp + 4] ; num1
    mov bx, [bp + 6] ; num2
    
modulus_loop:    
    cmp ax, bx
    jl modulus_end
    
    sub ax, bx
    jmp modulus_loop 
    
modulus_end:
    pop bp
    ret 4
ENDP modulus

; stdcall
; checks if a number is prime
; returns 1 if it is, 0 if it isn't
PROC is_prime
    push bp
    mov bp, sp
    
    mov cx, [bp + 4]

    xor ax, ax ; start off not prime
    cmp cx, 1 ; base case, input = 1 (not prime)
    jle is_prime_end
    
    cmp cx, 2 ; base case, input = 2 (prime)
    mov ax, 1 ; default: number is prime
    je is_prime_end
    
    mov bx, 2 ; start from 2

is_prime_loop:
    cmp bx, cx
    jge is_prime_end
    
    push ax
    push bx
    
    push bx
    push cx
    call modulus
    
    cmp ax, 0
    
    pop bx
    pop ax
    
    je not_prime ; if a number divides cx, its not prime
    
    inc bx
    jmp is_prime_loop

not_prime:
    xor ax, ax    
is_prime_end:
    pop bp
    ret 2
ENDP is_prime

; stdcall
; checks if the number is a valid public key
; valid means: 
; * prime number
; * less then the totient
; * totient % pkey != 0 
PROC is_valid_pub_key
    push bp
    mov bp, sp
    
    mov bx, [bp + 4]
    xor ax, ax ; assume key is default invalid
    
    ; check bx <= totient (valid)
    cmp bx, [totient]
    jge is_valid_pub_key_end
    
    push ax
    push bx
    
    ; check key % totient != 0 (valid)
    push [totient]
    push bx
    call modulus
    
    cmp ax, 0
    pop bx
    pop ax
    je is_valid_pub_key_end
    
    ; check key is prime
    push ax
    push bx
    
    push bx
    call is_prime
    
    cmp ax, 0
    pop bx
    pop ax
    je is_valid_pub_key_end

    mov ax, 0x1 ; passed all checks (key is validd)

    is_valid_pub_key_end:
    pop bp
    ret 2
ENDP is_valid_pub_key
    

start:
    ; STEP 1 - Calc totient
    push Q
    push P
    call calc_totient
    mov word ptr [totient], ax
    
    
    ; STEP 2 - Check valid public key
    push [pub_key]
    call is_valid_pub_key
    
    cmp ax, 0; check if the public key is invalid
    je end 

end:
    xor ah, ah
    int 16h
    ret