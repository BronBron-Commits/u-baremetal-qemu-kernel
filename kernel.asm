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
    mov di, cmd_gui
    call strcmp
    cmp ax, 1
    je command_gui

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
    mov di, cmd_write_arg
    call starts_with
    cmp ax, 1
    je command_write

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

command_gui:
    call draw_gui
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

command_write:
    mov si, buffer
    add si, 6

    mov di, filename_notes
    call strcmp
    cmp ax, 1
    jne write_not_supported

    call clear_sector_buffer

    mov si, notes_written_text
    mov di, sector_buffer
    call copy_string

    mov si, write_loading
    call print_string

    mov ah, 0x03
    mov al, 1
    mov ch, 0
    mov cl, 2
    mov dh, 1
    mov dl, 0
    mov bx, sector_buffer
    int 0x13

    jc write_fail

    mov si, write_ok
    call print_string
    jmp main_loop

write_not_supported:
    mov si, write_usage
    call print_string
    jmp main_loop

write_fail:
    mov si, write_error
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

clear_sector_buffer:
    mov di, sector_buffer
    mov cx, 512

.clear_sector_next:
    mov byte [di], 0
    inc di
    loop .clear_sector_next
    ret

copy_string:
.copy_next:
    mov al, [si]
    mov [di], al
    cmp al, 0
    je .copy_done
    inc si
    inc di
    jmp .copy_next

.copy_done:
    ret



draw_gui:
    mov byte [cursor_pos], 0
    call redraw_desktop

gui_loop:
    mov ah, 0x00
    int 0x16

    cmp al, 27
    je gui_exit

    cmp ah, 0x48
    je gui_up

    cmp ah, 0x50
    je gui_down

    cmp al, 13
    je gui_enter

    jmp gui_loop

gui_up:
    cmp byte [cursor_pos], 0
    je gui_loop
    dec byte [cursor_pos]
    call redraw_desktop
    jmp gui_loop

gui_down:
    cmp byte [cursor_pos], 2
    je gui_loop
    inc byte [cursor_pos]
    call redraw_desktop
    jmp gui_loop

gui_enter:
    cmp byte [cursor_pos], 0
    je gui_open_files

    cmp byte [cursor_pos], 1
    je gui_open_shell

    cmp byte [cursor_pos], 2
    je gui_open_about

    jmp gui_loop

gui_open_files:
    call files_menu_loop
    call redraw_desktop
    jmp gui_loop

gui_open_shell:
    call draw_shell_window
    jmp gui_loop

gui_open_about:
    call draw_about_window
    jmp gui_loop

gui_exit:
    mov ax, 0x0003
    int 0x10

    mov si, gui_return
    call print_string
    ret

redraw_desktop:
    mov ax, 0x0013
    int 0x10

    mov ax, 0xA000
    mov es, ax

    xor di, di
    mov cx, 64000
    mov al, 1

.fill_bg:
    stosb
    loop .fill_bg

    ; desktop top bar
    mov ax, 0
    mov bx, 0
    mov cx, 320
    mov dx, 20
    mov si, 0
    call draw_rect

    mov ax, 0
    mov bx, 20
    mov cx, 320
    mov dx, 2
    mov si, 11
    call draw_rect

    ; left navigation rail
    mov ax, 8
    mov bx, 28
    mov cx, 78
    mov dx, 146
    mov si, 0
    call draw_rect

    mov ax, 86
    mov bx, 28
    mov cx, 1
    mov dx, 146
    mov si, 11
    call draw_rect

    ; files icon
    mov ax, 12
    mov bx, 36
    mov cx, 62
    mov dx, 18
    mov si, 1
    call draw_rect

    mov ax, 12
    mov bx, 36
    mov cx, 70
    mov dx, 2
    mov si, 11
    call draw_rect

    ; shell icon
    mov ax, 12
    mov bx, 72
    mov cx, 62
    mov dx, 18
    mov si, 1
    call draw_rect

    mov ax, 12
    mov bx, 72
    mov cx, 70
    mov dx, 2
    mov si, 13
    call draw_rect

    ; about icon
    mov ax, 12
    mov bx, 108
    mov cx, 62
    mov dx, 18
    mov si, 1
    call draw_rect

    mov ax, 12
    mov bx, 108
    mov cx, 70
    mov dx, 2
    mov si, 11
    call draw_rect

    ; desktop text
    mov ax, 12
    mov bx, 7
    mov si, gui_title
    call draw_tiny_text

    mov dh, 23
    mov dl, 2
    mov si, gui_status
    call draw_text

    mov ax, 24
    mov bx, 43
    mov si, gui_files
    call draw_tiny_text

    mov ax, 24
    mov bx, 79
    mov si, gui_shell
    call draw_tiny_text

    mov ax, 24
    mov bx, 115
    mov si, gui_about
    call draw_tiny_text

    ; bottom status bar
    mov ax, 0
    mov bx, 184
    mov cx, 320
    mov dx, 16
    mov si, 0
    call draw_rect

    mov ax, 0
    mov bx, 183
    mov cx, 320
    mov dx, 1
    mov si, 11
    call draw_rect

    call draw_cursor
    ret

