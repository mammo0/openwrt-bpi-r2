#!/usr/bin/env bash

###########
# Variables
###########
TMP_DIR=$(mktemp -d)

BASE_DIR="$( cd "$(dirname "$0")" >/dev/null 2>&1 ; pwd -P )"


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
