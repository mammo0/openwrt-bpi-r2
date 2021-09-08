# OpenWRT for Banana Pi R2

**Important: On September 4, 2021 OpenWRT 21.02 was released.** This release has a much better built-in support for the Banana Pi R2. You can download a ready to use image now from the official OpenWRT site: https://firmware-selector.openwrt.org/ (just search for Banana Pi R2)

Please have a look at the official [Wiki](https://openwrt.org/docs/guide-user/installation/installation_methods/sd_card) for flashing the image to a SD card.

**This means this project is now discontinued**!

You can still find my images (up to version 19.07.8) on the [releases page](https://github.com/mammo0/openwrt-bpi-r2/releases).

</br>

_Finally, I want to thank everybody who used my images :)_

</br>

---


This repository contains a collection of scripts for building a
 - SD card and
 - EMMC

image of **OpenWRT**. The current version is

    19.07.8

</br>

**Many thanks to** [frank-w](https://github.com/frank-w) for making this possible.

![Build OpenWRT for BPi-R2](https://github.com/mammo0/openwrt-bpi-r2/workflows/Build%20OpenWRT%20for%20BPi-R2/badge.svg)



### Download the precompiled images
There's a GitHub workflow that builds the SD card and EMMC image of this repository. You can download them directly from the [releases page](https://github.com/mammo0/openwrt-bpi-r2/releases).



### Manual building
If you want to build the images by yourself, please follow these instructions:

1. Install the requiered dependencies:
    - **git** - just for the sake of completeness ;)
    - **curl**
    - **dosfstools** and **e2fsprogs** for image creation
    - for U-Boot:
        - **bison**
        - **gcc** for **arm-linux-gnueabihf** architecture (have a look at your distro documentaion for the right package)
        - **flex**
        - **python** (with development files)
        - **swig**
        - **xxd**
    - for OpenWRT see the official documentaion: **https://openwrt.org/docs/guide-developer/build-system/install-buildsystem#examples_of_package_installations**
    - for restoring:
        - **qemu-arm-static** (have a look at your distro documentaion for the right package) The static binaries must be registred via binfmt!
2. Run **0_prepare.sh**
3. Run **1_build_uboot.sh**
3. Run **2_build_openwrt.sh**
4. Run **3_build_images.sh**
5. (Optional) Run **restore_config.sh** (Please have a look at the restoring section below for more information)

The resulting images are placed in the `out` directory of this repository.

For cleaning the compilation area append `clean` argument to any of the above mentioned scripts.



### Building with Docker
If you don't want to setup the build context on your system but also want to build local, you can use docker for building it.

#### 1) Build the Docker image
To build the Docker image run:
```shell
docker build -t bpi_r2-openwrt .
```
For customizations you can specify the following build arguments:
- `BUILD_USER`: The name for the user that runs the build process.
- `PUID`: The user ID of that user.
- `PGID`: The group ID that belongs to that user.

#### 2) Run the Docker image to build the OpenWRT images
To start the automated build process run:
```shell
docker run [--privileged] -v `pwd`:/out bpi_r2-openwrt [uboot|openwrt]
```
By default if no arguments were specified, the `--privileged` parameter is **required** for the image creation process. The resulting SD card and EMMC images should be available in your current working directory. Otherwise check the `-v` parameter. On container side the path should be equal to the `VOLUME_DIR` path that is defined in the Dockerfile.

The optional arguments:
- **uboot**: Only build the U-Boot binary. After the build you should find the `u-boot.bin` in your current working directory.
- **openwrt**: Only build OpenWRT. Afterwards you should find the `openwrt-kernel.bin` and the `openwrt-rootfs.tar.gz` in your current working directory.

*If you use the `uboot` or `openwrt` argument, the `--privileged` parameter is not necessary. Afterwards you can copy the resulting U-Boot or OpenWRT files from the current working directory to the `artifacts` directory. Then you can call the `3_build_images.sh` script directly on your host PC to build the images (check the dependencies above for this).*



### Flashing the images

#### SD card
Just flash the imge to the SD card, e.g. with `dd`:

```shell
dd if=BPI-R2_SD.img of=/dev/<sd_device>
```

#### EMMC
You need a running system on the Banana Pi for flashing. For this you can also use the SD card version of OpenWRT.

After logging into the system via SSH or Serial console you
1. first need to flash the **BPI-R2_EMMC.img** image:
    ```shell
    dd if=BPI-R2_EMMC.img of=/dev/mmcblk0
    ```
    *Assuming that `mmcblk0` is the EMMC device.*

2. After that flash the **BPI-R2_EMMC_boot0.img** image:
    ```shell
    dd if=BPI-R2_EMMC_boot0.img of=/dev/mmcblk0boot0
    ```
    *Assuming that `mmcblk0boot0` is the EMMC device.*

    If you get an error that you don't have permissions for this operation, you may need to activate write mode for the boot partition of the EMMC device:
    ```shell
    echo 0 > /sys/block/mmcblk0boot0/force_ro
    ```



### Upgrading the firmware
**A "normal" upgrade via the LuCi-Webinterface is not possible!**

To perform an upgrade a manual reflash of the image(s) is needed like it's described in the previous section.

**Warning: This would mean to lose all custom settings!** So it's necessary to perform a backup of the settings first!

#### Backup settings
One way is via the LuCi-Webinterface:

    System > Backup / Flash Firmware

**Warning: The above backup does not contain additional installed packages!** If you installed software packages with `opkg` or through LuCi, you need perform a special backup:

1. Login to the router via SSH.
2. Execute
```shell
sysupgrade -k -b <backup_file>.tar.gz
```
3. Transfer the created file to your PC, e.g. with `scp`.

#### Restore settings
If you made the backup with the LuCi-Webinterface, you can restore your settings on the same page.

**Warning: This means, that on the first boot the device uses its default configuration!** If you don't want this behaviour or if you also backed up your installed packages, please use this alternative restoring method:

You could also integrate your backed up configuration into an image before flashing it to the device. To do this call the `restore_config.sh` script:
```shell
# this scripts asks for admin rights during execution!
restore_config.sh -i <image_file> -c <conifg_file>
```

`<image_file>` This is the image file to which the configuration should be applied. Could be either the SD card or EMMC image.

`<conifg_file>` This the *.tar.gz archive that was created either via LuCi or with the `sysupgrade` command above.

After that your settings have been integrated into the image file and can be flashed to either SD card or EMMC.


#### EMMC
The upgrade of the EMMC device can be done while the system is runing from that device. Usually only the `BPI-R2_EMMC.img` image needs to be (re-)flashed since this contains the filesystem and kernel.
