#!/data/data/com.termux/files/usr/bin/bash

set -e

nasm -f bin boot.asm -o boot.bin
nasm -f bin kernel.asm -o kernel.bin

cp kernel.bin kernel_padded.bin
truncate -s 8192 kernel_padded.bin

cat \
  boot.bin \
  kernel_padded.bin \
  readme_sector.bin \
  dir_sector.bin \
  notes_sector.bin \
  hello_sector.bin \
  filetable_sector.bin \
  > os.img

truncate -s 1474560 os.img

echo "Build complete"
