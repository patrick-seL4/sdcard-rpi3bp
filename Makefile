
.PHONY: clean
clean:
	rm -rf build/

.PHONY: build
build: clean
	mkdir -p build/
	cp bootcode.bin build/
	cp start.elf build/
	cp u-boot.bin build/
	cp config.txt build/
	cp bcm2710-rpi-3-b-plus.dtb build/
	cp fixup.dat build/

.PHONY: flash
flash: build
	# Clear out everything on the SD Card.
	rm -rf $(SDCARD_PATH)/*
	# Copy everything from build onto SD Card.
	cp -vR build/* $(SDCARD_PATH)