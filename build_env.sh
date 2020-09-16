#!/usr/bin/env bash

##################################################
# Check if the build environment is already loaded
##################################################
if [ "$BUILD_ENV_LOADED" = "true" ]; then
    return 0
fi


# exit if a command fails
set -e


###########
# Variables
###########
# the variables are stored in an .env file that is created by 0_prepare.sh
if [ ! -f ".env" ]; then
    echo "Please run 0_prepare.sh first!" >&2
    return 1
fi
# source .env file
. .env


###########
# Functions
###########

# this function should be called when entering the environment
function _enter() {
    pushd "$BASE_DIR"

    # mark the entering process as complete
    export BUILD_ENV_ENTERED="true"
}

# this function should be called when leaving the environment
function _leave() {
    # remove the temporary directory
    rm -rf "$TMP_DIR"

    # the following steps should only be taken if _enter was called before
    if [ "$BUILD_ENV_ENTERED" = "true" ]; then
        # equivalent to the pushd in the _enter function
        popd

        unset BUILD_ENV_ENTERED
    fi
}

# try to call the 'build' function
function _build() {
    _enter
    declare -f -F "build" > /dev/null && build

    # collect all relevant artifacts, that were produced during the build process
    declare -f -F "collect_artifacts" > /dev/null && collect_artifacts
    _leave
}
# try to call the 'clean' function
function _clean() {
    _enter
    declare -f -F "clean" > /dev/null && clean
    _leave
}


function apply_patches() {
    for patch_file in "$1"/*.patch; do
        [ -f "$patch_file" ] || break

        echo "Applying patch $patch_file"

        # check if it's a git patch or not
        if grep -q -- "--git" "$patch_file"; then
            # ignore a or b path prefix in the patch file
            out=$(patch -N -d "$2" -p1 < "$patch_file") || echo "${out}" | grep "Skipping patch" -q || (echo "$out" && false)
        else
            out=$(patch -N -d "$2" < "$patch_file") || echo "${out}" | grep "Skipping patch" -q || (echo "$out" && false)
        fi
    done
}


function get_loopdev() {
    if [ ! -f "$1" ]; then
        echo "No image specified!" 1>&2
        return 1
    fi
    # create the loop device for editing the image
	loop_dev=$(sudo losetup -Pf --show "$1")

	# workaround if losetup can't create 'p1' and 'p2' nods
	# drop the first line, as this is our LOOPDEV itself, but we only want the child partitions
	loop_partitions=$(lsblk --raw --output "MAJ:MIN" --noheadings ${loop_dev} | tail -n +2)
	loop_partitions_counter=1
	for i in $loop_partitions; do
		maj=$(echo $i | cut -d: -f1)
		min=$(echo $i | cut -d: -f2)
		if [ ! -e "${loop_dev}p${loop_partitions_counter}" ]; then
			sudo mknod ${loop_dev}p${loop_partitions_counter} b $maj $min
		fi
		loop_partitions_counter=$((loop_partitions_counter + 1))
	done

    # return the loop device
    echo "$loop_dev"
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


######################################
# mark the build environment as loaded
######################################
BUILD_ENV_LOADED="true"
