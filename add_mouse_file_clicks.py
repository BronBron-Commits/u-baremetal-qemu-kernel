from pathlib import Path

p = Path("kernel.asm")
s = p.read_text()

# Add a state flag so mouse clicks know when the Files window is open
if "files_window_open:" not in s:
    s = s.replace(
"""mouse_click_lock:
    db 0""",
"""mouse_click_lock:
    db 0

files_window_open:
    db 0"""
)

# When clicking FILES on desktop, mark files window open
s = s.replace(
"""    call draw_files_window
    call draw_mouse_cursor
    jmp .done""",
"""    mov byte [files_window_open], 1
    call draw_files_window
    call draw_mouse_cursor
    jmp .done"""
)

# Reset state when redrawing desktop
s = s.replace(
"""redraw_desktop:
    mov ax, 0x0013""",
"""redraw_desktop:
    mov byte [files_window_open], 0

    mov ax, 0x0013"""
)

# Insert files-window click handling near start of handle_mouse_click after lock
needle = """    mov byte [mouse_click_lock], 1

    ; FILES button:"""

replacement = """    mov byte [mouse_click_lock], 1

    cmp byte [files_window_open], 1
    jne .desktop_clicks

    call handle_files_window_click
    jmp .done

.desktop_clicks:
    ; FILES button:"""

s = s.replace(needle, replacement)

# Add handler before handle_mouse_click
insert_at = s.index("handle_mouse_click:")

handler = r"""
handle_files_window_click:
    ; file window list area:
    ; x 110-260
    cmp word [mouse_x], 110
    jb .done
    cmp word [mouse_x], 260
    ja .done

    ; README.TXT row
    cmp word [mouse_y], 70
    jb .check_notes
    cmp word [mouse_y], 86
    ja .check_notes

    mov ch, 0
    mov cl, 18
    mov dh, 0
    call gui_read_and_show_file
    mov byte [files_window_open], 1
    call draw_files_window
    jmp .done

.check_notes:
    cmp word [mouse_y], 88
    jb .check_hello
    cmp word [mouse_y], 104
    ja .check_hello

    mov ch, 0
    mov cl, 2
    mov dh, 1
    call gui_read_and_show_file
    mov byte [files_window_open], 1
    call draw_files_window
    jmp .done

.check_hello:
    cmp word [mouse_y], 106
    jb .done
    cmp word [mouse_y], 122
    ja .done

    mov ch, 0
    mov cl, 3
    mov dh, 1
    call gui_read_and_show_file
    mov byte [files_window_open], 1
    call draw_files_window

.done:
    ret

"""

s = s[:insert_at] + handler + "\n" + s[insert_at:]

p.write_text(s)
print("Added mouse clicks for files window")
