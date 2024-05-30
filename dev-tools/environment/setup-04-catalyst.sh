#!/bin/bash

source ../../.env-shared.sh || exit 1
source "${PATH_EXTRA_ENV_ENVIRONMENT}" || failure "Failed to load env ${PATH_EXTRA_ENV_ENVIRONMENT}"

empty_directory "${EN_PATH_CATALYST_PATCH_DIR}"

# Apply patches to Catalyst scripts if missing
for PATCH in ${EN_PATH_PATCH_PATHS[@]}; do
    PATCH_NAME=$(printf "%04d.patch" $((i+1)))
    cp "${PATCH}" "${EN_PATH_CATALYST_PATCH_DIR}/${PATCH_NAME}"
done

# Install Catalyst
unmask_package "dev-util/catalyst" "**"
unmask_package "sys-fs/squashfs-tools-ng" "~*"
use_set_package "sys-apps/util-linux" "python"
emerge dev-util/catalyst --newuse --update --deep

# Create working directories
for RELEASE_NAME in ${CONF_CATALYST_RELEASE_NAMES[@]}; do
    mkdir -p "${EN_PATH_CATALYST_BUILDS}/${RELEASE_NAME}"
    mkdir -p "${EN_PATH_CATALYST_PACKAGES}/${RELEASE_NAME}"
done
mkdir -p "${EN_PATH_CATALYST_STAGES}"

# Configure Catalyst
sed -i 's/\(\s*\)# "pkgcache",/\1"pkgcache",/' "${EN_PATH_CATALYST_CONF}"
update_config_assign_space jobs "${EN_CONF_CATALYST_JOBS}" "${EN_PATH_CATALYST_CONF}"
update_config_assign_space load-average "${EN_CONF_CATALYST_LOAD}" "${EN_PATH_CATALYST_CONF}"
update_config_assign_space binhost "${URL_GITHUB_RAW_BINHOSTS}" "${EN_PATH_CATALYST_CONF}"

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
            print "COMMON_FLAGS = \"-O2 -pipe -mcpu=cell -mtune=cell -mabi=altivec -mno-string -mno-update -mno-multiple\""
        } else if ($0 ~ /^USE/) {
            print "USE = [ \"altivec\", \"ibm\", \"ps3\",]"
        } else {
            print  # Retain any other lines within the section
        }
    } else {
        print  # Retain the original lines outside the section
    }
}'
readonly TEMP_FILE_TOML=$(mktemp)
awk "${AWK_PPC_TOML_EXPR}" "${EN_PATH_CATALYST_PPC_TOML}" > "${TEMP_FILE_TOML}"
mv "${TEMP_FILE_TOML}" "${EN_PATH_CATALYST_PPC_TOML}"
