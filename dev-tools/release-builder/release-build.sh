#!/bin/bash

# Error handling function
die() {
    echo "$*" 1>&2
    exit 1
}

# Error handling and cleanup function
cleanup() {
    umount "${PATH_CATALYST_PACKAGES}" || echo "Failed to umount binhost."
}
trap cleanup EXIT

# Paths
readonly PATH_START=$(dirname "$(realpath "$0")") || die
readonly PATH_ROOT=$(realpath -m "${PATH_START}/../..") || die
readonly PATH_ENV_READY="${PATH_ROOT}/local/env_ready"
readonly PATH_LOCAL_TMP="${PATH_ROOT}/local/release_test"
readonly PATH_CATALYST_PACKAGES="/var/tmp/catalyst/packages/default"
readonly PATH_REPO_BINHOST="${PATH_ROOT}/binhosts/ps3-gentoo-binhosts/default"
readonly PATH_RELEASE_INFO="${PATH_LOCAL_TMP}/release_latest"
readonly PATH_INSTALLER_UPDATER="${PATH_ROOT}/dev-tools/ps3-gentoo-installer/ps3-gentoo-installer-ebuild-updater.sh "

# URLs
readonly URL_RELEASE_GENTOO="https://gentoo.osuosl.org/releases/ppc/autobuilds/current-stage3-ppc64-openrc"
readonly URL_STAGE_INFO="https://gentoo.osuosl.org/releases/ppc/autobuilds/latest-stage3-ppc64-openrc.txt"

# Check if env is ready
[ -f "${PATH_ENV_READY}" ] || die "Dev environment was not initialized. Please run dev-tools/setup-environment.sh first."

# Ask if should update installer if there are any changes pending.
$PATH_INSTALLER_UPDATER --ask

# Release information
readonly TIMESTAMP=$(cat "${PATH_RELEASE_INFO}") || die "Failed to read current release details. Please run release-prepare.sh first."
[ -z "${TIMESTAMP}" ] && die "Failed to read current release details. Please run release-prepare.sh first."

# Release files paths
readonly PATH_STAGE1="${PATH_LOCAL_TMP}/stage1-cell.$TIMESTAMP.spec"
readonly PATH_STAGE3="${PATH_LOCAL_TMP}/stage3-cell.$TIMESTAMP.spec"
readonly PATH_STAGE1_INSTALLCD="${PATH_LOCAL_TMP}/stage1-cell.installcd.$TIMESTAMP.spec"
readonly PATH_STAGE2_INSTALLCD="${PATH_LOCAL_TMP}/stage2-cell.installcd.$TIMESTAMP.spec"

# Bind binhost
mount -o bind "${PATH_REPO_BINHOST}" "${PATH_CATALYST_PACKAGES}" || die "Failed to mount binhost repo ${PATH_REPO_BINHOST} to ${PATH_CATALYST_PACKAGES}"

# Building release
catalyst -f "${PATH_STAGE1}" || die "Failed to build stage1"
catalyst -f "${PATH_STAGE3}" || die "Failed to build stage3"
catalyst -f "${PATH_STAGE1_INSTALLCD}" || die "Failed o build stage1.installcd"
catalyst -f "${PATH_STAGE2_INSTALLCD}" || die "Failed to build stage2.installcd"

exit 0
