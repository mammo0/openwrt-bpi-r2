#!/usr/bin/env bash

. build_env.sh


MNT_ROOT=$(mktemp -d)


help() {
    usage
    echo
    echo "  -i IMAGE      The image file where the configuration should be applied."
    echo "  -c CONFIG     The *.tar.gz file that contains the OpenWRT configuration."
    echo
    exit 0
}
usage() {
    echo "Usage: $0 [ -i IMAGE ] [ -c CONFIG ]" 1>&2
}
while getopts ":i:c:h" options; do
    echo "$options"
    case "${options}" in
        i)
            IMAGE=${OPTARG}
            if [ ! -f "$IMAGE" ]; then
                echo "ERROR: The file '$IMAGE' does not exist!" 1>&2
                exit 1
            fi

            pcapdir_set=true
            ;;
        c)
            CONFIG=($OPTARG)
            if [ ! -f "$CONFIG" ]; then
                echo "ERROR: The file '$CONFIG' does not exist!" 1>&2
                exit 1
            fi
            ;;
        :)
            echo "Error: -${OPTARG} requires an argument."
            exit 1
            ;;
        h)
            help
            ;;
        *)
            usage
            exit 1
            ;;
    esac
done
if [ $OPTIND -ne 5 ]; then
    usage
    exit 1
fi


LOOP_DEV=$(get_loopdev "$IMAGE")
# mount the root file system
sudo mount -t ext4 ${LOOP_DEV}p2 "$MNT_ROOT"

# prepare chroot
sudo mount -o bind /dev "$MNT_ROOT"/dev/
sudo mount -t proc proc "$MNT_ROOT"/proc/
sudo mkdir -p "$MNT_ROOT"/tmp/lock
sudo cp /etc/resolv.conf "$MNT_ROOT"/tmp/
sudo cp "$CONFIG" "$MNT_ROOT"/tmp/backup.tar.gz

# execute chroot commands
! sudo chroot "$MNT_ROOT" /bin/sh << "EOT"
/sbin/sysupgrade -r /tmp/backup.tar.gz
/bin/opkg update
/bin/opkg install $(/bin/cat /etc/backup/installed_packages.txt | /bin/sed -E 's/\tunknown//')
/bin/rm -rf /tmp/*
EOT

# unmount all again
sudo umount "$MNT_ROOT"/dev
sudo umount "$MNT_ROOT"/proc
sudo umount "$MNT_ROOT"
rmdir "$MNT_ROOT"
# close the loop device again
sudo losetup -d $LOOP_DEV
