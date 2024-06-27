#!/bin/bash

source ../../.env-shared.sh --silent || exit 1

# Build package using crossdev.
PORTDIR_OVERLAY="${PATH_OVERLAYS_PS3_GENTOO}" ${CONF_CROSSDEV_TARGET}-emerge --buildpkg --oneshot "$1"

exit

# Save binpkgs generaged by crossdev in KE_PATH_WORK_PKG.
cp "${KE_PATH_CROSSDEV_BINPKGS_KERNEL_PACKAGE}"/* "${KE_PATH_WORK_BINPKGS}"/
current_section=()
in_section=false
while IFS= read -r line; do
    if [[ "$line" == CPV:* ]]; then
        if [[ "$line" == CPV:\ sys-kernel/gentoo-kernel-ps3* ]]; then
            current_section=("$line")
            in_section=true
        else
            in_section=false
        fi
    else
        if $in_section; then
            current_section+=("$line")
        fi
    fi
done < "${KE_PATH_BINPKGS_PACKAGES_SRC}"
echo ""
echo "/var/cache/binpkgs/Packages entry:"
echo ""
for line in "${current_section[@]}"; do
    echo "${line}"
    echo "${line}" >> "${KE_PATH_BINPKGS_PACKAGES_DST}"
done
