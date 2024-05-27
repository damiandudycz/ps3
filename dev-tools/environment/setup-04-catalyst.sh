#!/bin/bash

# This script emerges, patches and configures catalyst.

# --- Shared environment
source ../../.env-shared.sh || exit 1
trap failure ERR

# Constants
readonly CONF_JOBS="8"
readonly CONF_LOAD="12.0"

readonly PATH_CATALYST_CONFIGS="${PATH_ETC}/catalyst"
readonly PATH_CATALYST_CONF="${PATH_CATALYST_CONFIGS}/catalyst.conf"
readonly PATH_CATALYST_PPC_TOML="${PATH_CATALYST_USR}/arch/ppc.toml"
readonly PATH_ACCEPT_KEYWORDS_CATALYST="${PATH_ETC_PORTAGE_PACKAGE_ACCEPT_KEYWORDS}/PS3_ENV_dev-util_catalyst"
readonly PATH_PACKAGE_USE_CATALYST="${PATH_ETC_PORTAGE_PACKAGE_USE}/PS3_ENV_dev-util_catalyst"
readonly PATH_FILES_CATALYST_PATCHES="${PATH_DEV_TOOLS_ENVIRONMENT}/data/catalyst-patches"

# Apply patches to Catalyst scripts if missing
mkdir -p "${PATH_CATALYST_PATCH_DIR}"
readonly PATCH_URLS="$(find ${PATH_FILES_CATALYST_PATCHES} -maxdepth 1 -type f -name '*.patch' | sort)"
for PATCH in ${PATCH_URLS[@]}; do
    PATCH_NAME=$(printf "%04d.patch" $((i+1)))
    cp "${PATCH}" "${PATH_CATALYST_PATCH_DIR}/${PATCH_NAME}"
done

# Install Catalyst
if [ ! -f "${PATH_ACCEPT_KEYWORDS_CATALYST}" ]; then
    echo "# Catalyst requirements" >> "${PATH_ACCEPT_KEYWORDS_CATALYST}"
    echo "dev-util/catalyst **" >> "${PATH_ACCEPT_KEYWORDS_CATALYST}"
    echo "sys-fs/squashfs-tools-ng ~*" >> "${PATH_ACCEPT_KEYWORDS_CATALYST}"
    echo "sys-apps/util-linux python" >> "${PATH_PACKAGE_USE_CATALYST}"
fi
emerge dev-util/catalyst --newuse --update --deep

# Create working directories
mkdir -p "${PATH_CATALYST_BUILDS}"
mkdir -p "${PATH_CATALYST_STAGES}"
mkdir -p "${PATH_CATALYST_BINHOST}"

# Configure Catalyst
sed -i 's/\(\s*\)# "pkgcache",/\1"pkgcache",/' "${PATH_CATALYST_CONF}"
sed -i "/^jobs\s*=/c\jobs = ${CONF_JOBS}" "${PATH_CATALYST_CONF}" || echo "jobs = ${CONF_JOBS}" >> "${PATH_CATALYST_CONF}"
sed -i "/^load-average\s*=/c\load-average = ${CONF_LOAD}" "${PATH_CATALYST_CONF}" || echo "load-average = ${CONF_LOAD}" >> "${PATH_CATALYST_CONF}"
sed -i "/^binhost\s*=/c\binhost = \"${URL_BINHOST}/\"" "${PATH_CATALYST_CONF}" || echo "binhost = \"${URL_BINHOST}/\"" >> "${PATH_CATALYST_CONF}"

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
awk "${AWK_PPC_TOML_EXPR}" "${PATH_CATALYST_PPC_TOML}" > "${TEMP_FILE_TOML}"
mv "${TEMP_FILE_TOML}" "${PATH_CATALYST_PPC_TOML}"
