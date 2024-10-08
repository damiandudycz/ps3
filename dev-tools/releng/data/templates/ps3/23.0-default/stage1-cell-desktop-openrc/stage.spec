subarch: cell
target: stage1
version_stamp: desktop-openrc-@TIMESTAMP@
profile: default/linux/ppc64/23.0/desktop
#portage_prefix: releng
source_subpath: @PLATFORM@/@REL_TYPE@/stage3-ppc64-openrc-@TIMESTAMP@
snapshot_treeish: @TREEISH@
compression_mode: pixz
update_seed: yes
update_seed_command: --update --deep --newuse --usepkg --buildpkg @system @world
pkgcache_path: @PKGCACHE_PATH@/.stage1
