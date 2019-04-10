This repository can be used to create an ArchLinuxARM image for the OrangePi
PC 2 board.


Dependencies
============

- `make`
- `bsdtar` (`libarchive`)
- `python2`
- `uboot-tools`
- `sudo`
- `fdisk`


Prerequisite
============

In order to build the image, you need a working ARM toolchain.


Preparing the files
===================

Run `make` (specifying jobs with `-jX` is supported and recommended).

This will provide:

- the ArchLinuxARM aarch64 default rootfs (`ArchLinuxARM-aarch64-latest.tar.gz`)
- an u-boot image compiled for the OrangePi PC2 (`u-boot-sunxi-with-spl.bin`)
- a boot script (`boot.scr`) to be copied in `/boot`


Installing the distribution
===========================

Run `make install BLOCK_DEVICE=/dev/mmcblk0` with the appropriate value for
`BLOCK_DEVICE`.

This is running commands similar to [any other AllWinner ArchLinuxARM
installation][alarm-allwinner].

[alarm-allwinner]: https://archlinuxarm.org/platforms/armv7/allwinner/.


Goodies
=======

If you have a serial cable and `miniterm.py` installed (`python-pyserial`),
`make serial` will open a session with the appropriate settings.


