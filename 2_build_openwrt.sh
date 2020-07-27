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
    # N_CPU=$(grep ^processor /proc/cpuinfo  | wc -l)
    make -j1 V=s
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


# preperation for building
vermagic_patch_file="$PATCH_DIR/openwrt/fix_custom_kernel_vermagic.patch"
vermagic_patch=$'diff --git a/include/kernel-defaults.mk b/include/kernel-defaults.mk
--- a/include/kernel-defaults.mk
+++ b/include/kernel-defaults.mk
@@ -105,7 +105,7 @@
 		cp $(LINUX_DIR)/.config.set $(LINUX_DIR)/.config.prev; \
 	}
 	$(_SINGLE) [ -d $(LINUX_DIR)/user_headers ] || $(KERNEL_MAKE) INSTALL_HDR_PATH=$(LINUX_DIR)/user_headers headers_install
-	grep \'=[ym]\' $(LINUX_DIR)/.config.set | LC_ALL=C sort | mkhash md5 > $(LINUX_DIR)/.vermagic
+	echo "<vermagic>" > $(LINUX_DIR)/.vermagic
 endef

 define Kernel/Configure/Initramfs'

# the official needed vermagic is used in the openwrt package dependencies
official_vermagic=$(
    # get the official package list
    curl -s https://downloads.openwrt.org/releases/$OPENWRT_VER/targets/mediatek/mt7623/packages/Packages | \
    # the vermagic hides in the dependencies of the 'kmod' packages
    grep -m 1 "Depends: kernel" | \
    # extract the vermagic
    sed -E 's/.*([a-zA-Z0-9]{32}).*/\1/'
)

# write the temporary patch
echo "$vermagic_patch" | sed "s/<vermagic>/$official_vermagic/g" > "$vermagic_patch_file"


entry_point "$@"
