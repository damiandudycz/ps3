#!/bin/bash

# For given list of scripts, downloads every one from repository, and add's it to
# /etc/init.d/. Use this to add some special custom scripts needed for given platform,
# which are not available in portage.

for script in "${guest_init_scripts[@]}"; do
    # Download and install init script
    local url_script="$url_repo/init.d/$script"
    local path_script="$path_chroot/etc/init.d/$script"
    try wget "$url_script" -O "$path_script" --no-http-keep-alive --no-cache --no-cookies $quiet_flag
    try chmod +x "$path_script"
done
