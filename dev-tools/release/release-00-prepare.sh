#!/bin/bash

# This script prepares catalyst files for a new release.
# It will fetch the new snapshot and seed, and then generage spec files.
# At the beggining it also checks if there is a need to release a new ps3-gentoo-installer
# ebuild, and asks if you want to release it first, so that it can be used in the new build.

# Error handling function
die() {
    echo "$*" 1>&2
    exit 1
}

# Configuration
readonly TIMESTAMP=$(date -u +"%Y%m%dT%H%M%SZ")
readonly CONF_JOBS="8"
readonly CONF_LOAD="12.0"

# Paths
readonly PATH_START=$(dirname "$(realpath "$0")") || die
readonly PATH_ROOT=$(realpath -m "${PATH_START}/../..") || die
readonly PATH_ENV_READY="${PATH_ROOT}/.env_ready"
readonly PATH_LOCAL_TMP="/var/tmp/ps3/release"
readonly PATH_CATALYST_BUILDS="/var/tmp/catalyst/builds/default"
readonly PATH_PKG_CACHE="${PATH_ROOT}/binhosts/ps3-gentoo-binhosts/default"
readonly PATH_OVERLAY="${PATH_ROOT}/overlays/ps3-gentoo-overlay"
readonly PATH_STAGE1="${PATH_LOCAL_TMP}/stage1-cell.$TIMESTAMP.spec"
readonly PATH_STAGE3="${PATH_LOCAL_TMP}/stage3-cell.$TIMESTAMP.spec"
readonly PATH_STAGE1_INSTALLCD="${PATH_LOCAL_TMP}/stage1-cell.installcd.$TIMESTAMP.spec"
readonly PATH_STAGE2_INSTALLCD="${PATH_LOCAL_TMP}/stage2-cell.installcd.$TIMESTAMP.spec"
readonly PATH_LIVECD_OVERLAY_ORIGINAL="${PATH_START}/data/iso_overlay"
readonly PATH_LIVECD_OVERLAY="${PATH_LOCAL_TMP}/iso_overlay"
readonly PATH_LIVECD_FSSCRIPT_ORIGINAL="${PATH_START}/data/iso_fsscript.sh"
readonly PATH_LIVECD_FSSCRIPT="${PATH_LOCAL_TMP}/iso_fsscript.sh"
readonly PATH_INTERPRETER="/usr/bin/qemu-ppc64"
readonly PATH_SNAPSHOT_LOG="${PATH_LOCAL_TMP}/snapshot_log.txt"
readonly PATH_RELENG="/var/tmp/ps3/releng"
readonly PATH_RELEASE_INFO="${PATH_LOCAL_TMP}/release_latest"
readonly PATH_INSTALLER_UPDATER="${PATH_ROOT}/dev-tools/ps3-installer/ps3-gentoo-installer-ebuild-updater.sh "

PATH_PORTAGE_CONFDIR_STAGES="${PATH_RELENG}/releases/portage/stages"
PATH_PORTAGE_CONFDIR_ISOS="${PATH_RELENG}/releases/portage/isos"

# URLs
readonly URL_RELEASE_GENTOO="https://gentoo.osuosl.org/releases/ppc/autobuilds"
readonly URL_STAGE_INFO="https://gentoo.osuosl.org/releases/ppc/autobuilds/latest-stage3-ppc64-openrc.txt"

# Determine if host is PS3 or another architecture
[ "$(uname -m)" != "ppc64" ] && use_qemu=true

if [ "${use_qemu}" ]; then
    PATH_PORTAGE_CONFDIR_STAGES="${PATH_PORTAGE_CONFDIR_STAGES}-qemu"
    PATH_PORTAGE_CONFDIR_ISOS="${PATH_PORTAGE_CONFDIR_ISOS}-qemu"
    INTERPRETER="interpreter: ${PATH_INTERPRETER}"
fi

# Check if env is ready
[ -f "${PATH_ENV_READY}" ] || die "Dev environment was not initialized. Please run dev-tools/setup-environment.sh first."

# Ask if should update installer if there are any changes pending.
$PATH_INSTALLER_UPDATER --ask || die "Failed to run installer updater."

# Create local tmp path
mkdir -p "${PATH_LOCAL_TMP}" || die "Failed to create local tmp directory"

# Copy helper files
cp -rf "${PATH_LIVECD_OVERLAY_ORIGINAL}" "${PATH_LIVECD_OVERLAY}" || die "Failed to copy iso overlay"
cp "${PATH_LIVECD_FSSCRIPT_ORIGINAL}" "${PATH_LIVECD_FSSCRIPT}" || die "Failed to copy fsscript"

# Download current snapshot
[ -f "${PATH_SNAPSHOT_LOG}" ] && rm -f "${PATH_SNAPSHOT_LOG}"
catalyst --snapshot stable | tee "${PATH_SNAPSHOT_LOG}" || die "Failed to download current snapshot"
readonly SQUASHFS_IDENTIFIER=$(grep -oP 'Creating gentoo tree snapshot \K[0-9a-f]{40}' "${PATH_SNAPSHOT_LOG}")

