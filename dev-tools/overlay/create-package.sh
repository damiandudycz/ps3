#!/bin/bash

source ../../.env-shared.sh || exit 1
register_usage "$1 <--ebuild <Path>> <--version <Version> | --version-increment> [--file <Path>...] [--distfile <Path>...] [--save]"

# Builds and inserts a new package ebuild and distfiles to overlay.
# Files are renamed to match ebuild version.
# Distfiles are compressed into tarball.

# Input parameters:
# - ebuild file (without version)
# - ebuild version
# - files (stored in overlay files directory)
# - distdiles (stored in overlay.distfiles as tar.xz)

empty_directory "${PATH_WORK_OVERLAY}"

declare -a OV_FILES;
declare -a OV_DISTFILES;

# Input parsing.
while [ $# -gt 0 ]; do case "$1" in
    --ebuild)            shift; readonly OV_EBUILD_PATH="$1";;
    --category)          shift; readonly OV_EBUILD_CATEGORY="$1";;
    --version)           shift; readonly OV_EBUILD_VERSION="$1";;
    --version-increment)        readonly OV_FLAG_VERSION_INCREMENT=true;;
    --save)                     readonly OV_FLAG_SAVE=true;;
    --file)              shift; OV_FILES+=("$1");;
    --distfile)          shift; OV_DISTFILES+=("$1");;
    *) show_usage
esac; shift; done

# Validate input parameters.
[[ -z "${OV_EBUILD_PATH}" ]] && failure "Please provide ebuild path."
[[ -z "${OV_EBUILD_CATEGORY}" ]] && failure "Please provide ebuild category."
[[ -z "${OV_EBUILD_VERSION}" ]] && [[ -z "${OV_FLAG_VERSION_INCREMENT}" ]] && failure "Please provide ebuild version or use --version-increment flag."
[[ ! -z "${OV_EBUILD_VERSION}" ]] && [[ ! -z "${OV_FLAG_VERSION_INCREMENT}" ]] && failure "Can not use both --version and --version-increment flags."

# Overlay and distfiles paths.
readonly OV_PATH_PACKAGE_DIR="${PATH_OVERLAYS_PS3_GENTOO}/${OV_EBUILD_CATEGORY}"
readonly OV_PATH_PACKAGE_FILES="${OV_PATH_PACKAGE_DIR}/files"
readonly OV_PATH_DISTFILES_DIR="${PATH_OVERLAYS_PS3_GENTOO_DISTFILES}/${OV_EBUILD_CATEGORY}"

# Determine used package version - specified or next version.
if [[ -z "${OV_EBUILD_VERSION}" ]]; then
    # Automatically increment next version.
    readonly OV_PATH_WORK_EBUILD_CURRENT=$(find "${OV_PATH_PACKAGE_DIR}" -name "*.ebuild" | grep -v "9999" | sort -V | tail -n 1)
    readonly OV_VAL_OVERLAY_EBUILD_CURRENT_VERSION="$(echo ${OV_PATH_WORK_EBUILD_CURRENT} | sed -r 's/.*-([0-9]+(\.[0-9]+)*)\.ebuild/\1/')"
    readonly OV_VAL_EBUILD_VERSION_SELECTED=$(echo "${OV_VAL_OVERLAY_EBUILD_CURRENT_VERSION}" | awk -F. -v OFS=. '{ $NF=$NF+1; print }')
else
    # Use specified version.
    readonly OV_VAL_EBUILD_VERSION_SELECTED="${OV_EBUILD_VERSION}"
fi

readonly OV_VAL_DISTFILE_NAME="$(basename "${OV_EBUILD_PATH}" .${OV_EBUILD_PATH##*.})-${OV_VAL_EBUILD_VERSION_SELECTED}.tar.xz"
readonly OV_VAL_EBUILD_NAME="$(basename "${OV_EBUILD_PATH}" .${OV_EBUILD_PATH##*.})-${OV_VAL_EBUILD_VERSION_SELECTED}.${OV_EBUILD_PATH##*.}"

readonly OV_PATH_WORK_EBUILD_DIR="${PATH_WORK_OVERLAY}/${OV_EBUILD_CATEGORY}"
readonly OV_PATH_WORK_EBUILD_FILES="${PATH_WORK_OVERLAY}/${OV_EBUILD_CATEGORY}/files"
readonly OV_PATH_WORK_EBUILD="${OV_PATH_WORK_EBUILD_DIR}/${OV_VAL_EBUILD_NAME}"
readonly OV_PATH_WORK_EBUILD_MANIFEST="${PATH_WORK_OVERLAY}/${OV_EBUILD_CATEGORY}/Manifest"
readonly OV_PATH_WORK_DISTFILES_DIR="${PATH_WORK_OVERLAY}/distfiles"
readonly OV_PATH_WORK_DISTFILES_TAR="${OV_PATH_WORK_DISTFILES_DIR}/${OV_VAL_DISTFILE_NAME}"

