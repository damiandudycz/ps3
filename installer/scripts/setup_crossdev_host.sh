#!/bin/bash

# Configures host crossdev environment.
# To be used on PS3 Helper Host. Not for PS3 itself.

# Create crossdev overlay
chroot_call 'mkdir -p /var/db/repos/crossdev/{profiles,metadata}'
chroot_call 'chown -R portage:portage /var/db/repos/crossdev'
chroot_call 'mkdir -p /etc/portage/repos.conf'
echo 'crossdev' >> "$path_chroot/var/db/repos/crossdev/profiles/repo_name"
echo 'masters = gentoo' >> "$path_chroot/var/db/repos/crossdev/metadata/layout.conf"
echo '[crossdev]' >> "$path_chroot/etc/portage/repos.conf/crossdev.conf"
echo 'location = /var/db/repos/crossdev' >> "$path_chroot/etc/portage/repos.conf/crossdev.conf"
echo 'priority = 10' >> "$path_chroot/etc/portage/repos.conf/crossdev.conf"
echo 'masters = gentoo' >> "$path_chroot/etc/portage/repos.conf/crossdev.conf"
echo 'auto-sync = no' >> "$path_chroot/etc/portage/repos.conf/crossdev.conf"

# Default configuration for the PS3 helper.
chroot_call "crossdev --b '${crossdev_config['b']}' --g '${crossdev_config['g']}' --k '${crossdev_config['k']}' --l '${crossdev_config['l']}' -t powerpc64-unknown-linux-gnu --abis ${crossdev_config['a']}"