# Download stage3 seed
readonly LATEST_GENTOO_CONTENT=$(wget -q -O - "${URL_STAGE_INFO}" --no-http-keep-alive --no-cache --no-cookies) || die "Failed to download latest stage3 seed"
readonly LATEST_STAGE3=$(echo "${LATEST_GENTOO_CONTENT}" | grep "ppc64-openrc" | head -n 1 | cut -d' ' -f1)
readonly LATEST_STAGE3_FILENAME=$(basename "${LATEST_STAGE3}") || die "Failed to get stage3 filename"
readonly SEED_TIMESTAMP=$(echo "${LATEST_STAGE3_FILENAME}" | sed -n 's/.*-\([0-9]\{8\}T[0-9]\{6\}Z\)\.tar\.xz/\1/p') || die "Failed to get seed timestamp"
readonly PATH_STAGE3_SEED="${PATH_CATALYST_BUILDS}/${LATEST_STAGE3_FILENAME}"
readonly URL_GENTOO_TARBALL="$URL_RELEASE_GENTOO/$LATEST_STAGE3"
[ -z "${LATEST_STAGE3}" ] && die "Failed to download Stage3 URL"
[ -f "${PATH_STAGE3_SEED}" ] || wget "${URL_GENTOO_TARBALL}" -O "${PATH_STAGE3_SEED}" || die "Failed to download stage3 seed"

# Prepare spec files
cp "$PATH_START/data/spec/stage1-cell.spec" "$PATH_STAGE1" || die "Failed to copy stage1 spec file"
cp "$PATH_START/data/spec/stage3-cell.spec" "$PATH_STAGE3" || die "Failed to copy stage3 spec file"
cp "$PATH_START/data/spec/stage1-cell.installcd.spec" "$PATH_STAGE1_INSTALLCD" || die "Failed to copy stage1 installcd spec file"
cp "$PATH_START/data/spec/stage2-cell.installcd.spec" "$PATH_STAGE2_INSTALLCD" || die "Failed to copy stage2 installcd spec file"

# Substitute placeholders with actual values in spec files
sed -i "s|@TREEISH@|${SQUASHFS_IDENTIFIER}|g" "$PATH_STAGE1" || die "Failed to substitute TREEISH in stage1 spec file"
sed -i "s|@TREEISH@|${SQUASHFS_IDENTIFIER}|g" "$PATH_STAGE3" || die "Failed to substitute TREEISH in stage3 spec file"
sed -i "s|@TREEISH@|${SQUASHFS_IDENTIFIER}|g" "$PATH_STAGE1_INSTALLCD" || die "Failed to substitute TREEISH in stage1 installcd spec file"
sed -i "s|@TREEISH@|${SQUASHFS_IDENTIFIER}|g" "$PATH_STAGE2_INSTALLCD" || die "Failed to substitute TREEISH in stage2 installcd spec file"
sed -i "s|@SEEDTIMESTAMP@|${SEED_TIMESTAMP}|g" "$PATH_STAGE1" "$PATH_STAGE1_INSTALLCD" "$PATH_STAGE2_INSTALLCD" || die "Failed to substitute SEEDTIMESTAMP in spec files"
sed -i "s|@TIMESTAMP@|${TIMESTAMP}|g" "$PATH_STAGE1" "$PATH_STAGE3" "$PATH_STAGE1_INSTALLCD" "$PATH_STAGE2_INSTALLCD" || die "Failed to substitute TIMESTAMP in spec files"
sed -i "s|@PORTAGE_CONFDIR@|${PATH_PORTAGE_CONFDIR_STAGES}|g" "$PATH_STAGE1" || die "Failed to substitute PORTAGE_CONFDIR in stage1 spec file"
sed -i "s|@PORTAGE_CONFDIR@|${PATH_PORTAGE_CONFDIR_STAGES}-cell|g" "$PATH_STAGE3" || die "Failed to substitute PORTAGE_CONFDIR in stage3 spec file"
sed -i "s|@PORTAGE_CONFDIR@|${PATH_PORTAGE_CONFDIR_ISOS}|g" "$PATH_STAGE1_INSTALLCD" || die "Failed to substitute PORTAGE_CONFDIR in stage1 installcd spec file"
sed -i "s|@PORTAGE_CONFDIR@|${PATH_PORTAGE_CONFDIR_ISOS}-cell|g" "$PATH_STAGE2_INSTALLCD" || die "Failed to substitute PORTAGE_CONFDIR in stage2 installcd spec file"
sed -i "s|@PKGCACHE_PATH@|${PATH_PKG_CACHE}|g" "$PATH_STAGE1" "$PATH_STAGE3" "$PATH_STAGE1_INSTALLCD" "$PATH_STAGE2_INSTALLCD" || die "Failed to substitute PKGCACHE_PATH in spec files"
sed -i "s|@INTERPRETER@|${INTERPRETER}|g" "$PATH_STAGE1" "$PATH_STAGE3" "$PATH_STAGE1_INSTALLCD" "$PATH_STAGE2_INSTALLCD" || die "Failed to substitute INTERPRETER in spec files"
sed -i "s|@REPOS@|${PATH_OVERLAY}|g" "$PATH_STAGE1_INSTALLCD" "$PATH_STAGE2_INSTALLCD" || die "Failed to substitute REPOS in installcd spec files"
sed -i "s|@LIVECD_OVERLAY@|${PATH_LIVECD_OVERLAY}|g" "$PATH_STAGE2_INSTALLCD" || die "Failed to substitute LIVECD_OVERLAY in stage2 installcd spec file"
sed -i "s|@LIVECD_FSSCRIPT@|${PATH_LIVECD_FSSCRIPT}|g" "$PATH_STAGE2_INSTALLCD" || die "Failed to substitute LIVECD_FSSCRIPT in stage2 installcd spec file"

# Save latest release timestamp
echo "${TIMESTAMP}" > "${PATH_RELEASE_INFO}" || die "Failed to save latest release timestamp"

exit 0
