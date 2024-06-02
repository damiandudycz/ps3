#!/bin/bash

# This script binds or unbinds the repository binhost directory to/from the catalyst packages directory.

source ../../.env-shared.sh || exit 1
register_usage "$0 --bind | --unbind"

[ "$#" -ne 1 ] && show_usage

case "$1" in
    --bind)
        # Check if already mounted
        CURRENT_MOUNT=$(findmnt -nr -o SOURCE,TARGET "${PATH_CATALYST_BINHOST_DEFAULT}" || true)

        if [ -n "$CURRENT_MOUNT" ]; then
            CURRENT_SOURCE=$(echo "$CURRENT_MOUNT" | awk '{print $1}')
            CURRENT_SOURCE_REALPATH=$(realpath "$(echo "$CURRENT_SOURCE" | tail -n 1 | sed -E 's|.+\[(.+)\]|\1|')" 2>/dev/null)

            if [ "$CURRENT_SOURCE_REALPATH" == "${PATH_BINHOSTS_PS3_GENTOO_DEFAULT}" ]; then
                echo "${PATH_BINHOSTS_PS3_GENTOO_DEFAULT} is already bound with ${PATH_CATALYST_BINHOST_DEFAULT}."
            else
                failure "${PATH_BINHOSTS_PS3_GENTOO_DEFAULT} is already bound with ${CURRENT_SOURCE_REALPATH}, not ${PATH_BINHOSTS_PS3_GENTOO_DEFAULT}."
            fi
        else
            # Bind binhost
            mount -o bind "${PATH_BINHOSTS_PS3_GENTOO_DEFAULT}" "${PATH_CATALYST_BINHOST_DEFAULT}"
            echo "Successfully bounded ${PATH_BINHOSTS_PS3_GENTOO_DEFAULT} to ${PATH_CATALYST_BINHOST_DEFAULT}"
        fi
        ;;
    --unbind)
        # Unbind binhost
        umount "${PATH_CATALYST_BINHOST_DEFAULT}"
        echo "Successfully unbounded ${PATH_CATALYST_BINHOST_DEFAULT}"
        ;;
    *)
        # Unsupported option
        show_usage
        ;;
esac
