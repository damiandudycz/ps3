# Relese version details
version_stamp: openrc-@TIMESTAMP@
source_subpath: default/stage3-ppc64-openrc-@TIMESTAMP@
snapshot_treeish: @TREEISH@
portage_confdir: @PORTAGE_CONFDIR@
@INTERPRETER@

# Architecture and profile
subarch: cell
target: stage1
rel_type: default
profile: default/linux/ppc64/23.0
compression_mode: pixz
update_seed: yes
portage_prefix: releng
