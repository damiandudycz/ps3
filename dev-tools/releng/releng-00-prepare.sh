#!/bin/bash

# This script prepares catalyst files for a new release.
# It will fetch the new snapshot and seed, and then generage spec files.
# At the beggining it also checks if there is a need to release a new ps3-gentoo-installer
# ebuild, and asks if you want to release it first, so that it can be used in the new build.

source ../../.env-shared.sh || exit 1
source "${PATH_EXTRA_ENV_RELENG}" || failure "Failed to load env ${PATH_EXTRA_ENV_RELENG}"

if [[ -z "${RL_TARGETS}" ]]; then
	FILTER_TARGETS=false
else
	FILTER_TARGETS=true
fi

if [[ "${RL_FLAG_CLEAN}" = true ]]; then
	empty_directory "/var/tmp/catalyst/builds/23.0-default"
	empty_directory "/var/tmp/catalyst/tmp/23.0-default"
fi
empty_directory "${PATH_WORK_RELENG}"
rm -rf "/tmp/catalyst-auto"*

# Ask if should update installer if there are any changes pending.
(source ${PATH_SCRIPT_PS3_INSTALLER_UPDATE} --ask)

# Copy helper files.
cp -rf "${PATH_RELENG_TEMPLATES}/"* "${PATH_WORK_RELENG}/"

# Download stage3 seed.
readonly LATEST_GENTOO_CONTENT=$(wget -q -O - "${URL_STAGE3_INFO}" --no-http-keep-alive --no-cache --no-cookies --no-check-certificate) # TODO: Remove --no-check-certificate
readonly LATEST_STAGE3=$(echo "${LATEST_GENTOO_CONTENT}" | grep "${CONF_TARGET_ARCH}-openrc" | head -n 1 | cut -d' ' -f1)
readonly LATEST_STAGE3_FILENAME=$(basename "${LATEST_STAGE3}")
readonly SEED_RE_VAL_TIMESTAMP=$(echo "${LATEST_STAGE3_FILENAME}" | sed -n 's/.*-\([0-9]\{8\}T[0-9]\{6\}Z\)\.tar\.xz/\1/p')
readonly PATH_STAGE3_SEED="${PATH_CATALYST_BUILDS_DEFAULT}/${LATEST_STAGE3_FILENAME}"
readonly URL_GENTOO_TARBALL="$URL_RELEASE_GENTOO/$LATEST_STAGE3"
[[ -z "${LATEST_STAGE3}" ]] && failure "Failed to download Stage3 URL"
[[ -f "${PATH_STAGE3_SEED}" ]] || wget "${URL_GENTOO_TARBALL}" -O "${PATH_STAGE3_SEED}" --no-check-certificate

# Prepare portage directories - copy releng bases.
for spec_dir in "${PATH_WORK_RELENG}/portage/"*; do
    releng_base_file="$spec_dir/releng_base"
    if [[ -f "$releng_base_file" ]]; then
        releng_base=$(cat "$releng_base_file")
        releng_base_dir="${PATH_RELENG_PORTAGE_CONFDIR}/${releng_base}${CONF_QEMU_RELENG_POSTFIX}"
        cp -ru "${releng_base_dir}/"* "${spec_dir}/"
        rm "$releng_base_file"
    fi
done

# Sort spec files by inheritance
readonly SPEC_DIR="${PATH_RELENG_TEMPLATES}/specs"

sort_array() {
    local array=("${!1}")
    local sorted_array
    IFS=$'\n' sorted_array=($(sort <<<"${array[*]}"))
    unset IFS
    echo "${sorted_array[@]}"
}

contains_string() {
    local array=("${!1}")
    local search_string="$2"
    local found=0

    for element in "${array[@]}"; do
        if [[ "$element" == "$search_string" ]]; then
            found=1
            break
        fi
    done

    if [[ $found -eq 1 ]]; then
        return 0  # true
    else
        return 1  # false
    fi
}

get_parent_source() {
	filename="$1"
	source=$(cat "$SPEC_DIR/$filename" | sed -n 's/^source_subpath: [^/]*\/\([^@]*\)\(-@TIMESTAMP@\)\?$/\1/p')
	echo $source
}

spec_files=()
while IFS= read -r file; do
    spec_file="$(basename $file)"
    if [[ "${FILTER_TARGETS}" = true ]]; then
	# Find at least one matching regex for this spec file
	add=false
	for regex in "${RL_TARGETS[@]}"; do
        	if [[ "$spec_file" == $regex* ]]; then
			add=true
		fi
	done
	if [[ "$add" = true ]]; then
		spec_files+=("${spec_file}")
	fi
    else
	spec_files+=("${spec_file}")
    fi
done < <(find "$SPEC_DIR" -type f -name "*.spec")
spec_files=($(sort_array spec_files[@]))

SPECS_LIST=()
process_spec() {
    local spec_file="$1"
    local parent_file="$(get_parent_source $spec_file).spec"
    if [[ -f "$SPEC_DIR/$parent_file" ]]; then
        process_spec "$parent_file"
    fi
    if ! contains_string SPECS_LIST[@] "$spec_file"; then
        SPECS_LIST+=($spec_file)
    fi
}
for spec in "${spec_files[@]}"; do
    process_spec $spec
done
SPECS_LIST="${SPECS_LIST[@]}"

# Configure catalyst-auto-conf script.
sed -i "s|@SPECS_DIR@|${PATH_WORK_RELENG}/specs|g" "${RL_PATH_CATALYST_AUTO_CONF_DST}"
sed -i "s|@SPECS@|${SPECS_LIST}|g" "${RL_PATH_CATALYST_AUTO_CONF_DST}"
sed -i "s|@EMAIL_FROM@|${CONF_RELEASE_EMAIL_FROM}|g" "${RL_PATH_CATALYST_AUTO_CONF_DST}"
sed -i "s|@EMAIL_TO@|${CONF_RELEASE_EMAIL_TO}|g" "${RL_PATH_CATALYST_AUTO_CONF_DST}"
sed -i "s|@EMAIL_PREPEND@|${CONF_RELEASE_EMAIL_PREPEND}|g" "${RL_PATH_CATALYST_AUTO_CONF_DST}"

# Configure variables in spec files.
for spec_file in "${PATH_WORK_RELENG}/specs/"*.spec; do
    sed -i "s|@INTERPRETER@|${RL_VAL_INTERPRETER_ENTRY}|g" "${spec_file}"
    sed -i "s|@REPOS@|${PATH_OVERLAYS_PS3_GENTOO}|g" "${spec_file}"
    sed -i "s|@PORTAGE_CONFDIR@|${PATH_WORK_RELENG}/portage|g" "${spec_file}"
    sed -i "s|@FSSCRIPTS@|${PATH_WORK_RELENG}/fsscripts|g" "${spec_file}"
    sed -i "s|@OVERLAYS@|${PATH_WORK_RELENG}/overlays|g" "${spec_file}"
    sed -i "s|@ROOT_OVERLAYS@|${PATH_WORK_RELENG}/root_overlays|g" "${spec_file}"
    sed -i "s|@PKGCACHE_PATH@|${PATH_RELENG_RELEASES_BINPACKAGES}|g" "${spec_file}"
done

# Copy everything from distfiles overlay to cache, so that it's available during emerge even if packages were not yet uploaded to git.
source ${PATH_OVERLAY_SCRIPT_COPY_PS3_FILES}
