#!/bin/bash

source ../../.env-shared.sh || exit 1

# Copy patches for catalyst.
for PATCH in "${PATH_CATALYST_PATCHES_SRC}"/*.patch; do
    PATCH_NAME=$(printf "%04d.patch" $((i+1)))
    cp -f "${PATCH}" "${PATH_CATALYST_PATCHES_DST}/${PATCH_NAME}"
done

# Install Catalyst
unmask_package "dev-util/catalyst" "**"
unmask_package "sys-fs/squashfs-tools-ng" # Unmask arch mask only.
use_set_package "sys-apps/util-linux" "python"
emerge dev-util/catalyst --newuse --update --deep

# Create working directories
for RELEASE_NAME in ${CONF_RELEASE_TYPES[@]}; do
    mkdir -p "${PATH_CATALYST_BUILDS}/${RELEASE_NAME}"
    mkdir -p "${PATH_CATALYST_PACKAGES}/${RELEASE_NAME}"
done
mkdir -p "${PATH_CATALYST_STAGES}"

# Configure Catalyst
sed -i 's/\(\s*\)# "pkgcache",/\1"pkgcache",/' "${PATH_CATALYST_CONF}"
update_config_assign_space jobs "${CONF_CATALYST_JOBS}" "${PATH_CATALYST_CONF}"
update_config_assign_space load-average "${CONF_CATALYST_LOAD}" "${PATH_CATALYST_CONF}"
update_config_assign_space binhost "${URL_GITHUB_RAW_BINHOSTS}" "${PATH_CATALYST_CONF}"

# Configure CELL settings for Catalyst
readonly AWK_PPC_TOML_EXPR='
BEGIN { inside_section = 0 }
{
    if ($0 ~ /^\[ppc64\.cell\]$/) {
        inside_section = 1
    } else if ($0 ~ /^\[.*\]/) {
        if (inside_section == 1) {
            inside_section = 0
        }
    }
    if (inside_section == 1) {
        if ($0 ~ /^COMMON_FLAGS/) {
            print "COMMON_FLAGS = \"'${CONF_TARGET_COMMON_FLAGS}'\""
        } else if ($0 ~ /^USE/) {
            print "USE = [ ${CONF_RELENG_USE_FLAGS},]"
        } else {
            print  # Retain any other lines within the section
        }
    } else {
        print  # Retain the original lines outside the section
    }
}'
readonly TEMP_FILE_TOML=$(mktemp)
awk "${AWK_PPC_TOML_EXPR}" "${PATH_CATALYST_PPC_TOML}" > "${TEMP_FILE_TOML}"
mv "${TEMP_FILE_TOML}" "${PATH_CATALYST_PPC_TOML}"
