#!/bin/bash

# HELPER VARIABLES ==============================================================================

dir="$(pwd)" # Current directory where script was called from.
branch="main"
path_tmp="$dir/_gentoo_tmp_files" # Temporary files storage directory.
path_chroot="$dir/_gentoo_chroot" # Gentoo chroot environment directory.
quiet_flag='--quiet'              # Quiet flag used to silence the output.
quiet_flag_short='-q'             # Quiet flag used to silence the output.
ssh_distcc_host_user='root'       # Username for SSH when updating distcc host configuration. Can change with --distcc-user flag.
fast=false

# MAIN PROGRAM ==================================================================================

## Prepare --------------------------------------------------------------------------------------
source <(sed '1,/^# FUNCTIONS #.*$/d' "$0") # Load functions at the bottom of the script.

read_variables "$@"    # Read user input variables - device, configuration, verbose.
validate_input_data    # Validate if input data is correct.
warn_about_disk_wiping # Asks user to confirm disk formatting is applying.

prepare_directories            # Create path_tmp and path_chroot.
get_config                     # Download configuration or load local configuration file.
override_config                # Override default values from config, using flags.
validate_config                # Checks if all settings in configuration are set correctly.
sort_partitions_by_mount_order # Prepare array of devices sorted by mounting order.

## Setup disk -----------------------------------------------------------------------------------
disk_clean_signatures   # Remove existing signatures of partition table, and partitions from the disk.
disk_create_partitions  # Create new partitions, definied in the configuration.
disk_create_filesystems # Create filesystems definied in the configuration.

## Mount partitions -----------------------------------------------------------------------------
disk_mount_partitions # Mount new partitions to temporary locations in chroot.

## Download and extract stage3/4 ----------------------------------------------------------------
gentoo_download # Download newest Stage3 or Stage4 tarball.
gentoo_extract  # Extract tarball to chroot directory.

## Prepare for chroot ---------------------------------------------------------------------------
prepare_chroot # Mount devices required for chroot to work and copies resolve.conf.

## Portage configuration ------------------------------------------------------------------------
setup_make_conf       # Configure make.conf flags.
setup_packages_config # Configure package.use, package.accep_keywords.

## Various configs ------------------------------------------------------------------------------
setup_root_password # Sets root password to selected.
setup_fstab         # Generates fstab file from configuration.
setup_hostname      # Sets hostname.
setup_network       # Setup network devices links and configs.
setup_ssh           # Configure SSH access.
setup_main_repo     # Creates empty directory, removes warning before syncing portage.

## Setup PS3 Gentoo internal chroot environment -------------------------------------------------
update_environment       # Refreshing env variables.
setup_locales            # Generate locales and select default one.
setup_portage_repository # Downloads latest portage tree.
setup_profile            # Changes profile to selected.
setup_cpu_flags          # Downloads and uses cpuid2cpuflags to generate flags for current CPU.
install_base_tools       # Installs tools needed at early stage, before distcc is available.
setup_distcc_client      # Downloads and configures distcc if used.
setup_distcc_hosts       # Uploads SSH public key to all of the hosts.
install_updates          # Updates and rebuilds @world and @system including new use flags.
install_other_tools      # Installs other selected tools.
setup_autostart          # Adds init scripts to selected runlevels.

## Cleanup and exit -----------------------------------------------------------------------------
revdep_rebuild          # Fixes broken dependencies.
cleanup                 # Cleans unneded files.
unprepare_chroot        # Unmounts devices and removed DNS configuration.
disk_unmount_partitions # Unmounts partitions.
cleanup_directories     # Removes temporart installation files.
summary                 # Show summary information if applicable.

## Summary --------------------------------------------------------------------------------------
log green "Installation done"

