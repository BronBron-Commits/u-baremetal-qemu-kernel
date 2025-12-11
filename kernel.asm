; 16-bit real mode start
[org 0x1000]
[bits 16]

cli                     ; disable interrupts
mov ax, 0x0000
mov ds, ax
mov ss, ax
mov sp, 0x7C00

; load GDT
lgdt [gdt_descriptor]

; set PE bit in CR0
mov eax, cr0
or eax, 1
mov cr0, eax

; far jump to 32-bit protected mode
jmp 0x08:protected_mode_start

; -----------------------------
; GDT definition
; -----------------------------
gdt_start:
    dq 0x0000000000000000       ; null descriptor
    dq 0x00CF9A000000FFFF       ; code segment descriptor
    dq 0x00CF92000000FFFF       ; data segment descriptor
gdt_end:

gdt_descriptor:
    dw gdt_end - gdt_start - 1
    dd gdt_start

; -----------------------------
; 32-bit protected mode
; -----------------------------
[bits 32]
protected_mode_start:
    mov ax, 0x10        ; data segment selector (2nd entry)
    mov ds, ax
    mov es, ax
    mov fs, ax
    mov gs, ax
    mov ss, ax

    mov ebp, 0x90000
    mov esp, ebp

    ; write message directly to VGA memory
    mov edi, 0xB8000
    mov esi, message

.print_loop:
    lodsb
    or al, al
    jz .done
    mov ah, 0x0F         ; white text
    stosw
    jmp .print_loop
.done:
    hlt

message db "Protected mode active!",0
