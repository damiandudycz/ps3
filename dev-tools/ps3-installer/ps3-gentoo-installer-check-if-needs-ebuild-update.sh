#!/bin/bash

# Error handling function
die() {
    echo "$*" 1>&2
    exit -1
}

# Cleanup function
cleanup() {
    if [[ "$KEEP_FILES" != true ]]; then
        rm -rf "${PATH_TMP}" || echo "Failed to remove temporary directory: ${PATH_TMP}" 1>&2
    fi
}
trap cleanup EXIT

# Handle script arguments
KEEP_FILES=false
CLEAN_FILES=false

for arg in "$@"; do
    case $arg in
        --keepfiles)
        KEEP_FILES=true
        shift
        ;;
        --cleanfiles)
        CLEAN_FILES=true
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

PATH_START=$(dirname "$(realpath "$0")") || die "Failed to determine the script directory"
PATH_ROOT=$(realpath -m "$PATH_START/../..") || die "Failed to determine the root directory"
PATH_TMP="${PATH_ROOT}/local/ps3-gentoo-installer-ebuild-updater"

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

# Clean files and exit if --cleanfiles flag is set
if [[ "$CLEAN_FILES" == true ]]; then
    cleanup
    exit 0
fi

echo "Checking for ps3-gentoo-installer update"

mkdir -p "${PATH_TMP}" || die "Failed to create temporary directory"

# Copy distfiles to tmp
cp "${PATH_INSTALLER_EBUILD_EBUILD}" "${PATH_TMP}/${PN}-${CONF_EBUILD_VERSION_NEW}.ebuild" || die "Failed to copy ebuild file"
cp "${PATH_INSTALLER_EBUILD_INSTALLER}" "${PATH_TMP}/${PN}" || die "Failed to copy installer file"
cp "${PATH_INSTALLER_EBUILD_CONFIG}" "${PATH_TMP}/config" || die "Failed to copy config file"

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
