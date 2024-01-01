#!/bin/bash

# TODO: This tool requires configured /etc/portage/repos.conf/gentoo.conf with default gentoo configuration.
# And local repository, to be able to build package manifests

# HELPER VARIABLES ==============================================================================

dir="$(pwd)"                   # Current directory where script was called from.
quiet_flag='--quiet'           # Quiet flag used to silence the output.
defconfig_name='ps3_defconfig' # Name of base kernel configuration.
defconfig_gentoo_name='ps3_gentoo_defconfig' # Name of modified kernel configuration.
clear=false                    # Clear sources and emerge them again.
menuconfig=false               # Run make menuconfig to adjust kernel configuration.
config="PS3"
save=false                     # Should generated ebuild be saved in overlay repository, and configuration diff file stored as default for future builds.

# MAIN PROGRAM ==================================================================================

## Prepare --------------------------------------------------------------------------------------
source <(sed '1,/^# FUNCTIONS #.*$/d' "$0") # Load functions at the bottom of the script.
source "${dir}/data/patches_ps3_list.txt"

read_variables "$@"        # Read user input variables.
validate_input_data        # Validate if input data is correct.
get_newest_kernel_version  # Read newest kernel available in portage.
setup_default_repo         # Creates file /etc/portage/repos.conf/gentoo.conf with default configuration. Needed for pkgdev manifest to work.
setup_local_overlay        # Creates local overlay for building manifests.
setup_sources              # Downloads kernel sources, Applies patches and current stored configuration.
prepare_new_kernel_configs # Sets up new ps3_defconfig_diffs and ps3_gentoo_defconfig
create_ebuild              # Generates ebuild
save
cleanup                    # Cleans unneded files.
summary                    # Show summary information if applicable.

## Summary --------------------------------------------------------------------------------------
log green "Done"

exit # The rest of the script is loaded automatically using 'source'.

# FUNCTIONS # ===================================================================================

log() {
    local color="$1"
    shift
    local msg="$@"
    local color_value
    case "$color" in
    'black') color_value="30" ;;
    'red') color_value="31" ;;
    'green') color_value="32" ;;
    'yellow') color_value="33" ;;
    'blue') color_value="34" ;;
    'magneta') color_value="35" ;;
    'cyan') color_value="36" ;;
    'white') color_value="37" ;;
    *) color_value="37" ;;
    esac
    echo -e "\033[0;${color_value}m[ $msg ]\033[0m"
}

error() {
    log red "$@"
    exit
}

error_continue() {
    log red "$@"
    local prompt="c - continue; e - exit; r - repeat: "
    local response

    while true; do
        read -p "$prompt" response
        case "$response" in
        "c" | "continue")
            break
            ;;
        "e" | "exit")
            exit 1
            ;;
        "r" | "repeat")
            try "$@"
            break
            ;;
        *) ;;
        esac
    done
}

try() {
    log cyan "$@"
    if [ -n "$quiet_flag" ]; then
        "$@" > /dev/null
    else
        "$@"
    fi
    local exit_code=$?
    if [ $exit_code -ne 0 ]; then
        error_continue "$@"
    fi
}

print_usage() {
    echo "Usage: $0 [OPTIONS]"
    echo "Options:"
    echo "  --verbose		Enable verbose output."
    echo ""
    echo "  --menuconfig	Modify kernel configuration befire generating new ebuild."
    echo ""
    exit 1
}

## Main functions -------------------------------------------------------------------------------

read_variables() {
    while [ $# -gt 0 ]; do
        case "$1" in
        --config)
            shift
            if [ $# -gt 0 ]; then
                config="$1"
            fi
            ;;
        --verbose)
            unset quiet_flag
            unset quiet_flag_short
            verbose_flag="--verbose"
            ;;
        --clear)
            clear=true
            ;;
        --menuconfig)
            menuconfig=true
            ;;
        --save)
            save=true
            ;;
        *)
            error "Unknown option: $1"
            ;;
        esac
        shift
    done
}

validate_input_data() {
    # Validate if required properties are set.
return;
}

download_patches() {
    local files_path="${sources_selected_root_path}/files"
    local patches_path="${files_path}/ps3_patches"

    if [ ! -d "${patches_path}" ]; then
        try mkdir -p "${patches_path}"
    fi
    cd "${patches_path}"
    for patch_url in ${ps3_patches[@]}; do
        try wget "$patch_url" $quiet_flag
    done
#    local patches_compressed_path="${sources_selected_root_path}/files/patches-ps3-${kernel_version}.tar.xz"
#    try tar -caf "$patches_compressed_path" -C "${patches_path}" .

    cd "${dir}"
}

get_newest_kernel_version() {
    local newest_kernel=$(equery m sys-kernel/gentoo-kernel | awk '{print $2}' | grep -Eo '[0-9]+\.[0-9]+\.[0-9]+' | tail -n 1)
    kernel_version="$newest_kernel"
    sources_selected_root_path=$(realpath -m "${dir}/../../local/gentoo-sources/${config}/${kernel_version}")
}

