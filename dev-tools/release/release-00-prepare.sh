#!/bin/bash

# This script prepares catalyst files for a new release.
# It will fetch the new snapshot and seed, and then generage spec files.
# At the beggining it also checks if there is a need to release a new ps3-gentoo-installer
# ebuild, and asks if you want to release it first, so that it can be used in the new build.

source ../../.env-shared.sh || exit 1
source "${PATH_EXTRA_ENV_RELEASE}" || failure "Failed to load env ${PATH_EXTRA_ENV_RELEASE}"

empty_directory "${PATH_WORK_RELEASE}"

# Ask if should update installer if there are any changes pending.
${PATH_SCRIPT_PS3_INSTALLER_UPDATER} --ask

# Copy helper files
cp -rf "${RE_PATH_LIVECD_OVERLAY_SRC}" "${RE_PATH_LIVECD_OVERLAY_DST}"
cp "${RE_PATH_LIVECD_FSSCRIPT_SRC}" "${RE_PATH_LIVECD_FSSCRIPT_DST}"

# Download current snapshot
catalyst --snapshot stable | tee "${RE_PATH_SNAPSHOT_LOG}"
readonly SQUASHFS_IDENTIFIER=$(grep -oP 'Creating gentoo tree snapshot \K[0-9a-f]{40}' "${RE_PATH_SNAPSHOT_LOG}")

# Download stage3 seed
readonly LATEST_GENTOO_CONTENT=$(wget -q -O - "${URL_STAGE3_INFO}" --no-http-keep-alive --no-cache --no-cookies)
readonly LATEST_STAGE3=$(echo "${LATEST_GENTOO_CONTENT}" | grep "${CONF_TARGET_ARCHITECTURE}-openrc" | head -n 1 | cut -d' ' -f1)
readonly LATEST_STAGE3_FILENAME=$(basename "${LATEST_STAGE3}")
readonly SEED_RE_VAL_TIMESTAMP=$(echo "${LATEST_STAGE3_FILENAME}" | sed -n 's/.*-\([0-9]\{8\}T[0-9]\{6\}Z\)\.tar\.xz/\1/p')
readonly PATH_STAGE3_SEED="${PATH_CATALYST_BUILDS_DEFAULT}/${LATEST_STAGE3_FILENAME}"
readonly URL_GENTOO_TARBALL="$URL_RELEASE_GENTOO/$LATEST_STAGE3"
[[ -z "${LATEST_STAGE3}" ]] && failure "Failed to download Stage3 URL"
[[ -f "${PATH_STAGE3_SEED}" ]] || wget "${URL_GENTOO_TARBALL}" -O "${PATH_STAGE3_SEED}"

# Prepare spec files
cp "${PATH_RELEASE_DATA_SPEC}/stage1-cell.spec" "$RE_PATH_STAGE1"
cp "${PATH_RELEASE_DATA_SPEC}/stage3-cell.spec" "$RE_PATH_STAGE3"
cp "${PATH_RELEASE_DATA_SPEC}/stage1-cell.installcd.spec" "$RE_PATH_STAGE1_INSTALLCD"
cp "${PATH_RELEASE_DATA_SPEC}/stage2-cell.installcd.spec" "$RE_PATH_STAGE2_INSTALLCD"

# Substitute placeholders with actual values in spec files
sed -i "s|@TREEISH@|${SQUASHFS_IDENTIFIER}|g" "${RE_PATH_STAGE1}" "${RE_PATH_STAGE3}" "${RE_PATH_STAGE1_INSTALLCD}" "${RE_PATH_STAGE2_INSTALLCD}"
sed -i "s|@SEEDRE_VAL_TIMESTAMP@|${SEED_RE_VAL_TIMESTAMP}|g" "${RE_PATH_STAGE1}" "${RE_PATH_STAGE1_INSTALLCD}" "${RE_PATH_STAGE2_INSTALLCD}"
sed -i "s|@RE_VAL_TIMESTAMP@|${RE_VAL_TIMESTAMP}|g" "{$RE_PATH_STAGE1}" "${RE_PATH_STAGE3}" "${RE_PATH_STAGE1_INSTALLCD}" "${RE_PATH_STAGE2_INSTALLCD}"
sed -i "s|@PORTAGE_CONFDIR@|${PATH_PORTAGE_CONFDIR_STAGES}|g" "${RE_PATH_STAGE1}"
sed -i "s|@PORTAGE_CONFDIR@|${PATH_PORTAGE_CONFDIR_STAGES}-cell|g" "${RE_PATH_STAGE3}"
sed -i "s|@PORTAGE_CONFDIR@|${PATH_PORTAGE_CONFDIR_ISOS}|g" "${RE_PATH_STAGE1_INSTALLCD}"
sed -i "s|@PORTAGE_CONFDIR@|${PATH_PORTAGE_CONFDIR_ISOS}-cell|g" "${RE_PATH_STAGE2_INSTALLCD}"
sed -i "s|@PKGCACHE_PATH@|${PATH_PKG_CACHE}|g" "${RE_PATH_STAGE1}" "${RE_PATH_STAGE3}" "${RE_PATH_STAGE1_INSTALLCD}" "${RE_PATH_STAGE2_INSTALLCD}"
sed -i "s|@INTERPRETER@|${RE_VAL_INTERPRETER_ENTRY}|g" "${RE_PATH_STAGE1}" "${RE_PATH_STAGE3}" "${RE_PATH_STAGE1_INSTALLCD}" "${RE_PATH_STAGE2_INSTALLCD}"
sed -i "s|@REPOS@|${PATH_OVERLAY}|g" "${RE_PATH_STAGE1_INSTALLCD}" "${RE_PATH_STAGE2_INSTALLCD}"
sed -i "s|@LIVECD_OVERLAY@|${PATH_LIVECD_OVERLAY}|g" "${RE_PATH_STAGE2_INSTALLCD}"
sed -i "s|@LIVECD_FSSCRIPT@|${PATH_LIVECD_FSSCRIPT}|g" "${RE_PATH_STAGE2_INSTALLCD}"

# Save latest release RE_VAL_TIMESTAMP
echo "${RE_VAL_TIMESTAMP}" > "${RE_PATH_RELEASE_INFO}"
