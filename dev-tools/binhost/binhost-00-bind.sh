#!/bin/bash

# This script binds or unbinds the repository binhost directory to/from the catalyst packages directory.

# Function to print error message and exit
die() {
    echo "$1" >&2
    exit 1
}

# Function to show usage options
usage() {
    echo "Usage: $0 --bind | --unbind"
    exit 1
}

# Paths
readonly PATH_START=$(dirname "$(realpath "$0")") || die
readonly PATH_ROOT=$(realpath -m "${PATH_START}/../..") || die
readonly PATH_ENV_READY="${PATH_ROOT}/local/env_ready"
readonly PATH_CATALYST_PACKAGES="/var/tmp/catalyst/packages/default"
readonly PATH_REPO_BINHOST=$(realpath "${PATH_ROOT}/binhosts/ps3-gentoo-binhosts/default") || die

# Check if environment is ready
[ -f "${PATH_ENV_READY}" ] || die "Dev environment was not initialized. Please run dev-tools/setup-environment.sh first."

# Check the argument count and display usage if incorrect
[ "$#" -ne 1 ] && usage

case "$1" in
    --bind)
        # Check if already mounted
        CURRENT_MOUNT=$(findmnt -nr -o SOURCE,TARGET "${PATH_CATALYST_PACKAGES}")

        if [ -n "$CURRENT_MOUNT" ]; then
            CURRENT_SOURCE=$(echo "$CURRENT_MOUNT" | awk '{print $1}')
            CURRENT_SOURCE_REALPATH=$(realpath "${CURRENT_SOURCE#/dev/*}" 2>/dev/null)
            if [ "$CURRENT_SOURCE_REALPATH" == "${PATH_REPO_BINHOST}" ]; then
                echo "${PATH_CATALYST_PACKAGES} is already mounted with ${PATH_REPO_BINHOST}."
                exit 0
            else
                die "${PATH_CATALYST_PACKAGES} is already mounted with ${CURRENT_SOURCE_REALPATH}, not ${PATH_REPO_BINHOST}."
            fi
        fi
        # Bind binhost
        mount -o bind "${PATH_REPO_BINHOST}" "${PATH_CATALYST_PACKAGES}" || die "Failed to mount binhost repo ${PATH_REPO_BINHOST} to ${PATH_CATALYST_PACKAGES}"
        echo "Successfully mounted ${PATH_REPO_BINHOST} to ${PATH_CATALYST_PACKAGES}"
        ;;
    --unbind)
        # Unbind binhost
        umount "${PATH_CATALYST_PACKAGES}" || die "Failed to unmount ${PATH_CATALYST_PACKAGES}"
        echo "Successfully unmounted ${PATH_CATALYST_PACKAGES}"
        ;;
    *)
        # Unsupported option
        usage
        ;;
esac

exit 0
