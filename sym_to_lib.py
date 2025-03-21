#!/usr/bin/env python3

from pathlib import Path

data = (
"""Symbol 'Sfx_PlaySfxCentered' (VRAM: 0x800646F0, VROM: 0xADA650, SIZE: 0x48, build/ntsc-1.0/src/code/z_lib.o)
Symbol 'Sfx_PlaySfxCentered' (VRAM: 0x800646F0, VROM: 0xADA650, SIZE: 0x48, build/ntsc-1.1/src/code/z_lib.o)
Symbol 'Sfx_PlaySfxCentered' (VRAM: 0x80064DB0, VROM: 0xADA6D0, SIZE: 0x48, build/ntsc-1.2/src/code/z_lib.o)
Symbol 'Sfx_PlaySfxCentered' (VRAM: 0x80064390, VROM: 0xAD94B0, SIZE: 0x48, build/gc-jp-ce/src/code/z_lib.o)
Symbol 'Sfx_PlaySfxCentered' (VRAM: 0x800643B0, VROM: 0xAD94D0, SIZE: 0x48, build/gc-jp/src/code/z_lib.o)
Symbol 'Sfx_PlaySfxCentered' (VRAM: 0x80064390, VROM: 0xAD94B0, SIZE: 0x48, build/gc-us/src/code/z_lib.o)
Symbol 'Sfx_PlaySfxCentered' (VRAM: 0x800643B0, VROM: 0xAD94D0, SIZE: 0x48, build/gc-jp-mq/src/code/z_lib.o)
Symbol 'Sfx_PlaySfxCentered' (VRAM: 0x80064390, VROM: 0xAD94B0, SIZE: 0x48, build/gc-us-mq/src/code/z_lib.o)
"""
)


def main():
    versions_map = {
        "ntsc-1.0": "liboot-1.0",
        "ntsc-1.1": "liboot-1.1",
        "ntsc-1.2": "liboot-1.2",
        "gc-jp-ce": "liboot-ce-j",
        "gc-jp": "liboot-gc-j",
        "gc-us": "liboot-gc-u",
        "gc-jp-mq": "liboot-mq-j",
        "gc-us-mq": "liboot-mq-u",
    }

    for line in data.split("\n"):
        if len(line.strip()) > 0:
            sym_name = line.split("' (")[0].removeprefix("Symbol '")
            split = line.removesuffix(")").split("(")[1].split(", ")
            vram = split[0].split(": ")[1]
            version = split[3].split("/")[1]

            with Path(f"./lib/{versions_map[version]}.a").open("a") as file:
                file.write(f"{sym_name} = {vram} ;\n")


if __name__ == "__main__":
    main()
