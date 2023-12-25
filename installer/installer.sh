#!/bin/bash

# HELPER VARIABLES ==============================================================================

dir="$(pwd)" # Current directory where script was called from.
branch="main"
url_repo_root="https://raw.githubusercontent.com/damiandudycz/ps3"
url_repo="$url_repo_root/$branch"
url_installer="$url_repo/installer"
path_tmp="/tmp/gentoo-setup"     # Temporary files storage directory.
path_chroot="/mnt/gentoo-setup"  # Gentoo chroot environment directory.
quiet_flag='--quiet'             # Quiet flag used to silence the output.
quiet_flag_short='-q'            # Quiet flag used to silence the output.

# MAIN PROGRAM ==================================================================================

## Prepare --------------------------------------------------------------------------------------
source <(sed '1,/^# FUNCTIONS #.*$/d' "$0") # Load functions at the bottom of the script.

read_variables "$@"             # Read user input variables - device, configuration, verbose.
validate_input_data             # Validate if input data is correct.
warn_about_disk_wiping          # Asks user to confirm disk formatting.

prepare_directories             # Create path_tmp and path_chroot.
get_config                      # Download configuration or load local configuration file.
override_config                 # Override default values from config, using flags.
validate_config                 # Checks if all settings in configuration are set correctly.

## Setup disk -----------------------------------------------------------------------------------
sort_partitions_by_mount_order  # Prepare array of devices sorted by mounting order.
disk_clean_signatures           # Remove existing signatures of partition table, and partitions from the disk.
disk_create_partitions          # Create new partitions, definied in the configuration.
disk_create_filesystems         # Create filesystems definied in the configuration.
disk_mount_partitions           # Mount new partitions to temporary locations in chroot.

## Download and extract stage3/4 ----------------------------------------------------------------
gentoo_download                 # Download newest Stage3 or Stage4 tarball.
gentoo_extract                  # Extract tarball to chroot directory.

## Prepare for chroot ---------------------------------------------------------------------------
prepare_chroot                  # Mount devices required for chroot to work and copies resolve.conf.

## Portage configuration ------------------------------------------------------------------------
setup_make_conf                 # Configure make.conf flags.
setup_packages_config           # Configure package.use, package.accep_keywords.

## Various configs ------------------------------------------------------------------------------
setup_root_password             # Sets root password to selected.
setup_fstab                     # Generates fstab file from configuration.
setup_hostname                  # Sets hostname.
setup_network_link              # Setup network devices links and configs.
setup_main_repo                 # Creates empty directory, removes warning before syncing portage.

## Setup PS3 Gentoo internal chroot environment -------------------------------------------------
update_environment              # Refreshing env variables.
setup_locales                   # Generate locales and select default one.
setup_portage_repository        # Downloads latest portage tree.
setup_binhosts                  # Configure binrepos if added in config.
setup_profile                   # Changes profile to selected.
setup_timezone                  # Selects timezone.
install_base_tools              # Installs tools needed at early stage, before distcc is available.
setup_distcc_client             # Downloads and configures distcc if used.
install_updates                 # Updates and rebuilds @world and @system including new use flags.
install_other_tools             # Installs other selected tools.
setup_autostart                 # Adds init scripts to selected runlevels.

## Cleanup and exit -----------------------------------------------------------------------------
revdep_rebuild                  # Fixes broken dependencies.
cleanup                         # Cleans unneded files.
unprepare_chroot                # Unmounts devices and removed DNS configuration.
disk_unmount_partitions         # Unmounts partitions.
cleanup_directories             # Removes temporart installation files.
summary                         # Show summary information if applicable.

