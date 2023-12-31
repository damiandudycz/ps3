#!/bin/bash

# HELPER VARIABLES ==============================================================================

dir="$(pwd)"                           # Current directory where script was called from.
path_tmp="/tmp/gentoo-kernel-building" # Temporary files storage directory.
quiet_flag='--quiet'                   # Quiet flag used to silence the output.
quiet_flag_short='-q'                  # Quiet flag used to silence the output.
defconfig_name='ps3_defconfig'         # Name of base kernel configuration.
clear=false                            # Clear sources and emerge them again.

# MAIN PROGRAM ==================================================================================

## Prepare --------------------------------------------------------------------------------------
source <(sed '1,/^# FUNCTIONS #.*$/d' "$0") # Load functions at the bottom of the script.

read_variables "$@"                 # Read user input variables.
validate_input_data                 # Validate if input data is correct.

prepare_directories                 # Create path_tmp and path_chroot.
get_config                          # Download configuration or load local configuration file.
override_kernel_version_with_newest # Override kernel version in config with latest available.
validate_config                     # Checks if all settings in configuration are set correctly.

## Setup sources and ebuild ---------------------------------------------------------------------
download_patches
# MAKE FUNCTION FROM THIS
local sources_selected_root_path=$(realpath "${dir}/../../local/gentoo-sources/${kernel_version}")
if [ $clear = true ] && [ -d "${sources_selected_root_path}" ]; then
    try rm -rf "${sources_selected_root_path}"
fi
if [ ! -d "${sources_selected_root_path}" ]; then
    try mkdir -p "${sources_selected_root_path}" # Create sources directory
    # Download and configure gentoo sources in temp
    ACCEPT_KEYWORDS="~*" emerge --root="${sources_selected_root_path}" --oneshot =sys-kernel/gentoo-sources-${kernel_version} $quiet_flag
    # Apply patches
    try cd "${sources_selected_root_path}" # TODO: Add rest of patch to linux sources, probably /usr/src/linux-VERSION
    for patch in "$path_tmp/kernel_patches"/*; do
	    try quiet patch -p1 < $patch
    done
fi
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
cleanup_directories             # Removes temporart installation files.
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

prepare_directories() {
    if [ ! -d "$path_tmp" ]; then
        try mkdir -p "$path_tmp"
    fi
    if [ ! -d "$path_tmp/kernel_patches" ]; then
        try mkdir -p "$path_tmp/kernel_patches"
    fi
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
    cd "$path_tmp/kernel_patches"
    try rm -rf "$path_tmp/kernel_patches"/*
    for patch_url in ${kernel_patches[@]}; do
        try wget "$patch_url" $quiet_flag
    done
    cd "${dir}"
}

override_kernel_version_with_newest() {
    local newest_kernel=$(equery m sys-kernel/gentoo-kernel | awk '{print $2}' | grep -Eo '[0-9]+\.[0-9]+\.[0-9]+' | tail -n 1)
    local newest_headers=$(equery m sys-kernel/linux-headers | awk '{print $2}' | grep -Eo '[0-9]+\.[0-9]+(-r[0-9]+)?' | tail -n 1)
    export kernel_version="$newest_kernel"
    export kernel_headers_version="$newest_headers"
}

upload_dev_patches_and_config() {
    # Compress patches
    local patches_path="$path_tmp/patches-ps3-${kernel_version}.tar.xz"
    try tar -caf "$patches_path" -C "$path_tmp/kernel_patches" .
}

# Cleaning ======================================================================================

cleanup() {
return;
}

cleanup_directories() {
    try rm -rf "$path_tmp"
}

summary() {
    log magenta "Completed"
}
