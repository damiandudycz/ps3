#!/bin/bash

# TODO: Add metadata.xml to repository
# TODO: Generate also gentoo-sources ebuild

source <(sed '1,/^# FUNCTIONS #.*$/d' "$0") # Load functions at the bottom of the script.

path_initial=$(dirname $(readlink -f "$0")) # Current directory where script was called from.
path_local=$(realpath -m "${path_initial}/../../local")
flag_quiet='--quiet' # Quiet flag used to silence the output.

# CONFIGURATION =================================================================================
config_save=false       # Should generated ebuild be saved in overlay repository, and configuration diff file stored as default for future builds.
config_clear=false      # Clear sources and emerge them again.
config_menuconfig=false # Run make menuconfig to adjust kernel configuration.
config_overwrite=false  # Allow owerwriting already existing ebuild. Also if set, new generated config diff file is set as the new default.
config_test_build=false # Try to compile locally to see if it works.

# CONSTANT NAMES ================================================================================
fname_overlay="ps3-gentoo-overlay"                  # Name of ebuild overlay repository.
fname_defconfig_ps3_original='ps3_defconfig'        # Name of base kernel configuration.
fname_defconfig_ps3_modified='ps3_gentoo_defconfig' # Name of modified kernel configuration.
fname_ebuild="gentoo-kernel-ps3"                    # Ebuild name.
fname_ebuild_raw="gentoo-kernel"                    # Original (raw) ebuild name.
fname_ebuild_sources_raw="gentoo-sources"           # Ebuild with gentoo sources.
fname_ebuild_category="sys-kernel"                  # Ebuild category.

# LOAD USER SETTINGS ============================================================================
cd "${path_initial}"
read_variables "$@" # Read user input variables.
setup_work_path     # Read newest kernel available in portage.

# PATHES ========================================================================================
path_data=$(realpath "${path_initial}/data")
path_data_patches_list=$(realpath "${path_data}/patches_ps3_list.txt")
path_data_gentoo_conf="${path_data}/gentoo.conf"
path_data_defconfig_diffs="${path_data}/${fname_defconfig_ps3_original}_diffs"
path_data_ebuild_patch="${path_data}/${fname_ebuild}.ebuild.patch"
path_work_src="${path_work}/usr/src/linux-$(echo $kernel_version | grep -Eo '[0-9]+\.[0-9]+\.[0-9]+')-gentoo$(echo $kernel_version | grep -Eo '(-r[0-9]+)?')"
path_work_files="${path_work}/files"
path_work_files_patches="${path_work_files}/ps3_patches"
path_work_files_defconfig_original="${path_work_files}/${fname_defconfig_ps3_original}"
path_work_files_defconfig_modified="${path_work_files}/${fname_defconfig_ps3_modified}"
path_work_files_defconfig_diffs="${path_work_files}/${fname_defconfig_ps3_original}_diffs"
path_work_files_entry_ebuild="${path_work_files}/${fname_ebuild}.ebuild"
path_work_files_ebuild_distfiles_tar="${path_work_files}/${fname_ebuild}-files-${kernel_version}.tar.xz"
path_overlay=$(realpath -m "${path_initial}/../../overlays/${fname_overlay}")
path_overlay_distfiles=$(realpath -m "${path_overlay}.distfiles")
path_overlay_distfiles_entry="${path_overlay_distfiles}/${fname_ebuild_category}/${fname_ebuild}"
path_overlay_distfiles_tarball="${path_overlay_distfiles_entry}/${fname_ebuild}-files-${kernel_version}.tar.xz"
path_overlay_entry="${path_overlay}/${fname_ebuild_category}/${fname_ebuild}"
path_overlay_entry_ebuild="${path_overlay_entry}/${fname_ebuild}-${kernel_version}.ebuild"
path_overlay_entry_manifest="${path_overlay_entry}/Manifest"
path_portage_repos="/etc/portage/repos.conf"
path_portage_repos_gentoo="${path_portage_repos}/gentoo.conf"
path_repos_gentoo_kernel_ebuild="/var/db/repos/gentoo/${fname_ebuild_category}/${fname_ebuild_raw}/${fname_ebuild_raw}-${kernel_version}.ebuild"

# OTHER =========================================================================================