## Summary --------------------------------------------------------------------------------------
log green "Installation done"

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
    echo "  --device <device>                 Specify the device to use."
    echo "  --directory <directory>           Specify the directory to work in."
    echo ""
    echo "  --config <remote_config>          Use a remote configuration."
    echo "  --custom-config <config_file>     Use a custom configuration file."
    echo ""
    echo "  --password <password>             Set root user password."
    echo "  --hostname <hostname>             Set hostname."
    echo "  --timezone <TimeZone>             Set timezone."
    echo ""
    echo "  --verbose                         Enable verbose output."
    echo ""
    echo "  --sync-portage true/false         Should perform emerge-sync during installation. If empty, uses value from config."
    echo "  --update-system true/false        Should update @world during installation. If empty, uses value from config."
    echo "  --use-target-swap true/false      Should installer use target device swap if available. If empty, uses value from config."
    echo ""
    echo "  --distcc <host>                   Specify a distcc host."
    exit 1
}

chroot_call() {
    try chroot "$path_chroot" '/bin/bash' -c "$@"
}

## Main functions -------------------------------------------------------------------------------

run_extra_scripts() {
    # Extra scripts are stored in target configuration, and run after finishing or skipping given functions.
    local post_function_name="$1"
    if [ -z "${extra_scripts[$post_function_name]}" ]; then
        return
    fi
    for script in ${extra_scripts[$post_function_name]}; do
        local url_script="$url_installer/scripts/$script.sh"
        local path_script="$path_tmp/scripts/$script.sh"
        try wget "$url_script" -O "$path_script" --no-cache --no-cookies $quiet_flag
        try source "$path_script"
    done
}

# Append values for existing settings in make.conf
append_make_config() {
    local path_make_conf="$path_chroot/etc/portage/make.conf"
    local key="$1"
    local value="$2"
    if grep -q "$key=" "$path_make_conf"; then
        try sed -i "/^$key=/ s/\"\(.*\)\"/\"\1 $value\"/" "$path_make_conf"
    else
        echo "$key=\"$value\"" | try tee -a "$path_make_conf" >/dev/null
    fi
}

# Set new value in make.conf
insert_make_config() {
    local path_make_conf="$path_chroot/etc/portage/make.conf"
    local key="$1"
    local value="$2"
    if grep -q "$key=" "$path_make_conf"; then
        try sed -i "s/^$key=.*/$key=\"$value\"/" "$path_make_conf"
    else
        echo "$key=\"$value\"" | try tee -a "$path_make_conf" >/dev/null
    fi
}

read_variables() {
    while [ $# -gt 0 ]; do
        case "$1" in
        --device)
            shift
            if [ $# -gt 0 ]; then
                disk_device="$1"
                installation_type='disk'
            fi
            ;;
        --directory)
            shift
            if [ $# -gt 0 ]; then
                path_chroot="$1"
                install_directory="$path_chroot"
                installation_type='directory'
            fi
            ;;
        --config)
            shift
            if [ $# -gt 0 ]; then
                config="$1"
            fi
            ;;
        --custom-config)
            shift
            if [ $# -gt 0 ]; then
                custom_config="$1"
            fi
            ;;
        --verbose)
            unset quiet_flag
            unset quiet_flag_short
            verbose_flag="--verbose"
            ;;
        --distcc)
            shift
            if [ $# -gt 0 ]; then
                distcc_hosts="$1"
            fi
            ;;
        --sync-portage)
            shift
            if [ $# -gt 0 ]; then
                fsync_portage=$1
            fi
            ;;
        --update-system)
            shift
            if [ $# -gt 0 ]; then
                fupdate_system=$1
            fi
            ;;
        --use-target-swap)
            shift
            if [ $# -gt 0 ]; then
                fuse_target_swap=$1
            fi
            ;;
        --password)
            shift
            if [ $# -gt 0 ]; then
                froot_password=$1
            fi
            ;;
        --hostname)
            shift
            if [ $# -gt 0 ]; then
                fhostname=$1
            fi
            ;;
        --timezone)
            shift
            if [ $# -gt 0 ]; then
                ftimezone=$1
            fi
            ;;
        *)
            error "Unknown option: $1"
            ;;
        esac
        shift
    done
    run_extra_scripts ${FUNCNAME[0]}
}

