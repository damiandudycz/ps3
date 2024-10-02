# Base build for desktop profiles. Includes only xorg-server and adds basic rc-scripts.
# Contains also base packages used in all desktop profiles, like kernel, sido, etc.

subarch: cell
target: stage4
rel_type: 23.0-default
version_stamp: desktop-openrc-@TIMESTAMP@
source_subpath: 23.0-default/stage3-cell-desktop-openrc-@TIMESTAMP@
snapshot_treeish: @TREEISH@
portage_confdir: @PORTAGE_CONFDIR@/@STAGE_NAME@/portage
profile: default/linux/ppc64/23.0/desktop
compression_mode: pixz
portage_prefix: releng
binrepo_path: ppc/binpackages/23.0/cell
pkgcache_path: @PKGCACHE_PATH@/cell
repos: @REPOS@
@INTERPRETER@

stage4/root_overlay: @ROOT_OVERLAYS@/stage4-cell-desktop-openrc
#stage4/fsscript: @FSSCRIPTS@/stage4-cell-desktop-openrc.sh

stage4/use:
	ps3
	dist-kernel
	X

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
	x11-base/xorg-server
	x11-misc/lightdm

stage4/rcadd:
	zram-init|boot
	ps3vram-swap|boot
	dbus|default
        NetworkManager|default
	sysklogd|default
	ntpd|default
	ntp-client|default
	display-manager|default

stage4/empty:
	/var/cache/distfiles

stage4/rm:
	/root/.bash_history