list_distfiles_tar_files=(
    # List of files and directories compressed into distfiles tarball for overlay distfiles repository.
    ps3_defconfig_diffs # Not needed, but kept for tracking changes between versions.
    ps3_gentoo_defconfig # Updated ps3_defconfig that will replace the original one.
    ps3_patches # PS3 specific patches to be applied to kernel. Snapshot created with ebuild.
)

# MAIN PROGRAM ==================================================================================

## Prepare --------------------------------------------------------------------------------------
source "${path_data_patches_list}"

check_if_should_continue   # Skip if ebuild already exists.
setup_default_repo         # Creates file /etc/portage/repos.conf/gentoo.conf with default configuration. Needed for pkgdev manifest to work.
setup_sources              # Downloads kernel sources, Applies patches and current stored configuration.
prepare_new_kernel_configs # Sets up new ps3_defconfig_diffs and ps3_gentoo_defconfig.
create_ebuild              # Generates ebuild.
run_test                   # Perform test build.
save                       # Save generated files in overlay repository.
upload_overlays

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
    if [ -n "$flag_quiet" ]; then
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
    echo "  --verbose     Enable verbose output."
    echo "  --menuconfig  Modify kernel configuration befire generating new ebuild."
    echo "  --clear       Removes previously prepared sources and its modifications."
    echo "  --version     Specify kernel version. If not set, uses newest one in portage."
    echo "  --save        Store new ebuild and distfiles in overlay repositories."
    echo "  --overwrite   Allow overwriting already existing ebuilds. Also if set, overwrites default config diff file."
    echo "  --test        Build locally to test if it works."
    echo ""
    exit 1
}

ppc64_run() {
    ARCHITECTURE=$(uname -m)
    ACTIONS="$@"
    if [ "$ARCHITECTURE" == "ppc64" ]; then
        $ACTIONS
    else
        ARCH=powerpc CROSS_COMPILE=powerpc64-unknown-linux-gnu- $ACTIONS
    fi
}

## Main functions -------------------------------------------------------------------------------

read_variables() {
    while [ $# -gt 0 ]; do
        case "$1" in
        --verbose)
            unset flag_quiet
            unset flag_quiet_short
            ;;
        --clear)
            config_clear=true
            ;;
        --menuconfig)
            config_menuconfig=true
            ;;
        --overwrite)
            config_overwrite=true
            ;;
        --test)
            config_test_build=true
            ;;
        --version)
            shift
            if [ $# -gt 0 ]; then
                kernel_version="$1"
            fi
            ;;
        --save)
            config_save=true
            ;;
        *)
            error "Unknown option: $1"
            ;;
        esac
        shift
    done
}

setup_work_path() {
    if [ -z ${kernel_version} ]; then
	kernel_version=$(equery m "${fname_ebuild_category}/${fname_ebuild_raw}" | grep " ppc64" | awk '{print $2}' | grep -Eo '[0-9]+\.[0-9]+\.[0-9]+(-r[0-9]+)?' | sort -V | tail -n 1)
    fi
    path_work=$(realpath -m "${path_local}/${fname_ebuild_sources_raw}/${kernel_version}")
}

check_if_should_continue() {
    # If ebuild for this version already exists, return.
    if [ -f "${path_overlay_entry_ebuild}" ] && [ $config_overwrite = false ]; then
        log magneta "Ebuild for version ${kernel_version} already exists. To overwrite use --overwrite flag. Skipping."
        exit 0
    fi
}

download_patches() {
    try mkdir -p "${path_work_files_patches}"
    cd "${path_work_files_patches}"
    for patch_url in ${ps3_patches[@]}; do
        try wget "$patch_url" $flag_quiet
    done
    cd "${path_initial}"
}

setup_default_repo() {
    if [ ! -e "${path_portage_repos_gentoo}" ]; then
        try mkdir -p "${path_portage_repos}"
        try cp "${path_data_gentoo_conf}" "${path_portage_repos_gentoo}"
    fi
}

