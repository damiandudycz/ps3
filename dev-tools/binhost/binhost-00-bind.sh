#!/bin/bash

# This script binds or unbinds the repository binhost directory to/from the catalyst packages directory.

# --- Shared environment
source ../../.env-shared.sh || exit 1
source env.sh || failure "Failed to load env.sh"
register_usage "$0 --bind | --unbind"

[ "$#" -ne 1 ] && show_usage

case "$1" in
    --bind)
        # Check if already mounted
        CURRENT_MOUNT=$(findmnt -nr -o SOURCE,TARGET "${B_PATH_BIND_DST}" || true)

        if [ -n "$CURRENT_MOUNT" ]; then
            CURRENT_SOURCE=$(echo "$CURRENT_MOUNT" | awk '{print $1}')
            CURRENT_SOURCE_REALPATH=$(realpath "$(echo "$CURRENT_SOURCE" | tail -n 1 | sed -E 's|.+\[(.+)\]|\1|')" 2>/dev/null)

            if [ "$CURRENT_SOURCE_REALPATH" == "${B_PATH_BIND_SRC}" ]; then
                echo "${B_PATH_BIND_SRC} is already bound with ${B_PATH_BIND_DST}."
            else
                failure "${B_PATH_BIND_SRC} is already bound with ${CURRENT_SOURCE_REALPATH}, not ${B_PATH_BIND_DST}."
            fi
        else
            # Bind binhost
            mount -o bind "${B_PATH_BIND_SRC}" "${B_PATH_BIND_DST}"
            echo "Successfully bounded ${B_PATH_BIND_SRC} to ${B_PATH_BIND_DST}"
        fi
        ;;
    --unbind)
        # Unbind binhost
        umount "${B_PATH_BIND_DST}"
        echo "Successfully unbounded ${B_PATH_BIND_DST}"
        ;;
    *)
        # Unsupported option
        show_usage
        ;;
esac
