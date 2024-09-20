#!/bin/sh
qemu-system-aarch64 -machine virt -cpu cortex-a76 -nographic \
-device loader,file=zig-out/bin/kernel.bin,addr=0x40100000 \
-device loader,addr=0x40100000,cpu-num=0 $@