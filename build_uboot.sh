#!/usr/bin/env bash

. build_env.sh


function build() {
    # go to the u-boot directory
    pushd "$UBOOT_DIR"
    echo "Building u-boot..."

    # add a custom uEnv.txt
    cp "$CONFIG_DIR/uEnv.txt" "$UBOOT_DIR/"

    # apply patches
    apply_patches "$PATCH_DIR/u-boot" "$UBOOT_DIR"

    # build u-boot
    ./build.sh importconfig
    ./build.sh build
    popd
}


function clean() {
    pushd "$UBOOT_DIR"
    # first clean all build artifacts
    git clean -xdf

    # then reset the u-boot submodule
    git reset --hard
    popd
}


entry_point "$@"
