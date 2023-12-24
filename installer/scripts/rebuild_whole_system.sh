# Rebuilds entire system from the begining
# Before starting cleans all binpkgs packages
# Used by Builder tool, to prepare all packages as binpkgs.

chroot_call "rm -rf /var/cache/binpkgs"
chroot_call "emerge @system @world --deep --emptytree --with-bdeps=y $quiet_flag"
