# Release version details
version_stamp: openrc-@TIMESTAMP@
source_subpath: default/stage1-cell-openrc-@TIMESTAMP@
snapshot_treeish: @TREEISH@
portage_confdir: @PORTAGE_CONFDIR@
@INTERPRETER@

# Architecture and profile
subarch: cell
target: stage3
rel_type: default
profile: default/linux/ppc64/23.0
compression_mode: pixz
portage_prefix: releng
binrepo_path: base