draw_cursor:
    cmp byte [cursor_pos], 0
    je .cursor_files

    cmp byte [cursor_pos], 1
    je .cursor_shell

    mov bx, 108
    jmp .draw

.cursor_files:
    mov bx, 36
    jmp .draw

.cursor_shell:
    mov bx, 72

.draw:
    mov ax, 4
    mov cx, 5
    mov dx, 20
    mov si, 13
    call draw_rect
    ret

draw_files_window:
    mov ax, 95
    mov bx, 40
    mov cx, 190
    mov dx, 120
    mov si, 2
    call draw_window

    mov ax, 95
    mov bx, 40
    mov cx, 190
    mov dx, 15
    mov si, 15
    call draw_rect

    mov ax, 110
    mov bx, 70
    mov cx, 160
    mov dx, 70
    mov si, 0
    call draw_rect

    mov dh, 6
    mov dl, 14
    mov si, files_title
    call draw_text

    mov dh, 9
    mov dl, 15
    mov si, file_1
    call draw_text

    mov dh, 11
    mov dl, 15
    mov si, file_2
    call draw_text

    mov dh, 13
    mov dl, 15
    mov si, file_3
    call draw_text

    mov dh, 16
    mov dl, 15
    mov si, file_hint
    call draw_text
    ret


files_menu_loop:
    call draw_files_window

.files_key:
    mov ah, 0x00
    int 0x16

    cmp al, 27
    je .files_done

    cmp al, '1'
    je .open_readme

    cmp al, '2'
    je .open_notes

    cmp al, '3'
    je .open_hello

    jmp .files_key

.open_readme:
    mov ch, 0
    mov cl, 18
    mov dh, 0
    call gui_read_and_show_file
    call draw_files_window
    jmp .files_key

.open_notes:
    mov ch, 0
    mov cl, 2
    mov dh, 1
    call gui_read_and_show_file
    call draw_files_window
    jmp .files_key

.open_hello:
    mov ch, 0
    mov cl, 3
    mov dh, 1
    call gui_read_and_show_file
    call draw_files_window
    jmp .files_key

.files_done:
    ret

gui_read_and_show_file:
    push es

    xor ax, ax
    mov es, ax

    mov ah, 0x02
    mov al, 1
    mov dl, 0
    mov bx, sector_buffer
    int 0x13

    pop es

    jc .disk_fail

    call draw_file_viewer
    jmp .wait_close

.disk_fail:
    call draw_file_error

.wait_close:
    mov ah, 0x00
    int 0x16
    ret

