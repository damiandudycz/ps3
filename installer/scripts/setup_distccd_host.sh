#!/bin/bash

# Configures host distcc environment.
# To be used on PS3 Helper Host. Not for PS3 itself.

for allow in "${distccd_host_allow[@]}"; do
    echo 'DISTCCD_OPTS="${DISTCCD_OPTS} --allow '${allow}'"' >> "$path_chroot/etc/conf.d/distccd"
done
