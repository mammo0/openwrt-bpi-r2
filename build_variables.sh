#!/usr/bin/env bash

#################################################
# Check if the build variables are already loaded
#################################################
if [ "$BUILD_VARIABLES_LOADED" = "true" ]; then
    return 0
fi


###########
# Variables
###########
TMP_DIR=$(mktemp -d)

BASE_DIR="$( cd "$(dirname "$0")" >/dev/null 2>&1 ; pwd -P )"

ARTIFACTS_DIR="$BASE_DIR/artifacts"
CONFIG_DIR="$BASE_DIR/config"
PATCH_DIR="$BASE_DIR/patches"
OUT_DIR="$BASE_DIR/out"

UBOOT_VER="2019-01-bpi-r2"
UBOOT_DIR="$BASE_DIR/src/u-boot"
UBOOT_BIN="$ARTIFACTS_DIR/u-boot.bin"

OPENWRT_VER="19.07.3"
OPENWRT_DIR="$BASE_DIR/src/openwrt"
OPENWRT_KERNEL="$ARTIFACTS_DIR/openwrt-kernel.bin"
OPENWRT_ROOTFS="$ARTIFACTS_DIR/openwrt-rootfs.tar.gz"

SD_IMAGE_FILE="$OUT_DIR/BPI-R2_SD.img"
EMMC_BOOT0_FILE="$OUT_DIR/BPI-R2_EMMC_boot0.img"
EMMC_IMAGE_FILE="$OUT_DIR/BPI-R2_EMMC.img"


####################################
# mark the build variables as loaded
####################################
BUILD_VARIABLES_LOADED="true"
