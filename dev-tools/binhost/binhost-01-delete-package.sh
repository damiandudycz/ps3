#!/bin/bash

# This script deletes a specified package from the binhost repository.
# Usage example: ./binhost-delete-package.sh sys-kernel/gentoo-kernel-ps3.

# --- Shared environment
source ../../.env-shared.sh || exit 1
trap failure ERR
register_usage "$0 <pckage>"

readonly CONF_PACKAGE_NAME="$1"
readonly CONF_PACKAGE_VERSION="$2"
readonly CONF_RELEASE_NAME="${CONF_CATALYST_RELEASE_NAME_DFAULT}"
readonly PATH_BINHOST="${PATH_BINHOSTS_PS3_GENTOO}/${CONF_RELEASE_NAME}"
readonly PATH_BINHOST_METADATA="${PATH_BINHOST}/Packages"

# Check if package parameter is provided and package exists
[[ ! -z "${CONF_PACKAGE_NAME}" ]] || show_usage
[[ -d "${PATH_BINHOST}/${CONF_PACKAGE_NAME}" ]] || failure "Package ${CONF_PACKAGE_NAME} not found in ${PATH_BINHOST}"

# Temp file.
readonly TEMP_DELETE_FILE=$(mktemp)
trap 'rm -f "$TEMP_DELETE_FILE"' EXIT

ENTRY=""
PACKAGES_COUNT=$(grep -oP '^PACKAGES: \K[0-9]+' "${PATH_BINHOST_METADATA}")
PACKAGE_FOUND=false

while IFS= read -r LINE || [[ -n $LINE ]]; do
    if [[ -n "$LINE" ]]; then
        ENTRY+="$LINE"$'\n'
    else
        if [[ "$ENTRY" == *"${CONF_PACKAGE_NAME}"* ]]; then
            PATH_PACKAGE=$(echo "$ENTRY" | grep -Po 'PATH: \K.*')
            if [[ -n "$PATH_PACKAGE" && -f "${PATH_BINHOST}/$PATH_PACKAGE" ]]; then
                rm -f "${PATH_BINHOST}/$PATH_PACKAGE"
                echo "Removed file: ${PATH_BINHOST}/$PATH_PACKAGE"
            fi
            ((PACKAGES_COUNT--))
            PACKAGE_FOUND=true
       else
            echo -e "$ENTRY" >> "$TEMP_DELETE_FILE"
        fi
        ENTRY=""
    fi
done < "$PATH_BINHOST_METADATA"

if [[ "$ENTRY" == *"${CONF_PACKAGE_NAME}"* ]]; then
    PATH_PACKAGE=$(echo "$ENTRY" | grep -Po 'PATH: \K.*')
    if [[ -n "$PATH_PACKAGE" && -f "${PATH_BINHOST}/$PATH_PACKAGE" ]]; then
        rm -f "${PATH_BINHOST}/$PATH_PACKAGE"
        echo "Removed file: ${PATH_BINHOST}/$PATH_PACKAGE"
    fi
    ((PACKAGES_COUNT--))
    PACKAGE_FOUND=true
else
    echo -e "$ENTRY" >> "$TEMP_DELETE_FILE"
fi

if $PACKAGE_FOUND; then
    mv "$TEMP_DELETE_FILE" "${PATH_BINHOST_METADATA}"
    sed -i "s/^PACKAGES: .*/PACKAGES: $PACKAGES_COUNT/" "${PATH_BINHOST_METADATA}"
    echo "Package ${CONF_PACKAGE_NAME} removed from repository."
else
    rm -f "$TEMP_DELETE_FILE"
    echo "Package ${CONF_PACKAGE_NAME} not found in repository."
fi