exit

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
    echo ""
    echo "  --fast [NOT IMPLEMENTED]          Performs faster method of installation, using stage4 tarball. Some options are not available in this mode."
    echo ""
    echo "  --verbose                         Enable verbose output."
    echo ""
    echo "  --sync-portage true/false         Should perform emerge-sync during installation. If empty, uses value from config."
    echo "  --update-system true/false        Should update @world during installation. If empty, uses value from config."
    echo "  --use-cpuid2cpuflags true/false   Install and use cpuid2cpuflags to setup /etc/portage/package.use/00cpu-flags. If empty, uses value from config."
    echo "  --use-target-swap true/false      Should installer use target device swap if available. If empty, uses value from config."
    echo ""
    echo "  --distcc <host>                   Specify a distcc host."
    echo "  --distcc-user <host_username>     Specify the username for distcc host."
    echo "  --distcc-password <host_password> Specify the password for distcc host."
    echo ""
    echo "  --branch <branch_name>            Specify branch of install script, from which to get files. Default: main."
    exit 1
}

chroot_call() {
    try chroot "$path_chroot" '/bin/bash' -c "$@"
}

## Disk preparation -----------------------------------------------------------------------------

run_extra_scripts() {
    # Extra scripts are stored in target configuration, and run after finishing or skipping given functions.
    local post_function_name="$1"
    if [ -z "${extra_scripts[$post_function_name]}" ]; then
        return
    fi
    for script in ${extra_scripts[$post_function_name]}; do
        local url_script="$url_repo/scripts/$script.sh"
        local path_script="$path_tmp/scripts/$script.sh"
        try wget "$url_script" -O "$path_script" --no-cache --no-cookies $quiet_flag
        try source "$path_script"
    done
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
        --fast)
            fast=true
            ;;
        --distcc)
            shift
            if [ $# -gt 0 ]; then
                distcc_hosts="$1"
            fi
            ;;
        --distcc-user)
            shift
            if [ $# -gt 0 ]; then
                ssh_distcc_host_user="$1"
            fi
            ;;
        --distcc-password)
            shift
            if [ $# -gt 0 ]; then
                ssh_distcc_host_password="$1"
            fi
            ;;
        --branch)
            shift
            if [ $# -gt 0 ]; then
                branch="$1"
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
        --use-cpuid2cpuflags)
            shift
            if [ $# -gt 0 ]; then
                fuse_cpuid2cpuflags=$1
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
        *)
            error "Unknown option: $1"
            ;;
        esac
        shift
    done
    url_repo="https://raw.githubusercontent.com/damiandudycz/Gentoo-Installer/$branch"
    run_extra_scripts ${FUNCNAME[0]}
}

override_config() {
    if [ ! -z $fsync_portage ]; then
        sync_portage=$fsync_portage
    fi
    if [ ! -z $fupdate_system ]; then
        update_system=$fupdate_system
    fi
    if [ ! -z $fuse_cpuid2cpuflags ]; then
        use_cpuid2cpuflags=$fuse_cpuid2cpuflags
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
            "no")
                exit 1
                ;;
            *) ;;
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
        local url_config="$url_repo/config/$config"
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
    local path_download="$path_tmp/gentoo.tar.xz"
    if [ $fast = true ]; then
        url_gentoo_tarball="$url_repo/stage4/$config.tar.xz"
    else
        local stageinfo_url="$base_url_autobuilds/latest-stage3.txt"
        local latest_gentoo_content="$(wget -q -O - "$stageinfo_url" --no-http-keep-alive --no-cache --no-cookies)"
        local latest_stage3="$(echo "$latest_gentoo_content" | grep "$arch-$init_system" | head -n 1 | cut -d' ' -f1)"
        if [ -n "$latest_stage3" ]; then
            url_gentoo_tarball="$base_url_autobuilds/$latest_stage3"
        else
            error "Failed to download Stage3 URL"
        fi
    fi
    # Download stage3/4 file
    try wget "$url_gentoo_tarball" -O "$path_download" $quiet_flag
    run_extra_scripts ${FUNCNAME[0]}
}

gentoo_extract() {
    local path_stage3="$path_tmp/gentoo.tar.xz"
    try tar -xvpf "$path_stage3" --xattrs-include="*/*" --numeric-owner -C "$path_chroot/"
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
    local path_make_conf="$path_chroot/etc/portage/make.conf"
    insert_config() {
        local key="$1"
        local value="$2"
        if grep -q "$key=" "$path_make_conf"; then
            try sed -i "s/^$key=.*/$key=\"$value\"/" "$path_make_conf"
        else
            echo "$key=\"$value\"" | try tee -a "$path_make_conf" >/dev/null
        fi
    }
    for key in "${!make_conf[@]}"; do
        insert_config "$key" "${make_conf[$key]}"
    done
    run_extra_scripts ${FUNCNAME[0]}
}

