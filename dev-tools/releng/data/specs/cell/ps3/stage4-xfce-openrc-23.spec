subarch: cell
target: stage4
rel_type: 23.0-default
version_stamp: xfce-openrc-@TIMESTAMP@
source_subpath: 23.0-default/stage4-cell-xorg-openrc-@TIMESTAMP@
snapshot_treeish: @TREEISH@
portage_confdir: @PORTAGE_CONFDIR@/xfce
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
	xfce4-base/xfce4-meta

stage4/empty:
	/var/cache/distfiles

stage4/rm:
	/root/.bash_history
