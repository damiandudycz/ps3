subarch: cell
target: stage1
rel_type: @REL_TYPE@
version_stamp: base-openrc-@TIMESTAMP@
profile: default/linux/ppc64/23.0
portage_confdir: @STAGEFILES_DIR@/@STAGE_NAME@/portage
portage_prefix: releng
source_subpath: @REL_TYPE@/stage3-ppc64-openrc-latest
snapshot_treeish: @TREEISH@
compression_mode: pixz
update_seed: yes
update_seed_command: --update --deep --newuse --usepkg --buildpkg @system @world
pkgcache_path: @PKGCACHE_PATH@/.stage1
@INTERPRETER@
