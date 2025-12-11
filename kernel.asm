[org 0x1000]

; set video mode 80x25 text
mov ah, 0x00
mov al, 0x03
int 0x10

; print 'K' on page 0
mov ah, 0x0E
mov al, 'K'
int 0x10

; wait for keypress
mov ah, 0x00
int 0x16

; switch to page 1
mov ah, 0x05
mov al, 1
int 0x10

; clear new page
mov ah, 0x06
xor al, al
xor cx, cx
mov dx, 0x184F
mov bh, 0x07
int 0x10

; print message on page 1
mov si, msg
call print_string

; hang
hlt

print_string:
    mov ah, 0x0E
.next:
    lodsb
    or al, al
    jz .done
    int 0x10
    jmp .next
.done:
    ret

msg db "Welcome to the second window!",0
