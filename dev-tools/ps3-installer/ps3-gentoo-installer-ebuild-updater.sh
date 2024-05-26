#!/bin/bash

# Error handling function
die() {
    echo "$*" 1>&2
    exit -1
}

# Cleanup function
cleanup() {
    $PATH_CHECK_FUNCTION --cleanfiles
}
trap cleanup EXIT

# Handle script arguments
ASK=false

for arg in "$@"; do
    case $arg in
        --ask)
        ASK=true
        shift
	;;
	*)
        # Unknown option
        ;;
    esac
done

# Define variables
PN="ps3-gentoo-installer"
PL="sys-apps/${PN}"

PATH_START=$(dirname "$(realpath "$0")") || die
PATH_ROOT=$(realpath -m "$PATH_START/../..") || die
PATH_TMP="/var/tmp/ps3/ps3-gentoo-installer-ebuild-updater"

PATH_OVERLAY_EBUILDS="${PATH_ROOT}/overlays/ps3-gentoo-overlay"
PATH_OVERLAY_DISTFILES="${PATH_ROOT}/overlays/ps3-gentoo-overlay.distfiles"
PATH_OVERLAY_EBUILDS_PACKAGE_LOCATION="${PATH_OVERLAY_EBUILDS}/${PL}"

PATH_INSTALLER_EBUILD_EBUILD="${PATH_START}/${PN}.ebuild"
PATH_INSTALLER_EBUILD_INSTALLER="${PATH_START}/ps3-gentoo-installer"
PATH_INSTALLER_EBUILD_CONFIG="${PATH_START}/config/PS3"

CONF_EBUILD_VERSION_CURRENT=$(find "${PATH_OVERLAY_EBUILDS_PACKAGE_LOCATION}" -name "*.ebuild" | grep -v "9999" | sed -r 's/.*-([0-9]+(\.[0-9]+)*)\.ebuild/\1/' | sort -V | tail -n 1)
CONF_EBUILD_VERSION_NEW=$(echo "${CONF_EBUILD_VERSION_CURRENT}" | awk -F. -v OFS=. '{ $NF=$NF+1; print }')

PATH_DISTFILES_TAR_TMP="${PATH_TMP}/${PN}-${CONF_EBUILD_VERSION_NEW}.tar.xz"
PATH_DISTFILES_TAR_NEW="${PATH_OVERLAY_DISTFILES}/${PL}/${PN}-${CONF_EBUILD_VERSION_NEW}.tar.xz"

PATH_OVERLAY_EBUILD_NEW="${PATH_OVERLAY_EBUILDS_PACKAGE_LOCATION}/${PN}-${CONF_EBUILD_VERSION_NEW}.ebuild"
PATH_CHECK_FUNCTION="${PATH_START}/ps3-gentoo-installer-check-if-needs-ebuild-update.sh"

# Check if update is needed
$PATH_CHECK_FUNCTION --keepfiles
if [ $? -ne 1 ]; then
    exit 0
fi

if [ "$ASK" ]; then
    while true; do
        read -p "Do you want to update ps3-gentoo-installer ebuild [yes/no]: " yn
        case $yn in
            [Yy]* ) break ;;
            [Nn]* ) exit 0 ;;
            * ) ;;
        esac
    done
fi

# Upload new distfiles
cp "${PATH_DISTFILES_TAR_TMP}" "${PATH_DISTFILES_TAR_NEW}"
cd "${PATH_OVERLAY_DISTFILES}"
if [[ $(git status --porcelain) ]]; then
    git add -A
    git commit -m "Installer automatic update (Catalyst release)"
    git push
fi

# Upload new ebuild
cp "${PATH_TMP}/${PN}-${CONF_EBUILD_VERSION_NEW}.ebuild" "${PATH_OVERLAY_EBUILD_NEW}"
cd "${PATH_OVERLAY_EBUILDS_PACKAGE_LOCATION}"
pkgdev manifest
cd "${PATH_OVERLAY_EBUILDS}"
if [[ $(git status --porcelain) ]]; then
    git add -A
    git commit -m "Installer automatic update (Catalyst release)"
    git push
fi

exit 0
