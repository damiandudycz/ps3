subarch: cell
target: stage4
rel_type: 23.0-default
version_stamp: openrc-@TIMESTAMP@
source_subpath: 23.0-default/stage3-cell-openrc-@TIMESTAMP@
snapshot_treeish: @TREEISH@
portage_confdir: @REPO_DIR@/releases/portage/stages@PORTAGE_CONFDIR_POSTFIX@
profile: default/linux/ppc64/23.0/desktop
compression_mode: pixz
portage_prefix: releng
binrepo_path: ppc/binpackages/23.0/cell # ??
pkgcache_path: @PKGCACHE_PATH@/cell
repos: @REPOS@
@INTERPRETER@

stage4/use:
	gtk
	gtk3

stage4/packages:
    --getbinpkg
	sys-kernel/gentoo-kernel-ps3
	app-admin/sudo
	app-admin/sysklogd
	app-misc/ps3pf_utils
	app-eselect/eselect-repository
	app-portage/gentoolkit
	dev-vcs/git
	new-misc/ntp
	sys-apps/ps3vram-swap
	sys-devel/distcc
	net-misc/dhcpcd
	x11-base/xorg-server
	mate-base/mate

stage4/rcadd:
	ps3vram-swap|boot
	net.eth0|default
	dbus|default
	sysklogd|default
	ntpd|default
	ntp-client|default
	display-manager|default

stage4/empty:
	/var/cache/distfiles

stage4/rm:
	/root/.bash_history

#stage4/fsscript: @STAGE4_FSSCRIPT@
#stage4/root_overlay: @STAGE4_OVERLAY@
