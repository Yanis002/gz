.section  .hdr, "a", @progbits
.set      nomips16
.set      nomicromips

.local    hdr
.type     hdr, @object
hdr:
  .long   __image_offset
  .long   __image_size
  .long   __ldr_size
  .long   __ldr_rom_lui_ori
.size     hdr, . - hdr
