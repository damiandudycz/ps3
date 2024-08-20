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
empty_directory "${PATH_WORK_RELENG}_2"
#rm -rf "/tmp/catalyst-auto"*

# Ask if should update installer if there are any changes pending.
#(source ${PATH_SCRIPT_PS3_INSTALLER_UPDATE} --ask)

# Copy helper files.
cp -rf "${PATH_RELENG_TEMPLATES}/"* "${PATH_WORK_RELENG}_2/"

# Download stage3 seed.
readonly LATEST_GENTOO_CONTENT=$(wget -q -O - "${URL_STAGE3_INFO}" --no-http-keep-alive --no-cache --no-cookies --no-check-certificate) # TODO: Remove --no-check-certificate
readonly LATEST_STAGE3=$(echo "${LATEST_GENTOO_CONTENT}" | grep "${CONF_TARGET_ARCH}-openrc" | head -n 1 | cut -d' ' -f1)
readonly LATEST_STAGE3_FILENAME=$(basename "${LATEST_STAGE3}")
readonly SEED_RE_VAL_TIMESTAMP=$(echo "${LATEST_STAGE3_FILENAME}" | sed -n 's/.*-\([0-9]\{8\}T[0-9]\{6\}Z\)\.tar\.xz/\1/p')
readonly PATH_STAGE3_SEED="${PATH_CATALYST_BUILDS_DEFAULT}/${LATEST_STAGE3_FILENAME}"
readonly URL_GENTOO_TARBALL="$URL_RELEASE_GENTOO/$LATEST_STAGE3"
#[[ -z "${LATEST_STAGE3}" ]] && failure "Failed to download Stage3 URL"
#[[ -f "${PATH_STAGE3_SEED}" ]] || wget "${URL_GENTOO_TARBALL}" -O "${PATH_STAGE3_SEED}" --no-check-certificate

# Prepare portage directories - copy releng bases.
for spec_dir in "${PATH_WORK_RELENG}_2/portage/"*; do
    releng_base_file="$spec_dir/releng_base"
    if [[ -f "$releng_base_file" ]]; then
        releng_base=$(cat "$releng_base_file")
        releng_base_dir="${PATH_RELENG_PORTAGE_CONFDIR}/${releng_base}${CONF_QEMU_RELENG_POSTFIX}"
        cp -ru "${releng_base_dir}/"* "${spec_dir}/"
        rm "$releng_base_file"
    fi
done

# Get the list of specs to build in order:

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

# All specs or only matching specified
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

echo "SF1: ${spec_files[@]} - only specified or all in none specified"

# Find specs to skip, due to specyfying --use <spec> flag. Only will skip if build exists and it's not explicitly specified to be build.
# Other specs will be updated to use existing source build instead of new one.
spec_files_skipped=()

process_skipped_targets() {
	matching_specs="$1[@]"
	directory="$2"

echo "MATCHING: ${matching_specs}"
echo "DIR: ${directory}"

	for match in ${matching_specs[@]}; do
		skip_spec_basename=$(basename $match)
		skip_spec_target="${skip_spec_basename%.*}"
		matching_files=($(find ${directory} -type f -name "${skip_spec_target}-*.tar.xz" | sort -r))
		# Remove main patch from found fuilds
		if [[ -n ${matching_files[@]} ]]; then
			used_build="${matching_files[0]}"
			used_build_name="$(basename $used_build)"
			used_build_name="$(echo $used_build_name | cut -d'.' -f1)"

			# Find out if target to skip was not explicitly stated to be build.
			can_skip=true
			for explicit_target in ${RL_TARGETS[@]}; do
				if [[ "${used_build_name}" == "${explicit_target}"* ]]; then
					can_skip=false
				fi
			done

			if [[ "${can_skip}" = true ]]; then
				# TODO: - Do this. Otherwise it can happend, that newest build not always will be used to skip.
				echo "Check if the same build if already skipped and if it is, but this one if of better date - replace it with new one"
			fi

			if [[ "${can_skip}" = true ]]; then
				echo "[WILL USE EXISTING BUILD: ${used_build_name}]"
				# RESTORE: cp "${used_build}"* "${PATH_CATALYST_BUILDS_DEFAULT}"/
				spec_files=("${spec_files[@]/${skip_spec_target}.spec}")
				spec_files_skipped+=("${skip_spec_target}")
				# TODO: Replace source in other spec files to this one. Store them in array and replace later with SED in all specs that might contain it.
#				echo "In every produced spec file replace string source_subpath: 23.0-default/${skip_spec_target}-@TIMESTAMP@ with ${used_build_name}"
#				echo "Remove from SPECS_LIST: $skip_spec_target"
			fi
		fi
	done
}

