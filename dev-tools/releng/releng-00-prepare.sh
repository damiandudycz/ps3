#!/bin/bash

# This script prepares catalyst files for a new release.
# It will fetch the new snapshot and seed, and then generage spec files.
# At the beggining it also checks if there is a need to release a new ps3-gentoo-installer
# ebuild, and asks if you want to release it first, so that it can be used in the new build.

# TODO: Prepare special PORTAGE_CONFDIR folders for stage4 or use some other way to unmask required desktop packages.

source ../../.env-shared.sh || exit 1
source "${PATH_EXTRA_ENV_RELENG}" || failure "Failed to load env ${PATH_EXTRA_ENV_RELENG}"

empty_directory "${PATH_WORK_RELENG}"
mkdir -p "${RL_PATH_SPECS_PS3_DST}"
mkdir -p "${RL_PATH_RELENG_PORTAGE_CONFDIR_DST}"

# Ask if should update installer if there are any changes pending.
(source ${PATH_SCRIPT_PS3_INSTALLER_UPDATE} --ask)

# Copy helper files.
cp -rf "${RL_PATH_LIVECD_OVERLAY_SRC}" "${RL_PATH_LIVECD_OVERLAY_DST}"
cp -f "${RL_PATH_LIVECD_FSSCRIPT_SRC}" "${RL_PATH_LIVECD_FSSCRIPT_DST}"
cp -f "${RL_PATH_CATALYST_AUTO_CONF_SRC}" "${RL_PATH_CATALYST_AUTO_CONF_DST}"

# Download stage3 seed.
readonly LATEST_GENTOO_CONTENT=$(wget -q -O - "${URL_STAGE3_INFO}" --no-http-keep-alive --no-cache --no-cookies)
readonly LATEST_STAGE3=$(echo "${LATEST_GENTOO_CONTENT}" | grep "${CONF_TARGET_ARCH}-openrc" | head -n 1 | cut -d' ' -f1)
readonly LATEST_STAGE3_FILENAME=$(basename "${LATEST_STAGE3}")
readonly SEED_RE_VAL_TIMESTAMP=$(echo "${LATEST_STAGE3_FILENAME}" | sed -n 's/.*-\([0-9]\{8\}T[0-9]\{6\}Z\)\.tar\.xz/\1/p')
readonly PATH_STAGE3_SEED="${PATH_CATALYST_BUILDS_DEFAULT}/${LATEST_STAGE3_FILENAME}"
readonly URL_GENTOO_TARBALL="$URL_RELEASE_GENTOO/$LATEST_STAGE3"
[[ -z "${LATEST_STAGE3}" ]] && failure "Failed to download Stage3 URL"
[[ -f "${PATH_STAGE3_SEED}" ]] || wget "${URL_GENTOO_TARBALL}" -O "${PATH_STAGE3_SEED}"

# Prepare PORTAGE_CONFDIR environments.
cp -rf "${PATH_RELENG_PORTAGE_CONFDIR_STAGES}" "${RL_PATH_RELENG_PORTAGE_CONFDIR_STAGES_DST}"
cp -rf "${PATH_RELENG_PORTAGE_CONFDIR_STAGES}" "${RL_PATH_RELENG_PORTAGE_CONFDIR_STAGE4_DST}"
cp -rf "${PATH_RELENG_PORTAGE_CONFDIR_ISOS}" "${RL_PATH_RELENG_PORTAGE_CONFDIR_ISOS_DST}"
# Synchronize environments modifications
find "${RL_PATH_RELENG_PORTAGE_CONFDIR_ENVS}" -mindepth 1 -maxdepth 1 -type d | while read dir; do
    env_name="$(basename ${dir})"
    env_dst="${RL_PATH_RELENG_PORTAGE_CONFDIR_DST}/${env_name}"
    echo "Configuring environment: ${env_dst} [${dir}]"
    cp -r "${dir}/"* "${env_dst}/"
done
#echo '*/* CPU_FLAGS_PPC: altivec' > "${RL_PATH_RELENG_PORTAGE_CONFDIR_STAGES}/package.use/00cpu-flags"
#echo '*/* CPU_FLAGS_PPC: altivec' > "${RL_PATH_RELENG_PORTAGE_CONFDIR_STAGE4}/package.use/00cpu-flags"
#echo '*/* CPU_FLAGS_PPC: altivec' > "${RL_PATH_RELENG_PORTAGE_CONFDIR_STAGES_ISOS}/package.use/00cpu-flags"

