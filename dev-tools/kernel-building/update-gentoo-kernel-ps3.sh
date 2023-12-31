#!/bin/bash

# HELPER VARIABLES ==============================================================================

dir="$(pwd)"                           # Current directory where script was called from.
path_tmp="/tmp/gentoo-kernel-building" # Temporary files storage directory.
quiet_flag='--quiet'                   # Quiet flag used to silence the output.
quiet_flag_short='-q'                  # Quiet flag used to silence the output.
defconfig_name='ps3_defconfig'         # Name of base kernel configuration.
clear=false                            # Clear sources and emerge them again.
menuconfig=false                       # Run make menuconfig to adjust kernel configuration.

# MAIN PROGRAM ==================================================================================

## Prepare --------------------------------------------------------------------------------------
source <(sed '1,/^# FUNCTIONS #.*$/d' "$0") # Load functions at the bottom of the script.

read_variables "$@"        # Read user input variables.
validate_input_data        # Validate if input data is correct.
get_config                 # Download configuration or load local configuration file.
get_newest_kernel_version  # Read newest kernel available in portage.
validate_config            # Checks if all settings in configuration are set correctly.
setup_sources              # Downloads kernel sources, Applies patches and current stored configuration.
prepare_new_kernel_configs # Sets up new ps3_defconfig_diffs and ps3_gentoo_defconfig

## Setup sources and ebuild ---------------------------------------------------------------------
# MAKE FUNCTION FROM THIS
#local sources_selected_root_path=$(realpath -m "${dir}/../../local/gentoo-sources/${kernel_version}")

# Modifu configs if requested
# Check if compiles correctly
# Store new changes in default configuration
# Create ebuild for gentoo-kernel with new config and patches

# Cleanup configuration and apply previous config
############
# Modify kernel configuration for dev ebuild kernel, upload it to dev
upload_dev_patches_and_config
# Create dev ebuild in local repository
# Build dev ebuild
# Copy installed kernel files, and create release tar, upload it
# Change ebuild to release ebuild
# Upload release ebuild
# Update PS3 config for the newest kernel and headers

## Cleanup and exit -----------------------------------------------------------------------------
cleanup                         # Cleans unneded files.
summary                         # Show summary information if applicable.

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
    echo "  --verbose	Enable verbose output."
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

get_config() {
    # Get config from the repository or local file.
    local path_config=$(realpath "${dir}/../../installer/config/${config}")
    try source "$path_config"
    # prepare additional fields
    arch_family=$(echo $arch | cut -d'/' -f1)
    arch_short=$(echo $arch | cut -d'/' -f2)
    arch_long=$(echo $arch | cut -d'/' -f3)
}

validate_config() {
    # TODO: Validate settings.
return;
}

download_patches() {
    if [ ! -d "${sources_selected_root_path}/kernel_patches" ]; then
        try mkdir -p "${sources_selected_root_path}/kernel_patches"
    fi
    cd "${sources_selected_root_path}/kernel_patches"
    for patch_url in ${kernel_patches[@]}; do
        try wget "$patch_url" $quiet_flag
    done
    cd "${dir}"
}

get_newest_kernel_version() {
    local newest_kernel=$(equery m sys-kernel/gentoo-kernel | awk '{print $2}' | grep -Eo '[0-9]+\.[0-9]+\.[0-9]+' | tail -n 1)
    local newest_headers=$(equery m sys-kernel/linux-headers | awk '{print $2}' | grep -Eo '[0-9]+\.[0-9]+(-r[0-9]+)?' | tail -n 1)
    kernel_version="$newest_kernel"
    kernel_headers_version="$newest_headers"
    sources_selected_root_path=$(realpath -m "${dir}/../../local/gentoo-sources/${config}/${kernel_version}")
}

upload_dev_patches_and_config() {
    # Compress patches
    local patches_path="${sources_selected_root_path}/patches-ps3-${kernel_version}.tar.xz"
    try tar -caf "$patches_path" -C "${sources_selected_root_path}/kernel_patches" .
}

setup_sources() {
	if [ $clear = true ] && [ -d "${sources_selected_root_path}" ]; then
	    try rm -rf "${sources_selected_root_path}"
	fi
	if [ ! -d "${sources_selected_root_path}" ]; then
            local ps3_defconfig_generated_path="${sources_selected_root_path}/${defconfig_name}_raw"
            local ps3_defconfig_modifications_path="${dir}/${defconfig_name}_diffs"

	    try mkdir -p "${sources_selected_root_path}" # Create sources directory
	    # Download and configure gentoo sources in temp
	    ACCEPT_KEYWORDS="~*" try emerge --nodeps --root="${sources_selected_root_path}" --oneshot =sys-kernel/gentoo-sources-${kernel_version} $quiet_flag
	    # Apply patches
	    download_patches
	    try cd "${sources_selected_root_path}/usr/src/linux-${kernel_version}-gentoo"
	    for patch in "${sources_selected_root_path}/kernel_patches"/*; do
		try patch -p1 -i "$patch"
	    done
            # Generate kernel configuration - ps3_defconfig + (current)ps3_defconfig_diffs
            ARCH=powerpc CROSS_COMPILE=powerpc64-unknown-linux-gnu- try make ${defconfig_name}
            try cp .config "$ps3_defconfig_generated_path"
            ${dir}/apply-diffconfig.rb "${ps3_defconfig_modifications_path}" "$ps3_defconfig_generated_path" > .config

	    try cd "${dir}"
	fi
}

prepare_new_kernel_configs() {
	    try cd "${sources_selected_root_path}/usr/src/linux-${kernel_version}-gentoo"
            ARCH=powerpc CROSS_COMPILE=powerpc64-unknown-linux-gnu- try make oldconfig
     	    if [ $menuconfig = true ]; then
                ARCH=powerpc CROSS_COMPILE=powerpc64-unknown-linux-gnu- try make menuconfig
            fi
	    # TODO: Generate new ps3_defconfig_diffs
            ARCH=powerpc CROSS_COMPILE=powerpc64-unknown-linux-gnu- try make savedefconfig
	    try cd "${dir}"
}

# Cleaning ======================================================================================

cleanup() {
return;
}

summary() {
    log magenta "Completed"
}