override_config() {
    if [ ! -z $fsync_portage ]; then
        sync_portage=$fsync_portage
    fi
    if [ ! -z $fupdate_system ]; then
        update_system=$fupdate_system
    fi
    if [ ! -z $fuse_target_swap ]; then
        use_target_swap=$fuse_target_swap
    fi
    if [ ! -z $froot_password ]; then
        root_password=$froot_password
    fi
    if [ ! -z $fhostname ]; then
        hostname=$fhostname
    fi
    if [ ! -z $ftimezone ]; then
        timezone=$ftimezone
    fi
}

validate_input_data() {
    # Validate if required properties are set.
    if [ -z "$disk_device" ] && [ -z "$install_directory" ]; then
        print_usage
    fi
    if [ ! -z "$disk_device" ] && [ ! -z "$install_directory" ]; then
        print_usage
    fi
    if [ -z "$config" ] && [ -z "$custom_config" ]; then
        print_usage
    fi
    if [ ! -z "$config" ] && [ ! -z "$custom_config" ]; then
        print_usage
    fi
    # Validate if disk is not being used.
    if [ "$installation_type" = 'device' ] && [ ! -e "$disk_device" ]; then
        error "Device $disk_device does not exists."
    fi
    if [ "$installation_type" = 'device' ] && [ lsblk -no MOUNTPOINT "$disk_device" | grep -q -v "^$" ]; then
        error "Device $disk_device is currently in use. Unmount it before usage."
    fi
    run_extra_scripts ${FUNCNAME[0]}
}

warn_about_disk_wiping() {
    if [ "$installation_type" = 'disk' ]; then
        log red "WARNING! If you continue, disk $disk_device will be completly erased. Do you want to continue?"
        local prompt="yes - continue and wipe disk; no - exit: "
        local response

        while true; do
            read -p "$prompt" response
            case "$response" in
            "yes")
                break
                ;;
            *)
                log red "Exiting."
                exit 1
                ;;
            esac
        done
    fi
    run_extra_scripts ${FUNCNAME[0]}
}

prepare_directories() {
    if [ ! -d "$path_tmp" ]; then
        try mkdir -p "$path_tmp"
    fi
    if [ ! -d "$path_tmp/scripts" ]; then
        try mkdir -p "$path_tmp/scripts"
    fi
    if [ ! -d "$path_chroot" ]; then
        try mkdir -p "$path_chroot"
    fi
    run_extra_scripts ${FUNCNAME[0]}
}

get_config() {
    # Get config from the repository or local file.
    local path_config="$path_tmp/config"
    if [ -z "$custom_config" ]; then
        local url_config="$url_installer/config/$config"
        try wget "$url_config" -O "$path_config" --no-http-keep-alive --no-cache --no-cookies $quiet_flag
    else
        try cp "$custom_config" "$path_config"
    fi
    try source "$path_config"
    run_extra_scripts ${FUNCNAME[0]}
}

validate_config() {
    # TODO: Validate settings.
    run_extra_scripts ${FUNCNAME[0]}
}

sort_partitions_by_mount_order() {
    if [ "$installation_type" != 'disk' ]; then
        run_extra_scripts ${FUNCNAME[0]}
        return
    fi
    IFS=$'\n' read -r -d '' -a disk_partitions_sorted_by_mount_order < <(
        for partition in "${disk_partitions[@]}"; do
            echo "$partition"
        done | tr ':' $'\t' | sort -k2,2n | tr $'\t' ':'
    )
    run_extra_scripts ${FUNCNAME[0]}
}

disk_clean_signatures() {
    # Cleans signatures from partition table and every partition.
    if [ "$installation_type" != 'disk' ]; then
        run_extra_scripts ${FUNCNAME[0]}
        return
    fi
    for partition in "$disk_device"*; do
        if [[ -b "$partition" && "$partition" != "$disk_device" ]]; then
            try wipefs -fa "$partition"
        fi
    done
    try wipefs -fa "$disk_device"
    try sleep 1 # Without sleep blockdev below sometimes fails
    try blockdev --rereadpt -v "$disk_device"
    run_extra_scripts ${FUNCNAME[0]}
}

