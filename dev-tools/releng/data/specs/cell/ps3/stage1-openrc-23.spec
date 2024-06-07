subarch: cell
target: stage1
rel_type: 23.0-default
version_stamp: openrc-@TIMESTAMP@
profile: default/linux/ppc64/23.0
portage_confdir: @REPO_DIR@/releases/portage/stages@PORTAGE_CONFDIR_POSTFIX@
portage_prefix: releng
source_subpath: 23.0-default/stage3-ppc64-openrc-latest
snapshot_treeish: @TREEISH@
compression_mode: pixz
update_seed: yes
update_seed_command: -uDN @world
@INTERPRETER@
