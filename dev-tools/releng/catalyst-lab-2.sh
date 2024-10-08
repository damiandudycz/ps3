#!/bin/bash

source ../../.env-shared.sh || exit 1

# Constants:

declare -A TARGET_MAPPINGS=([livecd-stage1]=livecd [livecd-stage2]=livecd)
readonly STAGE_VARIABLES=(platform release stage subarch target version_stamp source_subpath has_parent catalyst_conf source_url available_source_subpath)
readonly PKGCACHE_PATH=${PATH_RELENG_RELEASES_BINPACKAGES}
readonly TIMESTAMP=$(date -u +"%Y%m%dT%H%M%SZ") # Current timestamp.
readonly WORK_PATH=/tmp/catalyst-lab-${TIMESTAMP}

# Script arguments:

while [ $# -gt 0 ]; do case ${1} in
    --update-snapshot) FETCH_FRESH_SNAPSHOT=true;;
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
	treeish=$(find ${PATH_CATALYST_TMP}/snapshots -type f -name "*.sqfs" -exec ls -t {} + | head -n 1 | xargs -n 1 basename -s .sqfs | cut -d '-' -f 2)
	if [[ -z ${treeish} ]] || [[ ${FETCH_FRESH_SNAPSHOT} = true ]]; then
		catalyst -s stable
		echo "" # New line
		treeish=$(find ${PATH_CATALYST_TMP}/snapshots -type f -name "*.sqfs" -exec ls -t {} + | head -n 1 | xargs -n 1 basename -s .sqfs | cut -d '-' -f 2)
	fi
}

# Load list of stages to build for every platform and release.
# Prepare variables of every stage, including changes from sanitization process.
# Sort stages based on their inheritance.
load_stages() {
	declare -gA stages # Some details of stages retreived from scanning. (release,stage,target,source,has_parent).
	local available_builds=$(find ${PATH_CATALYST_BUILDS} -type f -name "*.tar.xz" -printf '%P\n')
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
					# Find best matching local build available
					local source_subpath_regex=$(echo $(sanitize_spec_variable ${PLATFORM} ${RELEASE} ${STAGE} ${stage_source_subpath}) | sed 's/@TIMESTAMP@/[0-9]{8}T[0-9]{6}Z/')
					local matching_source_builds=($(printf "%s\n" "${available_builds[@]}" | grep -E "${source_subpath_regex}"))
					local stage_available_source_subpath=$(printf "%s\n" "${matching_source_builds[@]}" | sort -r | head -n 1)
					# Store variables
					stages[${stages_count},platform]=${PLATFORM}
					stages[${stages_count},release]=${RELEASE}
					stages[${stages_count},stage]=${STAGE}
					stages[${stages_count},subarch]=$(sanitize_spec_variable ${PLATFORM} ${RELEASE} ${STAGE} ${stage_subarch})
					stages[${stages_count},target]=$(sanitize_spec_variable ${PLATFORM} ${RELEASE} ${STAGE} ${stage_target})
					stages[${stages_count},version_stamp]=$(sanitize_spec_variable ${PLATFORM} ${RELEASE} ${STAGE} ${stage_stamp})
					stages[${stages_count},source_subpath]=$(sanitize_spec_variable ${PLATFORM} ${RELEASE} ${STAGE} ${stage_source_subpath})
					stages[${stages_count},catalyst_conf]=${catalyst_conf}
					stages[${stages_count},available_source_subpath]=${stage_available_source_subpath}
					stages_count=$((stages_count + 1))

				fi
			done
		done
	done

	# Sort stages array by inheritance:
	stages_order=() # Order in which stages should be build, for inheritance to work. (1,5,2,0,...).
	# Prepare stages order by inheritance.
	local i; for (( i=0; i<${stages_count}; i++ )); do
		insert_stage_with_inheritance $i
	done
	# Sort stages by inheritance order in temp array..
	declare -A stages_temp
	local i; for (( i=0; i<${stages_count}; i++ )); do
		index=${stages_order[$i]}
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

	# List stages to build
	echo_color ${COLOR_TURQUOISE_BOLD} "[ Stages to build ]"
	local i; for (( i=0; i<$stages_count; i++ )); do
		echo "$((i+1)):	${stages[${i},'platform']}/${stages[${i},'release']}/${stages[${i},'stage']}"
	done
	echo "" # New line
}

