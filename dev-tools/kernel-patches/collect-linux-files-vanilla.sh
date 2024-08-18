#!/bin/bash

source ../../.env-shared.sh || exit 1
source "${PATH_EXTRA_ENV_KERNEL_PATCHES}" || failure "Failed to load env ${PATH_EXTRA_ENV_KERNEL_PATCHES}"

files_to_collect=()
for file in "${KP_PATH_PATCHES_USED}"/*.patch; do
	while IFS= read -r line; do
		if [[ "$line" == *"+++"* ]]; then
			file_path=$(echo "$line" | sed 's/^+++ b\///')
			files_to_collect+=($file_path)
		fi
	done < $file
done
files=$(echo ${files_to_collect[@]} | tr ' ' '\n' | sort -u)

find_version_pwd=$(dirname ${PATH_SCRIPT_KERNEL_EBUILD_FIND_VERSION})
cd $find_version_pwd
kernel_version=$(bash $(basename ${PATH_SCRIPT_KERNEL_EBUILD_FIND_VERSION}))
kernel_version_base=$(echo ${kernel_version} | cut -d"." -f1,2)
cd -
kernel_url_base="https://raw.githubusercontent.com/torvalds/linux"
echo "$kernel_version"
rm -rf "${KP_PATCH_LINUX_FILES_VANILLA}"
for file in ${files[@]}; do
	local_path="${KP_PATH_LINUX_FILES_VANILLA}/${file}"
	local_dir="$(dirname ${local_path})"
	mkdir -p "${local_dir}"
	url="${kernel_url_base}/v${kernel_version_base}/${file}"
	wget "${url}" -O "${local_path}" --quiet || (echo ">> [OK] File ${url} not found in remote repository" && rm -f ${local_path})
done