draw_file_viewer:
    mov ax, 94
    mov bx, 28
    mov cx, 214
    mov dx, 150
    mov si, 7
    call draw_window

    ; title region
    mov ax, 94
    mov bx, 28
    mov cx, 214
    mov dx, 18
    mov si, 0
    call draw_rect

    mov ax, 94
    mov bx, 46
    mov cx, 214
    mov dx, 2
    mov si, 11
    call draw_rect

    ; content panel
    mov ax, 102
    mov bx, 58
    mov cx, 198
    mov dx, 106
    mov si, 0
    call draw_rect

    mov dh, 4
    mov dl, 13
    mov si, viewer_title
    call draw_text

    mov dh, 8
    mov dl, 13
    mov si, sector_buffer
    call draw_multiline_text

    ret

draw_file_error:
    mov ax, 80
    mov bx, 60
    mov cx, 180
    mov dx, 60
    mov si, 4
    call draw_rect

    mov dh, 9
    mov dl, 13
    mov si, gui_disk_error
    call draw_text
    ret


draw_shell_window:
    mov ax, 95
    mov bx, 40
    mov cx, 190
    mov dx, 120
    mov si, 8
    call draw_window

    mov ax, 95
    mov bx, 40
    mov cx, 190
    mov dx, 15
    mov si, 15
    call draw_rect

    mov ax, 110
    mov bx, 70
    mov cx, 160
    mov dx, 70
    mov si, 0
    call draw_rect

    mov dh, 6
    mov dl, 14
    mov si, shell_title
    call draw_text

    mov dh, 10
    mov dl, 15
    mov si, shell_msg
    call draw_text
    ret

draw_about_window:
    mov ax, 95
    mov bx, 40
    mov cx, 190
    mov dx, 120
    mov si, 4
    call draw_window

    mov ax, 95
    mov bx, 40
    mov cx, 190
    mov dx, 15
    mov si, 15
    call draw_rect

    mov ax, 110
    mov bx, 70
    mov cx, 160
    mov dx, 70
    mov si, 0
    call draw_rect

    mov dh, 6
    mov dl, 14
    mov si, about_title
    call draw_text

    mov dh, 10
    mov dl, 15
    mov si, about_msg
    call draw_text
    ret




draw_tiny_text:
    push ax
    push bx
    push si

    mov [tiny_x], ax
    mov [tiny_y], bx
    mov [tiny_str], si

.tiny_next:
    mov si, [tiny_str]
    mov al, [si]
    cmp al, 0
    je .tiny_done

    inc si
    mov [tiny_str], si

    cmp al, ' '
    je .tiny_space

    cmp al, 'a'
    jb .not_lower
    cmp al, 'z'
    ja .not_lower
    sub al, 32

.not_lower:
    call draw_tiny_char
    add word [tiny_x], 8
    jmp .tiny_next

.tiny_space:
    add word [tiny_x], 5
    jmp .tiny_next

.tiny_done:
    pop si
    pop bx
    pop ax
    ret

draw_tiny_char:
    push ax
    push bx
    push cx
    push dx
    push si

    cmp al, '-'
    je .dash
    cmp al, '.'
    je .dot
    cmp al, '/'
    je .slash

    cmp al, '0'
    jb .letter_check
    cmp al, '9'
    ja .letter_check

    sub al, '0'
    xor ah, ah
    mov bx, 5
    mul bx
    mov si, font_digits
    add si, ax
    jmp .draw_glyph

.letter_check:
    cmp al, 'A'
    jb .done
    cmp al, 'Z'
    ja .done

    sub al, 'A'
    xor ah, ah
    mov bx, 5
    mul bx
    mov si, font_letters
    add si, ax
    jmp .draw_glyph

.dash:
    mov si, font_dash
    jmp .draw_glyph

.dot:
    mov si, font_dot
    jmp .draw_glyph

.slash:
    mov si, font_slash

.draw_glyph:
    mov byte [tiny_row], 0

.row_loop:
    cmp byte [tiny_row], 5
    jae .done

    mov bl, [si]
    inc si

    mov byte [tiny_col], 0

