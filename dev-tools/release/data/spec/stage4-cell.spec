# Release version details
version_stamp: openrc-@TIMESTAMP@
source_subpath: default/stage3-cell-openrc-@TIMESTAMP@
snapshot_treeish: @TREEISH@
portage_confdir: @PORTAGE_CONFDIR@
pkgcache_path: @PKGCACHE_PATH@
repos: @REPOS@
@INTERPRETER@

# Architecture and profile
subarch: cell
target: stage4
rel_type: default
profile: default/linux/ppc64/23.0
compression_mode: pixz
portage_prefix: releng
binrepo_path: default

stage4/use:

stage4/packages:
#    --getbinpkg
	sys-kernel/gentoo-kernel-ps3
	sys-apps/ps3vram-swap
# ...

stage4/rcadd:
	ps3vram-swap|boot
        net.eth0|default
        ntpd|default
        ntp-client|default

stage4/empty:
	/var/cache/distfiles
#	/usr/src/linux

stage4/rm:
	/root/.bash_history

stage4/fsscript:
	/path/to/file/fsscript.sh

stage4/root_overlay:
	/root/stage4-overlay
