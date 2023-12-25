# Rebuilds entire system from the begining

chroot_call "emerge @system @world --deep --emptytree --with-bdeps=y $quiet_flag"

# TODO: Run dispatch-conf and discard all changes from installed packages, keep already changed files intact.