setup_packages_config() {
    # USE
    local path_package_use="$path_chroot/etc/portage/package.use"
    for key in "${!package_use[@]}"; do
        echo "${package_use[$key]}" | try tee "$path_package_use/$key" >/dev/null
    done
    # Accept keywords
    local path_package_accept_keywords="$path_chroot/etc/portage/package.accept_keywords"
    for key in "${!package_accept_keywords[@]}"; do
        echo "${package_accept_keywords[$key]}" | try tee "$path_package_accept_keywords/$key" >/dev/null
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
    # Generate SSH key to be inserted in helper hosts. Also used by sshd on guest.
    chroot_call 'ssh-keygen -q -t rsa -N "" <<< $"\ny" >/dev/null 2>&1'

    if [ -z "$distcc_hosts" ]; then
        run_extra_scripts ${FUNCNAME[0]}
        return
    fi
    # USE='-zeroconf' is used to speed up installation the first time. Otherwise it will emerge avahi and all dependencies.
    # This will be updated later with default flags.
    chroot_call "FEATURES=\"-distcc\" USE='-zeroconf' emerge --update --newuse distcc $quiet_flag"
    # local hosts_cpplzo=$(echo "$distcc_hosts" | sed 's/\([^ ]\+\) \(localhost\|[^ ]\+\)/\1,lzo \2/g')
    chroot_call "distcc-config --set-hosts '$distcc_hosts'"
    update_distcc_host

    # Add features for distcc and getbinpkg
    chroot_call 'echo FEATURES="${FEATURES} distcc getbinpkg" >> /etc/portage/make.conf'

    for distcc_host in ${distcc_hosts[@]}; do
        if [ "$distcc_host" != 'localhost' ]; then
            # Insert PORTAGE_BINHOST
            local location="ssh://$ssh_distcc_host_user@$distcc_host/usr/$arch_long-unknown-linux-gnu/var/cache/binpkgs"
            chroot_call "echo '[$distcc_host]' >> /etc/portage/binrepos.conf"
            chroot_call "echo 'sync-uri = $location' >> /etc/portage/binrepos.conf"
            chroot_call "echo '' >> /etc/portage/binrepos.conf"
        fi
    done
    run_extra_scripts ${FUNCNAME[0]}
}

setup_distcc_hosts() {
    if [ -z "$distcc_hosts" ]; then
        run_extra_scripts ${FUNCNAME[0]}
        return
    fi

    for distcc_host in ${distcc_hosts[@]}; do
        if [ "$distcc_host" != 'localhost' ]; then
            # Upload ssh key, for passwordless communication
            if [ -z "$quiet_flag" ]; then
                ssh_quiet=''
            else
                ssh_quiet="-o LogLevel=quiet"
            fi
            # Add host to known_hosts
            chroot_call "ssh-keyscan -H $distcc_host >> ~/.ssh/known_hosts"
            if [ -z "$ssh_distcc_host_password" ]; then
                chroot_call "ssh-copy-id $ssh_distcc_host_user@$distcc_host"
            else
                chroot_call "sshpass -p $ssh_distcc_host_password ssh-copy-id $ssh_distcc_host_user@$distcc_host"
            fi
        fi
    done

    run_extra_scripts ${FUNCNAME[0]}
}

setup_ssh() {
    local sshd_path="$path_chroot/etc/ssh/sshd_config"
    if [ $ssh_allow_root = true ]; then
        try sed -i 's/^#PermitRootLogin .*/PermitRootLogin yes/' "$sshd_path"
    fi
    if [ $ssh_allow_passwordless = true ]; then
        try sed -i 's/^#PermitEmptyPasswords .*/PermitEmptyPasswords yes/' "$sshd_path"
    fi
    run_extra_scripts ${FUNCNAME[0]}
}

