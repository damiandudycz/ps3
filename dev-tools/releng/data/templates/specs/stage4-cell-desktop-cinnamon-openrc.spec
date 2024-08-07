subarch: cell
target: stage4
rel_type: 23.0-default
version_stamp: desktop-cinnamon-openrc-@TIMESTAMP@
source_subpath: 23.0-default/stage4-cell-desktop-openrc-@TIMESTAMP@
snapshot_treeish: @TREEISH@
portage_confdir: @PORTAGE_CONFDIR@/stage4-cell-desktop-cinnamon-openrc
profile: default/linux/ppc64/23.0/desktop
compression_mode: pixz
portage_prefix: releng
pkgcache_path: @PKGCACHE_PATH@/cell
repos: @REPOS@
@INTERPRETER@

stage4/use:
	ps3
	dist-kernel
	X

stage4/packages:
	gnome-extra/cinnamon

stage4/empty:
	/var/cache/distfiles

stage4/rm:
	/root/.bash_history
