#!/bin/bash

# This script binds or unbinds the repository binhost directory to/from the catalyst packages directory.

# --- Shared environment
source ../../.env-shared.sh || exit 1
trap failure ERR

usage() {
    echo "Usage: $0 --bind | --unbind"
    exit 1
}
[ "$#" -ne 1 ] && usage

# Paths
readonly PATH_CATALYST_PACKAGES="/var/tmp/catalyst/packages/default"
readonly PATH_REPO_BINHOST=$(realpath "${PATH_ROOT}/binhosts/ps3-gentoo-binhosts/default") || die

readonly PATH_CATALYST_USR="${PATH_USR_SHARE}/catalyst"
readonly PATH_CATALYST_TMP="${PATH_VAR_TMP}/catalyst"
readonly PATH_CATALYST_BUILDS="${PATH_CATALYST_TMP}/builds/default"
readonly PATH_CATALYST_STAGES="${PATH_CATALYST_TMP}/config/stages"
readonly PATH_CATALYST_BINHOST="${PATH_CATALYST_TMP}/packages/default"
readonly PATH_CATALYST_PATCH_DIR="${PATH_ETC_PORTAGE}/patches/dev-util/catalyst"

case "$1" in
    --bind)
        # Check if already mounted
        CURRENT_MOUNT=$(findmnt -nr -o SOURCE,TARGET "${PATH_CATALYST_PACKAGES}")

        if [ -n "$CURRENT_MOUNT" ]; then
            CURRENT_SOURCE=$(echo "$CURRENT_MOUNT" | awk '{print $1}')
            CURRENT_SOURCE_REALPATH=$(realpath "$(echo "$CURRENT_SOURCE" | tail -n 1 | sed -E 's|.+\[(.+)\]|\1|')" 2>/dev/null)

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
