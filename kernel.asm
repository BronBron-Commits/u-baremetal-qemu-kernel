[org 0x1000]
[bits 16]

start:
    cli
    xor ax, ax
    mov ds, ax
    mov es, ax
    mov ss, ax
    mov sp, 0x9000
    cld
    sti

    mov si, welcome
    call print_string

main_loop:
    mov si, prompt
    call print_string

    call clear_buffer

    mov di, buffer
    call read_line

    mov si, buffer
    mov di, cmd_help
    call strcmp
    cmp ax, 1
    je command_help

    mov si, buffer
    mov di, cmd_cat
    call strcmp
    cmp ax, 1
    je command_cat_usage

    mov si, buffer
    mov di, cmd_cat_arg
    call starts_with
    cmp ax, 1
    je command_cat

    mov si, buffer
    mov di, cmd_ls
    call strcmp
    cmp ax, 1
    je command_ls

    mov si, buffer
    mov di, cmd_pwd
    call strcmp
    cmp ax, 1
    je command_pwd

    mov si, buffer
    mov di, cmd_ftable
    call strcmp
    cmp ax, 1
    je command_ftable

    mov si, buffer
    mov di, cmd_sector
    call strcmp
    cmp ax, 1
    je command_sector

    mov si, buffer
    mov di, cmd_about
    call strcmp
    cmp ax, 1
    je command_about

    mov si, buffer
    mov di, cmd_cls
    call strcmp
    cmp ax, 1
    je command_clear

    mov si, buffer
    mov di, cmd_clear
    call strcmp
    cmp ax, 1
    je command_clear

    mov si, buffer
    mov di, cmd_reboot
    call strcmp
    cmp ax, 1
    je command_reboot

    mov si, buffer
    mov di, cmd_mem
    call strcmp
    cmp ax, 1
    je command_mem

    mov si, buffer
    mov di, cmd_time
    call strcmp
    cmp ax, 1
    je command_time

    mov si, buffer
    mov di, cmd_date
    call strcmp
    cmp ax, 1
    je command_date

    mov si, buffer
    mov di, cmd_echo
    call starts_with
    cmp ax, 1
    je command_echo

    mov si, unknown
    call print_string
    jmp main_loop

command_help:
    mov si, help_text
    call print_string
    jmp main_loop

command_cat_usage:
    mov si, cat_usage
    call print_string
    jmp main_loop

command_cat:
    mov si, cat_lookup
    call print_string

    ; Load file table from disk: head 1, sector 4
    mov ah, 0x02
    mov al, 1
    mov ch, 0
    mov cl, 4
    mov dh, 1
    mov dl, 0
    mov bx, sector_buffer
    int 0x13

    jc cat_fail

    mov si, sector_buffer

cat_search_loop:
    cmp byte [si], 0
    je cat_not_found

    mov di, buffer
    add di, 4

    call match_filename_row
    cmp ax, 1
    je cat_parse_entry

cat_skip_line:
    lodsb
    cmp al, 0
    je cat_not_found
    cmp al, 10
    jne cat_skip_line

    jmp cat_search_loop

cat_parse_entry:
    ; Move SI to comma after filename
cat_find_comma:
    lodsb
    cmp al, ','
    jne cat_find_comma

    ; Parse sector number into CL
    xor ax, ax

cat_parse_sector:
    lodsb
    cmp al, ','
    je cat_sector_done

    sub al, '0'
    mov bl, al

    mov al, ah
    mov dl, 10
    mul dl
    add al, bl
    mov ah, al

    jmp cat_parse_sector

cat_sector_done:
    mov cl, ah

    ; Parse head number into DH
    lodsb
    sub al, '0'
    mov dh, al

    mov si, cat_loading_dynamic
    call print_string

    call read_selected_file
    jmp main_loop

read_selected_file:
    mov ah, 0x02
    mov al, 1
    mov ch, 0
    mov dl, 0
    mov bx, sector_buffer
    int 0x13

    jc cat_fail

    mov si, sector_buffer
    call print_string
    ret

match_filename_row:
    push si
    push di

.match_loop:
    mov al, [si]
    mov bl, [di]

    cmp al, ','
    je .row_name_done

    cmp bl, 0
    je .no_match

    cmp al, bl
    jne .no_match

    inc si
    inc di
    jmp .match_loop

.row_name_done:
    cmp bl, 0
    jne .no_match

    pop di
    pop si
    mov ax, 1
    ret

.no_match:
    pop di
    pop si
    mov ax, 0
    ret

cat_fail:
    mov si, sector_error
    call print_string
    jmp main_loop

