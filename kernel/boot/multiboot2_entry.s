; kernel/boot/multiboot2_entry.s

bits 32

MULTIBOOT2_MAGIC    equ 0xE85250D6
MULTIBOOT2_ARCH     equ 0
HEADER_LENGTH       equ (mb2_header_end - mb2_header_start)
HEADER_CHECKSUM     equ -(MULTIBOOT2_MAGIC + MULTIBOOT2_ARCH + HEADER_LENGTH)

MULTIBOOT1_MAGIC    equ 0x1BADB002
MULTIBOOT1_FLAGS    equ 0x3
MULTIBOOT1_CHECKSUM equ -(MULTIBOOT1_MAGIC + MULTIBOOT1_FLAGS)

; ── Multiboot1 header (v86 / legacy bootloaders) ─────────────────────────
section .multiboot1_header
align 4
    dd MULTIBOOT1_MAGIC
    dd MULTIBOOT1_FLAGS
    dd MULTIBOOT1_CHECKSUM

; ── Multiboot2 header (GRUB on real hardware / QEMU) ─────────────────────
section .multiboot2_header
align 8
mb2_header_start:
    dd MULTIBOOT2_MAGIC
    dd MULTIBOOT2_ARCH
    dd HEADER_LENGTH
    dd HEADER_CHECKSUM
align 8
    dw 0
    dw 0
    dd 8
mb2_header_end:

section .data
align 8
gdt_start:
    dq 0
    dw 0xFFFF
    dw 0x0000
    db 0x00
    db 10011010b
    db 11001111b
    db 0x00
    dw 0xFFFF
    dw 0x0000
    db 0x00
    db 10010010b
    db 11001111b
    db 0x00
gdt_end:

gdt_descriptor:
    dw gdt_end - gdt_start - 1
    dd gdt_start

section .bss
align 16
kernel_stack_bottom:
    resb 16384
kernel_stack_top:

section .text.multiboot2_entry
global multiboot2_entry
extern multiboot2_main

multiboot2_entry:
    ; Save magic and MBI pointer FIRST before anything clobbers them
    mov edi, eax        ; edi = magic  (0x36D76289 = MB2, 0x2BADB002 = MB1)
    mov esi, ebx        ; esi = mbi_addr

    ; Install our GDT
    lgdt [gdt_descriptor]

    mov ax, 0x10
    mov ds, ax
    mov es, ax
    mov fs, ax
    mov gs, ax
    mov ss, ax

    jmp 0x08:.reload_cs
.reload_cs:

    mov esp, kernel_stack_top

    push 0
    popfd

    ; Pass both values to C — multiboot2_main now handles both magic values
    push esi            ; mbi_addr
    push edi            ; magic
    call multiboot2_main

.hang:
    cli
    hlt
    jmp .hang