#!/usr/bin/env bash

. build_env.sh


BASE_IMAGE_FILE="$TMP_DIR/base_img.img"


SD_IMAGE_FILE="$BASE_DIR/BPI-R2_SD.img"
# special SD card images (precompiled)
SD_PRELOADER="BPI-R2-preloader-DDR1600-20191024-2k.img"
SD_PRELOADER_FILE="$BIN_DIR/$SD_PRELOADER"
SD_HEAD_1="BPI-R2-HEAD440-0k.img"
SD_HEAD_1_FILE="$BIN_DIR/$SD_HEAD_1"
SD_HEAD_2="BPI-R2-HEAD1-512b.img"
SD_HEAD_2_FILE="$BIN_DIR/$SD_HEAD_2"


MMC_IMAGE_FILE="$BASE_DIR/BPI-R2_MMC.img"
MMC_BOOT0_FILE="$BASE_DIR/BPI-R2_MMC_boot0.img"
# precompiled binaries for MMC boot
MMC_PRELOADER="BPI-R2-EMMC-boot0-DDR1600-20191024-0k.img"
MMC_PRELOADER_FILE="$BIN_DIR/$MMC_PRELOADER"


function build() {
	############
	# main image
	############
	echo "Creating main image file..."

	# create the image
	dd if=/dev/zero of="$BASE_IMAGE_FILE" bs=1k count=512k

	# load the partition tale
	sfdisk "$BASE_IMAGE_FILE" < config/base_img.parttable

	# format the partitions
	LOOP_DEV=$(sudo losetup -Pf --show "$BASE_IMAGE_FILE")
	sudo mkfs.vfat ${LOOP_DEV}p1
	sudo mkfs.ext4 ${LOOP_DEV}p2
	sudo losetup -d $LOOP_DEV


	# TODO: copy filesystem


	#########
	# SD card
	#########
	echo "Building SD card image..."

	# download precompiled binaries for SD card
	pushd bin
	for image in $SD_PRELOADER $SD_HEAD_1 $SD_HEAD_2; do
		curl -LJO https://github.com/BPI-SINOVOIP/BPI-files/raw/master/SD/100MB/${image}.gz
		gunzip -f ${image}.gz
	done
	popd

	# creating the SD image
	cp "$BASE_IMAGE_FILE" "$SD_IMAGE_FILE"
	dd if=bin/"$SD_HEAD_1_FILE" of="$SD_IMAGE_FILE" conv=notrunc bs=1k seek=0
	dd if=bin/"$SD_HEAD_2_FILE" of="$SD_IMAGE_FILE" conv=notrunc bs=512 seek=1
	dd if=bin/"$SD_PRELOADER_FILE" of="$SD_IMAGE_FILE" conv=notrunc bs=1k seek=2
	dd if="$UBOOT_BIN" of="$SD_IMAGE_FILE" conv=notrunc bs=1k seek=320


	#####
	# MMC
	#####
	echo "Building MMC image..."

	# download precompiled binary for MMC
	pushd bin
	curl -LJO https://github.com/BPI-SINOVOIP/BPI-files/raw/master/SD/100MB/${MMC_PRELOADER}.gz
	gunzip -f ${MMC_PRELOADER}.gz
	popd

	# this binary is ready to use
	# it must be flashed to the boot0 partition of the MMC
	# dd if=BPI-R2_MMC_boot0.img of=/dev/mmcblk1boot0
	cp "$MMC_PRELOADER_FILE" "$MMC_BOOT0_FILE"

	# creating the MMC image
	cp "$BASE_IMAGE_FILE" "$MMC_IMAGE_FILE"
	dd if="$UBOOT_BIN" of="$MMC_IMAGE_FILE" conv=notrunc bs=1k seek=320
}

function clean() {
	rm "$SD_IMAGE_FILE"
	rm "$SD_PRELOADER_FILE"
	rm "$SD_HEAD_1_FILE"
	rm "$SD_HEAD_2_FILE"

	rm "$MMC_IMAGE_FILE"
	rm "$MMC_BOOT0_FILE"
	rm "$MMC_PRELOADER_FILE"
}


entry_point "$@"