cat_not_found:
    mov si, file_not_found
    call print_string
    jmp main_loop

command_ls:
    mov si, ls_loading
    call print_string

    mov ah, 0x02
    mov al, 1
    mov ch, 0
    mov cl, 1
    mov dh, 1
    mov dl, 0
    mov bx, sector_buffer
    int 0x13

    jc ls_fail

    mov si, sector_buffer
    call print_string
    jmp main_loop

ls_fail:
    mov si, sector_error
    call print_string
    jmp main_loop

command_pwd:
    mov si, pwd_text
    call print_string
    jmp main_loop

command_ftable:
    mov si, ftable_loading
    call print_string

    mov ah, 0x02
    mov al, 1
    mov ch, 0
    mov cl, 4
    mov dh, 1
    mov dl, 0
    mov bx, sector_buffer
    int 0x13

    jc sector_fail

    mov si, sector_buffer
    call print_string
    jmp main_loop

command_sector:
    mov si, sector_reading
    call print_string

    mov ah, 0x02
    mov al, 1
    mov ch, 0
    mov cl, 2
    mov dh, 0
    mov dl, 0
    mov bx, sector_buffer
    int 0x13

    jc sector_fail

    mov si, sector_ok
    call print_string

    mov si, sector_buffer
    mov cx, 16
    call print_hex_bytes

    mov si, newline
    call print_string

    jmp main_loop

sector_fail:
    mov si, sector_error
    call print_string
    jmp main_loop

command_about:
    mov si, about_text
    call print_string
    jmp main_loop

command_clear:
    mov ax, 0x0003
    int 0x10
    jmp main_loop

command_reboot:
    int 0x19

command_mem:
    int 0x12
    call print_number
    mov si, mem_suffix
    call print_string
    jmp main_loop

command_time:
    mov ah, 0x02
    int 0x1A

    mov si, time_prefix
    call print_string

    mov al, ch
    call print_bcd
    mov al, ':'
    call print_char_direct

    mov al, cl
    call print_bcd
    mov al, ':'
    call print_char_direct

    mov al, dh
    call print_bcd

    mov si, newline
    call print_string
    jmp main_loop

command_date:
    mov ah, 0x04
    int 0x1A

    mov si, date_prefix
    call print_string

    mov al, ch
    call print_bcd
    mov al, cl
    call print_bcd
    mov al, '-'
    call print_char_direct

    mov al, dh
    call print_bcd
    mov al, '-'
    call print_char_direct

    mov al, dl
    call print_bcd

    mov si, newline
    call print_string
    jmp main_loop

command_echo:
    mov si, buffer
    add si, 5
    call print_string
    mov si, newline
    call print_string
    jmp main_loop

read_line:
    xor cx, cx

.read_key:
    mov ah, 0x00
    int 0x16

    cmp al, 13
    je .enter

    cmp al, 8
    je .backspace

    cmp al, 127
    je .backspace

    cmp cx, 63
    jae .read_key

    mov [di], al
    inc di
    inc cx

    mov ah, 0x0E
    int 0x10

    jmp .read_key

.backspace:
    cmp cx, 0
    je .read_key

    dec di
    dec cx
    mov byte [di], 0

    mov ah, 0x0E
    mov al, 8
    int 0x10
    mov al, ' '
    int 0x10
    mov al, 8
    int 0x10

    jmp .read_key

.enter:
    mov byte [di], 0
    mov si, newline
    call print_string
    ret

strcmp:
.compare:
    mov al, [si]
    mov bl, [di]

    cmp al, bl
    jne .no

    cmp al, 0
    je .yes

    inc si
    inc di
    jmp .compare

.yes:
    mov ax, 1
    ret

.no:
    mov ax, 0
    ret

starts_with:
.compare:
    mov bl, [di]

    cmp bl, 0
    je .yes

    mov al, [si]
    cmp al, bl
    jne .no

    inc si
    inc di
    jmp .compare

.yes:
    mov ax, 1
    ret

.no:
    mov ax, 0
    ret

clear_buffer:
    mov di, buffer
    mov cx, 64

.clear_next:
    mov byte [di], 0
    inc di
    loop .clear_next
    ret

print_char_direct:
    mov ah, 0x0E
    int 0x10
    ret

print_hex_bytes:
.next_byte:
    mov al, [si]
    call print_hex_byte

    mov al, ' '
    call print_char_direct

    inc si
    loop .next_byte
    ret

print_hex_byte:
    push ax

    shr al, 4
    call print_hex_nibble

    pop ax
    and al, 0x0F
    call print_hex_nibble

    ret

