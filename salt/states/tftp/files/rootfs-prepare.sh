#!/bin/bash

set -x

python3 -m pip install contextvars
dpkg --configure -a
rm /etc/resolv.conf
echo nameserver 8.8.8.8 > /etc/resolv.conf
touch /etc/fstab

rm -v $0