# Prepare spec files.
cp -f "${RL_PATH_STAGE1_SRC}" "${RL_PATH_STAGE1_DST}"
cp -f "${RL_PATH_STAGE3_SRC}" "${RL_PATH_STAGE3_DST}"
cp -f "${RL_PATH_STAGE4_SRC}" "${RL_PATH_STAGE4_DST}"
cp -f "${RL_PATH_STAGE1_INSTALLCD_SRC}" "${RL_PATH_STAGE1_INSTALLCD_DST}"
cp -f "${RL_PATH_STAGE2_INSTALLCD_SRC}" "${RL_PATH_STAGE2_INSTALLCD_DST}"

# Substitute placeholders with actual values in files.
readonly SPECS_LIST_MAIN="${RL_SPECS_MAIN[@]}"
readonly SPECS_LIST_OPTIONAL="${RL_SPECS_OPTIONAL[@]}"
sed -i "s|@SPECS_DIR@|${RL_PATH_SPECS_PS3_DST}|g" "${RL_PATH_CATALYST_AUTO_CONF_DST}"
sed -i "s|@SPECS_MAIN@|${SPECS_LIST_MAIN}|g" "${RL_PATH_CATALYST_AUTO_CONF_DST}"
sed -i "s|@EMAIL_FROM@|${CONF_RELEASE_EMAIL_FROM}|g" "${RL_PATH_CATALYST_AUTO_CONF_DST}"
sed -i "s|@EMAIL_TO@|${CONF_RELEASE_EMAIL_TO}|g" "${RL_PATH_CATALYST_AUTO_CONF_DST}"
sed -i "s|@EMAIL_PREPEND@|${CONF_RELEASE_EMAIL_PREPEND}|g" "${RL_PATH_CATALYST_AUTO_CONF_DST}"
sed -i "s|@SPECS_OPTIONAL@|${SPECS_LIST_OPTIONAL}|g" "${RL_PATH_CATALYST_AUTO_CONF_DST}"
sed -i "s|@INTERPRETER@|${RL_VAL_INTERPRETER_ENTRY}|g" "${RL_PATH_STAGE1_DST}" "${RL_PATH_STAGE3_DST}" "${RL_PATH_STAGE4_DST}" "${RL_PATH_STAGE1_INSTALLCD_DST}" "${RL_PATH_STAGE2_INSTALLCD_DST}"
sed -i "s|@LIVECD_OVERLAY@|${RL_PATH_LIVECD_OVERLAY_DST}|g" "${RL_PATH_STAGE2_INSTALLCD_DST}"
sed -i "s|@LIVECD_FSSCRIPT@|${RL_PATH_LIVECD_FSSCRIPT_DST}|g" "${RL_PATH_STAGE2_INSTALLCD_DST}"
sed -i "s|@REPOS@|${PATH_OVERLAYS_PS3_GENTOO}|g" "${RL_PATH_STAGE1_INSTALLCD_DST}" "${RL_PATH_STAGE2_INSTALLCD_DST}" "${RL_PATH_STAGE4_DST}"
sed -i "s|@PORTAGE_CONFDIR@|${RL_PATH_RELENG_PORTAGE_CONFDIR_DST}|g" "${RL_PATH_STAGE1_DST}" "${RL_PATH_STAGE3_DST}" "${RL_PATH_STAGE4_DST}" "${RL_PATH_STAGE1_INSTALLCD_DST}" "${RL_PATH_STAGE2_INSTALLCD_DST}"
sed -i "s|@PKGCACHE_PATH@|${PATH_RELENG_RELEASES_BINPACKAGES}|g" "${RL_PATH_STAGE1_DST}" "${RL_PATH_STAGE3_DST}" "${RL_PATH_STAGE4_DST}" "${RL_PATH_STAGE1_INSTALLCD_DST}" "${RL_PATH_STAGE2_INSTALLCD_DST}"

# Copy everything from distfiles overlay to cache, so that it's available during emerge even if packages were not yet uploaded to git.
source ${PATH_OVERLAY_SCRIPT_COPY_PS3_FILES}
