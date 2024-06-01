#!/bin/bash

# This script prepares catalyst files for a new release.
# It will fetch the new snapshot and seed, and then generage spec files.
# At the beggining it also checks if there is a need to release a new ps3-gentoo-installer
# ebuild, and asks if you want to release it first, so that it can be used in the new build.

source ../../.env-shared.sh || exit 1

# Configuration
readonly TIMESTAMP=$(date -u +"%Y%m%dT%H%M%SZ")
#readonly CONF_JOBS="8"
#readonly CONF_LOAD="12.0"

# Paths
#readonly PATH_LOCAL_TMP="/var/tmp/ps3/release"
#readonly PATH_CATALYST_BUILDS="/var/tmp/catalyst/builds/default"
#readonly PATH_PKG_CACHE="${PATH_ROOT}/binhosts/ps3-gentoo-binhosts/default"
#readonly PATH_OVERLAY="${PATH_ROOT}/overlays/ps3-gentoo-overlay"
#readonly PATH_STAGE1="${PATH_LOCAL_TMP}/stage1-cell.$TIMESTAMP.spec"
#readonly PATH_STAGE3="${PATH_LOCAL_TMP}/stage3-cell.$TIMESTAMP.spec"
#readonly PATH_STAGE1_INSTALLCD="${PATH_LOCAL_TMP}/stage1-cell.installcd.$TIMESTAMP.spec"
#readonly PATH_STAGE2_INSTALLCD="${PATH_LOCAL_TMP}/stage2-cell.installcd.$TIMESTAMP.spec"
readonly PATH_LIVECD_OVERLAY_ORIGINAL="${PATH_DEV_TOOLS_RELEASE}/data/iso_overlay"
readonly PATH_LIVECD_OVERLAY="${PATH_WORK_RELEASE}/iso_overlay"
readonly PATH_LIVECD_FSSCRIPT_ORIGINAL="${PATH_DEV_TOOLS_RELEASE}/data/iso_fsscript.sh"
readonly PATH_LIVECD_FSSCRIPT="${PATH_WORK_RELEASE}/iso_fsscript.sh"
#readonly PATH_INTERPRETER="/usr/bin/qemu-ppc64"
readonly PATH_SNAPSHOT_LOG="${PATH_WORK_RELEASE}/snapshot_log.txt"
#readonly PATH_RELENG="/var/tmp/ps3/releng"
#readonly PATH_RELEASE_INFO="${PATH_LOCAL_TMP}/release_latest"
readonly PATH_INSTALLER_UPDATER="${PATH_ROOT}/dev-tools/ps3-installer/ps3-gentoo-installer-ebuild-updater.sh"

#PATH_PORTAGE_CONFDIR_STAGES="${PATH_RELENG}/releases/portage/stages"
#PATH_PORTAGE_CONFDIR_ISOS="${PATH_RELENG}/releases/portage/isos"

# URLs
#readonly URL_RELEASE_GENTOO="https://gentoo.osuosl.org/releases/ppc/autobuilds"
#readonly URL_STAGE_INFO="https://gentoo.osuosl.org/releases/ppc/autobuilds/latest-stage3-ppc64-openrc.txt"

set_if INTERPRETER "${VAL_QEMU_IS_NEEDED}" "interpreter: ${PATH_QEMU_INTERPRETER}" ""

# Ask if should update installer if there are any changes pending.
${PATH_INSTALLER_UPDATER} --ask

# Create local tmp path
mkdir -p "${PATH_WORK_RELEASE}"

# Copy helper files
cp -rf "${PATH_LIVECD_OVERLAY_ORIGINAL}" "${PATH_LIVECD_OVERLAY}"
cp "${PATH_LIVECD_FSSCRIPT_ORIGINAL}" "${PATH_LIVECD_FSSCRIPT}"

# Download current snapshot
rm -f "${PATH_SNAPSHOT_LOG}"
catalyst --snapshot stable | tee "${PATH_SNAPSHOT_LOG}"
readonly SQUASHFS_IDENTIFIER=$(grep -oP 'Creating gentoo tree snapshot \K[0-9a-f]{40}' "${PATH_SNAPSHOT_LOG}")

