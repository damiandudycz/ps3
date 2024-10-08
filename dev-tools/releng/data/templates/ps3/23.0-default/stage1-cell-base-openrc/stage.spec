#subarch: cell
target: stage1
version_stamp: base-openrc-@TIMESTAMP@
profile: default/linux/ppc64/23.0
portage_prefix: releng
source_subpath: ppc64/23.0-default/stage3-ppc64-openrc-@TIMESTAMP@
compression_mode: pixz
update_seed: yes
update_seed_command: --update --deep --newuse --usepkg --buildpkg @system @world
pkgcache_path: @PKGCACHE_PATH@/.stage1

#snapshot_treeish: @TREEISH@
