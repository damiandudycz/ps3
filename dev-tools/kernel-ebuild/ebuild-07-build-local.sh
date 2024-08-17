#!/bin/bash

source ../../.env-shared.sh --silent || exit 1
source "${PATH_EXTRA_ENV_KERNEL_EBUILD}" || failure "Failed to load env ${PATH_EXTRA_ENV_KERNEL_EBUILD}"

# Check if latest files are stored.
readonly EBUILD_FILES_DIFF=$(diff "${KE_PATH_EBUILD_FILE_DST}" "${KE_PATH_OVERLAY_EBUILD_FILE_PACKAGE}" 2> /dev/null) || failure "Files ${KE_PATH_EBUILD_FILE_DST} ${KE_PATH_OVERLAY_EBUILD_FILE_PACKAGE} differ"
[[ ! ${EBUILD_FILES_DIFF} ]] || failure "Current version of ebuild not stored in overlay."

empty_directory "${KE_PATH_WORK_LOCALBUILD}"
mkdir -p "${KE_PATH_WORK_LOCALBUILD}/boot"

# Build kernel and modules
cd "${KE_PATH_WORK_SRC_LINUX}"
ARCH=powerpc CROSS_COMPILE=${CONF_CROSSDEV_TARGET}- make -j ${CONF_CATALYST_JOBS}
ARCH=powerpc CROSS_COMPILE=${CONF_CROSSDEV_TARGET}- INSTALL_PATH="${KE_PATH_WORK_LOCALBUILD}/boot" make install
ARCH=powerpc CROSS_COMPILE=${CONF_CROSSDEV_TARGET}- INSTALL_MOD_PATH="${KE_PATH_WORK_LOCALBUILD}" make modules_install

# Strip kernel and modules debud symbols.
#${CONF_CROSSDEV_TARGET}-strip "${KE_PATH_WORK_LOCALBUILD}/boot/vmlinux-${KE_PACKAGE_VERSION_SELECTED}"*
#find "${KE_PATH_WORK_LOCALBUILD}/lib/modules" -type f -name '*.ko' -exec ${CONF_CROSSDEV_TARGET}-strip --strip-debug {} \;

# Compress build.
cd "${KE_PATH_WORK_LOCALBUILD}"
tar cvpf linux-${KE_PACKAGE_VERSION_SELECTED}.tar.xz --exclude linux-${KE_PACKAGE_VERSION_SELECTED}.tar.xz .
rm -rf boot lib

echo "Build stored in: ${KE_PATH_WORK_LOCALBUILD}/linux-${KE_PACKAGE_VERSION_SELECTED}.tar.xz"

if [[ -n "${KE_UPLOAD_ADDRESS}" ]]; then
    echo "Uploading to: ${KE_UPLOAD_ADDRESS}"
    scp "${KE_PATH_WORK_LOCALBUILD}/linux-${KE_PACKAGE_VERSION_SELECTED}.tar.xz" "${KE_UPLOAD_ADDRESS}:~/"
    ssh "${KE_UPLOAD_ADDRESS}" "tar -xvpf linux-${KE_PACKAGE_VERSION_SELECTED}.tar.xz -C ~/"
fi
