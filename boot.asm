[org 0x7C00]
[bits 16]

start:
    cli
    xor ax, ax
    mov ds, ax
    mov es, ax
    mov ss, ax
    mov sp, 0x7C00
    sti

    mov [boot_drive], dl

    mov si, boot_msg
    call print_string

    ; Load kernel from floppy:
    ; sector 2 onward into 0000:1000
    mov ah, 0x02
    mov al, 16
    mov ch, 0
    mov cl, 2
    mov dh, 0
    mov dl, [boot_drive]
    mov bx, 0x1000
    int 0x13

    jc disk_error

    jmp 0x0000:0x1000

disk_error:
    mov si, disk_msg
    call print_string
    jmp $

print_string:
    mov ah, 0x0E

.next:
    lodsb
    cmp al, 0
    je .done
    int 0x10
    jmp .next

.done:
    ret

boot_msg:
    db "BOOT OK", 13, 10, 0

disk_msg:
    db "DISK ERROR", 13, 10, 0

boot_drive:
    db 0

times 510 - ($ - $$) db 0
dw 0xAA55
