#!/bin/bash

if [ ! -n "${user}" ]; then
  local user_username="${user['username']}"
  local user_fullname="${user['fullname']}"
  local user_password="${user['password']}"
  local user_groups="${user['groups']}"
  local command="useradd -m -G ${user_groups} -c '${user_fullname}' -p '${user_password}' ${user_username}"
  chroot_call "${command}"
fi
