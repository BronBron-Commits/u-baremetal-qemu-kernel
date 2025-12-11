# u-baremetal-qemu-kernel

A minimal 16-bit real-mode “bare metal” bootloader and kernel demo, tested under **QEMU**.  
This project demonstrates how to hand-assemble a BIOS-bootable disk image that loads a second sector and executes it successfully.

---

## Overview

- **boot.asm** — A real-mode bootloader assembled for `0x7C00`.  
  Prints “BOOT OK” using BIOS `int 0x10`, loads the next sector with `int 0x13`, and jumps to it at `0x1000`.

- **kernel.asm** — A minimal kernel that prints the character `K` using BIOS video interrupt and halts.

- **os.img** — A 1.44 MB floppy image combining both binaries with the `0xAA55` boot signature.

---

## Build

nasm -f bin boot.asm -o boot.bin
nasm -f bin kernel.asm -o kernel.bin
cat boot.bin kernel.bin > os.img
truncate -s 1474560 os.img

---

## Run

qemu-system-i386 -drive format=raw,file=os.img,index=0,if=floppy -boot a -serial stdio

Expected output:

BOOT OKK

The first “BOOT OK” is from the bootloader.  
The final “K” confirms that the kernel sector loaded and executed correctly.

---

## License

MIT License © 2025 BronBron-Commits
