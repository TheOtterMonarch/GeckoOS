/*
 * linker.ld — GeckoOS kernel linker script
 *
 * Kernel is loaded at physical address 1 MB (0x100000), matching the
 * original layout.  Both Multiboot headers are forced to the very
 * beginning of the image so GRUB can locate them within the first 32 KB.
 *
 * Original author: Ember2819
 * Multiboot2 section added as part of the GRUB migration (Phase 2 roadmap).
 * Multiboot1 section added for v86 browser emulator compatibility.
 */

ENTRY(multiboot2_entry)

SECTIONS
{
    . = 0x100000;

    .multiboot1_header : {
        KEEP(*(.multiboot1_header))
    }

    .multiboot2_header : {
        KEEP(*(.multiboot2_header))
    }

    /* Entry stubs and existing kernel entry come next. */
    .text : {
        *(.text.multiboot2_entry)
        *(.text.entry)
        *(.text)
    }

    .rodata : { *(.rodata) }
    .data   : { *(.data)   }

    .bss : {
        *(.bss)
        *(COMMON)
    }
}