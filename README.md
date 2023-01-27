# SD Card Files to Boot seL4 on the Raspberry Pi 3 Model B+

The instructions to obtain these files can be found here: https://docs.sel4.systems/Hardware/Rpi3.html

These instructions were also used as a reference: https://summit.ivanvelickovic.com/rpi3b.html

## Explanation of required files

### `bcm2710-rpi-3-b-plus.dtb`

The Device Tree Blob (DTB) for our device was obtained from here: https://github.com/raspberrypi/firmware/blob/master/boot/bcm2710-rpi-3-b-plus.dtb

### `fixup.dat`

#### Why is `fixup.dat` required?

If `fixup.dat` isn't present, attempts to load `sel4test.bin` at `0x10000000` via UBoot will yield the following error:

```
U-Boot> fatload mmc 0 0x10000000 sel4test.bin
** Reading file would overwrite reserved memory **
```
If we try to understand why by running `bdinfo` in UBoot:

```
U-Boot> bdinfo
boot_params = 0x0000000000000100
DRAM bank   = 0x0000000000000000
-> start    = 0x0000000000000000
-> size     = 0x0000000008000000
flashstart  = 0x0000000000000000
flashsize   = 0x0000000000000000
flashoffset = 0x0000000000000000
baudrate    = 115200 bps
relocaddr   = 0x0000000007f39000
reloc off   = 0x0000000007eb9000
Build       = 64-bit
current eth = lan78xx_eth
ethaddr     = b8:27:eb:5f:e3:af
IP addr     = <NULL>
fdt_blob    = 0x0000000007fac640
new_fdt     = 0x0000000000000000
fdt_size    = 0x0000000000000000
Video       = hdmi@7e902000 active
FB base     = 0x000000000eaf0000
FB size     = 656x416x32
lmb_dump_all:
 memory.cnt  = 0x1
 memory[0]      [0x0-0x7ffffff], 0x08000000 bytes flags: 0
 reserved.cnt  = 0x2
 reserved[0]    [0x0-0xfff], 0x00001000 bytes flags: 0
 reserved[1]    [0x7b30930-0x7fdffff], 0x004af6d0 bytes flags: 0
devicetree  = embed
arch_number = 0x0000000000000000
TLB addr    = 0x0000000007fd0000
irq_sp      = 0x0000000007b34da0
sp start    = 0x0000000007b34da0
Early malloc usage: 738 / 2000
```
We can see that the `size` of the memory is being reported as `0x8000000` and the memory address range we have access to is from `0x0` to `0x7ffffff`. This explains why we weren't able to load our binary at `0x10000000`.

#### Where to obtain `fixup.dat` from?

`fixup.dat` should come from [this repo](https://github.com/raspberrypi/firmware/blob/master/boot/fixup.dat); however, I wasn't able to get that version of the file working. But an older version of `fixup.dat` in this repo works.

#### What should be observed when `fixup.dat` is included?

If `fixup.dat` is included, we get the following output when we run `bdinfo`:

```
U-Boot> bdinfo
boot_params = 0x0000000000000100
DRAM bank   = 0x0000000000000000
-> start    = 0x0000000000000000
-> size     = 0x000000003b400000
flashstart  = 0x0000000000000000
flashsize   = 0x0000000000000000
flashoffset = 0x0000000000000000
baudrate    = 115200 bps
relocaddr   = 0x000000003b359000
reloc off   = 0x000000003b2d9000
Build       = 64-bit
current eth = lan78xx_eth
ethaddr     = b8:27:eb:5f:e3:af
IP addr     = <NULL>
fdt_blob    = 0x000000003b3cc640
new_fdt     = 0x0000000000000000
fdt_size    = 0x0000000000000000
Video       = hdmi@7e902000 active
FB base     = 0x000000003eaf0000
FB size     = 656x416x32
lmb_dump_all:
 memory.cnt  = 0x1
 memory[0]      [0x0-0x3b3fffff], 0x3b400000 bytes flags: 0
 reserved.cnt  = 0x2
 reserved[0]    [0x0-0xfff], 0x00001000 bytes flags: 0
 reserved[1]    [0x3af50930-0x3b3fffff], 0x004af6d0 bytes flags: 0
devicetree  = embed
arch_number = 0x0000000000000000
TLB addr    = 0x000000003b3f0000
irq_sp      = 0x000000003af54da0
sp start    = 0x000000003af54da0
Early malloc usage: 738 / 2000
```
We see that the memory size is `0x3b400000`, which is 948 MB (about 1 GB). This means the entire 1GB of physical memory on the Raspberry Pi 3B+ is now visible to UBoot.

Now, we can successfully load and run the `sel4test.bin` binary using the following UBoot commands.

```
U-Boot> fatload mmc 0 0x10000000 sel4test.bin
4849576 bytes read in 217 ms (21.3 MiB/s)
U-Boot> go 0x10000000
## Starting application at 0x10000000 ...
```

