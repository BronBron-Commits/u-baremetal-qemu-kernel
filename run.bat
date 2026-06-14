@echo off

"C:\Program Files\qemu\qemu-system-i386.exe" -drive format=raw,file=os.img,index=0,if=floppy -boot a
