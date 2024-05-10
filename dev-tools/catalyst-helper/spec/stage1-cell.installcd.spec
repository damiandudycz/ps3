# Release version details
version_stamp: @TIMESTAMP@
source_subpath: default/stage3-cell-openrc-@TIMESTAMP@
snapshot_treeish: @TREEISH@
repos: @REPOS@
portage_confdir: @PORTAGE_CONFDIR@
@INTERPRETER@

# Architecture and profile
subarch: cell
target: livecd-stage1
rel_type: default
profile: default/linux/ppc64/23.0
compression_mode: pixz

# USE flags
livecd/use:
 	ps3
	alsa
	compile-locales
	fbcon
	livecd
	portaudio
	socks5
	unicode
	xml

# Packages
livecd/packages:
	sys-apps/ps3vram-swap
	app-accessibility/brltty
	app-admin/pwgen
	app-admin/syslog-ng
	app-arch/lbzip2
	app-arch/pigz
	app-arch/unzip
	app-arch/zstd
	app-crypt/gnupg
	app-misc/livecd-tools
	app-misc/screen
	app-misc/tmux
	app-portage/cpuid2cpuflags
	app-portage/mirrorselect
	app-shells/bash-completion
	app-shells/gentoo-bashcomp
	app-text/wgetpaste
	dev-embedded/u-boot-tools
	dev-vcs/git
	net-analyzer/tcptraceroute
	net-analyzer/traceroute
	net-dialup/mingetty
	net-dialup/picocom
	net-dialup/pptpclient
	net-dialup/rp-pppoe
	net-fs/cifs-utils
	net-fs/nfs-utils
	net-irc/irssi
	net-irc/weechat
	net-misc/chrony
	net-misc/dhcpcd
	net-misc/iputils
	net-misc/openssh
	net-misc/rdate
	net-misc/rsync
	net-wireless/iw
	net-wireless/iwd
	net-wireless/wireless-tools
	net-wireless/wpa_supplicant
	sys-apps/busybox
	sys-apps/ethtool
	sys-apps/fxload
	sys-apps/gptfdisk
	sys-apps/hdparm
	sys-apps/ibm-powerpc-utils
	sys-apps/ipmitool
	sys-apps/iproute2
	sys-apps/lm-sensors
	sys-apps/lsvpd
	sys-apps/memtester
	sys-apps/merge-usr
	sys-apps/opal-utils
	sys-apps/ppc64-diag
	sys-apps/sdparm
	sys-apps/usbutils
	sys-auth/ssh-import-id
	sys-block/parted
	sys-fs/bcache-tools
	sys-fs/btrfs-progs
	sys-fs/cryptsetup
	sys-fs/dosfstools
	sys-fs/e2fsprogs
	sys-fs/f2fs-tools
	sys-fs/iprutils
	sys-fs/jfsutils
	sys-fs/lsscsi
	sys-fs/lvm2
	sys-fs/mdadm
	sys-fs/mtd-utils
	sys-fs/reiserfsprogs
	sys-fs/squashfs-tools
	sys-fs/sysfsutils
	sys-fs/xfsdump
	sys-fs/xfsprogs
	sys-libs/gpm
	sys-process/htop
	sys-process/lsof
	www-client/links
#	sys-apps/nvme-cli
#	sys-apps/pciutils
#	sys-boot/grub
#	sys-fs/hfsplusutils
#	sys-fs/hfsutils
#	sys-fs/ntfs3g
#	sys-kernel/linux-firmware
