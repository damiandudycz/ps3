#!/bin.bash

# Configures bootloader using specified device configuration from config.
# Works with petitboot, grub and grub-efi.

if [ "$installation_type" != 'disk' ]; then
    log green 'Skipping bootloader configuration due to directory installation'
    return
fi
case "$bootloader" in
'petitboot')
    local disk_device_name=$(echo "$disk_device" | rev | cut -d'/' -f1 | rev)

    local root_index=0
    local boot_index=0

    # Find root and boot partition indexes
    scan_partition_config() {
        local disk_device="$1"
        local partition_data="$2"
        local partition_data_fragments=(${partition_data//:/ })
        local partition_data_index=${partition_data_fragments[0]}
        local partition_data_mount_point=${partition_data_fragments[3]}
        if [ "$partition_data_mount_point" = '/' ]; then
            root_index=$partition_data_index
        fi
        if [ "$partition_data_mount_point" = '/boot' ]; then
            boot_index=$partition_data_index
        fi
    }
    for part_config in "${disk_partitions[@]}"; do
        scan_partition_config "$disk_device" "$part_config"
    done
    if [ $boot_index -eq 0 ]; then
        boot_index=$root_index
    fi

    if [ $boot_index -eq $root_index ]; then
        # Install to /etc
        local kboot_entry1="Gentoo='/boot/vmlinux-$kernel_version initrd=/boot/initramfs-$kernel_version.img root=/dev/${disk_device_name}${root_index} video=ps3fb:mode:133 rhgb'"
        echo "$kboot_entry1" | try tee "$path_chroot/etc/kboot.conf" >/dev/null
    else
        # Install to /boot
        local kboot_entry1="Gentoo='/vmlinux-$kernel_version initrd=/initramfs-$kernel_version.img root=/dev/${disk_device_name}${root_index} video=ps3fb:mode:133 rhgb'"
        echo "$kboot_entry1" | try tee "$path_chroot/boot/kboot.conf" >/dev/null
    fi
    ;;
'grub')
    chroot_call 'grub-install'
    chroot_call 'grub-mkconfig -o /boot/grub/grub.cfg'
    ;;
'grub-efi')
    chroot_call 'grub-install --efi-directory=/boot'
    chroot_call 'grub-mkconfig -o /boot/grub/grub.cfg'
    ;;
*) ;;
esac