# Prepare array that describes the order of stages based on inheritance.
# Store information if stage has local parents.
# This is function uses requrency to process all required parents before selected stage is processed.
insert_stage_with_inheritance() { # arg - index
	local index=${1}
	use_stage ${index}
	if ! contains_string stages_order[@] ${index}; then
		# If you can find a parent that produces target = this.source, add this parent first. After that add this stage.
		local parent_index=""
		local i; for (( i=0; i<$stages_count; i++ )); do
			use_stage ${i} parent_
			local parent_product=${parent_platform}/${parent_release}/${parent_target}-${parent_subarch}-${parent_version_stamp}
			if [[ ${source_subpath} == ${parent_product} ]]; then
				parent_index=${i}
				break
			fi
		done
		if [[ -n ${parent_index} ]]; then
			insert_stage_with_inheritance ${parent_index}
			stages[${index},has_parent]=true
		else
			stages[${index},has_parent]=false
		fi
		stages_order+=(${index})
	fi
}

# Setup templates of stages.
prepare_stages() {
	empty_directory ${WORK_PATH}
	local i; for (( i=0; i<$stages_count; i++ )); do
		use_stage ${i}

		# Prepare stage catalyst parent dir
		local source_path=${PATH_CATALYST_BUILDS}/${source_subpath}.tar.xz
		local source_build_dir=$(dirname ${source_path})
		mkdir -p ${source_build_dir}

		# Check if should download seed and download if needed.
		local should_download=false
		if [[ ${has_parent} = false ]]; then
			if [[ ! -f ${source_path} ]]; then
				should_download=true
			fi
		fi
		# Download seed if needed.
		if [[ ${should_download} = true ]]; then
			# Download seed for ${source_subpath} to file ${source_filename}
			echo "Get seed info: ${platform}/${release}/${stage}"
			local source_target_stripped=$(echo ${source_subpath} | awk -F '/' '{print $NF}' | sed 's/-@TIMESTAMP@//')
			local source_target_regex=$(echo ${source_subpath} | awk -F '/' '{print $NF}' | sed 's/@TIMESTAMP@/[0-9]{8}T[0-9]{6}Z/')
			local metadata_url=${URL_RELEASE_GENTOO}/latest-${source_target_stripped}.txt
			local metadata_content=$(wget -q -O - ${metadata_url} --no-http-keep-alive --no-cache --no-cookies)
			local latest_seed=$(echo "${metadata_content}" | grep -E ${source_target_regex} | head -n 1 | cut -d ' ' -f 1)
			local url_seed_tarball=${URL_RELEASE_GENTOO}/${latest_seed}
			# Extract available timestamp from available seed name and update @TIMESTAMP@ in source_subpath with it.
			local latest_seed_timestamp=$(echo ${latest_seed} | sed -n 's/.*\([0-9]\{8\}T[0-9]\{6\}Z\).*/\1/p')
			stages[${i},source_url]=${url_seed_tarball} # Store URL of source, to download right before build
			stages[${i},source_subpath]=$(echo ${source_subpath} | sed "s/@TIMESTAMP@/${latest_seed_timestamp}/")
			# TODO: Generate URL_RELEASE_GENTOO with currect family for given spec. Currentl'y it's all for ppc
			# TODO: If getting parent url fails, stop script with erro
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

	echo ""
	echo "### Stages templates prepared in: ${WORK_PATH}"
	echo ""
}

# Build stages.
build_stages() {
	local i; for (( i=0; i<$stages_count; i++ )); do
		use_stage ${i}
		local stage_work_path=${WORK_PATH}/${platform}/${release}/${stage}
		local stage_spec_work_path=${stage_work_path}/stage.spec
		local source_path=${PATH_CATALYST_BUILDS}/${source_subpath}.tar.xz

		# If stage doesn't have parent built or already existing as .tar.xz, download it's
		if [[ -n ${source_url} ]] && [[ ! -f ${source_path} ]]; then
			echo ""
			echo "### Downloading seed for: ${platform}/${release}/${stage}"
			echo ""
			wget ${source_url} -O ${source_path}
			# TODO: Failure if can't download seed
		fi

		echo ""
		echo "### Building stage: ${platform}/${release}/${stage}"
		echo ""
		local args="-af ${stage_spec_work_path}"
		if [[ -n ${catalyst_conf} ]]; then
			args="${args} -c ${catalyst_conf}"
		fi
		catalyst $args || exit 1
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
# TODO: Check seeds timestamp when downloading and only download if it's changed.
# TODO: Add functions to manage platforms, releases and stages - add new, edit config, print config, etc.
# TODO: Add releng managemnt - downloading, checking, updating.
# TODO: If possible - add toml config management.
# TODO: Link all specs to single work directory, and rename to 01-stage_name.spec, 02-stage_name.spec, etc
# TODO: Only get links to missing stages first, download seeds only when starting build that needs it. Store URL in stages[]
