#!/bin/bash

source ../../.env-shared.sh || exit 1
source "${PATH_EXTRA_ENV_KERNEL_EBUILD}" || failure "Failed to load env ${PATH_EXTRA_ENV_KERNEL_EBUILD}"

# Prepare additional error handling and cleanup before start.
register_failure_handler 'rm -rf "${KE_PATH_WORK_PATCHES}";'
empty_directory "${KE_PATH_WORK_PATCHES}"

for file in "${KE_PATH_DATA_PATCHES_LISTS}"/*.txt; do
    patch_set_file_name="$(basename \"${file}\")"
    patch_set_name="${patch_set_file_name%.*}"

    mkdir -p "${KE_PATH_WORK_PATCHES}/${patch_set_name}"
    readarray -t URL_PS3_PATCHES < <(grep -vE '^\s*#|^\s*$' "${file}")

    # Download patches.
    echo "Downloading patches to ${KE_PATH_WORK_PATCHES}/${patch_set_name}"
    cd "${KE_PATH_WORK_PATCHES}/${patch_set_name}"
    for URL_PATCH in "${URL_PS3_PATCHES[@]}"; do
	echo "${URL_PATCH}"
	if [[ "${URL_PATCH}" == *'|'* ]]; then
		URL=$(echo "${URL_PATCH}" | cut -d'|' -f1)
		DIR_NAME=$(echo "${URL_PATCH}" | cut -d'|' -f2)
		DIR="${KE_PATH_WORK_PATCHES}/${patch_set_name}/${DIR_NAME}"
		mkdir -p "${DIR_NAME}"
	else
		URL="${URL_PATCH}"
		DIR="${KE_PATH_WORK_PATCHES}/${patch_set_name}"
	fi
        wget ${URL} --quiet -P "${DIR}"
        FILENAME="$(basename ${URL})"
        [[ ${FILENAME} == *.patch ]] || mv "${DIR}/${FILENAME}" "${DIR}/${FILENAME}.patch"
    done
done
