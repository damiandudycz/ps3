#!/bin/bash

# This script emerges gentoo-sources package of given version to local temp directory.
# Gentoo-Sources is emerged instead of Gentoo-Kernel, because it's only needed to patch and modify the sources.
# It's not needed to actually build and install kernel at this stage, hence gentoo-sources fits this puropuse better.
# If package was already downloaded, this will remove the previous version.
# Pass the version number as a parameter of this function.
# If no version is specified, script will use current stable version available.

# Error handling function
die() {
    echo "$*" 1>&2
    exit 1
}

NAME_KEYWORD=" ppc64"
PACKAGE_VERSION="$1"

readonly PATH_START=$(dirname "$(realpath "$0")") || die "Failed to determine script directory."
readonly PATH_VERSION_SCRIPT="${PATH_START}/ebuild-find-version.sh"

[ ! -z "${PACKAGE_VERSION}" ] || PACKAGE_VERSION=$($PATH_VERSION_SCRIPT) || die "Failed to get default version of package"
[[ "${PACKAGE_VERSION}" =~ ^[0-9]+\.[0-9]+\.[0-9]+([0-9]+)?$ ]] || die "Please provide valid version number, ie. $0 6.6.30"

readonly PATH_ROOT=$(realpath -m "${PATH_START}/../..") || die "Failed to determine root directory."
readonly PATH_LOCAL="${PATH_ROOT}/local/kernel/${PACKAGE_VERSION}/src"
readonly PATH_REPO_GENTOO="/var/db/repos/gentoo"
readonly NAME_PACKAGE="sys-kernel/gentoo-kernel"
readonly NAME_EBUILD="gentoo-kernel"

[ ! -d "${PATH_LOCAL}" ] || rm -rf "${PATH_LOCAL}" || die "Failed to clean previous files in ${PATH_LOCAL}"
mkdir -p "${PATH_LOCAL}" || die "Failed to create local working directory"

PORTAGE_TMPDIR="${PATH_LOCAL}" ebuild "${PATH_REPO_GENTOO}/${NAME_PACKAGE}/${NAME_EBUILD}-${PACKAGE_VERSION}.ebuild" configure || die "Failed to download Gentoo Kernel ${PACKAGE_VERSION}"

echo "Gentoo Kernel ${PACKAGE_VERSION} downloaded successfully"
exit 0
