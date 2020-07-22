#!/usr/bin/env bash

. build_env.sh


BASE_IMAGE_FILE="$TMP_DIR/base_img.img"


# special SD card images (precompiled)
SD_PRELOADER="BPI-R2-preloader-DDR1600-20191024-2k.img"
SD_PRELOADER_FILE="$BIN_DIR/$SD_PRELOADER"
SD_HEAD_1="BPI-R2-HEAD440-0k.img"
SD_HEAD_1_FILE="$BIN_DIR/$SD_HEAD_1"
SD_HEAD_2="BPI-R2-HEAD1-512b.img"
SD_HEAD_2_FILE="$BIN_DIR/$SD_HEAD_2"


# precompiled binaries for MMC boot
EMMC_PRELOADER="BPI-R2-EMMC-boot0-DDR1600-20191024-0k.img"
EMMC_PRELOADER_FILE="$BIN_DIR/$EMMC_PRELOADER"


function build() {
	############
	# main image
	############
	echo "Creating main image file..."

	# create the image
	dd if=/dev/zero of="$BASE_IMAGE_FILE" bs=1k count=512k

	# load the partition tale
	sfdisk "$BASE_IMAGE_FILE" < config/base_img.parttable

	# create mount points
	MNT_BOOT="$TMP_DIR/boot"
	MNT_ROOT="$TMP_DIR/root"
	mkdir -p "$MNT_BOOT"
	mkdir -p "$MNT_ROOT"

	# create the loop device for editing the image
	LOOP_DEV=$(sudo losetup -Pf --show "$BASE_IMAGE_FILE")

	# format the partitions
	sudo mkfs.vfat ${LOOP_DEV}p1
	sudo mkfs.ext4 ${LOOP_DEV}p2

	# mount
	sudo mount -t vfat ${LOOP_DEV}p1 "$MNT_BOOT"
	sudo mount -t ext4 ${LOOP_DEV}p2 "$MNT_ROOT"

	# copy the boot files
	cp "$CONFIG_DIR/uEnv.txt" "$MNT_BOOT"
	cp "$OPENWRT_DIR/build_dir/target-arm_cortex-a7+neon-vfpv4_musl_eabi/linux-mediatek_mt7623/7623n-bananapi-bpi-r2-kernel.bin" "$MNT_BOOT/uImage"

	# copy/extract the file system
	sudo tar -xf "$OPENWRT_DIR/bin/targets/mediatek/mt7623/openwrt-$OPENWRT_VER-mediatek-mt7623-device-7623n-bananapi-bpi-r2-rootfs.tar.gz" -C "$MNT_BOOT"

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
