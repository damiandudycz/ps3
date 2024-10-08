# Base build for desktop profiles. Includes only xorg-server and adds basic rc-scripts.
# Contains also base packages used in all desktop profiles, like kernel, sido, etc.

target: stage4
version_stamp: base-openrc-@TIMESTAMP@
source_subpath: @PLATFORM@/@REL_TYPE@/stage3-cell-base-openrc-@TIMESTAMP@
snapshot_treeish: @TREEISH@
profile: default/linux/@BASE_ARCH@/23.0
compression_mode: pixz
binrepo_path: ppc/binpackages/23.0/cell
pkgcache_path: @PKGCACHE_PATH@/cell
repos: @REPOS@

#subarch: cell
#portage_prefix: releng

stage4/use:
	ps3
	dist-kernel

stage4/packages:
	sys-kernel/gentoo-kernel-ps3
        sys-kernel/linux-headers
        sys-devel/distcc
        app-eselect/eselect-repository
        dev-vcs/git
        app-portage/gentoolkit
	app-misc/ps3pf_utils
	sys-apps/ps3vram-swap
	sys-block/zram-init
#	net-misc/dhcpcd
	app-admin/sudo
	app-admin/sysklogd
	net-misc/ntp
        net-misc/networkmanager

stage4/rcadd:
	zram-init|boot
	ps3vram-swap|boot
	dbus|default
        NetworkManager|default
	sysklogd|default
	ntpd|default
	ntp-client|default

stage4/empty:
	/var/cache/distfiles

stage4/rm:
	/root/.bash_history
