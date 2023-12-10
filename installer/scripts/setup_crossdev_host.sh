#!/bin/bash

# Configures host crossdev environment.
# Creates and configures crossdev targets.

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

# TODO: Get values from script arguments

# Default configuration for the PS3 - Should be added to config of target and not stored directly here.
chroot_call 'crossdev --b '~2.40' --g '~13.2.1_p20230826' --k '~6.5' --l '~2.37' -t powerpc64-unknown-linux-gnu --abis altivec'

# TODO: Get value of profile somehow and powerpc64-unknown-linux-gnu.
chroot_call 'PORTAGE_CONFIGROOT=/usr/powerpc64-unknown-linux-gnu eselect profile set 1'

path_makeconf="$path_chroot/usr/powerpc64-unknown-linux-gnu/etc/portage/make.conf"
echo '' > "$path_makeconf"
echo 'CHOST=powerpc64-unknown-linux-gnu' >> "$path_makeconf"
echo 'CBUILD=aarch64-unknown-linux-gnu' >> "$path_makeconf"
echo 'ROOT=/usr/${CHOST}/' >> "$path_makeconf"
echo 'ACCEPT_KEYWORDS="${ARCH}"' >> "$path_makeconf"
echo 'ACCEPT_LICENSE="*"' >> "$path_makeconf"
echo 'USE="ps3 zeroconf mdnsresponder-compat"' >> "$path_makeconf"
echo 'VIDEO_CARDS="fbdev"' >> "$path_makeconf"
echo 'INPUT_DEVICES="evdev"' >> "$path_makeconf"
echo 'COMMON_FLAGS="-O2 -pipe -mcpu=cell -mtune=cell -mabi=altivec -maltivec -mno-string -mno-update -mno-multiple"' >> "$path_makeconf"
echo 'CFLAGS="${COMMON_FLAGS}"' >> "$path_makeconf"
echo 'CXXFLAGS="${COMMON_FLAGS}"' >> "$path_makeconf"
echo 'FCFLAGS="${COMMON_FLAGS}"' >> "$path_makeconf"
echo 'FFLAGS="${COMMON_FLAGS}"' >> "$path_makeconf"
echo 'MAKEOPTS="-j6"' >> "$path_makeconf"
echo 'FEATURES="-collision-protect sandbox buildpkg -news"' >> "$path_makeconf"
echo 'PKGDIR=${ROOT}var/cache/binpkgs/' >> "$path_makeconf"
echo 'PORTAGE_TMPDIR=${ROOT}tmp/' >> "$path_makeconf"
echo 'PKG_CONFIG_PATH="${ROOT}usr/lib/pkgconfig/"' >> "$path_makeconf"

path_use="$path_chroot/usr/powerpc64-unknown-linux-gnu/etc/portage/package.use"
echo '*/* CPU_FLAGS_PPC: altivec' >> "$path_use"

path_accept="$path_chroot/usr/powerpc64-unknown-linux-gnu/etc/portage/package.accept_keywords"
echo 'app-misc/neofetch ~ppc64' >> "$path_accept"
echo 'app-misc/ps3pf_utils ~ppc64' >> "$path_accept"
echo 'net-misc/sshpass ~ppc64' >> "$path_accept"
echo '=sys-kernel/linux-headers-6.5-r1 ~ppc64' >> "$path_accept"

# TODO: Build and upload exe_wrapper to path_chroot/usr/powerpc64-unknown-linux-gnu/usr/bin, plus register it in qemu on this host
