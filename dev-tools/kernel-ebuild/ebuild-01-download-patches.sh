#!/bin/bash

source ../../.env-shared.sh || exit 1
source "${PATH_EXTRA_ENV_KERNEL_EBUILD}" --accept-custom-flags || failure "Failed to load env ${PATH_EXTRA_ENV_KERNEL_EBUILD}"

patches=("$@")

# Prepare additional error handling and cleanup before start.
register_failure_handler 'rm -rf "${KE_PATH_WORK_PATCHES}";'

for file in "${KE_PATH_DATA_PATCHES_LISTS}"/*.txt; do
    patch_set_file_name="$(basename \"${file}\")"
    patch_set_name="${patch_set_file_name%.*}"

    if [[ -z "${patches[@]}" ]] || [[ ${patches[@]} =~ $patch_set_name ]]; then
        empty_directory "${KE_PATH_WORK_PATCHES}/${patch_set_name}"
        readarray -t URL_PS3_PATCHES < <(grep -vE '^\s*#|^\s*$' "${file}")

        # Download patches.
        echo "Downloading patches to ${KE_PATH_WORK_PATCHES}/${patch_set_name}"
        cd "${KE_PATH_WORK_PATCHES}/${patch_set_name}"
        DIR="${KE_PATH_WORK_PATCHES}/${patch_set_name}"
        for URL_PATCH in "${URL_PS3_PATCHES[@]}"; do
	    echo "${URL_PATCH}"
	    if [[ "${URL_PATCH}" == *'|'* ]]; then
		    URL=$(echo "${URL_PATCH}" | cut -d'|' -f1)
		    FILENAME=$(echo "${URL_PATCH}" | cut -d'|' -f2)
	    else
		    URL="${URL_PATCH}"
	            FILENAME="$(basename ${URL})"
            fi
            wget ${URL} --quiet -P "${DIR}/${FILENAME}"
        done
    fi

done
