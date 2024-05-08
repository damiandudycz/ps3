# Release version details
version_stamp: openrc-@TIMESTAMP@
source_subpath: 23.0-default/stage1-cell-openrc-@TIMESTAMP@
snapshot_treeish: @TREEISH@

# Architecture and profile
subarch: cell
target: stage3
rel_type: 23.0-default
profile: default/linux/ppc64/23.0
compression_mode: pixz
portage_confdir: /var/tmp/catalyst/releng/releases/portage/stages@CONFDIR_POSTFIX@
portage_prefix: releng
binrepo_path: base
@INTERPRETER@