.col_loop:
    cmp byte [tiny_col], 3
    jae .next_row

    mov al, bl
    mov cl, 2
    sub cl, [tiny_col]
    shr al, cl
    and al, 1

    cmp al, 0
    je .skip_pixel

    push si
    push bx

    mov ax, [tiny_x]
    mov bl, [tiny_col]
    xor bh, bh
    shl bx, 1
    add ax, bx

    mov bx, [tiny_y]
    mov cl, [tiny_row]
    xor ch, ch
    shl cx, 1
    add bx, cx

    mov cx, 2
    mov dx, 2
    mov si, 11
    call draw_rect

    pop bx
    pop si

.skip_pixel:
    inc byte [tiny_col]
    jmp .col_loop

.next_row:
    inc byte [tiny_row]
    jmp .row_loop

.done:
    pop si
    pop dx
    pop cx
    pop bx
    pop ax
    ret

draw_multiline_text:
    push ax
    push bx
    push dx
    push si

    mov byte [text_row], dh
    mov byte [text_col], dl

.set_cursor:
    mov ah, 0x02
    mov bh, 0
    mov dh, [text_row]
    mov dl, [text_col]
    int 0x10

.next_char:
    mov al, [si]
    cmp al, 0
    je .done

    cmp al, 13
    je .skip_char

    cmp al, 10
    je .newline

    cmp byte [text_col], 37
    jae .wrap_line

    mov ah, 0x02
    mov bh, 0
    mov dh, [text_row]
    mov dl, [text_col]
    int 0x10

    mov al, [si]
    mov ah, 0x0E
    mov bh, 0
    mov bl, 15
    int 0x10

    inc byte [text_col]
    inc si
    jmp .next_char

.skip_char:
    inc si
    jmp .next_char

.wrap_line:
    inc byte [text_row]
    mov byte [text_col], 13

    cmp byte [text_row], 19
    jae .done

    jmp .set_cursor

.newline:
    inc byte [text_row]
    mov byte [text_col], 13
    inc si

    cmp byte [text_row], 19
    jae .done

    jmp .set_cursor

.done:
    pop si
    pop dx
    pop bx
    pop ax
    ret

draw_text:
    push ax
    push bx
    push cx
    push dx
    push si

    mov ah, 0x02
    mov bh, 0
    int 0x10

.draw_text_next:
    mov al, [si]
    cmp al, 0
    je .draw_text_done

    mov ah, 0x0E
    mov bh, 0
    mov bl, 15
    int 0x10

    inc si
    jmp .draw_text_next

.draw_text_done:
    pop si
    pop dx
    pop cx
    pop bx
    pop ax
    ret


draw_window:
    ; AX=x BX=y CX=w DX=h SI ignored
    push ax
    push bx
    push cx
    push dx

    ; soft shadow
    add ax, 2
    add bx, 2
    mov si, 0
    call draw_rect

    pop dx
    pop cx
    pop bx
    pop ax

    push ax
    push bx
    push cx
    push dx

    ; body
    mov si, 1
    call draw_rect

    ; top accent
    mov dx, 2
    mov si, 11
    call draw_rect

    pop dx
    pop cx
    pop bx
    pop ax

    push ax
    push bx
    push cx
    push dx

    ; bottom subtle edge
    add bx, dx
    sub bx, 1
    mov dx, 1
    mov si, 8
    call draw_rect

    pop dx
    pop cx
    pop bx
    pop ax

    ret

; draw_rect
; AX = x
; BX = y
; CX = width
; DX = height
; SI = color
draw_rect:
    push ax
    push bx
    push cx
    push dx
    push si

    mov [rect_x], ax
    mov [rect_y], bx
    mov [rect_w], cx
    mov [rect_h], dx
    mov [rect_color], si

    xor bp, bp

.row_loop:
    mov ax, [rect_y]
    add ax, bp

    mov bx, 320
    mul bx

    add ax, [rect_x]
    mov di, ax

    mov cx, [rect_w]
    mov ax, [rect_color]

.pixel_loop:
    mov [es:di], al
    inc di
    loop .pixel_loop

    inc bp
    cmp bp, [rect_h]
    jl .row_loop

    pop si
    pop dx
    pop cx
    pop bx
    pop ax
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
    db "gui         - launch graphics demo", 13, 10
    db "ftable      - show file table", 13, 10
    db "sector      - read raw disk sector", 13, 10
    db "echo TEXT   - print text", 13, 10
    db "write FILE  - overwrite NOTES.TXT", 13, 10
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

