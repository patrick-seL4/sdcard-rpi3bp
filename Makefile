
.PHONY: clean
clean:
	rm -rf build/

.PHONY: directories
directories:
	mkdir -p build/

.PHONY: build-bootscript
build-bootscript: directories
	mkimage \
		-A arm \
		-T script \
		-d scripts/$(BOOT_SCRIPT) \
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

.PHONY: build-sdboot-sel4test
build-sdboot-sel4test: build-common
	$(MAKE) build-bootscript \
		BOOT_SCRIPT="sdboot-sel4test.script"

.PHONY: flash-common
flash-common:
# Only build the Core Platform if the SDK doesn't exist already.
ifeq ("$(wildcard $(SDCARD_PATH))","")
	@echo "The SD card does not exist."
else
	# Clear out everything on the SD card.
	rm -vrf $(SDCARD_PATH)/*
	# Copy everything from build onto SD card.
	cp -vR build/* $(SDCARD_PATH)
	# Copy an sel4test image onto SD card.
	cp -v images/sel4test-driver-image-arm-bcm2837 $(SDCARD_PATH)/sel4test.bin
	@echo "===> Finished flashing SD card at $(SDCARD_PATH)"
	@echo "===> Listing files on SD card at $(SDCARD_PATH)"
	ls -la $(SDCARD_PATH)
endif

.PHONY: flash-sdboot-sel4test
flash-sdboot-sel4test: \
	build-sdboot-sel4test \
	flash-common
