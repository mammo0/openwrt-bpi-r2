#!/usr/bin/env bash

. build_env.sh


function build() {
    if [[ ! -d "$UBOOT_DIR" ]]; then
        # get the source
        git clone -b "$UBOOT_VER" --depth 1 https://github.com/frank-w/u-boot.git "$UBOOT_DIR"
    fi

    # go to the u-boot directory
    pushd "$UBOOT_DIR"
    echo "Building u-boot..."

    # add a custom uEnv.txt
    cp "$CONFIG_DIR/uEnv_default.txt" "$UBOOT_DIR/"

    # apply patches
    apply_patches "$PATCH_DIR/u-boot" "$UBOOT_DIR"

    # build u-boot
    ./build.sh importconfig
    ./build.sh build
    popd
}


function clean() {
    rm -rf "$UBOOT_DIR"
}


entry_point "$@"