print_hex_nibble:
    cmp al, 9
    jbe .digit

    add al, 'A' - 10
    call print_char_direct
    ret

.digit:
    add al, '0'
    call print_char_direct
    ret

print_bcd:
    push ax

    shr al, 4
    add al, '0'
    call print_char_direct

    pop ax
    and al, 0x0F
    add al, '0'
    call print_char_direct

    ret

print_number:
    mov bx, 10
    xor cx, cx

.divide:
    xor dx, dx
    div bx
    push dx
    inc cx

    cmp ax, 0
    jne .divide

.print_digits:
    pop dx
    add dl, '0'
    mov al, dl
    mov ah, 0x0E
    int 0x10
    loop .print_digits

    ret

print_string:
    mov ah, 0x0E

.print_next:
    mov al, [si]
    cmp al, 0
    je .done
    int 0x10
    inc si
    jmp .print_next

.done:
    ret

welcome:
    db 13, 10
    db "u-baremetal kernel loaded", 13, 10
    db "Type 'help' for commands.", 13, 10
    db 0

prompt:
    db "> ", 0

newline:
    db 13, 10, 0

unknown:
    db "Unknown command", 13, 10, 0

help_text:
    db "Commands:", 13, 10
    db "help        - show help", 13, 10
    db "cat FILE    - print file contents", 13, 10
    db "ls          - list files", 13, 10
    db "pwd         - print current directory", 13, 10
    db "ftable      - show file table", 13, 10
    db "sector      - read raw disk sector", 13, 10
    db "echo TEXT   - print text", 13, 10
    db "mem         - show conventional memory", 13, 10
    db "time        - show BIOS time", 13, 10
    db "date        - show BIOS date", 13, 10
    db "about       - show kernel info", 13, 10
    db "cls         - clear screen", 13, 10
    db "clear       - clear screen", 13, 10
    db "reboot      - reboot machine", 13, 10
    db 0

cat_usage:
    db "Usage: cat FILE", 13, 10, 0

cat_lookup:
    db "Searching file table...", 13, 10, 0

cat_loading_dynamic:
    db "Loading file from disk...", 13, 10, 13, 10, 0

cat_loading_readme:
    db "Loading README.TXT from disk...", 13, 10, 13, 10, 0

cat_loading_notes:
    db "Loading NOTES.TXT from disk...", 13, 10, 13, 10, 0

cat_loading_hello:
    db "Loading HELLO.TXT from disk...", 13, 10, 13, 10, 0

file_not_found:
    db "File not found", 13, 10, 0

sector_reading:
    db "Reading sector 2...", 13, 10, 0

sector_ok:
    db "OK", 13, 10, 0

sector_error:
    db "Disk read failed", 13, 10, 0

ls_loading:
    db "Loading directory from disk...", 13, 10, 13, 10, 0

ftable_loading:
    db "Loading file table...",13,10,13,10,0

    db "Loading file table...",13,10,13,10,0

pwd_text:
    db "/", 13, 10, 0

cat_file:
    db "--- README.TXT ---", 13, 10
    db "Welcome to u-baremetal.", 13, 10
    db "Running from QEMU in Termux.", 13, 10
    db "This shell accepts full commands.", 13, 10
    db "------------------", 13, 10
    db 0

about_text:
    db "u-baremetal", 13, 10
    db "version 0.2", 13, 10
    db "16-bit real mode BIOS kernel", 13, 10
    db 0

cmd_help:
    db "help", 0

cmd_cat:
    db "cat", 0

cmd_cat_arg:
    db "cat ", 0

filename_readme:
    db "README.TXT", 0

filename_notes:
    db "NOTES.TXT", 0

filename_hello:
    db "HELLO.TXT", 0

cmd_ls:
    db "ls", 0

cmd_pwd:
    db "pwd", 0

cmd_ftable:
    db "ftable", 0

cmd_sector:
    db "sector", 0

cmd_about:
    db "about", 0

cmd_cls:
    db "cls", 0

cmd_clear:
    db "clear", 0

cmd_reboot:
    db "reboot", 0

cmd_mem:
    db "mem", 0

cmd_time:
    db "time", 0

cmd_date:
    db "date", 0

date_prefix:
    db "BIOS date: ", 0

time_prefix:
    db "BIOS time: ", 0

mem_suffix:
    db " KB conventional memory", 13, 10, 0

cmd_echo:
    db "echo ", 0

buffer:
    times 64 db 0

sector_buffer:
    times 512 db 0