setup_default_repo() {
	local conf_path="/etc/portage/repos.conf"
	local conf_gentoo_path="${conf_path}/gentoo.conf"
	local conf_gentoo_default_path="${dir}/data/gentoo.conf"
	if [ ! -e "${conf_gentoo_path}" ]; then
		try mkdir -p "${conf_path}"
		try cp "${conf_gentoo_default_path}" "${conf_gentoo_path}"
	fi
}

setup_local_overlay() {
	local overlay_path="/var/db/repos/local"
	if [ ! -d "$overlay_path" ]; then
            try eselect repository create local
	fi
}

setup_sources() {
	if [ $clear = true ] && [ -d "${sources_selected_root_path}" ]; then
	    try rm -rf "${sources_selected_root_path}"
	fi
	if [ ! -d "${sources_selected_root_path}" ]; then
            local files_path="${sources_selected_root_path}/files"
	    local patches_path="${files_path}/ps3_patches"
            local src_path="${sources_selected_root_path}/usr/src/linux-${kernel_version}-gentoo"
            local ps3_defconfig_generated_path="${files_path}/${defconfig_name}_raw"
            local ps3_defconfig_modifications_path="${dir}/data/${defconfig_name}_diffs"

	    try mkdir -p "${sources_selected_root_path}" # Create sources directory
            try mkdir -p "${files_path}"

	    # Download and configure gentoo sources in temp
	    ACCEPT_KEYWORDS="~*" try emerge --nodeps --root="${sources_selected_root_path}" --oneshot =sys-kernel/gentoo-sources-${kernel_version} $quiet_flag

	    # Apply patches
	    download_patches
	    try cd "${src_path}"
	    for patch in "${patches_path}"/*; do
		try patch -p1 -i "$patch"
	    done

            # Generate kernel configuration - ps3_defconfig + (current)ps3_defconfig_diffs
            ARCH=powerpc CROSS_COMPILE=powerpc64-unknown-linux-gnu- try make ${defconfig_name}
            try cp .config "${ps3_defconfig_generated_path}"
            ${dir}/data/apply-diffconfig.rb "${ps3_defconfig_modifications_path}" "$ps3_defconfig_generated_path" > .config

	    try cd "${dir}"
	fi
}

prepare_new_kernel_configs() {
            local files_path="${sources_selected_root_path}/files"
            local src_path="${sources_selected_root_path}/usr/src/linux-${kernel_version}-gentoo"
            local ps3_defconfig_modifications_new_path="${files_path}/${defconfig_name}_diffs"
            local ps3_gentoo_defconfig_new_path="${files_path}/${defconfig_gentoo_name}"
	    try cd "${src_path}"
            ARCH=powerpc CROSS_COMPILE=powerpc64-unknown-linux-gnu- try make oldconfig
     	    if [ $menuconfig = true ]; then
                ARCH=powerpc CROSS_COMPILE=powerpc64-unknown-linux-gnu- make menuconfig
            fi
            ARCH=powerpc CROSS_COMPILE=powerpc64-unknown-linux-gnu- try make savedefconfig
            try cp "defconfig" "${ps3_gentoo_defconfig_new_path}"
            ./scripts/diffconfig arch/powerpc/configs/ps3_defconfig defconfig > "${ps3_defconfig_modifications_new_path}"
	    try cd "${dir}"
}

create_ebuild() {
            local files_path="${sources_selected_root_path}/files"
	    local ebuild_path="${files_path}/gentoo-kernel-ps3-${kernel_version}.ebuild"
	    local ebuild_patch_path="${dir}/data/gentoo-kernel-ps3.ebuild.patch" # Changes to original ebuild
	    local ebuild_original_path="/var/db/repos/gentoo/sys-kernel/gentoo-kernel/gentoo-kernel-${kernel_version}.ebuild"
            try cp "${ebuild_original_path}" "${ebuild_path}"
            try patch -u "${ebuild_path}" -i "${ebuild_patch_path}"
	    # NOTE: To change generated ebuild, its required to generate new patch in $ebuild_patch_path.
            # use: diff -u $ebuild_original_path $ebuild_path to create one. Before this, edit $ebuild_path file.
}

save() {
    if [ $save = true ]; then
        local files_path="${sources_selected_root_path}/files"
        local ps3_defconfig_modifications_path="${dir}/data/${defconfig_name}_diffs"
        local ps3_defconfig_modifications_new_path="${files_path}/${defconfig_name}_diffs"
        local files_compressed_path="${files_path}/files-${kernel_version}.tar.xz"
        local files_to_compress=(
            ps3_defconfig_diffs
            ps3_gentoo_defconfig
            ps3_patches
        )
        # Create package with additional files for ebuild, and upload it to overlay repository.
        try tar -caf "$files_compressed_path" -C "${files_path}" "${files_to_compress[@]}"
        # Upload patches file to overlay repository

	# Store ebuild in local overlay and create manifest for it.
	# Copy ebuild and manifest to overlay git, and publish it

	# Override "${dir}/data/${defconfig_name}_diffs" with new diffs
	try cp "${ps3_defconfig_modifications_new_path}" "${ps3_defconfig_modifications_path}"
    fi

}

# Cleaning ======================================================================================

cleanup() {
return;
}

summary() {
    log magenta "Completed"
}
