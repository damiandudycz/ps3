#!/bin/bash

source ../../.env-shared.sh --silent || exit 1
source "./catalyst-lab.conf" # TODO: Store conf in /etc/catalyst-lab.sh

# Constants:

declare -A TARGET_MAPPINGS=([livecd-stage1]=livecd [livecd-stage2]=livecd)
readonly STAGE_VARIABLES=(platform release stage subarch target version_stamp source_subpath parent catalyst_conf source_url available_build rebuild)
readonly PKGCACHE_PATH=${PATH_RELENG_RELEASES_BINPACKAGES}
readonly TIMESTAMP=$(date -u +"%Y%m%dT%H%M%SZ") # Current timestamp.
readonly WORK_PATH=/tmp/catalyst-lab-${TIMESTAMP}
CLEAN_BUILD=false

# Script arguments:

declare -a selected_stages_templates
while [ $# -gt 0 ]; do case ${1} in
	--update-snapshot) FETCH_FRESH_SNAPSHOT=true;;
	--clean) CLEAN_BUILD=true;; # Perform clean build - don't use any existing sources even if available (Except for downloaded seeds).
	--*) echo "Unknown option ${1}"; exit;;
	*) selected_stages_templates+=("${1}")
esac; shift; done

# Functions:

# Get list of directories in given directory.
get_directories() {
	local path=${1}
	local directories=($(find ${path} -mindepth 1 -maxdepth 1 -type d -exec basename {} \; | sort))
	echo ${directories[@]}
}

# Read variables of stage at index. Use this in functions that sould work with given stage, instead of loading all variables manually.
# Use prefix if need to compare with other stage variables.
use_stage() {
	local prefix=${2}
	for variable in ${STAGE_VARIABLES[@]}; do
		eval ${prefix}${variable}=${stages[${1},${variable}]}
	done
	# Load parent info
	if [[ -z ${prefix} ]]; then
		parent_index=""
		local i; for (( i=0; i<$stages_count; i++ )); do
			use_stage ${i} parent_
			local parent_product=${parent_platform}/${parent_release}/${parent_target}-${parent_subarch}-${parent_version_stamp}
			if [[ ${source_subpath} == ${parent_product} ]]; then
				parent_index=${i}
				break
			fi
		done
		if [[ -z ${parent_index} ]]; then # If parent not found, clean it's data
		        for variable in ${STAGE_VARIABLES[@]}; do
		                unset parent_${variable}
		        done
		fi
	fi
}

# Return value of given property from given spec file.
read_spec_variable() {
	local spec_path=${1}
	local variable_name=${2}
	# get variable from spec file and trim whitespaces.
	local value=$(cat ${spec_path} | sed -n "/^${variable_name}:/s/^${variable_name}:\(.*\)/\1/p" | tr -d '[:space:]')
	echo ${value}
}

# Update value in given spec or add if it's not present there
set_spec_variable() {
	local spec_path=${1}
	local key=${2}
	local new_value="${3}"
	if grep -q "^$key:" "${spec_path}"; then
		sed -i "s|^$key: .*|$key: $new_value|" ${spec_path}
	else
		echo "$key: $new_value" >> "${spec_path}"
	fi
}

# Fill tmp data in spec (@TIMESTAMP@, etc)
update_spec_variable() {
	local spec_path=${1}
	local key=${2}
	local new_value="${3}"
	sed -i "s|@${key}@|${new_value}|g" ${spec_path}
}

# Replace variables in given stage variable, by replacing some strings with calculated end results - TIMESTAMP, PLATFORM, STAGE.
sanitize_spec_variable() {
	local platform="$1"
	local release="$2"
	local stage="$3"
	local value="$4"
	echo "${value}" | sed "s/@REL_TYPE@/${release}/g" | sed "s/@PLATFORM@/${platform}/g" | sed "s/@STAGE@/${stage}/g"
	# TODO: Decide if add more variables. But be careful, with some variables it's better to leave intact until the end, like timestamp
}

#  Get portage snapshot version and download new if needed.
prepare_portage_snapshot() {
# TODO: If it's empty, prevent loadind, so that console error doesn't appear
	treeish=$(find ${PATH_CATALYST_TMP}/snapshots -type f -name "*.sqfs" -exec ls -t {} + | head -n 1 | xargs -n 1 basename -s .sqfs | cut -d '-' -f 2)
	if [[ -z ${treeish} ]] || [[ ${FETCH_FRESH_SNAPSHOT} = true ]]; then
		echo_color ${COLOR_TURQUOISE_BOLD} "[ Refreshing portage snapshot ]"
		catalyst -s stable
		treeish=$(find ${PATH_CATALYST_TMP}/snapshots -type f -name "*.sqfs" -exec ls -t {} + | head -n 1 | xargs -n 1 basename -s .sqfs | cut -d '-' -f 2)
		echo "" # New line
	fi
}

