# Relese version details
version_stamp: openrc-@TIMESTAMP@
source_subpath: 23.0-default/stage3-ppc64-openrc-@TIMESTAMP@
snapshot_treeish: @TREEISH@

# Architecture and profile
subarch: ppc64 # Arch for Stage1 should be generic, this is why it's not set to cell
target: stage1
rel_type: 23.0-default
profile: default/linux/ppc64/23.0
compression_mode: pixz
update_seed: yes
portage_confdir: /var/tmp/catalyst/releng/releases/portage/stages@CONFDIR_POSTFIX@
portage_prefix: releng
binrepo_path: base
@INTERPRETER@
