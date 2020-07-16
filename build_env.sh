#!/usr/bin/env bash

###########
# Variables
###########
TMP_DIR=$(mktemp -d)

BASE_DIR="$( cd "$(dirname "$0")" >/dev/null 2>&1 ; pwd -P )"

BIN_DIR=$BASE_DIR/bin
CONFIG_DIR=$BASE_DIR/config
PATCH_DIR=$BASE_DIR/patches

UBOOT_DIR=$BASE_DIR/include/u-boot
UBOOT_BIN=$UBOOT_DIR/u-boot.bin


###########
# Functions
###########

# this function should be called when entering the environment
function _enter() {
    pushd $BASE_DIR
}

# this function should be called when leaving the environment
function _leave() {
    # remove the temporary directory
    rm -rf $TMP_DIR

    # equivalent to the pushd in the _enter function
    popd
}

# try to call the 'build' function
function _build() {
    _enter
    declare -f -F "build" > /dev/null && build
    _leave
}
# try to call the 'clean' function
function _clean() {
    _enter
    declare -f -F "clean" > /dev/null && clean
    _leave
}


# override of the pusd and popd functions to suppress output
function pushd() {
    command pushd "$@" > /dev/null
}
function popd() {
    command popd "$@" > /dev/null
}


# this is the entering point for each script
function entry_point() {
    case "$1" in
        "build")
            _build
            ;;
        "clean")
            _clean
            ;;
        *)
            _build
            ;;
    esac
}

# override of the exit function
function exit() {
    # leave the environment before exiting
    _leave

    command exit "$@"
}
