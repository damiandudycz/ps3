#!/bin/bash

source ../../.env-shared.sh --silent || exit 1
source "${PATH_EXTRA_ENV_KERNEL_EBUILD}" || failure "Failed to load env ${PATH_EXTRA_ENV_KERNEL_EBUILD}"

# Check if latest files are stored.
readonly EBUILD_FILES_DIFF=$(diff "${KE_PATH_EBUILD_FILE_DST}" "${KE_PATH_OVERLAY_EBUILD_FILE_PACKAGE}" 2> /dev/null) || failure "Files ${KE_PATH_EBUILD_FILE_DST} ${KE_PATH_OVERLAY_EBUILD_FILE_PACKAGE} differ"
[[ ! ${EBUILD_FILES_DIFF} ]] || failure "Current version of ebuild not stored in overlay."

empty_directory "${KE_PATH_WORK_BINPKGS}"
empty_directory "${PATH_CROSSDEV_BINPKGS}"

# Copy everything from distfiles overlay to cache, so that it's available during emerge even if packages were not yet uploaded to git.
source ${PATH_OVERLAY_SCRIPT_COPY_PS3_FILES}

# Build package using crossdev.
PORTDIR_OVERLAY="${PATH_OVERLAYS_PS3_GENTOO}" USE="${KE_PACKAGE_USE}" ${CONF_CROSSDEV_TARGET}-emerge --buildpkgonly "=${KE_NAME_PACKAGE_DST_VERSIONED}"

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
