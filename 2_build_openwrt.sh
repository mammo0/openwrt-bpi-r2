#!/usr/bin/env bash

. build_env.sh


function build() {
    if [[ ! -d "$OPENWRT_DIR" ]]; then
        # get the source
        git clone -b "v$OPENWRT_VER" --depth 1 https://github.com/openwrt/openwrt.git "$OPENWRT_DIR"
    fi

    pushd "$OPENWRT_DIR"
    # update the feeds
    scripts/feeds update -a
    scripts/feeds install -a

    # get the build config
    curl "https://downloads.openwrt.org/releases/$OPENWRT_VER/targets/mediatek/mt7623/config.buildinfo" --output .config

    # apply some patches
    apply_patches "$PATCH_DIR/openwrt" "$OPENWRT_DIR"

    # apply the config
    make defconfig

    # fetch all dependency source code (needed for multi-core build)
    make download

    # build
    N_CPU=$(grep ^processor /proc/cpuinfo  | wc -l)
    make -j$N_CPU
    popd
}


function collect_artifacts() {
    # the kernel
    cp "$OPENWRT_DIR/build_dir/target-arm_cortex-a7+neon-vfpv4_musl_eabi/linux-mediatek_mt7623/7623n-bananapi-bpi-r2-kernel.bin" "$OPENWRT_KERNEL"
    # the root file system
    cp "$OPENWRT_DIR/bin/targets/mediatek/mt7623/openwrt-$OPENWRT_VER-mediatek-mt7623-device-7623n-bananapi-bpi-r2-rootfs.tar.gz" "$OPENWRT_ROOTFS"
}


function clean() {
    rm -rf "$OPENWRT_DIR"

    rm "$OPENWRT_KERNEL"
    rm "$OPENWRT_ROOTFS"
}


entry_point "$@"