# Load list of stages to build for every platform and release.
# Prepare variables of every stage, including changes from sanitization process.
# Sort stages based on their inheritance.
load_stages() {
	declare -gA stages # Some details of stages retreived from scanning. (release,stage,target,source,has_parent).
	available_builds=$(find ${PATH_CATALYST_BUILDS} -type f -name "*.tar.xz" -printf '%P\n')
	stages_count=0 # Number of stages to build. Script will determine this value automatically.

	readonly RL_VAL_PLATFORMS=$(get_directories ${PATH_RELENG_TEMPLATES})
	for PLATFORM in ${RL_VAL_PLATFORMS[@]}; do
		local platform_path=${PATH_RELENG_TEMPLATES}/${PLATFORM}
		# Find list of releases. (23.0-default, 23.0-llvm, etc).
		RL_VAL_RELEASES=$(get_directories ${platform_path})
		# Collect information about stages in releases.
		for RELEASE in ${RL_VAL_RELEASES[@]}; do
			# (data/templates/23.0-default)
			local release_path=${platform_path}/${RELEASE}
			# Find list of stages in current releass. (stage1-cell-base-openrc stage3-cell-base-openrc, ...)
			RL_VAL_RELEASE_STAGES=$(get_directories ${release_path})
			for STAGE in ${RL_VAL_RELEASE_STAGES[@]}; do
				# (data/templates/23.0-default/stage1-openrc-cell-base)
				local stage_path=${PATH_RELENG_TEMPLATES}/${PLATFORM}/${RELEASE}/${STAGE}
				# (data/templates/23.0-default/stage1-openrc-cell-base/stage.spec)
				local stage_spec_path=${stage_path}/stage.spec
				if [[ -f ${stage_spec_path} ]]; then
					local stage_subarch=$(read_spec_variable ${stage_spec_path} subarch) # eq.: cell
					local stage_target=$(read_spec_variable ${stage_spec_path} target) # eq.: stage3
					local stage_stamp=$(read_spec_variable ${stage_spec_path} version_stamp) # eq.: base-openrc-@TIMESTAMP@
					local stage_source_subpath=$(read_spec_variable ${stage_spec_path} source_subpath)
					# Find custom catalyst.conf if any
					local platform_catalyst_conf=${platform_path}/catalyst.conf
					local release_catalyst_conf=${release_path}/catalyst.conf
					local stage_catalyst_conf=${stage_path}/catalyst.conf
					local catalyst_conf=""
					if
					     [[ -f ${stage_catalyst_conf} ]]; then catalyst_conf=${stage_catalyst_conf};
					elif [[ -f ${release_catalyst_conf} ]]; then catalyst_conf=${release_catalyst_conf};
					elif [[ -f ${platform_catalyst_conf} ]]; then catalyst_conf=${platform_catalyst_conf};
					fi
					# Find best matching local build available.
					local stage_product=${PLATFORM}/${RELEASE}/${stage_target}-${stage_subarch}-${stage_stamp}
					local stage_product_regex=$(echo $(sanitize_spec_variable ${PLATFORM} ${RELEASE} ${STAGE} ${stage_product}) | sed 's/@TIMESTAMP@/[0-9]{8}T[0-9]{6}Z/')
					local matching_stage_builds=($(printf "%s\n" "${available_builds[@]}" | grep -E "${stage_product_regex}"))
					local stage_available_build=$(printf "%s\n" "${matching_stage_builds[@]}" | sort -r | head -n 1)

					# Store variables
					stages[${stages_count},platform]=${PLATFORM}
					stages[${stages_count},release]=${RELEASE}
					stages[${stages_count},stage]=${STAGE}
					stages[${stages_count},subarch]=$(sanitize_spec_variable ${PLATFORM} ${RELEASE} ${STAGE} ${stage_subarch})
					stages[${stages_count},target]=$(sanitize_spec_variable ${PLATFORM} ${RELEASE} ${STAGE} ${stage_target})
					stages[${stages_count},version_stamp]=$(sanitize_spec_variable ${PLATFORM} ${RELEASE} ${STAGE} ${stage_stamp})
					stages[${stages_count},source_subpath]=$(sanitize_spec_variable ${PLATFORM} ${RELEASE} ${STAGE} ${stage_source_subpath})
					stages[${stages_count},catalyst_conf]=${catalyst_conf}
					stages[${stages_count},available_build]=${stage_available_build}
					stages_count=$((stages_count + 1))

				fi
			done
		done
	done

	# Sort stages array by inheritance:
	stages_order=() # Order in which stages should be build, for inheritance to work. (1,5,2,0,...).
	# Prepare stages order by inheritance.
	local i; for (( i=0; i<${stages_count}; i++ )); do
		insert_stage_with_inheritance ${i}
	done
	# Sort stages by inheritance order in temp array..
	declare -A stages_temp
	local i; for (( i=0; i<${stages_count}; i++ )); do
		local index=${stages_order[${i}]}
		for key in ${!stages[@]}; do
			if [[ ${key} == ${index},* ]]; then
				field=${key#*,}
				stages_temp[${i},${field}]=${stages[${key}]}
			fi
		done
	done
	# Write sorted array back to stages array.
	local i; for (( i=0; i<${stages_count}; i++ )); do
		for key in ${!stages_temp[@]}; do
			if [[ ${key} == ${i},* ]]; then
				field=${key#*,}
				stages[${i},${field}]=${stages_temp[$key]}
			fi
		done
	done
	unset stages_order
	unset stages_temp

	# Determine if state needs to be rebuilt or can local build be used instead.
	# Depends on selected stages and local builds availibility.
	if [[ ${#selected_stages_templates[@]} -eq 0 ]]; then
		# If no specific builds were selected, it means that all should be rebuild.
		local i; for (( i=0; i<${stages_count}; i++ )); do
			stages[${i},rebuild]=true
		done
	else
		local required_seeds=() # List of stages that are needed to be build, as stage for another required stages
		# If specified list of stages - build only if listed or if it's needed by another stage and has no local build available.
		local i; for (( i=(( ${stages_count} - 1 )); i>=0; i-- )); do # Go in reverse order, to find required parent seeds too
			use_stage ${i}
			local stage_subpath=${platform}/${release}/${stage}
			if contains_string selected_stages_templates[@] ${stage_subpath}; then
				stages[${i},rebuild]=true
				required_seeds+=(${parent}) # Remember that current stage source need's to exist or be build.
			else
				# Check if this stage is required as a source for another stage.
				# In this situation it's marked as required only if local build is also not available or CLEAN_BUILD is set.
				if contains_string required_seeds[@] ${stage_subpath} && [[ -z ${available_build} || ${CLEAN_BUILD} = true ]]; then
					stages[${i},rebuild]=true
					stages[${i},available_build]="" # If rebuilding, forget about available build subpath, as new release will be created anyway.
					required_seeds+=(${parent}) # Remember that current stage source need's to exist or be build.
				else
					stages[${i},rebuild]=false
				fi
			fi
		done
	fi

	# List stages to build
	echo_color ${COLOR_TURQUOISE_BOLD} "[ Stages to rebuild ]"
	local i; local j=1; for (( i=0; i<$stages_count; i++ )); do
		local rebuild=${stages[${i},rebuild]}
		if [[ ${rebuild} = true ]]; then
			echo "$((j)): ${stages[${i},'platform']}/${stages[${i},'release']}/${stages[${i},'stage']}"
			((j++))
		fi
	done
	echo "" # New line
}

# Prepare array that describes the order of stages based on inheritance.
# Store information if stage has local parents.
# This is function uses requrency to process all required parents before selected stage is processed.
insert_stage_with_inheritance() { # arg - index, required_by_id
	local index=${1}
	use_stage ${index}
	if ! contains_string stages_order[@] ${index}; then
		# If you can find a parent that produces target = this.source, add this parent first. After that add this stage.
		if [[ -n ${parent_index} ]]; then
			stages[${index},parent]=${parent_platform}/${parent_release}/${parent_stage}
			insert_stage_with_inheritance ${parent_index}
		else
			stages[${index},parent]=""
		fi
		stages_order+=(${index})
	fi
}

# Setup templates of stages.
prepare_stages() {
	echo_color ${COLOR_TURQUOISE_BOLD} "[ Preparing stages ]"
	empty_directory ${WORK_PATH}

	local i; for (( i=0; i<$stages_count; i++ )); do
		use_stage ${i}
		if [[ ${rebuild} = false ]]; then
			continue
		fi

		# Load platform config
		local platform_conf_path=${PATH_RELENG_TEMPLATES}/${platform}/platform.conf
		source ${platform_conf_path}
		# TODO: If some properties are not set in config - unset them while loading new config

		# Prepare stage catalyst parent dir
		local source_path=${PATH_CATALYST_BUILDS}/${source_subpath}.tar.xz
		local source_build_dir=$(dirname ${source_path})
		mkdir -p ${source_build_dir}
		# Determine if stage's parent will also be rebuild, to know if it should use available_source_subpath or new parent build.
		if [[ -n "${parent_index}" ]] && [[ "${parent_rebuild}" = false ]] && [[ -n ${parent_available_build} ]]; then
			echo "Using existing source ${parent_available_build} for ${platform}/${release}/${stage}"
			stages[${i},source_subpath]=${parent_available_build%.tar.xz}
			use_stage ${i} # Reload data
		fi
		# Check if should download seed and download if needed.
		local use_remote_build=false
		if [[ -z ${parent} ]]; then
			if [[ ! -f ${source_path} ]]; then
				use_remote_build=true
			fi
		fi

		# Download seed if needed.
		if [[ ${use_remote_build} = true ]]; then
			local source_target_stripped=$(echo ${source_subpath} | awk -F '/' '{print $NF}' | sed 's/-@TIMESTAMP@//')
			local source_target_regex=$(echo ${source_subpath} | awk -F '/' '{print $NF}' | sed 's/@TIMESTAMP@/[0-9]{8}T[0-9]{6}Z/')
			# Check if build for this seed exists already, only if building specified list of stages (otherwise always get latest details).
			local matching_source_builds=($(printf "%s\n" "${available_builds[@]}" | grep -E "${source_target_regex}"))
			local source_available_build=$(printf "%s\n" "${matching_source_builds[@]}" | sort -r | head -n 1)
			if [[ ${#selected_stages_templates[@]} -ne 0 ]] && [[ -n ${source_available_build} ]] && [[ ${CLEAN_BUILD} = false ]]; then
				echo "Using existing source ${source_available_build} for ${platform}/${release}/${stage}"
				stages[${i},source_subpath]=${parent_available_build%.tar.xz}
			else
				# Download seed for ${source_subpath} to file ${source_filename}
				echo "Get seed info: ${platform}/${release}/${stage}"
				local seeds_arch_url=$(echo ${seeds_url} | sed "s/@ARCH_FAMILY@/${arch_family}/")
				local metadata_url=${seeds_arch_url}/latest-${source_target_stripped}.txt
				local metadata_content=$(wget -q -O - ${metadata_url} --no-http-keep-alive --no-cache --no-cookies)
				local latest_seed=$(echo "${metadata_content}" | grep -E ${source_target_regex} | head -n 1 | cut -d ' ' -f 1)
				local url_seed_tarball=${seeds_arch_url}/${latest_seed}
				# Extract available timestamp from available seed name and update @TIMESTAMP@ in source_subpath with it.
				local latest_seed_timestamp=$(echo ${latest_seed} | sed -n 's/.*\([0-9]\{8\}T[0-9]\{6\}Z\).*/\1/p')
				stages[${i},source_url]=${url_seed_tarball} # Store URL of source, to download right before build
				stages[${i},source_subpath]=$(echo ${source_subpath} | sed "s/@TIMESTAMP@/${latest_seed_timestamp}/")
				# TODO: Generate URL_RELEASE_GENTOO with currect family for given spec. Currentl'y it's all for ppc
				# TODO: If getting parent url fails, stop script with erro
			fi
			# Reload variables, because after downloading details, they could have been changed
			use_stage ${i}
		fi

		# Copy stage template workfiles to work_path.
		local stage_path=${PATH_RELENG_TEMPLATES}/${platform}/${release}/${stage}
		local stage_work_path=${WORK_PATH}/${platform}/${release}/${stage}
		mkdir -p ${stage_work_path}
		cp -rf ${stage_path}/* ${stage_work_path}/

		# Prepare portage enviroment - Combine base portage files from releng with stage template portage files.
		local portage_path=${stage_work_path}/portage
		local releng_base_file=${portage_path}/releng_base
		if [[ -f ${releng_base_file} ]]; then
			releng_base=$(cat ${releng_base_file})
			releng_base_dir=${PATH_RELENG_PORTAGE_CONFDIR}/${releng_base}${CONF_QEMU_RELENG_POSTFIX}
			cp -ru ${releng_base_dir}/* ${portage_path}/
			rm ${releng_base_file}
		fi

		# Setup spec entries.
		local stage_overlay_path=${stage_work_path}/overlay
		local stage_root_overlay_path=${stage_work_path}/root_overlay
		local stage_fsscript_path=${stage_work_path}/fsscript.sh
		local stage_spec_work_path=${stage_work_path}/stage.spec
		local target_mapping="${TARGET_MAPPINGS[${target}]:-${target}}"

		# Replace spec templates with real data
		echo "" >> ${stage_spec_work_path} # Add new line, to separate new entries
		set_spec_variable ${stage_spec_work_path} rel_type ${platform}/${release}
		set_spec_variable ${stage_spec_work_path} portage_confdir ${portage_path}
		set_spec_variable ${stage_spec_work_path} source_subpath ${source_subpath}
		set_spec_variable ${stage_spec_work_path} snapshot_treeish ${treeish}
		if [[ -d ${stage_overlay_path} ]]; then
		        set_spec_variable ${stage_spec_work_path} ${target_mapping}/overlay ${stage_overlay_path}
		fi
		if [[ -d ${stage_root_overlay_path} ]]; then
		        set_spec_variable ${stage_spec_work_path} ${target_mapping}/root_overlay ${stage_root_overlay_path}
		fi
		if [[ -f ${stage_fsscript_path} ]]; then
		        set_spec_variable ${stage_spec_work_path} ${target_mapping}/fsscript ${stage_fsscript_path}
		fi
		if [[ ${CONF_QEMU_IS_NEEDED} ]]; then
			set_spec_variable ${stage_spec_work_path} interpreter ${CONF_QEMU_INTERPRETER}
		fi
		update_spec_variable ${stage_spec_work_path} TIMESTAMP ${TIMESTAMP}
		update_spec_variable ${stage_spec_work_path} PLATFORM ${platform}
		update_spec_variable ${stage_spec_work_path} REL_TYPE ${release}
		update_spec_variable ${stage_spec_work_path} TREEISH ${treeish}
		update_spec_variable ${stage_spec_work_path} PKGCACHE_PATH ${PKGCACHE_PATH}
		update_spec_variable ${stage_spec_work_path} REPOS ${PATH_OVERLAYS_PS3_GENTOO}

	done

	echo "Stages templates prepared in: ${WORK_PATH}"
	echo ""
}

# Build stages.
build_stages() {
	echo_color ${COLOR_TURQUOISE_BOLD} "[ Building stages ]"
	local i; for (( i=0; i<$stages_count; i++ )); do
		use_stage ${i}
		if [[ ${rebuild} = false ]]; then
			continue
                fi
		local stage_work_path=${WORK_PATH}/${platform}/${release}/${stage}
		local stage_spec_work_path=${stage_work_path}/stage.spec
		local source_path=${PATH_CATALYST_BUILDS}/${source_subpath}.tar.xz

		# If stage doesn't have parent built or already existing as .tar.xz, download it's
		if [[ -n ${source_url} ]] && [[ ! -f ${source_path} ]]; then
			echo "Downloading seed for: ${platform}/${release}/${stage}"
			echo ""
			wget ${source_url} -O ${source_path}
			# TODO: Failure if can't download seed
		fi

		echo "Building stage: ${platform}/${release}/${stage}"
		echo ""
		local args="-af ${stage_spec_work_path}"
		if [[ -n ${catalyst_conf} ]]; then
			args="${args} -c ${catalyst_conf}"
		fi
		catalyst $args || exit 1
		echo ""
	done
}

# Main program:

# Check for root privilages.
if [[ $EUID -ne 0 ]]; then
	echo "This script must be run as root"
	exit 1
fi

prepare_portage_snapshot
load_stages
prepare_stages
#build_stages

# TODO: Add lock file preventing multiple runs at once.
# TODO: Make this script independant of PS3 environment. Use configs in /etc/ instead.
# TODO: Add functions to manage platforms, releases and stages - add new, edit config, print config, etc.
# TODO: Add releng managemnt - downloading, checking, updating.
# TODO: If possible - add toml config management.
# TODO: Link all specs to single work directory, and rename to 01-stage_name.spec, 02-stage_name.spec, etc
# TODO: Add possibility to specify in spec templates things that should be added only if they are not specified yet. For example: treeish
# TODO: Copy catalyst.conf to templates and use it from there.
