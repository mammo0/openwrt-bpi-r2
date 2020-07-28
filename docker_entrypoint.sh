#!/usr/bin/env bash

# the following ENV variables should be set by the Dockerfile:
#   - BUILD_USER
#   - PUID
#   - PGID
#   - BUILD_DIR
#   - VOLUME_DIR

# just to be sure we're in the right directory
cd "$BUILD_DIR"

# load build environment
./0_prepare.sh
. build_env.sh

case "$1" in
    uboot)
        ./1_build_uboot.sh

        # save u-boot.bin
        cp "$UBOOT_BIN" "$VOLUME_DIR/"
        ;;
    openwrt)
        # only build openwrt
        ./2_build_openwrt.sh

        # save kernel and rootfs
        cp "$OPENWRT_KERNEL" "$VOLUME_DIR/"
        cp "$OPENWRT_ROOTFS" "$VOLUME_DIR/"
        ;;
    *)
        # do all three steps
        ./1_build_uboot.sh
        ./2_build_openwrt.sh
        ./3_build_images.sh

        # copy the resulting images to the output volume
        cp "$SD_IMAGE_FILE" "$VOLUME_DIR/"
        cp "$EMMC_BOOT0_FILE" "$VOLUME_DIR/"
        cp "$EMMC_IMAGE_FILE" "$VOLUME_DIR/"
        ;;
esac
