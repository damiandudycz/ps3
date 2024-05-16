# Base build for desktop profiles. Includes only xorg-server and adds basic rc-scripts.
# Contains also base packages used in all desktop profiles, like kernel, sido, etc.

subarch: cell
target: stage4
rel_type: 23.0-default
version_stamp: xorg-openrc-@TIMESTAMP@
source_subpath: 23.0-default/stage3-cell-openrc-@TIMESTAMP@
snapshot_treeish: @TREEISH@
portage_confdir: @PORTAGE_CONFDIR@/xorg
profile: default/linux/ppc64/23.0/desktop
compression_mode: pixz
portage_prefix: releng
binrepo_path: ppc/binpackages/23.0/cell
pkgcache_path: @PKGCACHE_PATH@/cell
repos: @REPOS@
@INTERPRETER@

stage4/use:
	ps3
	dist-kernel
	X

stage4/packages:
    --getbinpkg
	sys-kernel/gentoo-kernel-ps3
	app-admin/sudo #?
	app-admin/sysklogd #?
	app-misc/ps3pf_utils
	net-misc/ntp #?
	sys-apps/ps3vram-swap
	sys-devel/distcc #?
	net-misc/dhcpcd
	x11-base/xorg-server
	x11-apps/mesa-progs #?
#	=sys-devel/gcc-9.5.0 #?
#	app-eselect/eselect-repository
#	app-portage/gentoolkit
#	dev-vcs/git

stage4/rcadd:
	ps3vram-swap|boot
	net.eth0|default
	dbus|default
	sysklogd|default
	ntpd|default
	ntp-client|default

stage4/empty:
	/var/cache/distfiles

stage4/rm:
	/root/.bash_history
