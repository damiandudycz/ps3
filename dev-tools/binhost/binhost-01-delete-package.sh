#!/bin/bash

# This script deletes a specified package from the binhost repository.
# Usage example: ./binhost-delete-package.sh sys-kernel/gentoo-kernel-ps3.

# --- Shared environment
source ../../.env-shared.sh || exit 1
trap failure ERR
register_usage "$0 <pckage>[-version]"

readonly ARG_PACKAGES_TO_REMOVE=("$@")
readonly CONF_RELEASE_NAME="${CONF_CATALYST_RELEASE_NAME_DFAULT}"
readonly PATH_BINHOST="${PATH_BINHOSTS_PS3_GENTOO}/${CONF_RELEASE_NAME}"
readonly PATH_BINHOST_METADATA="${PATH_BINHOST}/Packages"

# Check if package parameter is provided and package exists
[[ ! -z "${ARG_PACKAGES_TO_REMOVE}" ]] || show_usage
[[ -d "${PATH_BINHOST}/${CONF_PACKAGE_NAME}" ]] || failure "Package ${CONF_PACKAGE_NAME} not found in ${PATH_BINHOST}"

# Process metadata file
PACKAGES_COUNT=$(grep -oP '^PACKAGES: \K[0-9]+' "${PATH_BINHOST_METADATA}")
VAR_METADATA_NEW=""
ENTRY=""
unset ENTRY_DELETE
unset METADATA_MODIFIED
while IFS= read -r LINE || [[ -n $LINE ]]; do
    # New line means we are starting new entry.
    if [[ -z "${LINE}" ]]; then
	# Process entry
        ENTRY_PACKAGE=$(awk -F'/' '{print $1"/"$2}' <<< "${ENTRY_PATH}") # sys-kernel/gentoo-kernel-ps3
        ENTRY_VERSION="${ENTRY_CPV#"$ENTRY_PACKAGE-"}"
        ENTRY_PACKAGE_VERSIONED="${ENTRY_PACKAGE}-${ENTRY_VERSION}"
        # Check if package is present in specified packages to delete
        for PACKAGE_TO_REMOVE in ${ARG_PACKAGES_TO_REMOVE[@]}; do
            # Check if package to remove equals given package to remove including versioning
            if [[ "${ENTRY_PACKAGE_VERSIONED}" == "${PACKAGE_TO_REMOVE}"* ]] && [[ "${PACKAGE_TO_REMOVE}" == "${ENTRY_PACKAGE}"* ]]; then
                # Checks if version ending charakters are not different.
                # This is done, so that setting for example 6.8.1 doesn't remove 6.8.11
                REMAINING="${ENTRY_PACKAGE_VERSIONED#${PACKAGE_TO_REMOVE}}"
                [[ ! "$REMAINING" =~ ^[0-9] ]] && ENTRY_DELETE=true
            fi
        done
        if [[ -n ${ENTRY_DELETE} ]]; then
            # Package was market to delete
            echo "Removing ${ENTRY_CPV}"
            ((PACKAGES_COUNT--))
            METADATA_MODIFIED=true
            rm -f "${PATH_BINHOST}/${ENTRY_PATH}"
        else
            # Add entry if shoudn't delete it
            VAR_METADATA_NEW+="${ENTRY}\n"
        fi
        # Reset variables
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
done < "$PATH_BINHOST_METADATA"

# Save changes
if [ ${METADATA_MODIFIED} ]; then
    echo -e "${VAR_METADATA_NEW}" > "${PATH_BINHOST_METADATA}"
    sed -i "s/^PACKAGES: .*/PACKAGES: $PACKAGES_COUNT/" "${PATH_BINHOST_METADATA}"
else
    echo "Packages: ${ARG_PACKAGES_TO_REMOVE[@]} not found in repository."
fi
