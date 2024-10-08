target: stage4
version_stamp: desktop-xfce-openrc-@TIMESTAMP@
source_subpath: @PLATFORM@/@REL_TYPE@/stage4-cell-desktop-openrc-@TIMESTAMP@
snapshot_treeish: @TREEISH@
profile: default/linux/@BASE_ARCH@/23.0/desktop
compression_mode: pixz
pkgcache_path: @PKGCACHE_PATH@/cell
repos: @REPOS@

#subarch: cell
#portage_prefix: releng

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
