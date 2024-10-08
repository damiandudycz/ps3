# This stage is building seed for LLVM/CLANG/MUSL releases by adding required applications - clang, musl, llvm to normal stage3 release.

target: stage4
version_stamp: seed-llvm-openrc-@TIMESTAMP@
source_subpath: @BASE_ARCH@/stage3-@BASE_ARCH@-musl-hardened-openrc-@TIMESTAMP@
snapshot_treeish: @TREEISH@
profile: default/linux/@BASE_ARCH@/23.0/musl
compression_mode: pixz
pkgcache_path: @PKGCACHE_PATH@/cell

#subarch: cell
#portage_prefix: releng
#repos: @REPOS@

stage4/packages:
	llvm
	clang
