FROM ubuntu:18.04

ARG BUILD_USER=builder
ARG PUID=1000
ARG PGID=1000
ENV BUILD_DIR=/build
ENV VOLUME_DIR=/out


# install dependencies
RUN apt-get update && \
    apt-get -y install \
        # for admin rights
        sudo \
        build-essential \
        curl \
        dosfstools \
        e2fsprogs \
        git \
        # u-boot
        gcc-arm-linux-gnueabihf \
        bison \
        flex \
        python-dev \
        swig \
        xxd \
        # openwrt
        ecj \
        fastjar \
        file \
        g++ \
        gawk \
        gettext \
        java-propose-classpath \
        libelf-dev \
        libncurses5-dev \
        libssl-dev \
        python \
        python3 \
        python3-distutils \
        subversion \
        unzip \
        wget \
        zlib1g-dev



# add build user
RUN [ $(getent group $PGID) ] || groupadd -f -g $PGID $BUILD_USER && \
    useradd -ms /bin/bash -u $PUID -g $PGID $BUILD_USER && \
    echo "Cmnd_Alias IMAGE_CREATION = /sbin/losetup, /sbin/mkfs.ext4, /sbin/mkfs.vfat, /bin/mount, /bin/umount, /bin/cp, /bin/tar, /bin/mknod" >> /etc/sudoers && \
    echo "$BUILD_USER ALL = NOPASSWD: IMAGE_CREATION" >> /etc/sudoers

# setup build context
RUN mkdir "$BUILD_DIR" && \
    mkdir "$VOLUME_DIR" && \
    chown $PUID:$PGID "$VOLUME_DIR"
ADD . "$BUILD_DIR"
RUN chown -R $PUID:$PGID "$BUILD_DIR"
WORKDIR "$BUILD_DIR"


USER $BUILD_USER
VOLUME "$VOLUME_DIR"
COPY docker_entrypoint.sh /usr/bin/
ENTRYPOINT ["docker_entrypoint.sh"]
