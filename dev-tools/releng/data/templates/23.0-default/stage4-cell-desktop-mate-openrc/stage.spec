subarch: cell
target: stage4
rel_type: @REL_TYPE@
version_stamp: desktop-mate-openrc-@TIMESTAMP@
source_subpath: @REL_TYPE@/stage4-cell-desktop-openrc-@TIMESTAMP@
snapshot_treeish: @TREEISH@
portage_confdir: @STAGEFILES_DIR@/@STAGE_NAME@/portage
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
	mate-base/mate

stage4/empty:
	/var/cache/distfiles

stage4/rm:
	/root/.bash_history
