#!/usr/bin/env bash

. build_env.sh


function build() {
    if [[ ! -d "$OPENWRT_DIR" ]]; then
        # get the source
        git clone -b "v$OPENWRT_VER" --depth 1 https://github.com/openwrt/openwrt.git "$OPENWRT_DIR"
    fi

    pushd "$OPENWRT_DIR"
    # get the build config
    curl "https://downloads.openwrt.org/releases/$OPENWRT_VER/targets/mediatek/mt7623/config.buildinfo" --output .config
    apply_patches "$PATCH_DIR/openwrt" "$OPENWRT_DIR"

    # update the feeds
    scripts/feeds update -a
    scripts/feeds install -a

    # apply the config
    make defconfig

    # build
    N_CPU=$(grep ^processor /proc/cpuinfo  | wc -l)
    make -j$N_CPU
    popd
}


function clean() {
    rm -rf "$OPENWRT_DIR"
}


entry_point "$@"