for target in "${RL_SKIP[@]}"; do
	matching_specs="$(ls ${PATH_WORK_RELENG}_2/specs/${target}*.spec)"
	process_skipped_targets "${matching_specs}" "${PATH_RELEASES_PS3_GENTOO_DEFAULT}"
	process_skipped_targets "${matching_specs}" "${PATH_CATALYST_BUILDS_DEFAULT}"
done

echo "SKIPPED: ${spec_files_skipped[@]}"
echo "SF2: ${spec_files[@]} - should remove skipped found here"

# List of actual specs to be build - sorted by inheritance.
SPECS_LIST=()
process_spec() {
    local spec_file="$1"
    if ! contains_string spec_files_skipped[@] "${spec_file%.*}"; then
        local parent_file="$(get_parent_source $spec_file).spec"
        if [[ -f "$SPEC_DIR/$parent_file" ]]; then
            process_spec "$parent_file"
        fi
        if ! contains_string SPECS_LIST[@] "${spec_file}.spec"; then
            SPECS_LIST+=($spec_file)
        fi
    fi
}
for spec in "${spec_files[@]}"; do
    process_spec $spec
done
SPECS_LIST=(${SPECS_LIST[@]})

echo "FINAL LIST TO BUILD: ${SPECS_LIST[@]}"

# Configure catalyst-auto-conf script.
sed -i "s|@SPECS_DIR@|${PATH_WORK_RELENG}_2/specs|g" "${RL_PATH_CATALYST_AUTO_CONF_DST}"
sed -i "s|@SPECS@|${SPECS_LIST}|g" "${RL_PATH_CATALYST_AUTO_CONF_DST}"
sed -i "s|@EMAIL_FROM@|${CONF_RELEASE_EMAIL_FROM}|g" "${RL_PATH_CATALYST_AUTO_CONF_DST}"
sed -i "s|@EMAIL_TO@|${CONF_RELEASE_EMAIL_TO}|g" "${RL_PATH_CATALYST_AUTO_CONF_DST}"
sed -i "s|@EMAIL_PREPEND@|${CONF_RELEASE_EMAIL_PREPEND}|g" "${RL_PATH_CATALYST_AUTO_CONF_DST}"

# Configure variables in spec files.
for spec_file in "${PATH_WORK_RELENG}_2/specs/"*.spec; do
    sed -i "s|@INTERPRETER@|${RL_VAL_INTERPRETER_ENTRY}|g" "${spec_file}"
    sed -i "s|@REPOS@|${PATH_OVERLAYS_PS3_GENTOO}|g" "${spec_file}"
    sed -i "s|@PORTAGE_CONFDIR@|${PATH_WORK_RELENG}/portage|g" "${spec_file}"
    sed -i "s|@FSSCRIPTS@|${PATH_WORK_RELENG}/fsscripts|g" "${spec_file}"
    sed -i "s|@OVERLAYS@|${PATH_WORK_RELENG}/overlays|g" "${spec_file}"
    sed -i "s|@ROOT_OVERLAYS@|${PATH_WORK_RELENG}/root_overlays|g" "${spec_file}"
    sed -i "s|@PKGCACHE_PATH@|${PATH_RELENG_RELEASES_BINPACKAGES}|g" "${spec_file}"
done

echo "[Build specs: ${SPECS_LIST[@]}]"

# Copy everything from distfiles overlay to cache, so that it's available during emerge even if packages were not yet uploaded to git.
#source ${PATH_OVERLAY_SCRIPT_COPY_PS3_FILES}
