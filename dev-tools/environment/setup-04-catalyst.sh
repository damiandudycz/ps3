#!/bin/bash

# This script emerges, patches and configures catalyst.

# Error handling function
die() {
    echo "$*" 1>&2
    exit 1
}

# Error handling and cleanup function
cleanup() {
    rm -f "${TEMP_FILE}" || echo "Failed to remove temporary file: ${TEMP_FILE}" 1>&2
}
trap cleanup EXIT

# Constants
readonly PATH_START=$(dirname "$(realpath "$0")") || die
readonly PATH_ROOT=$(realpath -m "${PATH_START}/../..") || die
readonly PATH_LOCAL_TMP="${PATH_ROOT}/local/release"
readonly PATH_CATALYST_USR="/usr/share/catalyst"
readonly PATH_CATALYST_TMP="/var/tmp/catalyst"
readonly PATH_CATALYST_CONFIGS="/etc/catalyst"
readonly PATH_CATALYST_BUILDS="${PATH_CATALYST_TMP}/builds/default"
readonly PATH_CATALYST_STAGES="${PATH_CATALYST_TMP}/config/stages"
readonly PATH_CATALYST_BINHOST="${PATH_CATALYST_TMP}/packages/default"
readonly PATH_CATALYST_PATCH_DIR="/etc/portage/patches/dev-util/catalyst"
readonly PATH_CATALYST_CONF="${PATH_CATALYST_CONFIGS}/catalyst.conf"
readonly PATH_PPC_TOML="${PATH_CATALYST_USR}/arch/ppc.toml"
readonly PATH_PORTAGE="/etc/portage"
readonly PATH_ACCEPT_KEYWORDS="${PATH_PORTAGE}/package.accept_keywords/dev-util_catalyst"
readonly PATH_PACKAGE_USE="${PATH_PORTAGE}/package.use/dev-util_catalyst"
readonly CONF_JOBS="8"
readonly CONF_LOAD="12.0"
readonly URL_BINHOST="https://raw.githubusercontent.com/damiandudycz/ps3-gentoo-binhosts/main"

# Array of patch URLs
declare -a PATCH_URLS=(
    "${PATH_START}/data/catalyst-patches/0001-Introduce-basearch-settings.patch"
    "${PATH_START}/data/catalyst-patches/0002-Fix-missing-vmlinux-filename-support.patch"
)

# AWK expression for modifying ppc.toml
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

# Exit if Catalyst is already set up
if [ -d "${PATH_CATALYST_USR}" ]; then
    echo "Catalyst is already installed. Skipping setup."
    exit 0
fi

# Apply patches to Catalyst scripts if missing
mkdir -p "${PATH_CATALYST_PATCH_DIR}" || die "Failed to create patch directory: ${PATH_CATALYST_PATCH_DIR}"
for ((i=0; i<${#PATCH_URLS[@]}; i++)); do
    PATCH="${PATCH_URLS[i]}"
    PATCH_NAME=$(printf "%04d.patch" $((i+1)))
    if [ ! -f "${PATH_CATALYST_PATCH_DIR}/${PATCH_NAME}" ]; then
        cp "${PATCH}" "${PATH_CATALYST_PATCH_DIR}/${PATCH_NAME}" || die "Failed to copy patch: ${PATCH}"
    fi
done

# Install Catalyst
if [ ! -f "${PATH_ACCEPT_KEYWORDS}" ]; then
    echo "# Catalyst requirements" >> "${PATH_ACCEPT_KEYWORDS}" || die "Failed to update package.accept_keywords"
    echo "dev-util/catalyst **" >> "${PATH_ACCEPT_KEYWORDS}" || die "Failed to update package.accept_keywords"
    echo "sys-fs/squashfs-tools-ng ~*" >> "${PATH_ACCEPT_KEYWORDS}" || die "Failed to update package.accept_keywords"
    echo "sys-apps/util-linux python" >> "${PATH_PACKAGE_USE}" || die "Failed to update package.use"
fi
emerge dev-util/catalyst -q || die "Failed to emerge catalyst"

# Create working directories
mkdir -p "${PATH_CATALYST_BUILDS}" || die "Failed to create build directory: ${PATH_CATALYST_BUILDS}"
mkdir -p "${PATH_CATALYST_STAGES}" || die "Failed to create stages directory: ${PATH_CATALYST_STAGES}"
mkdir -p "${PATH_CATALYST_BINHOST}" || die "Failed to create binhost directory: ${PATH_CATALYST_BINHOST}"

# Configure Catalyst
sed -i 's/\(\s*\)# "pkgcache",/\1"pkgcache",/' "${PATH_CATALYST_CONF}" || die "Failed to update catalyst.conf"
echo "jobs = ${CONF_JOBS}" >> "${PATH_CATALYST_CONF}" || die "Failed to update catalyst.conf"
echo "load-average = ${CONF_LOAD}" >> "${PATH_CATALYST_CONF}" || die "Failed to update catalyst.conf"
echo "binhost = \"${URL_BINHOST}/\"" >> "${PATH_CATALYST_CONF}" || die "Failed to update catalyst.conf"

# Configure CELL settings for Catalyst
readonly TEMP_FILE=$(mktemp) || die "Failed to create temporary file"
awk "${AWK_PPC_TOML_EXPR}" "${PATH_PPC_TOML}" > "${TEMP_FILE}" || die "Failed to modify ppc.toml"
mv "${TEMP_FILE}" "${PATH_PPC_TOML}" || die "Failed to move modified ppc.toml"

exit 0