# Download stage3 seed
readonly LATEST_GENTOO_CONTENT=$(wget -q -O - "${URL_STAGE3_INFO}" --no-http-keep-alive --no-cache --no-cookies) || failure "Failed to download latest stage3 seed"
readonly LATEST_STAGE3=$(echo "${LATEST_GENTOO_CONTENT}" | grep "ppc64-openrc" | head -n 1 | cut -d' ' -f1)
readonly LATEST_STAGE3_FILENAME=$(basename "${LATEST_STAGE3}") || failure "Failed to get stage3 filename"
readonly SEED_TIMESTAMP=$(echo "${LATEST_STAGE3_FILENAME}" | sed -n 's/.*-\([0-9]\{8\}T[0-9]\{6\}Z\)\.tar\.xz/\1/p') || failure "Failed to get seed timestamp"
readonly PATH_STAGE3_SEED="${PATH_CATALYST_BUILDS}/${LATEST_STAGE3_FILENAME}"
readonly URL_GENTOO_TARBALL="$URL_RELEASE_GENTOO/$LATEST_STAGE3"
[[ ! -z "${LATEST_STAGE3}" ]] || failure "Failed to download Stage3 URL"
[[ -f "${PATH_STAGE3_SEED}" ]] || wget "${URL_GENTOO_TARBALL}" -O "${PATH_STAGE3_SEED}"

# Prepare spec files
cp "$PATH_START/data/spec/stage1-cell.spec" "$PATH_STAGE1"
cp "$PATH_START/data/spec/stage3-cell.spec" "$PATH_STAGE3"
cp "$PATH_START/data/spec/stage1-cell.installcd.spec" "$PATH_STAGE1_INSTALLCD"
cp "$PATH_START/data/spec/stage2-cell.installcd.spec" "$PATH_STAGE2_INSTALLCD"

# Substitute placeholders with actual values in spec files
sed -i "s|@TREEISH@|${SQUASHFS_IDENTIFIER}|g" "$PATH_STAGE1"
sed -i "s|@TREEISH@|${SQUASHFS_IDENTIFIER}|g" "$PATH_STAGE3"
sed -i "s|@TREEISH@|${SQUASHFS_IDENTIFIER}|g" "$PATH_STAGE1_INSTALLCD"
sed -i "s|@TREEISH@|${SQUASHFS_IDENTIFIER}|g" "$PATH_STAGE2_INSTALLCD"
sed -i "s|@SEEDTIMESTAMP@|${SEED_TIMESTAMP}|g" "$PATH_STAGE1" "$PATH_STAGE1_INSTALLCD" "$PATH_STAGE2_INSTALLCD"
sed -i "s|@TIMESTAMP@|${TIMESTAMP}|g" "$PATH_STAGE1" "$PATH_STAGE3" "$PATH_STAGE1_INSTALLCD" "$PATH_STAGE2_INSTALLCD"
sed -i "s|@PORTAGE_CONFDIR@|${PATH_PORTAGE_CONFDIR_STAGES}|g" "$PATH_STAGE1"
sed -i "s|@PORTAGE_CONFDIR@|${PATH_PORTAGE_CONFDIR_STAGES}-cell|g" "$PATH_STAGE3"
sed -i "s|@PORTAGE_CONFDIR@|${PATH_PORTAGE_CONFDIR_ISOS}|g" "$PATH_STAGE1_INSTALLCD"
sed -i "s|@PORTAGE_CONFDIR@|${PATH_PORTAGE_CONFDIR_ISOS}-cell|g" "$PATH_STAGE2_INSTALLCD"
sed -i "s|@PKGCACHE_PATH@|${PATH_PKG_CACHE}|g" "$PATH_STAGE1" "$PATH_STAGE3" "$PATH_STAGE1_INSTALLCD" "$PATH_STAGE2_INSTALLCD"
sed -i "s|@INTERPRETER@|${INTERPRETER}|g" "$PATH_STAGE1" "$PATH_STAGE3" "$PATH_STAGE1_INSTALLCD" "$PATH_STAGE2_INSTALLCD"
sed -i "s|@REPOS@|${PATH_OVERLAY}|g" "$PATH_STAGE1_INSTALLCD" "$PATH_STAGE2_INSTALLCD"
sed -i "s|@LIVECD_OVERLAY@|${PATH_LIVECD_OVERLAY}|g" "$PATH_STAGE2_INSTALLCD"
sed -i "s|@LIVECD_FSSCRIPT@|${PATH_LIVECD_FSSCRIPT}|g" "$PATH_STAGE2_INSTALLCD"

# Save latest release timestamp
echo "${TIMESTAMP}" > "${PATH_RELEASE_INFO}"