setup_sources() {
    if [ ${config_clear} = true ] && [ -d "${path_work}" ]; then
        try rm -rf "${path_work}"
    fi
    if [ ! -d "${path_work}" ]; then
        try mkdir -p "${path_work}"
        try mkdir -p "${path_work_files}"

        # Download and configure gentoo sources in temp
        ACCEPT_KEYWORDS="~*" try emerge --nodeps --root="${path_work}" --oneshot =${fname_ebuild_category}/${fname_ebuild_sources_raw}-${kernel_version} $flag_quiet

        # Apply patches
        download_patches
        try cd "${path_work_src}"
        for patch in "${path_work_files_patches}"/*; do
            try patch -p1 -i "$patch"
        done

        # Generate kernel configuration - ps3_defconfig + (current)ps3_defconfig_diffs
        try ppc64_run make ${fname_defconfig_ps3_original}
        try cp .config "${path_work_files_defconfig_original}"

        # Merge original ps3_defconfig with stored changes.
        ${path_data}/apply-diffconfig.rb "${path_data_defconfig_diffs}" "$path_work_files_defconfig_original" > .config_updated
        try ppc64_run ./scripts/kconfig/merge_config.sh .config_updated
        rm .config_updated

        try cd "${path_initial}"
    fi
}

prepare_new_kernel_configs() {
    try cd "${path_work_src}"
    if [ ${config_menuconfig} = true ]; then
        ppc64_run make menuconfig
    fi
    # Generate ps3_gentoo_defconfig.
    try ppc64_run make savedefconfig
    try mv "defconfig" "${path_work_files_defconfig_modified}"
    # Determine new file with changes between ps3_defconfig and ps3_gentoo_defconfig.
    ./scripts/diffconfig arch/powerpc/configs/${fname_defconfig_ps3_original} "${path_work_files_defconfig_modified}" > "${path_work_files_defconfig_diffs}"
    try cd "${path_initial}"
}

run_test() {
    if [ ${config_test_build} = true ]; then
        try cd "${path_work_src}"
        ppc64_run make
        try cd "${path_initial}"
    fi
}

create_ebuild() {
	# Create ebuild in work_files.
        try cp "${path_repos_gentoo_kernel_ebuild}" "${path_work_files_entry_ebuild}"
        try patch -u "${path_work_files_entry_ebuild}" -i "${path_data_ebuild_patch}"
        # NOTE: To change generated ebuild, its required to generate new patch in data/fname_ebuild.ebuild.patch.
        # use: diff -u $ebuild_original_path $ebuild_path to create one. Before this, edit $ebuild_path file.
}

save() {
    if [ ${config_save} = true ]; then
        # Create distfiles tarball.
        try tar --sort=name \
            --mtime="" \
            --owner=0 --group=0 --numeric-owner \
            --pax-option=exthdr.name=%d/PaxHeaders/%f,delete=atime,delete=ctime \
            -caf "${path_work_files_ebuild_distfiles_tar}" \
            -C "${path_work_files}" "${list_distfiles_tar_files[@]}"
        if [ ! -d "${path_overlay_entry}" ]; then
            try mkdir -p "${path_overlay_entry}"
        fi
        try cp "${path_work_files_ebuild_distfiles_tar}" "${path_overlay_distfiles_tarball}"
        try cp "${path_work_files_ebuild_distfiles_tar}" "/var/cache/distfiles/" # Store in distfiles, for pkgdev manifest to work without downloading.

        # Save ebuild to overlay.
        try mkdir -p "${path_overlay_entry}"
        try cp "${path_work_files_entry_ebuild}" "${path_overlay_entry_ebuild}"

        # Generate new Manifest file.
        if [ -f "${path_overlay_entry_manifest}" ]; then
            try rm "${path_overlay_entry_manifest}"
        fi
        try cd "${path_overlay_entry}"
        try pkgdev manifest

        # Store updated diffs file as default (requires overwrite flag).
        if [ $config_overwrite = true ]; then
            try cp "${path_work_files_defconfig_diffs}" "${path_data_defconfig_diffs}"
        fi

        cd "${path_initial}"
    fi
}

upload_overlays() {
    if [ ${config_save} = true ]; then
        cd "${path_overlay}"
        if [[ $(git status --porcelain) ]]; then
            try git add -A
            try git commit -m "Ebuilds automatic update"
            try git push
        fi
        cd "${path_overlay_distfiles}"
        if [[ $(git status --porcelain) ]]; then
            try git add -A
            try git commit -m "Distfiles automatic update"
            try git push
        fi
        cd "${path_initial}"
        tracked_files=(
            "../../overlays/ps3-gentoo-overlay"
            "../../overlays/ps3-gentoo-overlay.distfiles"
            "./data/ps3_defconfig_diffs"
        )
        if ! git diff --quiet "${tracked_files[@]}"; then
            try git add "${tracked_files[@]}"
            try git commit -m "Ebuilds automatic update"
            try git push
        fi
    fi
}
