#!/bin/bash

source ../../.env-shared.sh || exit 1

# Copy patches for catalyst.
mkdir -p "${PATH_CATALYST_PATCHES_DST}"
i=0
for PATCH in "${PATH_CATALYST_PATCHES_SRC}"/*.patch; do
    i=$((i + 1))
    PATCH_NAME=$(printf "%04d.patch" ${i})
    cp -f "${PATCH}" "${PATH_CATALYST_PATCHES_DST}/${PATCH_NAME}"
done

# Install Catalyst
unmask_package "dev-util/catalyst" "**"
unmask_package "sys-fs/squashfs-tools-ng" # Unmask arch mask only.
use_set_package "sys-apps/util-linux" "python"
emerge dev-util/catalyst --newuse --update --deep
