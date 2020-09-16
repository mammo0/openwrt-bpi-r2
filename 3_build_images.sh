#!/usr/bin/env bash

. build_env.sh


TMP_DIR=$(mktemp -d)
BASE_IMAGE_FILE="$TMP_DIR/base_img.img"


# special SD card images (precompiled)
SD_PRELOADER="BPI-R2-preloader-DDR1600-20191024-2k.img"
SD_PRELOADER_FILE="$ARTIFACTS_DIR/$SD_PRELOADER"
SD_HEAD_1="BPI-R2-HEAD440-0k.img"
SD_HEAD_1_FILE="$ARTIFACTS_DIR/$SD_HEAD_1"
SD_HEAD_2="BPI-R2-HEAD1-512b.img"
SD_HEAD_2_FILE="$ARTIFACTS_DIR/$SD_HEAD_2"


# precompiled binaries for MMC boot
EMMC_PRELOADER="BPI-R2-EMMC-boot0-DDR1600-20191024-0k.img"
EMMC_PRELOADER_FILE="$ARTIFACTS_DIR/$EMMC_PRELOADER"


function build() {
	############
	# main image
	############
	echo "Creating main image file..."

	# create the image
	dd if=/dev/zero of="$BASE_IMAGE_FILE" bs=1KB count=65KB

	# load the partition tale
	sfdisk "$BASE_IMAGE_FILE" < config/base_img.parttable

	# create mount points
	MNT_BOOT="$TMP_DIR/boot"
	MNT_ROOT="$TMP_DIR/root"
	mkdir -p "$MNT_BOOT"
	mkdir -p "$MNT_ROOT"

	# create the loop device for editing the image
	LOOP_DEV=$(get_loopdev "$BASE_IMAGE_FILE")

	# format the partitions
	sudo mkfs.vfat ${LOOP_DEV}p1
	sudo mkfs.ext4 ${LOOP_DEV}p2

	# mount
	sudo mount -t vfat ${LOOP_DEV}p1 "$MNT_BOOT"
	sudo mount -t ext4 ${LOOP_DEV}p2 "$MNT_ROOT"

	# copy the boot files
	sudo cp "$CONFIG_DIR/uEnv.txt" "$MNT_BOOT"
	sudo cp "$OPENWRT_KERNEL" "$MNT_BOOT/uImage"

	# copy/extract the file system
	sudo tar -xf "$OPENWRT_ROOTFS" -C "$MNT_ROOT"

	# unmount
	sudo umount "$MNT_BOOT"
	sudo umount "$MNT_ROOT"

	# close the loop device again
	sudo losetup -d $LOOP_DEV


	#########
	# SD card
	#########
	echo "Building SD card image..."

	# download precompiled binaries for SD card
	pushd $ARTIFACTS_DIR
	for image in $SD_PRELOADER $SD_HEAD_1 $SD_HEAD_2; do
		curl -LJO https://github.com/BPI-SINOVOIP/BPI-files/raw/master/SD/100MB/${image}.gz
		gunzip -f ${image}.gz
	done
	popd

	# creating the SD image
	cp "$BASE_IMAGE_FILE" "$SD_IMAGE_FILE"
	dd if="$SD_HEAD_1_FILE" of="$SD_IMAGE_FILE" conv=notrunc bs=1k seek=0
	dd if="$SD_HEAD_2_FILE" of="$SD_IMAGE_FILE" conv=notrunc bs=512 seek=1
	dd if="$SD_PRELOADER_FILE" of="$SD_IMAGE_FILE" conv=notrunc bs=1k seek=2
	dd if="$UBOOT_BIN" of="$SD_IMAGE_FILE" conv=notrunc bs=1k seek=320


	#####
	# MMC
	#####
	echo "Building MMC image..."

	# download precompiled binary for MMC
	pushd $ARTIFACTS_DIR
	curl -LJO https://github.com/BPI-SINOVOIP/BPI-files/raw/master/SD/100MB/${EMMC_PRELOADER}.gz
	gunzip -f ${EMMC_PRELOADER}.gz
	popd

	# this binary is ready to use
	# it must be flashed to the boot0 partition of the MMC
	# dd if=BPI-R2_MMC_boot0.img of=/dev/mmcblk1boot0
	cp "$EMMC_PRELOADER_FILE" "$EMMC_BOOT0_FILE"

	# creating the MMC image
	cp "$BASE_IMAGE_FILE" "$EMMC_IMAGE_FILE"
	dd if="$UBOOT_BIN" of="$EMMC_IMAGE_FILE" conv=notrunc bs=1k seek=320
}

function clean() {
	rm "$SD_IMAGE_FILE"
	rm "$SD_PRELOADER_FILE"
	rm "$SD_HEAD_1_FILE"
	rm "$SD_HEAD_2_FILE"

	rm "$EMMC_IMAGE_FILE"
	rm "$EMMC_BOOT0_FILE"
	rm "$EMMC_PRELOADER_FILE"
}


entry_point "$@"
