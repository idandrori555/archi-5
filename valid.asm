org 100h

jmp start
  
P equ 7
Q equ 2

totient dw 0x0
pub_key dw 0x5

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
; returns a % b in ax
PROC modulus
    push bp
    mov bp, sp
    
    mov bx, [bp + 6] ; num 1
    xor ax, ax
    cmp bx, 0 ; can't divide by 0
    je modulus_end
    
    mov ax, [bp + 4] ; num 2
    
modulus_loop:     
    cmp ax, bx
    jb modulus_end
    
    sub ax, bx
    jmp modulus_loop  
    
modulus_end:
    pop bp
    ret 4
ENDP modulus

; stdcall
; checks if a number is prime
; returns 1 if it is, else 0
PROC is_prime
    push bp
    mov bp, sp
    
    mov cx, [bp + 4]

    xor ax, ax ; start off not prime
    cmp cx, 1 ; base case not prime
    jle is_prime_end
    
    mov ax, 1 ; default: number is prime  
    cmp cx, 2 ; input = 2 (prime)
    je is_prime_end
    
    mov bx, 2 ; start from 2

is_prime_loop:
    cmp bx, cx
    jae is_prime_end 
    
    push ax
    push bx
    
    push bx
    push cx 
    call modulus
    
    cmp ax, 0
    
    pop bx
    pop ax
    
    je not_prime
    
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
; vali d:
; * number < totient
; * prime number
; * totient % pkey != 0
PROC is_valid_pub_key
    push bp
    mov bp, sp
    
    mov bx, [bp + 4]  ; pubkey
    xor ax, ax ; default invalid
    
    cmp bx, 1
    jbe is_valid_pub_key_end
    
    ; check bx < totient
    cmp bx, [totient]
    jae is_valid_pub_key_end
    
    push bx
    
    push bx
    push [totient]
    call modulus
    
    cmp ax, 0
    pop bx
    je is_valid_pub_key_end
    
    ; check is prime
    push bx
    
    push bx
    call is_prime
    
    cmp ax, 0
    pop bx
    je is_valid_pub_key_end

    mov ax, 0x1 ; valid

is_valid_pub_key_end:
    pop bp
    ret 2
ENDP is_valid_pub_key

; stdcall
; finds private key
; returns the private key if found, 0 if not found.
PROC calc_private_key
    push bp
    mov bp, sp
    
    mov bx, [bp + 4] ; pubkey
    mov cx, [totient]
    dec cx ; start from totient-1

    xor ax, ax
    cmp cx, 0
    jle calc_private_key_end
    
calc_private_key_loop:
    mov ax, cx
    mul bx
    
    push bx
    push cx
    
    push [totient]
    push ax
    call modulus
    
    cmp ax, 1
    
    pop cx
    pop bx
    
    je valid_private_key_found
    
    loop calc_private_key_loop
    
    ; not found
    xor ax, ax
    jmp calc_private_key_end
                    
valid_private_key_found:
    mov ax, cx
    
calc_private_key_end:    
    pop bp
    ret 2
ENDP calc_private_key

start:
    ; STEP 1 - Calc totient
    push Q
    push P
    call calc_totient
    mov word ptr [totient], ax
    
    ; STEP 2 - Check valid public key
    push [pub_key]
    call is_valid_pub_key
    
    cmp ax, 0
    je end
    
    ; STEP 3 - Calc private key
    push [pub_key]
    call calc_private_key
    
end:
    xor ah, ah
    int 16h
    ret