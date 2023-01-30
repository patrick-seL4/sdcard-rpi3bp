
.PHONY: clean
clean:
	rm -rf build/

.PHONY: directories
directories:
	mkdir -p build/

# ===============================
# Common Build steps.
# ===============================

.PHONY: build-bootscript
build-bootscript: directories
	mkimage \
		-A arm \
		-T script \
		-d scripts/$(BOOTSCRIPT) \
		build/boot.scr

.PHONY: build-common
build-common: clean \
	directories
	cp bootcode.bin build/
	cp start.elf build/
	cp u-boot.bin build/
	cp config.txt build/
	cp bcm2710-rpi-3-b-plus.dtb build/
	cp fixup.dat build/

# ===============================
# Commands for specific boot modes (SD boot or TFTP boot) and files.
# ===============================

# Boots from SD card and immediately runs sel4test.
.PHONY: build-sdboot-sel4test
build-sdboot-sel4test: build-common
	$(MAKE) build-bootscript \
		BOOTSCRIPT="sdboot-sel4test.script"

# Boots from home TFTP server and immediately runs /tftboot/rpi3bp/image.bin on
# home server.
.PHONY: build-tftpboot-home
build-tftpboot-home: build-common
	# $(MAKE) build-bootscript \
	# 	BOOTSCRIPT="tftpboot-home.script"
	cp -v ubootenv/tftpboot-home.env build/uboot.env

# ===============================
# Flashing the SD card
# ===============================

.PHONY: ls-sdcard
ls-sdcard:
	@echo "===> Listing files on SD card at $(SDCARD_PATH)"
	ls -la $(SDCARD_PATH)

.PHONY: flash-common
flash-common:
# Don't flash if the SD card does not exist.
ifeq ("$(wildcard $(SDCARD_PATH))","")
	@echo "The SD card does not exist."
else
	# Clear out everything on the SD card.
	rm -vrf $(SDCARD_PATH)/*
	# Copy everything from build onto SD card.
	cp -vR build/* $(SDCARD_PATH)
endif

# E.g. $ make flash-sdboot-sel4test SDCARD_PATH="/Volumes/SDCARD/"
.PHONY: flash-sdboot-sel4test
flash-sdboot-sel4test: \
	build-sdboot-sel4test \
	flash-common
	# Copy an sel4test image onto SD card.
	cp -v images/sel4test-driver-image-arm-bcm2837 $(SDCARD_PATH)/sel4test.bin
	@echo "===> Finished flashing SD card at $(SDCARD_PATH) to SD boot sel4test."
	$(MAKE) ls-sdcard

# E.g. $ make flash-tftpboot-home SDCARD_PATH="/Volumes/SDCARD/"
.PHONY: flash-tftpboot-home
flash-tftpboot-home: \
	build-tftpboot-home \
	flash-common
	@echo "===> Finished flashing SD card at $(SDCARD_PATH) for TFTP boot at home."
	$(MAKE) ls-sdcard
