#!/usr/bin/env bash

###########
# Variables
###########
TMP_DIR=$(mktemp -d)

UBOOT_BIN=bin/u-boot.bin


###########
# Functions
###########

# this function should be called when entering the environment
function _enter() {
    working_dir=$(dirname $0)

    pushd $working_dir
}

# this function should be called when leaving the environment
function _leave() {
    # remove the temporary directory
    rm -rf $TMP_DIR

    # equivalent to the pushd in the _enter function
    popd
}


# override of the pusd and popd functions to suppress output
function pushd() {
    command pushd "$@" > /dev/null
}
function popd() {
    command popd "$@" > /dev/null
}


# override of the exit function
function exit() {
    # leave the environment before exiting
    _leave

    command exit "$@"
}



################
# Entering point
################

case "$1" in
    "start")
        _enter
        ;;
    "stop")
        _leave
        ;;
esac
