subarch: cell
target: stage1
rel_type: 23.0-default
version_stamp: base-openrc-@TIMESTAMP@
profile: default/linux/ppc64/23.0
portage_confdir: @PORTAGE_CONFDIR@/stage1-cell-base-openrc
portage_prefix: releng
source_subpath: 23.0-default/stage3-ppc64-openrc-latest
snapshot_treeish: @TREEISH@
compression_mode: pixz
update_seed: yes
update_seed_command: --update --deep --newuse --usepkg --buildpkg @system @world
pkgcache_path: @PKGCACHE_PATH@/.stage1
@INTERPRETER@
