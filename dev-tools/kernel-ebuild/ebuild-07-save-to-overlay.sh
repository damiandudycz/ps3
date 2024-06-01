#!/bin/bash

source ../../.env-shared.sh || exit 1
source "${PATH_EXTRA_ENV_KERNEL_EBUILD}" || failure "Failed to load env ${PATH_EXTRA_ENV_KERNEL_EBUILD}"

# Verify data.
[[ -d "${KE_PATH_WORK_EBUILD_DISTFILES}" ]] || failure "KE_PATH_WORK_EBUILD_DISTFILES not found at: ${KE_PATH_WORK_EBUILD_DISTFILES}"
[[ -f "${KE_PATH_EBUILD_FILE_DST}" ]] || failure "KE_PATH_EBUILD_FILE_DST not found at: ${KE_PATH_EBUILD_FILE_DST}"

readonly TMP_MANIFEST=$(mktemp)
register_failure_handler 'rm -f ${TMP_MANIFEST}'

# Copy distfiles and ebuild.
cp -rf "${KE_PATH_WORK_EBUILD_DISTFILES}"/* "${KE_PATH_OVERLAY_DISTFILES}"/
cp -f "${KE_PATH_EBUILD_FILE_DST}" "${KE_PATH_OVERLAY_EBUILD_FILE_PACKAGE}"

# Merge new manifest to overlay manifest.
if [[ -f "${KE_PATH_OVERLAY_EBUILD_FILE_MANIFEST}" ]]; then
    awk '
        { B_entries[$1 " " $2] = $0 }
        END {
            for (entry in A_entries) { print A_entries[entry] }
            for (entry in B_entries) { if (!(entry in A_entries)) { print B_entries[entry] } }
        }
    ' "${KE_PATH_OVERLAY_EBUILD_FILE_MANIFEST}" "${KE_PATH_EBUILD_FILE_MANIFEST}" | sort > "${TMP_MANIFEST}"
    mv "${TMP_MANIFEST}" "${KE_PATH_OVERLAY_EBUILD_FILE_MANIFEST}"
else
    rm -f "${TMP_MANIFEST}"
    cp "${KE_PATH_EBUILD_FILE_MANIFEST}" "${KE_PATH_OVERLAY_EBUILD_FILE_MANIFEST}"
fi

echo "Ebuild and distfiles saved in ${KE_PATH_OVERLAY_EBUILD_FILE_PACKAGE}, ${KE_PATH_OVERLAY_DISTFILES}"