disk_create_partitions() {
    # Create partitions on device.
    if [ "$installation_type" != 'disk' ]; then
        run_extra_scripts ${FUNCNAME[0]}
        return
    fi
    local fdisk_command=''

    if [ "$disk_scheme" = 'gpt' ]; then
        fdisk_command='g\n'
    fi
    if [ "$disk_scheme" = 'dos' ]; then
        fdisk_command='o\n'
    fi

    # Creating partition for given configuration.
    create_partition_from_config() {
        local disk_device="$1"
        local disk_scheme="$2"
        local partition_data="$3"
        local partition_data_fragments=(${partition_data//:/ })
        local partition_data_index="${partition_data_fragments[0]}"
        local partition_data_size="${partition_data_fragments[4]}"
        local primary_partition_selector="" # Adds "p\n" for MBR partition scheme to command.
        if [ "$disk_scheme" = 'dos' ]; then
            primary_partition_selector='p\n'
        fi
        fdisk_command="${fdisk_command}n\n${primary_partition_selector}${partition_data_index}\n\n${partition_data_size}\n"
    }

    for part_config in "${disk_partitions[@]}"; do
        create_partition_from_config "$disk_device" "$disk_scheme" "$part_config"
    done
    # Write new partition scheme
    fdisk_command="${fdisk_command}w\n"
    printf "$fdisk_command" | try fdisk "$disk_device" --wipe auto
    run_extra_scripts ${FUNCNAME[0]}
}

disk_create_filesystems() {
    # Creating filesystem for given configuration.
    if [ "$installation_type" != 'disk' ]; then
        run_extra_scripts ${FUNCNAME[0]}
        return
    fi
    create_filesystem_from_config() {
        local disk_device="$1"
        local partition_data="$2"
        local partition_data_fragments=(${partition_data//:/ })
        local partition_data_index="${partition_data_fragments[0]}"
        local partition_data_filesystem="${partition_data_fragments[2]}"
        local partition_device="${disk_device}${partition_data_index}"
        case "$partition_data_filesystem" in
        'vfat') try mkfs.vfat -F32 "$partition_device" ;;
        'ext3') try mkfs.ext3 -F $quiet_flag_short "$partition_device" ;;
        'ext4') try mkfs.ext4 -F $quiet_flag_short "$partition_device" ;;
        'btrfs') try mkfs.btrfs -f $quiet_flag_short "$partition_device" ;;
        'swap') try mkswap $quiet_flag_short "$partition_device" ;;
        *) error "Unknown partition filesystem $partition_data_filesystem" ;;
        esac
    }
    for part_config in "${disk_partitions[@]}"; do
        create_filesystem_from_config "$disk_device" "$part_config"
    done
    run_extra_scripts ${FUNCNAME[0]}
}