setup_network() {
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

setup_portage_repository() {
    if [ $fast = false ]; then
        chroot_call "emerge-webrsync $quiet_flag"
    fi
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

setup_cpu_flags() {
    if [ $use_cpuid2cpuflags = false ]; then
        run_extra_scripts ${FUNCNAME[0]}
        return
    fi
    chroot_call "FEATURES=\"-distcc\" emerge --update --newuse cpuid2cpuflags -1 $quiet_flag"
    chroot_call 'echo "*/* $(cpuid2cpuflags)" > /etc/portage/package.use/00cpu-flags'
    run_extra_scripts ${FUNCNAME[0]}
}

update_distcc_host() {
    if [ -z "$distcc_hosts" ]; then
        run_extra_scripts ${FUNCNAME[0]}
        return
    fi
    log cyan "Reading distcc system configuration"
    BINUTILS_VER=$(qatom -F '%{PV}' $(qfile -v $(realpath /usr/bin/ld) | cut -d' ' -f1))
    GCC_VER=$(qatom -F '%{PV}' $(qfile -v $(realpath /usr/bin/gcc) | cut -d' ' -f1))
    KERNEL_VER=$(qatom -F '%{PV}' $(qlist -Ive sys-kernel/linux-headers))
    LIBC_VER=$(qatom -F '%{PV}' $(qlist -Ive sys-libs/glibc))
    if [ ! -z "$abi" ]; then
        distcc_host_setup_command="crossdev --b '~${BINUTILS_VER}' --g '~${GCC_VER}' --k '~${KERNEL_VER}' --l '~${LIBC_VER}' -t $(portageq envvar CHOST) --abis $abi"
    else
        distcc_host_setup_command="crossdev --b '~${BINUTILS_VER}' --g '~${GCC_VER}' --k '~${KERNEL_VER}' --l '~${LIBC_VER}' -t $(portageq envvar CHOST)"
    fi
    # If configuration didn't change, we can skip this.
    if [ ! -z "$distcc_host_setup_command_stored" ] && [ "$distcc_host_setup_command_stored" = "$distcc_host_setup_command" ]; then
        run_extra_scripts ${FUNCNAME[0]}
        return
    fi
    distcc_host_setup_command_stored="$distcc_host_setup_command"
    if [ -z "$quiet_flag" ]; then
        ssh_quiet=''
    else
        ssh_quiet="-o LogLevel=quiet"
    fi
    for distcc_host in ${distcc_hosts[@]}; do
        if [ "$distcc_host" != 'localhost' ]; then
            chroot_call "ssh $ssh_quiet $ssh_distcc_host_user@$distcc_host $distcc_host_setup_command"
            # TODO: Set /usr/<crossdev>/ profile to the same as of this machine
            # TODO: Insert /usr/<crossdev>/etc/portage/ files and config
        fi
    done
    run_extra_scripts ${FUNCNAME[0]}
}

install_updates() {
    if [ $update_system = true ]; then
        chroot_call "emerge --newuse --deep --update @system @world $quiet_flag"
        update_distcc_host
    fi
    run_extra_scripts ${FUNCNAME[0]}
}

install_base_tools() {
    for package in "${guest_base_tools[@]}"; do
        chroot_call "FEATURES=\"-distcc\" emerge --update --newuse --deep $package $quiet_flag"
    done
    run_extra_scripts ${FUNCNAME[0]}
}

install_other_tools() {
    for package in "${guest_tools[@]}"; do
        chroot_call "emerge --update --newuse --deep $package $quiet_flag"
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

        try umount -l $path_chroot/dev{/shm,/pts,}
        try umount $path_chroot/{sys,proc}

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

# TODO: Wireless networking configuration
# TODO: Custom repos usage
# TODO: Users add scripts
# TODO: GIT repository from binpkg's

# TODO: Automatic configuration of helper tools:
# distcc initial config
# copying make conf and other portage details
# setting the same profile # PORTAGE_CONFIGROOT=/usr/powerpc64-unknown-linux-gnu eselect profile set 1
# building @system with --keep-going and other flags: https://wiki.gentoo.org/wiki/Cross_build_environment
# powerpc64-unknown-linux-gnu-emerge -uva --keep-going @system
# emerge --newuse --update --deep @world
# Or instead ot last two, use emerge -e @world, but this might not work
# TODO: Add distcc and getbinpkg on demand depending on configuration.