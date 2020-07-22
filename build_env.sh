#!/usr/bin/env bash

##################################################
# Check if the build environment is already loaded
##################################################
if [ "$BUILD_ENV_LOADED" = "true" ]; then
    return 0
fi


###########
# Variables
###########
TMP_DIR=$(mktemp -d)

BASE_DIR="$( cd "$(dirname "$0")" >/dev/null 2>&1 ; pwd -P )"

BIN_DIR="$BASE_DIR/bin"
CONFIG_DIR="$BASE_DIR/config"
PATCH_DIR="$BASE_DIR/patches"

UBOOT_VER="2019-01-bpi-r2"
UBOOT_DIR="$BASE_DIR/src/u-boot"
UBOOT_BIN="$UBOOT_DIR/u-boot.bin"

OPENWRT_VER="19.07.3"
OPENWRT_DIR="$BASE_DIR/src/openwrt"

SD_IMAGE_FILE="$BASE_DIR/BPI-R2_SD.img"
EMMC_BOOT0_FILE="$BASE_DIR/BPI-R2_EMMC_boot0.img"
EMMC_IMAGE_FILE="$BASE_DIR/BPI-R2_EMMC.img"


###########
# Functions
###########

# this function should be called when entering the environment
function _enter() {
    pushd "$BASE_DIR"
}

# this function should be called when leaving the environment
function _leave() {
    # remove the temporary directory
    rm -rf "$TMP_DIR"

    # equivalent to the pushd in the _enter function
    popd
}

# try to call the 'build' function
function _build() {
    _enter
    declare -f -F "build" > /dev/null && build
    _leave
}
# try to call the 'clean' function
function _clean() {
    _enter
    declare -f -F "clean" > /dev/null && clean
    _leave
}


function apply_patches() {
    for patch_file in "$1"/*.patch; do
        [ -f "$patch_file" ] || break

        echo "Applying patch $patch_file"

        # check if it's a git patch or not
        if grep -q -- "--git" "$patch_file"; then
            # ignore a or b path prefix in the patch file
            patch -N -d "$2" -p1 < "$patch_file"
        else
            patch -N -d "$2" < "$patch_file"
        fi
    done
}


# override of the pusd and popd functions to suppress output
function pushd() {
    command pushd "$@" > /dev/null
}
function popd() {
    command popd "$@" > /dev/null
}


# this is the entering point for each script
function entry_point() {
    case "$1" in
        "build")
            _build
            ;;
        "clean")
            _clean
            ;;
        *)
            _build
            ;;
    esac
}

# override of the exit function
function exit() {
    # leave the environment before exiting
    _leave

    command exit "$@"
}


######################################
# mark the build environment as loaded
######################################
BUILD_ENV_LOADED="true"