readonly OV_PATH_OVERLAY_EBUILD_DIR="${PATH_OVERLAYS_PS3_GENTOO}/${OV_EBUILD_CATEGORY}"
readonly OV_PATH_OVERLAY_EBUILD_FILES="${OV_PATH_OVERLAY_EBUILD_DIR}/files"
readonly OV_PATH_OVERLAY_EBUILD="${OV_PATH_OVERLAY_EBUILD_DIR}/${OV_VAL_EBUILD_NAME}"
readonly OV_PATH_OVERLAY_EBUILD_MANIFEST="${OV_PATH_OVERLAY_EBUILD_DIR}/Manifest"
readonly OV_PATH_OVERLAY_DISTFILES_DIR="${PATH_OVERLAYS_PS3_GENTOO_DISTFILES}/${OV_EBUILD_CATEGORY}"
readonly OV_PATH_OVERLAY_DISTFILES_TAR="${OV_PATH_OVERLAY_DISTFILES_DIR}/${OV_VAL_DISTFILE_NAME}"

echo "Copying ebuild"
mkdir -p "${OV_PATH_WORK_EBUILD_DIR}"
cp -f "${OV_EBUILD_PATH}" "${OV_PATH_WORK_EBUILD}"

if [[ ! -z "${OV_FILES}" ]]; then
    echo "Collecting files"
    mkdir -p "${OV_PATH_WORK_EBUILD_FILES}"
    for file in "${OV_FILES[@]}"; do
        OV_PATH_WORK_FILE="${OV_PATH_WORK_EBUILD_FILES}/$(basename "${file}" .${file##*.})-${OV_VAL_EBUILD_VERSION_SELECTED}.${file##*.}"
        echo " - $file"
        cp -rf "${file}" "${OV_PATH_WORK_FILE}"
    done
fi

if [[ ! -z "${OV_DISTFILES}" ]]; then
    echo "Collecting distfiles"
    mkdir -p "${OV_PATH_WORK_DISTFILES_DIR}"
    declare -a FILES_TO_COMPRESS
    for file in "${OV_DISTFILES[@]}"; do
        OV_PATH_WORK_DISTFILE="${OV_PATH_WORK_DISTFILES_DIR}/$(basename "${file}")"
        echo " - $file"
        cp -rf "${file}" "${OV_PATH_WORK_DISTFILE}"
        FILES_TO_COMPRESS+=($(basename "${OV_PATH_WORK_DISTFILE}"))
    done
    echo "Compressing distfiles"
    tar --sort=name \
        --mtime="" \
        --owner=0 --group=0 --numeric-owner \
        --pax-option=exthdr.name=%d/PaxHeaders/%f,delete=atime,delete=ctime \
        -caf "${OV_PATH_WORK_DISTFILES_TAR}" \
        -C "${OV_PATH_WORK_DISTFILES_DIR}" "${FILES_TO_COMPRESS[@]}"
    # Clean files after compressing
    find "${OV_PATH_WORK_DISTFILES_DIR}" -mindepth 1 ! -name "${OV_VAL_DISTFILE_NAME}" -exec rm -rf {} +
fi

echo "Building manifest"
DISTDIR="${OV_PATH_WORK_DISTFILES_DIR}" ebuild "${OV_PATH_WORK_EBUILD}" manifest clean

echo "Package ${OV_VAL_DISTFILE_NAME} created successfully."

# Merge with overlay.
if [[ ! -z "${OV_FLAG_SAVE}" ]]; then
    echo "Merging package ${OV_VAL_EBUILD_NAME} with overlay: ${OV_PATH_OVERLAY_EBUILD_DIR}"
    readonly TMP_MANIFEST=$(mktemp)
    register_failure_handler 'rm -f ${TMP_MANIFEST}'

    # Copy distfiles, files and ebuild.
    mkdir -p "${OV_PATH_OVERLAY_EBUILD_DIR}"
    mkdir -p "${OV_PATH_OVERLAY_EBUILD_FILES}"
    mkdir -p "${OV_PATH_OVERLAY_DISTFILES_DIR}"
    cp -rf "${OV_PATH_WORK_EBUILD}" "${OV_PATH_OVERLAY_EBUILD}"
    cp -rf "${OV_PATH_WORK_EBUILD_FILES}"/* "${OV_PATH_OVERLAY_EBUILD_FILES}"/
    cp -rf "${OV_PATH_WORK_DISTFILES_TAR}" "${OV_PATH_OVERLAY_DISTFILES_TAR}"

    # Merge new manifest to overlay manifest.
    if [[ -f "${OV_PATH_OVERLAY_EBUILD_MANIFEST}" ]]; then
        awk '
        { B_entries[$1 " " $2] = $0 }
            END {
                for (entry in A_entries) { print A_entries[entry] }
                for (entry in B_entries) { if (!(entry in A_entries)) { print B_entries[entry] } }
            }
        ' "${OV_PATH_OVERLAY_EBUILD_MANIFEST}" "${OV_PATH_WORK_EBUILD_MANIFEST}" | sort > "${TMP_MANIFEST}"
        mv "${TMP_MANIFEST}" "${OV_PATH_OVERLAY_EBUILD_MANIFEST}"
    else
        rm -f "${TMP_MANIFEST}"
        cp "${OV_PATH_WORK_EBUILD_MANIFEST}" "${OV_PATH_OVERLAY_EBUILD_MANIFEST}"
    fi
fi
