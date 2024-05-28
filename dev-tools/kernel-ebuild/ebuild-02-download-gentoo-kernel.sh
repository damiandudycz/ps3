#!/bin/bash

# This script emerges gentoo-sources package of given version to local temp directory.
# Gentoo-Sources is emerged instead of Gentoo-Kernel, because it's only needed to patch and modify the sources.
# It's not needed to actually build and install kernel at this stage, hence gentoo-sources fits this puropuse better.
# If package was already downloaded, this will remove the previous version.
# Pass the version number as a parameter of this function.
# If no version is specified, script will use current stable version available.

# --- Shared environment
source ../../.env-shared.sh || exit 1
source "${PATH_ADDITIONAL_PATHS_KERNEL_EBUILDER}" || exit 1
trap failure ERR
register_usage "$0 [package_version]"

PACKAGE_VERSION="$1"
NAME_KEYWORD=" ppc64"
readonly NAME_PACKAGE="sys-kernel/gentoo-kernel"
readonly NAME_EBUILD="gentoo-kernel"

# Setup patchs.
readonly PATH_VERSION_SCRIPT="${PATH_DEV_TOOLS_KERNEL_EBUILD}/ebuild-00-find-version.sh"
[ ! -z "${PACKAGE_VERSION}" ] || PACKAGE_VERSION=$($PATH_VERSION_SCRIPT)

readonly PATH_WORK_DOWNLOAD_GENTOO_KERNEL="${PATH_WORK_KERNEL_EBUILD}/${PACKAGE_VERSION}/src"

# Validate data.
[ ! -z "${PACKAGE_VERSION}" ] || failure "Failed to determine kernel version"
[[ "${PACKAGE_VERSION}" =~ ^[0-9]+\.[0-9]+\.[0-9]+([0-9]+)?$ ]] || show_usage

# Prepare workdir.
[ ! -d "${PATH_WORK_DOWNLOAD_GENTOO_KERNEL}" ] || rm -rf "${PATH_WORK_DOWNLOAD_GENTOO_KERNEL}"
mkdir -p "${PATH_WORK_DOWNLOAD_GENTOO_KERNEL}"

PORTAGE_TMPDIR="${PATH_WORK_DOWNLOAD_GENTOO_KERNEL}" ebuild "${PATH_VAR_DB_REPOS_GENTOO}/${NAME_PACKAGE}/${NAME_EBUILD}-${PACKAGE_VERSION}.ebuild" configure
