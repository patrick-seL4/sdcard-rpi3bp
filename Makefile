
BUILD_DIR = build

.PHONY: clean
clean:
	rm -rf $(BUILD_DIR)/

.PHONY: directories
directories:
	mkdir -p $(BUILD_DIR)/

# ===============================
# Common Build steps.
# ===============================

.PHONY: build-bootscript
build-bootscript: directories
	mkimage \
		-A arm \
		-T script \
		-d scripts/$(BOOTSCRIPT) \
		$(BUILD_DIR)/boot.scr

# To understand what all the arguments of the dtc command mean run:
# $ dtc -h
.PHONY: build-sdhci-overlay
build-sdhci-overlay: directories
	dtc \
		-@ \
		-I dts \
		-O dtb \
		-o $(BUILD_DIR)/sdhci_overlay.dtbo \
		sdhci_overlay.dts

.PHONY: build-common
build-common: \
	clean \
	directories \
	build-sdhci-overlay
	cp bootcode.bin $(BUILD_DIR)/
	cp start.elf $(BUILD_DIR)/
	cp u-boot.bin $(BUILD_DIR)/
	cp config.txt $(BUILD_DIR)/
	cp bcm2710-rpi-3-b-plus.dtb $(BUILD_DIR)/
	cp fixup.dat $(BUILD_DIR)/
	cp -R overlays $(BUILD_DIR)/

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
	$(MAKE) build-bootscript \
		BOOTSCRIPT="tftpboot-home.script"
	# cp -v ubootenv/tftpboot-home.env $(BUILD_DIR)/uboot.env

# Boots from my desk's TS TFTP server.
.PHONY: build-tftpboot-tsdesk
build-tftpboot-tsdesk: build-common
	$(MAKE) build-bootscript \
		BOOTSCRIPT="tftpboot-tsdesk.script"

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

# E.g. $ make flash-tftpboot-tsdesk SDCARD_PATH="/Volumes/SDCARD/"
.PHONY: flash-tftpboot-tsdesk
flash-tftpboot-tsdesk: \
	build-tftpboot-tsdesk \
	flash-common
	@echo "===> Finished flashing SD card at $(SDCARD_PATH) for TFTP boot at TS on my desk."
	$(MAKE) ls-sdcard

