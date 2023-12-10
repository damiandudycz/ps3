#!/bin/bash

# Configures host distcc environment.

for allow in "${distccd_host_allow[@]}"; do
    echo 'DISTCCD_OPTS="${DISTCCD_OPTS} --allow '${allow}'"' >> "$path_chroot/etc/conf.d/distccd"
done
