# Relese version details
version_stamp: openrc-@TIMESTAMP@
#source_subpath: default/stage3-ppc64-openrc-@SEEDTIMESTAMP@
source_subpath: 23.0-default/stage3-ppc64-openrc-latest
snapshot_treeish: @TREEISH@
#portage_confdir: @PORTAGE_CONFDIR@
portage_confdir: @REPO_DIR@/releases/portage/stages-qemu
#pkgcache_path: @PKGCACHE_PATH@
#@INTERPRETER@
interpreter: /usr/bin/qemu-ppc64

# Architecture and profile
subarch: cell
target: stage1
rel_type: 23.0-default
profile: default/linux/ppc64/23.0
compression_mode: pixz
update_seed: yes
update_seed_command: -uDN @world
portage_prefix: releng

