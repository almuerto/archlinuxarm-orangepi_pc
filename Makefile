# User configuration
SERIAL_DEVICE = /dev/ttyUSB0
WGET = wget
MINITERM = miniterm.py
CROSS_COMPILE ?= aarch64-linux-gnu-
PYTHON ?= python2
BLOCK_DEVICE ?= /dev/null
FIND ?= find
GIT = git

UBOOT_SCRIPT = boot.scr
UBOOT_BIN = u-boot-sunxi-with-spl.bin
PLAT = sun50iw1p1
ARCH = arm64
ARCH_TARBALL = ArchLinuxARM-aarch64-latest.tar.gz
UBOOT_DIR = u-boot
MOUNT_POINT = mnt
ARM_FIRMWARE_DIR = arm-trusted-firmware
ARM_FRIMWARE_BIN = bl31.bin

ALL =  $(ARCH_TARBALL) $(UBOOT_DIR) $(ARM_FIRMWARE_DIR) $(ARM_FRIMWARE_BIN) $(UBOOT_BIN) $(UBOOT_SCRIPT) 

all: $(ALL)


$(UBOOT_DIR):
	$(GIT) clone --depth=1 git://git.denx.de/u-boot.git 
$(ARM_FIRMWARE_DIR):
	$(GIT) clone --depth=1 https://github.com/apritzel/arm-trusted-firmware.git
$(ARCH_TARBALL):
	$(WGET) http://archlinuxarm.org/os/$@


$(ARM_FRIMWARE_BIN): $(ARM_FIRMWARE_DIR)
	cd $< && $(MAKE) ARCH=$(ARCH) CROSS_COMPILE=$(CROSS_COMPILE) PLAT=$(PLAT) DEBUG=1 bl31 -j2

$(UBOOT_BIN): $(UBOOT_DIR)
	cd $< && cp ../$(ARM_FIRMWARE_DIR)/build/$(PLAT)/debug/$(ARM_FRIMWARE_BIN) . && $(MAKE) ARCH=arm CROSS_COMPILE=$(CROSS_COMPILE) orangepi_pc2_defconfig && $(MAKE) ARCH=arm CROSS_COMPILE=$(CROSS_COMPILE) PYTHON=$(PYTHON) -j2
	cp $</$@ .

# Note: non-deterministic output as the image header contains a timestamp and a
# checksum including this timestamp (2x32-bit at offset 4)
$(UBOOT_SCRIPT): boot.cmd
	mkimage -A $(ARCH) -O linux -T script -C none -n "U-Boot boot script" -d boot.cmd boot.scr

define part1
/dev/$(shell basename $(shell $(FIND) /sys/block/$(shell basename $(1))/ -maxdepth 2 -name "partition" -printf "%h"))
endef

install: $(ALL) fdisk.cmd
ifeq ($(BLOCK_DEVICE),/dev/null)
	@echo You must set BLOCK_DEVICE option
else
	sudo dd if=/dev/zero of=$(BLOCK_DEVICE) bs=1M count=8
	sudo fdisk $(BLOCK_DEVICE) < fdisk.cmd
	sync
	sudo mkfs.ext4 $(call part1,$(BLOCK_DEVICE))
	mkdir -p $(MOUNT_POINT)
	sudo umount $(MOUNT_POINT) || true
	sudo mount $(call part1,$(BLOCK_DEVICE)) $(MOUNT_POINT)
	sudo bsdtar -xpf $(ARCH_TARBALL) -C $(MOUNT_POINT)
	sudo cp $(UBOOT_SCRIPT) $(MOUNT_POINT)/boot
	sync
	sudo umount $(MOUNT_POINT) || true
	rmdir $(MOUNT_POINT) || true
	sudo dd if=$(UBOOT_BIN) of=$(BLOCK_DEVICE) bs=1024 seek=8
endif

serial:
	$(MINITERM) --raw --eol=lf $(SERIAL_DEVICE) 115200

clean:
	$(RM) -r $(ALL)
.PHONY: all serial clean install
