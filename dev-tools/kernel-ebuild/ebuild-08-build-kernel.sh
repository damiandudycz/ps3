#!/bin/bash

# This function compiles kernel and copies vmlinux and modules
# to local/gentoo-kernel-ps3/linux.
# This can be used for testing configuration.
# Can be used before creating manifest.
# Generated linux and kernels are not stripped.
# Currently generating initramfs is not supported.

# TODO: ADD --clean flag.

die() {
    echo "$*" 1>&2
    exit 1
}

PACKAGE_VERSION="$1"

readonly NAME_PS3_DEFCONFIG="ps3_defconfig"
readonly NAME_PACKAGE="sys-kernel/gentoo-kernel"
readonly DRACUT_FLAGS="--xz --no-hostonly -a dmsquash-live -a mdraid -o btrfs -o crypt -o i18n -o usrmount -o lunmask -o qemu -o qemu-net -o nvdimm -o multipath -o resume";
readonly MAKE_JOBS=8

readonly PATH_START=$(dirname "$(realpath "$0")") || die "Failed to determine script directory."
readonly PATH_ROOT=$(realpath -m "${PATH_START}/../..") || die "Failed to determine root directory."
readonly PATH_VERSION_STORAGE="${PATH_START}/data/version-storage"
readonly PATH_DEFAULT_CONFIG="${PATH_VERSION_STORAGE}/default/config"
readonly PATH_VERSION_SCRIPT="${PATH_START}/ebuild-00-find-version.sh"
[ ! -z "${PACKAGE_VERSION}" ] || PACKAGE_VERSION=$($PATH_VERSION_SCRIPT) || die "Failed to get default version of package"
readonly PATH_WORK="/var/tmp/ps3/gentoo-kernel-ps3/${PACKAGE_VERSION}/linux"
readonly PATH_SOURCES="/var/tmp/ps3/gentoo-kernel-ps3/${PACKAGE_VERSION}/src"
readonly PATH_VERSION_CONFIG="${PATH_VERSION_STORAGE}/${PACKAGE_VERSION}/config/defconfig"
readonly PATH_SOURCES_SRC="$(find ${PATH_SOURCES}/portage/${NAME_PACKAGE}-${PACKAGE_VERSION}/work/ -maxdepth 1 -name linux-* -type d -print -quit)"
readonly PATH_SOURCES_DEFCONFIG="${PATH_SOURCES_SRC}/arch/powerpc/configs/${NAME_PS3_DEFCONFIG}"

[[ "${PACKAGE_VERSION}" =~ ^[0-9]+\.[0-9]+\.[0-9]+([0-9]+)?$ ]] || die "Please provide valid version number, ie. $0 6.6.30"
[ ! $PATH_SOURCES_SRC ] && die "Failed to find PATH_SOURCES_SRC"
[ -d "${PATH_SOURCES}" ] || die "${PATH_SOURCES} not found. Please run ebuild-emerge-gentoo-sources.sh <version> first."
[ -f "${PATH_VERSION_CONFIG}" ] || die "${PATH_VERSION_CONFIG} not found."

# Prepare workdir.
[ ! -d "${PATH_WORK}" ] || rm -rf "${PATH_WORK}" || die "Failed to clean previous files in ${PATH_WORK}"
mkdir -p "${PATH_WORK}" || die "Failed to create local working directory"

echo "Config used: ${PATH_VERSION_CONFIG}"

cd "${PATH_SOURCES_SRC}" || die "Failed to open directory ${PATH_SOURCES_SRC}"

# Overwrite PS3_Defcongig
cp "${PATH_VERSION_CONFIG}" "${PATH_SOURCES_DEFCONFIG}" || die "Failed to overwrite ${NAME_PS3_DEFCONFIG}"

# Generate liunx and initramfs.
ARCH=powerpc make ${NAME_PS3_DEFCONFIG} || die "Failed to generate PS3 Defconfig"
ARCH=powerpc make -j${MAKE_JOBS} || die "Failed to build kernel"
ARCH=powerpc make modules_install INSTALL_MOD_PATH="${PATH_WORK}" || die "Failed to install modules"
# This would strip symbols from modules, but might not work on another architecture
#ARCH=powerpc make modules_install INSTALL_MOD_STRIP=1 INSTALL_MOD_PATH="${PATH_WORK}" || die "Failed to install modules"
cp "${PATH_SOURCES_SRC}/vmlinux" "${PATH_WORK}"/ || die "Failed to copy vmlinux"
# // Dracut requires installing some special tools, plus it's not sure how it will behave on different host architecture
#dracut $DRACUT_FLAGS --include . "${PATH_WORK}/initramfs.img" $(make kernelrelease) || die "Failed to generate initramfs"

echo "Kernel built successfully."
exit 0
