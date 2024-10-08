subarch: cell
target: stage4
version_stamp: desktop-xfce-openrc-@TIMESTAMP@
source_subpath: @PLATFORM@/@REL_TYPE@/stage4-cell-desktop-openrc-@TIMESTAMP@
snapshot_treeish: @TREEISH@
profile: default/linux/ppc64/23.0/desktop
compression_mode: pixz
#portage_prefix: releng
pkgcache_path: @PKGCACHE_PATH@/cell
repos: @REPOS@

stage4/use:
	ps3
	dist-kernel
	X

stage4/packages:
	xfce-base/xfce4-meta

stage4/empty:
	/var/cache/distfiles

stage4/rm:
	/root/.bash_history
