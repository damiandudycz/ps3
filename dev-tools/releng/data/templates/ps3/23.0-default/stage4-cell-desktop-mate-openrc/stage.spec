target: stage4
version_stamp: desktop-mate-openrc-@TIMESTAMP@
source_subpath: @PLATFORM@/@REL_TYPE@/stage4-cell-desktop-openrc-@TIMESTAMP@
profile: default/linux/@BASE_ARCH@/23.0/desktop
compression_mode: pixz

stage4/use:
	ps3
	dist-kernel
	X

stage4/packages:
	mate-base/mate

stage4/empty:
	/var/cache/distfiles

stage4/rm:
	/root/.bash_history

#subarch: cell
#portage_prefix: releng
#pkgcache_path: @PKGCACHE_PATH@/cell
#snapshot_treeish: @TREEISH@
#repos: @REPOS@
