#!/bin/bash

# This script deletes a specified package from the binhost repository.
# Usage example: ./binhost-delete-package.sh sys-kernel/gentoo-kernel-ps3.
# It can also remove packages larger than specified size - this functionality
# can be used with or without specifying package name.

source ../../.env-shared.sh || exit 1
register_usage "$0 --pkgcache <PKG_CACHE_DIRECTORY> <package>[-version] --if-larger <SIZE_LIMIT>"

# Parse input parameters
declare -a ARG_PACKAGES_TO_REMOVE
while [[ $# -gt 0 ]]; do
    case "$1" in
        --verbose) ;; # Handled by env-shared.sh
        --pkgcache|-p)
            readonly PKGCACHE_DIR="$2"
            shift 2
            ;;
        --if-larger|-s)
            SIZE_LIMIT=$2
            SIZE_LIMIT_ARG=$2
            case "${SIZE_LIMIT: -1}" in
                K|k) SIZE_LIMIT=$(( ${SIZE_LIMIT%K*} * 1024 )) ;;
                M|m) SIZE_LIMIT=$(( ${SIZE_LIMIT%M*} * 1024 * 1024 )) ;;
                G|g) SIZE_LIMIT=$(( ${SIZE_LIMIT%G*} * 1024 * 1024 * 1024 )) ;;
            esac
            shift 2
            ;;
        --*|-*)
            failure "Unknown parameter: $1"
            ;;
        *)
            # If the package doesn't contain a category, prepend '*' to match any category
            if [[ "$1" != */* ]]; then
                ARG_PACKAGES_TO_REMOVE+=("*/$1")
            else
                ARG_PACKAGES_TO_REMOVE+=("$1")
            fi
            shift
            ;;
    esac
done

# Check if package parameter is provided and package exists
[[ ! -z "${PKGCACHE_DIR}" ]] || show_usage
[[ ! -z "${ARG_PACKAGES_TO_REMOVE}" ]] || [ ${SIZE_LIMIT} ] || show_usage

# Convert wildcard to regex
convert_to_regex() {
    local WILDCARD="$1"
    WILDCARD="${WILDCARD//\*/.*}"
    WILDCARD="${WILDCARD//\?/.}"
    echo "^${WILDCARD}(-[0-9][0-9.a-zA-Z]*)?(_p[0-9]+)?(-r[0-9]+)?$"
}

# Convert package names with wildcards to regex
declare -a ARG_PACKAGES_TO_REMOVE_REGEX
for PACKAGE in "${ARG_PACKAGES_TO_REMOVE[@]}"; do
    ARG_PACKAGES_TO_REMOVE_REGEX+=("$(convert_to_regex "$PACKAGE")")
done

# Process metadata file
PKGCACHE_METADATA="${PKGCACHE_DIR}/Packages"
PACKAGES_COUNT=$(grep -oP '^PACKAGES: \K[0-9]+' "${PKGCACHE_METADATA}")
VAR_METADATA_NEW=""
ENTRY=""
unset ENTRY_DELETE
unset METADATA_MODIFIED
while IFS= read -r LINE || [[ -n $LINE ]]; do
    if [[ -z "${LINE}" ]]; then
        ENTRY_PACKAGE=$(awk -F'/' '{print $1"/"$2}' <<< "${ENTRY_PATH}")
        ENTRY_VERSION="${ENTRY_CPV#"$ENTRY_PACKAGE-"}"
        ENTRY_PACKAGE_VERSIONED="${ENTRY_PACKAGE}-${ENTRY_VERSION}"
        for PACKAGE_REGEX in "${ARG_PACKAGES_TO_REMOVE_REGEX[@]}"; do
            if [[ ! ${SIZE_LIMIT} ]] || [[ ${ENTRY_SIZE} -gt ${SIZE_LIMIT} ]]; then
                if [[ ! -z "${ENTRY_CPV}" ]] && [[ "${ENTRY_PACKAGE_VERSIONED}" =~ ${PACKAGE_REGEX} ]]; then
                    ENTRY_DELETE=true
                fi
            fi
        done
        if [[ ! -z "${ENTRY_CPV}" ]] && [[ -z "${ARG_PACKAGES_TO_REMOVE_REGEX}" ]] && [[ ${ENTRY_SIZE} -gt ${SIZE_LIMIT} ]]; then
            ENTRY_DELETE=true
        fi
        if [[ -n ${ENTRY_DELETE} ]]; then
            echo "Removing ${ENTRY_CPV} [${ENTRY_PATH}]"
            ((PACKAGES_COUNT--)) || PACKAGES_COUNT=0
            METADATA_MODIFIED=true
            rm -f "${PKGCACHE_DIR}/${ENTRY_PATH}"
        else
            VAR_METADATA_NEW+="${ENTRY}\n"
        fi
        ENTRY=""; ENTRY_CPV=""; ENTRY_PATH=""; ENTRY_SIZE=0; unset ENTRY_DELETE
    else
        ENTRY+="${LINE}\n"
        KEY=${LINE%% *}
        if [[ "${KEY}" == "CPV:" ]]; then
            ENTRY_CPV=${LINE#* }
        elif [[ "${KEY}" == "PATH:" ]]; then
            ENTRY_PATH=${LINE#* }
        elif [[ "${KEY}" == "SIZE:" ]]; then
            ENTRY_SIZE=${LINE#* }
        fi
    fi
done < "${PKGCACHE_METADATA}"

# Save changes
if [ ${METADATA_MODIFIED} ]; then
    echo -e "${VAR_METADATA_NEW}" > "${PKGCACHE_METADATA}"
    sed -i "s/^PACKAGES: .*/PACKAGES: $PACKAGES_COUNT/" "${PKGCACHE_METADATA}"
elif [ ${SIZE_LIMIT} ]; then
    echo "Packages: ${ARG_PACKAGES_TO_REMOVE[@]} larger than ${SIZE_LIMIT_ARG} not found in repository."
else
    echo "Packages: ${ARG_PACKAGES_TO_REMOVE[@]} not found in repository."
fi
