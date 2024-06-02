#!/bin/bash

source ../../.env-shared.sh || exit 1
source "${PATH_EXTRA_ENV_PS3_INSTALLER}" || failure "Failed to load env ${PATH_EXTRA_ENV_PS3_INSTALLER}"

# Handle script arguments
ASK=false

for arg in "$@"; do; case $arg in
    --ask) ASK=true; shift;;
esac; done







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















PATH_TMP="/var/tmp/ps3/ps3-gentoo-installer-ebuild-updater"

PATH_OVERLAY_EBUILDS="${PATH_ROOT}/overlays/ps3-gentoo-overlay"
PATH_OVERLAY_DISTFILES="${PATH_ROOT}/overlays/ps3-gentoo-overlay.distfiles"
PATH_OVERLAY_EBUILDS_PACKAGE_LOCATION="${PATH_OVERLAY_EBUILDS}/${PL}"

PATH_INSTALLER_EBUILD_EBUILD="${PATH_START}/${PN}.ebuild"
PATH_INSTALLER_EBUILD_INSTALLER="${PATH_START}/ps3-gentoo-installer"
PATH_INSTALLER_EBUILD_CONFIG="${PATH_START}/config/PS3"

CONF_EBUILD_VERSION_CURRENT=$(find "${PATH_OVERLAY_EBUILDS_PACKAGE_LOCATION}" -name "*.ebuild" | grep -v "9999" | sed -r 's/.*-([0-9]+(\.[0-9]+)*)\.ebuild/\1/' | sort -V | tail -n 1) || die "Failed to determine the current ebuild version"
CONF_EBUILD_VERSION_NEW=$(echo "${CONF_EBUILD_VERSION_CURRENT}" | awk -F. -v OFS=. '{ $NF=$NF+1; print }') || die "Failed to determine the new ebuild version"

PATH_DISTFILES_TAR_TMP="${PATH_TMP}/${PN}-${CONF_EBUILD_VERSION_NEW}.tar.xz"
PATH_DISTFILES_TAR_OLD="${PATH_OVERLAY_DISTFILES}/${PL}/${PN}-${CONF_EBUILD_VERSION_CURRENT}.tar.xz"
PATH_DISTFILES_TAR_NEW="${PATH_OVERLAY_DISTFILES}/${PL}/${PN}-${CONF_EBUILD_VERSION_NEW}.tar.xz"

LIST_DISTFILES_TAR_FILES=(
    ps3-gentoo-installer
    config
)

empty_directory "${PATH_TMP}"

echo "Checking for ps3-gentoo-installer update"

# TODO: Move this functionality into create installer itself, and in this script just compare dates of existing ebuild and installer/config modification dates

# Copy distfiles to tmp
cp "${PATH_INSTALLER_EBUILD_EBUILD}" "${PATH_TMP}/${PN}-${CONF_EBUILD_VERSION_NEW}.ebuild"
cp "${PATH_INSTALLER_EBUILD_INSTALLER}" "${PATH_TMP}/${PN}"
cp "${PATH_INSTALLER_EBUILD_CONFIG}" "${PATH_TMP}/config"

# Create tmp distfiles tar
tar --sort=name \
    --mtime="" \
    --owner=0 --group=0 --numeric-owner \
    --pax-option=exthdr.name=%d/PaxHeaders/%f,delete=atime,delete=ctime \
    -caf "${PATH_DISTFILES_TAR_TMP}" \
    -C "${PATH_TMP}" "${LIST_DISTFILES_TAR_FILES[@]}" || die "Failed to create tar file"

if diff -q "$PATH_DISTFILES_TAR_TMP" "$PATH_DISTFILES_TAR_OLD" >/dev/null; then
    echo "No changes in installer, Update is not required"
    echo ""
    exit 0
else
    echo "Installer requires an update"
    echo ""
    exit 1
fi




















# TODO: Remove upload from there, unless its required for catalusy to grab the newest.
# Try to add lcal overlay somehow first



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