disk_mount_partitions() {
    if [ "$installation_type" != 'disk' ]; then
        run_extra_scripts ${FUNCNAME[0]}
        return
    fi
    mount_filesystem_from_config() {
        local disk_device="$1"
        local partition_data="$2"
        local partition_data_fragments=(${partition_data//:/ })
        local partition_data_index="${partition_data_fragments[0]}"
        local partition_data_filesystem="${partition_data_fragments[2]}"
        local partition_data_mount_point="${partition_data_fragments[3]}"
        local partition_device="${disk_device}${partition_data_index}"
        local partition_mount_path="$path_chroot$partition_data_mount_point"
        if [ "$partition_data_mount_point" != 'none' ]; then
            if [ ! -d "$partition_mount_path" ]; then
                try mkdir "$partition_mount_path"
            fi
            try mount "$partition_device" "$partition_mount_path"
        fi
        if [ "$partition_data_filesystem" = 'swap' ] && [ $use_target_swap = true ]; then
            try swapon "$partition_device"
        fi
    }
    for part_config in "${disk_partitions_sorted_by_mount_order[@]}"; do
        mount_filesystem_from_config "$disk_device" "$part_config"
    done
    run_extra_scripts ${FUNCNAME[0]}
}

# Downloading files =============================================================================

gentoo_download() {
    local url_gentoo_tarball
    local path_download="$path_chroot/gentoo.tar.xz"
    local stageinfo_url="$base_url_autobuilds/latest-stage3.txt"
    local latest_gentoo_content="$(wget -q -O - "$stageinfo_url" --no-http-keep-alive --no-cache --no-cookies)"
    local latest_stage3="$(echo "$latest_gentoo_content" | grep "$arch-$init_system" | head -n 1 | cut -d' ' -f1)"
    if [ -n "$latest_stage3" ]; then
        url_gentoo_tarball="$base_url_autobuilds/$latest_stage3"
    else
        error "Failed to download Stage3 URL"
    fi
    # Download stage3/4 file
    try wget "$url_gentoo_tarball" -O "$path_download" $quiet_flag
    run_extra_scripts ${FUNCNAME[0]}
}

gentoo_extract() {
    local path_stage3or4="$path_chroot/gentoo.tar.xz"
    try tar -xvpf "$path_stage3or4" --xattrs-include="*/*" --numeric-owner -C "$path_chroot/"
    try rm "$path_stage3or4"
    run_extra_scripts ${FUNCNAME[0]}
}

# Configuring system ============================================================================

prepare_chroot() {
    # Mount required devices.
    try mount --types proc /proc "$path_chroot/proc"
    try mount --rbind /sys "$path_chroot/sys"
    try mount --make-rslave "$path_chroot/sys"
    try mount --rbind /dev "$path_chroot/dev"
    try mount --make-rslave "$path_chroot/dev"
    try mount --bind /run "$path_chroot/run"
    try mount --make-slave "$path_chroot/run"
    # Copy DNS information.
    try cp --dereference '/etc/resolv.conf' "$path_chroot/etc/resolv.conf"
    run_extra_scripts ${FUNCNAME[0]}
}

setup_make_conf() {
    for key in "${!make_conf[@]}"; do
        insert_make_config "$key" "${make_conf[$key]}"
    done
    if [ ! -z "$add_features" ]; then
        append_make_config "FEATURES" "$add_features"
    fi
    run_extra_scripts ${FUNCNAME[0]}
}

setup_packages_config() {
    # USE
    local path_package_use="$path_chroot/etc/portage/package.use"
    for key in $(echo "${!package_use[@]}" | tr ' ' '\n' | sort); do
        local key_short=$(echo $key | cut -d'_' -f1)
        echo "${package_use[$key]}" | try tee -a "$path_package_use/$key_short" >/dev/null
    done
    # Accept keywords
    local path_package_accept_keywords="$path_chroot/etc/portage/package.accept_keywords"
    for key in $(echo "${!package_accept_keywords[@]}" | tr ' ' '\n' | sort); do
        local key_short=$(echo $key | cut -d'_' -f1)
        echo "${package_accept_keywords[$key]}" | try tee -a "$path_package_accept_keywords/$key_short" >/dev/null
    done
    run_extra_scripts ${FUNCNAME[0]}
}

setup_binhosts() {
    local path_binrepos="$path_chroot/etc/portage/binrepos.conf"
    if [ ! -d "$path_binrepos" ]; then
        try mkdir -p "$path_binrepos"
    fi    
    for key in $(echo "${!binhosts[@]}" | tr ' ' '\n' | sort); do
        local path_binrepo="$path_binrepos/$key.conf"
        echo "[$key]" | try tee -a "$path_binrepo" >/dev/null
        echo "sync-uri = ${binhosts[$key]}" | try tee -a "$path_binrepo" >/dev/null
    done
    run_extra_scripts ${FUNCNAME[0]}
}

setup_fstab() {
    if [ "$installation_type" != 'disk' ]; then
        log green 'Skipping fstab configuration due to directory installation'
        run_extra_scripts ${FUNCNAME[0]}
        return
    fi
    local path_fstab="$path_chroot/etc/fstab"
    add_partition_entry() {
        local disk_device="$1"
        local partition_data="$2"
        local partition_data_fragments=(${partition_data//:/ })
        local partition_data_index="${partition_data_fragments[0]}"
        local partition_data_filesystem="${partition_data_fragments[2]}"
        local partition_data_mount_point="${partition_data_fragments[3]}"
        local partition_data_flags="${partition_data_fragments[5]}"
        local partition_data_dump="${partition_data_fragments[6]}"
        local partition_data_pass="${partition_data_fragments[7]}"
        local partition_device="${disk_device}${partition_data_index}"
        local partition_mount_path="$path_chroot$partition_data_mount_point"
        local entry="${partition_device} ${partition_data_mount_point} ${partition_data_filesystem} ${partition_data_flags} ${partition_data_dump} ${partition_data_pass}"
        echo "$entry" | try tee -a "$path_fstab" >/dev/null
    }
    for part_config in "${disk_partitions_sorted_by_mount_order[@]}"; do
        add_partition_entry "$disk_device" "$part_config"
    done
    run_extra_scripts ${FUNCNAME[0]}
}

setup_hostname() {
    local path_hostname="$path_chroot/etc/hostname"
    echo "$hostname" | try tee "$path_hostname" >/dev/null
    run_extra_scripts ${FUNCNAME[0]}
}

setup_distcc_client() {
    if [ -z "$distcc_hosts" ]; then
        run_extra_scripts ${FUNCNAME[0]}
        return
    fi
    chroot_call "distcc-config --set-hosts '$distcc_hosts'"
    append_make_config "FEATURES" "distcc"
    run_extra_scripts ${FUNCNAME[0]}
}

# TODO: Add other ways of configuring network, line network manager api.
setup_network_link() {
    local path_initd="$path_chroot/etc/init.d"
    for link in "${network_links[@]}"; do
        ln -s 'net.lo' "$path_initd/net.$link"
    done
    run_extra_scripts ${FUNCNAME[0]}
}

# Actions inside chroot =========================================================================

setup_main_repo() {
    # Silences warnings before emerge-webrsync was run.
    chroot_call 'mkdir -p /var/db/repos/gentoo'
    run_extra_scripts ${FUNCNAME[0]}
}

update_environment() {
    chroot_call 'env-update && source /etc/profile'
    run_extra_scripts ${FUNCNAME[0]}
}

setup_root_password() {
    chroot_call "usermod --password '$root_password' root"
    run_extra_scripts ${FUNCNAME[0]}
}

setup_locales() {
    # Add locales.
    local path_make_conf="$path_chroot/etc/locale.gen"
    echo "C.UTF8 UTF-8" | try tee "$path_make_conf" >/dev/null
    for ((i = 0; i < "${#locales[@]}"; i++)); do
        echo "${locales[$i]}" | try tee -a "$path_make_conf" >/dev/null
    done
    # Generate locales and select default.
    chroot_call 'locale-gen'
    chroot_call "eselect locale set $locale"
    chroot_call 'env-update && source /etc/profile'
    run_extra_scripts ${FUNCNAME[0]}
}

setup_timezone() {
    if [ ! -z "$timezone" ]; then
        chroot_call "echo '$timezone' >> /etc/timezone"
        chroot_call "emerge --config sys-libs/timezone-data"
    fi
}

setup_portage_repository() {
    chroot_call "emerge-webrsync $quiet_flag"
    if [ $sync_portage = true ]; then
        chroot_call "emerge --sync $quiet_flag"
    fi
    run_extra_scripts ${FUNCNAME[0]}
}

setup_profile() {
    chroot_call "eselect profile set $profile"
    chroot_call 'env-update && source /etc/profile'
    run_extra_scripts ${FUNCNAME[0]}
}

install_updates() {
    if [ $update_system = true ]; then
        chroot_call "emerge --newuse --deep --update --with-bdeps=y @system @world $quiet_flag"
    fi
    run_extra_scripts ${FUNCNAME[0]}
}

install_base_tools() {
    for package in "${guest_base_tools[@]}"; do
        chroot_call "FEATURES='-distcc' emerge --update --newuse $package $quiet_flag"
    done
    run_extra_scripts ${FUNCNAME[0]}
}

install_other_tools() {
    for package in "${guest_tools[@]}"; do
        chroot_call "emerge --update --newuse $package $quiet_flag"
    done
    run_extra_scripts ${FUNCNAME[0]}
}

revdep_rebuild() {
    chroot_call "revdep-rebuild $quiet_flag"
    run_extra_scripts ${FUNCNAME[0]}
}

setup_autostart() {
    for key in "${!guest_rc_startup[@]}"; do
        for tool in ${guest_rc_startup[$key]}; do
            chroot_call "rc-update add $tool $key"
        done
    done
    run_extra_scripts ${FUNCNAME[0]}
}

# Cleaning ======================================================================================

cleanup() {
    # News
    chroot_call 'eselect news read all'
    # Portage
    chroot_call "emerge --depclean $quiet_flag"
    chroot_call "eclean --deep $quiet_flag distfiles"
    chroot_call "eclean --deep $quiet_flag packages"
    try rm -rf "$path_chroot/var/cache/distfiles"/*
    try rm -rf "$path_chroot/var/cache/binpkgs"/*
    run_extra_scripts ${FUNCNAME[0]}
}

unprepare_chroot() {
    # Unmount devices
    try umount -l "$path_chroot/dev"{"/shm","/pts"}
    try umount -R "$path_chroot/proc"
    try umount -R "$path_chroot/run"
    try umount -R "$path_chroot/dev"
    try umount -R "$path_chroot/sys"
    # DNS information
    try rm "$path_chroot/etc/resolv.conf"
    run_extra_scripts ${FUNCNAME[0]}
}

disk_unmount_partitions() {
    if [ "$installation_type" != 'disk' ]; then
        run_extra_scripts ${FUNCNAME[0]}
        return
    fi
    unmount_filesystem_from_config() {
        local disk_device="$1"
        local partition_data="$2"
        local partition_data_fragments=(${partition_data//:/ })
        local partition_data_index=${partition_data_fragments[0]}
        local partition_data_filesystem=${partition_data_fragments[2]}
        local partition_data_mount_point=${partition_data_fragments[3]}
        local partition_device=${disk_device}${partition_data_index}
        if [ "$partition_data_filesystem" = 'swap' ] && [ $use_target_swap = true ]; then
            try swapoff $partition_device
        fi
        # Normal partitions are unmountd below
    }
    try umount -R $path_chroot

    # Reverse order of mounting
    for ((i = ${#_disk_partitions_sorted_by_mount_order[@]} - 1; i >= 0; i--)); do
        local part_config="${disk_partitions_sorted_by_mount_order[$i]}"
        unmount_filesystem_from_config $disk_device $part_config
    done
    run_extra_scripts ${FUNCNAME[0]}
}

cleanup_directories() {
    try rm -rf "$path_tmp"
    if [ "$installation_type" = 'disk' ]; then
        try rm -rf "$path_chroot"
    fi
    run_extra_scripts ${FUNCNAME[0]}
}

summary() {
    log magenta "Installation completed"
    if [ "$installation_type" == 'directory' ]; then
        log yellow "Remeber to configure fstab and bootloader"
    fi
    run_extra_scripts ${FUNCNAME[0]}
}
