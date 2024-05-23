#!/bin/bash

# This script uploads the newest version of generated release files.
# Please use after finishing release-build.sh.
# Script also updates the metadata files:
# latest-stage3-cell-openrc.txt, latest-install-cell-minimal.txt.

# Error handling function
die() {
    echo "$*" 1>&2
    exit 1
}

# Paths
readonly PATH_START=$(dirname "$(realpath "$0")") || die
readonly PATH_ROOT=$(realpath -m "${PATH_START}/../..") || die
readonly PATH_ENV_READY="${PATH_ROOT}/local/env_ready"
readonly PATH_LOCAL_TMP="${PATH_ROOT}/local/release"
readonly PATH_REPO_AUTOBUILDS="${PATH_ROOT}/autobuilds/ps3-gentoo-autobuilds"
readonly PATH_CATALYST_BUILDS="/var/tmp/catalyst/builds/default"
readonly PATH_RELEASE_INFO="${PATH_LOCAL_TMP}/release_latest"

# Check if env is ready
[ -f "${PATH_ENV_READY}" ] || die "Dev environment was not initialized. Please run dev-tools/setup-environment.sh first."

# Release information
readonly TIMESTAMP=$(cat "${PATH_RELEASE_INFO}") || die "Failed to read current release details. Please run release-prepare.sh first."
[ -z "${TIMESTAMP}" ] && die "Failed to read current release details. Please run release-prepare.sh first."

# Release files paths
readonly PATH_CATALYST_BUILD_STAGE3="${PATH_CATALYST_BUILDS}/stage3-cell-openrc-${TIMESTAMP}.tar.xz"
readonly PATH_CATALYST_BUILD_ISO="${PATH_CATALYST_BUILDS}/install-cell-minimal-${TIMESTAMP}.iso"
[ -f "$PATH_CATALYST_BUILD_STAGE3" ] || die "Stage3 not found at ${PATH_CATALYST_BUILD_STAGE3}. Please run release-build.sh first."
[ -f "$PATH_CATALYST_BUILD_ISO" ] || die "ISO not found at ${PATH_CATALYST_BUILD_ISO}. Please run release-build.sh first."
readonly PATH_AUTOBUILDS_NEW="${PATH_REPO_AUTOBUILDS}/${TIMESTAMP}"
mkdir "${PATH_AUTOBUILDS_NEW}" || die "Failed to crate autobuilds location at ${PATH_AUTOBUILDS_NEW}"

# Move files to autobuilds
cp "${PATH_CATALYST_BUILD_STAGE3}"* "${PATH_AUTOBUILDS_NEW}"/ || die "Failed to move Stage3 files to autobuilds"
cp "${PATH_CATALYST_BUILD_ISO}"* "${PATH_AUTOBUILDS_NEW}"/ || die "Failed to move ISO files to autobuilds"

# Generate autobuilds metadata
TIMESTAMP_FORMATTED=$(echo $TIMESTAMP | sed -r 's/(.*)T(..)(..)(..)/\1 \2:\3:\4/')
FORMATTED_DATE=$(date -u -d "${TIMESTAMP_FORMATTED}" +"%a, %d %b %Y %H:%M:%S %z") || die "Failed to update metadata"
EPOCH_TIME=$(date -u -d "${TIMESTAMP_FORMATTED}" +%s) || die "Failed to update metadata"
echo "# Latest as of ${FORMATTED_DATE}" > "${PATH_REPO_AUTOBUILDS}/latest-stage3-cell-openrc.txt" || die "Failed to update metadata"
echo "# ts=${EPOCH_TIME}" >> "${PATH_REPO_AUTOBUILDS}/latest-stage3-cell-openrc.txt" || die "Failed to update metadata"
echo "${TIMESTAMP}/stage3-cell-openrc-${TIMESTAMP}.tar.xz $(stat -c%s ${PATH_AUTOBUILDS_NEW}/stage3-cell-openrc-${TIMESTAMP}.tar.xz)" >> "${PATH_REPO_AUTOBUILDS}/latest-stage3-cell-openrc.txt" || die "Failed to update metadata"
echo "# Latest as of ${FORMATTED_DATE}" > "${PATH_REPO_AUTOBUILDS}/latest-install-cell-minimal.txt" || die "Failed to update metadata"
echo "# ts=${EPOCH_TIME}" >> "${PATH_REPO_AUTOBUILDS}/latest-install-cell-minimal.txt" || die "Failed to update metadata"
echo "${TIMESTAMP}/install-cell-minimal-${TIMESTAMP}.iso $(stat -c%s ${PATH_AUTOBUILDS_NEW}/install-cell-minimal-${TIMESTAMP}.iso)" >> "${PATH_REPO_AUTOBUILDS}/latest-install-cell-minimal.txt" || die "Failed to update metadata"

# Upload autobuilds
cd "${PATH_REPO_AUTOBUILDS}" || die "Failed to open PATH_REPO_AUTOBUILDS"
git add -A || die "Failed to add files to repo"
git commit -m "Autobuilds automatic update (Catalyst release)" || die "Failed to commit files to repo"
git push || die "Failed to push files to repo"
cd "${PATH_START}" || die "Failed to return to starting location"

exit 0
