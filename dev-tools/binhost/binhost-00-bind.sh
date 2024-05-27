#!/bin/bash

# This script binds or unbinds the repository binhost directory to/from the catalyst packages directory.

# --- Shared environment
source ../../.env-shared.sh || exit 1
trap failure ERR
register_usage "$0 --bind | --unbind"

[ "$#" -ne 1 ] && show_usage

readonly CONF_RELEASE_NAME="${CONF_CATALYST_RELEASE_NAME_DFAULT}"
readonly PATH_BIND_SRC="${PATH_BINHOSTS_PS3_GENTOO}/${CONF_RELEASE_NAME}"
readonly PATH_BIND_DST="${PATH_CATALYST_PACKAGES}/${CONF_RELEASE_NAME}"

case "$1" in
    --bind)
        # Check if already mounted
        CURRENT_MOUNT=$(findmnt -nr -o SOURCE,TARGET "${PATH_BIND_DST}" || true)

        if [ -n "$CURRENT_MOUNT" ]; then
            CURRENT_SOURCE=$(echo "$CURRENT_MOUNT" | awk '{print $1}')
            CURRENT_SOURCE_REALPATH=$(realpath "$(echo "$CURRENT_SOURCE" | tail -n 1 | sed -E 's|.+\[(.+)\]|\1|')" 2>/dev/null)

            if [ "$CURRENT_SOURCE_REALPATH" == "${PATH_BIND_SRC}" ]; then
                echo "${PATH_BIND_SRC} is already bound with ${PATH_BIND_DST}."
            else
                failure "${PATH_BIND_SRC} is already bound with ${CURRENT_SOURCE_REALPATH}, not ${PATH_BIND_DST}."
            fi
        else
            # Bind binhost
            mount -o bind "${PATH_BIND_SRC}" "${PATH_BIND_DST}"
            echo "Successfully bounded ${PATH_BIND_SRC} to ${PATH_BIND_DST}"
        fi
        ;;
    --unbind)
        # Unbind binhost
        umount "${PATH_BIND_DST}"
        echo "Successfully unbounded ${PATH_BIND_DST}"
        ;;
    *)
        # Unsupported option
        show_usage
        ;;
esac
