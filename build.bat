@echo off

"C:\Program Files\NASM\nasm.exe" -f bin boot.asm -o boot.bin
"C:\Program Files\NASM\nasm.exe" -f bin kernel.asm -o kernel.bin

copy kernel.bin kernel_padded.bin /Y
fsutil file seteof kernel_padded.bin 8192

copy /b boot.bin+kernel_padded.bin+readme_sector.bin+dir_sector.bin+notes_sector.bin+hello_sector.bin+filetable_sector.bin os.img

echo Build complete
