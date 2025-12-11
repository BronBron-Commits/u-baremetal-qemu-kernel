[org 0x7C00]

    cli
    xor ax, ax
    mov ds, ax
    mov es, ax
    mov ss, ax
    mov sp, 0x7C00
    sti

    mov si, msg
.print:
    lodsb
    or al, al
    jz .load
    mov ah, 0x0E
    int 0x10
    jmp .print

.load:
    mov ax, 0x0000       ; ES:BX -> buffer for loaded sector
    mov es, ax
    mov bx, 0x1000
    mov ah, 0x02          ; BIOS read sector
    mov al, 1             ; read 1 sector
    mov ch, 0             ; cylinder
    mov cl, 2             ; sector number (start from 2)
    mov dh, 0             ; head
    mov dl, [BOOT_DRIVE]  ; BIOS drive number
    int 0x13
    jc disk_error

    jmp 0x0000:0x1000

disk_error:
    mov si, err
    call print_str
    jmp $

print_str:
.next:
    lodsb
    or al, al
    jz .ret
    mov ah, 0x0E
    int 0x10
    jmp .next
.ret:
    ret

msg db 'BOOT OK',0
err db 'DISK ERROR',0

BOOT_DRIVE db 0
times 510 - ($ - $$) db 0
dw 0xAA55
