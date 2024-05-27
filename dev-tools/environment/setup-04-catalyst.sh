#!/bin/bash

# This script emerges, patches and configures catalyst.

# --- Shared environment --- # Imports shared environment configuration,
source ../../.env-shared.sh  # patches and functions.
trap failure ERR             # Sets a failure trap on any error.
# -------------------------- #

# Constants
readonly CONF_JOBS="8"
readonly CONF_LOAD="12.0"

readonly PATH_CATALYST_USR="${PATH_USR_SHARE}/catalyst"
readonly PATH_CATALYST_TMP="${PATH_VAR_TMP}/catalyst"
readonly PATH_CATALYST_CONFIGS="${PATH_ETC}/catalyst"
readonly PATH_CATALYST_BUILDS="${PATH_CATALYST_TMP}/builds/default"
readonly PATH_CATALYST_STAGES="${PATH_CATALYST_TMP}/config/stages"
readonly PATH_CATALYST_BINHOST="${PATH_CATALYST_TMP}/packages/default"
readonly PATH_CATALYST_PATCH_DIR="${PATH_ETC_PORTAGE}/patches/dev-util/catalyst"
readonly PATH_CATALYST_CONF="${PATH_CATALYST_CONFIGS}/catalyst.conf"
readonly PATH_CATALYST_PPC_TOML="${PATH_CATALYST_USR}/arch/ppc.toml"
readonly PATH_ACCEPT_KEYWORDS="${PATH_ETC_PORTAGE}/package.accept_keywords/PS3_ENV_dev-util_catalyst"
readonly PATH_PACKAGE_USE="${PATH_ETC_PORTAGE}/package.use/PS3_ENV_dev-util_catalyst"
readonly PATCH_FILES_CATALYST_PATCHES="${PATH_DEV_TOOLS_ENVIRONMENT}/data/catalyst-patches"

# Apply patches to Catalyst scripts if missing
mkdir -p "${PATH_CATALYST_PATCH_DIR}"
readonly PATCH_URLS="$(find ${PATCH_FILES_CATALYST_PATCHES} -maxdepth 1 -type f -name '*.patch' | sort)"
for ((i=0; i<${#PATCH_URLS[@]}; i++)); do
    PATCH="${PATCH_URLS[i]}"
    PATCH_NAME=$(printf "%04d.patch" $((i+1)))
    if [ ! -f "${PATH_CATALYST_PATCH_DIR}/${PATCH_NAME}" ]; then
        cp "${PATCH}" "${PATH_CATALYST_PATCH_DIR}/${PATCH_NAME}"
    fi
done

# Install Catalyst
if [ ! -f "${PATH_ACCEPT_KEYWORDS}" ]; then
    echo "# Catalyst requirements" >> "${PATH_ACCEPT_KEYWORDS}"
    echo "dev-util/catalyst **" >> "${PATH_ACCEPT_KEYWORDS}"
    echo "sys-fs/squashfs-tools-ng ~*" >> "${PATH_ACCEPT_KEYWORDS}"
    echo "sys-apps/util-linux python" >> "${PATH_PACKAGE_USE}"
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

exit 0
