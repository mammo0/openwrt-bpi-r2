# OpenWRT for Banana Pi R2

This repository contains a collection of scripts for building a
 - SD card and
 - EMMC

image of **OpenWRT**. The current version is

    19.07.03

</br>

**Many thanks to** [frank-w](https://github.com/frank-w) for making this possible.



### Download the precompiled images
There's a GitHub workflow that builds the SD card and EMMC image of this repository. You can download them directly from the releases page.



### Manual building
If you want to build the images by yourself, please follow these instructions:

1. Install the requiered dependencies:
    - **git** - just for the sake of completeness ;)
    - **curl**
    - for U-Boot:
        - **bison**
        - **gcc** for **arm-linux-gnueabihf** architecture (have a look at your distro documentaion for the right package)
        - **flex**
        - **python** (with development files)
        - **swig**
        - **xxd**
    - for OpenWRT see the official documentaion: **https://openwrt.org/docs/guide-developer/build-system/install-buildsystem#examples_of_package_installations**
2. Run **1_build_uboot.sh**
3. Run **2_build_openwrt.sh**
4. Run **3_build_images.sh**

The resulting images are placed in the `out` directory of this repository.

For cleaning the compilation area append `clean` argument to any of the above mentioned scripts.



### Flashing the images

##### SD card
Just flash the imge to the SD card, e.g. with `dd`:

```shell
dd if=BPI-R2_SD.img of=/dev/<sd_device>
```

##### EMMC
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

**Importatnt: This would mean to lose all custom settings!** So it's necessary to perform a backup of the settings first. This can be done with the LuCi-Webinterface:

    System > Backup / Flash Firmware

After the the upgrade the settings can be restored on the same page.


##### EMMC
The upgrade of the EMMC device can be done while the system is runing from that device. Usually only the `BPI-R2_EMMC.img` image needs to be (re-)flashed since this contains the filesystem and kernel.