write_loading:
    db "Writing NOTES.TXT to disk...", 13, 10, 0

write_ok:
    db "Write complete", 13, 10, 0

write_error:
    db "Disk write failed", 13, 10, 0

write_usage:
    db "Usage: write NOTES.TXT", 13, 10, 0

notes_written_text:
    db "--- NOTES.TXT ---", 13, 10
    db "This file was overwritten by the kernel.", 13, 10
    db "BIOS disk writes are working.", 13, 10
    db "-----------------", 13, 10
    db 0

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


tiny_x:
    dw 0
tiny_y:
    dw 0
tiny_str:
    dw 0
tiny_row:
    db 0
tiny_col:
    db 0

font_dash:
    db 0,0,7,0,0

font_dot:
    db 0,0,0,0,2

font_slash:
    db 1,1,2,4,4

font_digits:
    db 7,5,5,5,7
    db 2,6,2,2,7
    db 7,1,7,4,7
    db 7,1,7,1,7
    db 5,5,7,1,1
    db 7,4,7,1,7
    db 7,4,7,5,7
    db 7,1,1,1,1
    db 7,5,7,5,7
    db 7,5,7,1,7

font_letters:
    db 7,5,7,5,5 ; A
    db 6,5,6,5,6 ; B
    db 7,4,4,4,7 ; C
    db 6,5,5,5,6 ; D
    db 7,4,6,4,7 ; E
    db 7,4,6,4,4 ; F
    db 7,4,5,5,7 ; G
    db 5,5,7,5,5 ; H
    db 7,2,2,2,7 ; I
    db 1,1,1,5,7 ; J
    db 5,5,6,5,5 ; K
    db 4,4,4,4,7 ; L
    db 5,7,7,5,5 ; M
    db 5,7,7,7,5 ; N
    db 7,5,5,5,7 ; O
    db 7,5,7,4,4 ; P
    db 7,5,5,7,1 ; Q
    db 7,5,7,6,5 ; R
    db 7,4,7,1,7 ; S
    db 7,2,2,2,2 ; T
    db 5,5,5,5,7 ; U
    db 5,5,5,5,2 ; V
    db 5,5,7,7,5 ; W
    db 5,5,2,5,5 ; X
    db 5,5,2,2,2 ; Y
    db 7,1,2,4,7 ; Z

gui_title:
    db "u-baremetal os", 0

gui_files:
    db "files", 0

gui_shell:
    db "shell", 0

gui_about:
    db "about", 0

files_title:
    db "files", 0

file_1:
    db "1 README.TXT", 0

file_2:
    db "2 NOTES.TXT", 0

file_3:
    db "3 HELLO.TXT", 0

file_hint:
    db "1-3 OPEN  ESC BACK", 0

viewer_title:
    db "file viewer", 0

viewer_loaded:
    db "FILE LOADED", 0

viewer_test_1:
    db "Disk read succeeded.", 0

viewer_test_2:
    db "Next: render sector text.", 0

gui_disk_error:
    db "DISK ERROR", 0

shell_title:
    db "shell", 0

shell_msg:
    db "Press ESC to exit GUI", 0

about_title:
    db "about", 0

about_msg:
    db "u-baremetal v0.1", 0

gui_status:
    db "UP/DOWN navigate   ENTER open   ESC back", 0

gui_return:
    db "Returned from GUI", 13, 10, 0

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

cmd_gui:
    db "gui", 0

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

cmd_write_arg:
    db "write ", 0

cmd_echo:
    db "echo ", 0

buffer:
    times 64 db 0

sector_buffer:
    times 512 db 0

rect_x:
    dw 0
rect_y:
    dw 0
rect_w:
    dw 0
rect_h:
    dw 0
rect_color:
    dw 0

cursor_pos:
    db 0

text_row:
    db 0
text_col:
    db 0
