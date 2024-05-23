#!/bin/bash

# Create alias for ethernet card
cd /etc/init.d
ln -s net.lo net.eth0
