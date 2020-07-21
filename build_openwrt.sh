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


function clean() {
    rm -rf "$OPENWRT_DIR"
}


entry_point "$@"
