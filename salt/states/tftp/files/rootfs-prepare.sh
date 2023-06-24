#!/bin/bash

set -x

python3 -m pip install contextvars
dpkg --configure -a
rm /etc/resolv.conf
echo nameserver 8.8.8.8 > /etc/resolv.conf
touch /etc/fstab

# workaround - start TODO: will be deleted
git clone https://github.com/canonical/cloud-init /tmp/cloud-init
rm -rf /usr/lib/python3/dist-packages/cloudinit
mv /tmp/cloud-init/cloudinit /usr/lib/python3/dist-packages/
rm -rf /tmp/cloud-init
mkdir -p /root/.ssh
echo ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABgQDFPj1hMaKq5Rrrk2TuREfqoAfhKjubpwqocTBGWz1SHgjKD6ma05X+fdwMLZThiUULmUQinuRV60TH1itlhv5LjKc6uRJNbMrdBLWL5rV2IJEUL1bcFMoP9CGxA8r8iOCCSDLOwNte03U8t5NPCwpbM45ih7g1dps06FOHZ7W629kcUsuLqmQ7Vdh5pnq8ztfAhQ3bIxlHSrHI8D5Iz2xKxt5bR+vQ1P0FK27k/S8gaMAaIFXFCGNLZkyeiP/mWQUGmKf84QmqFngwVlYGVwfCf6YxxaLoLHbm2gqrjRrQZ+Tiog15LcYkmEbwQ8VHmyRebjD/0Zi17T0QW5EIjXrt29SUSBLYfTAC9M/iTIrELApi3pVtIHZv7aVOiKJwJANGHBvf/7D3hhnPQpz6EvQDqe6CDtaosayVJayZi8Mnu0jxr/Kusj9+A5v+0+OcdmSUdd/P8X1nqJL/Y0e6hc5JCUqO/ldWlbn06/yZJsTvG2txWbKxymnukCuRdbx5SCE= > /root/.ssh/authorized_keys
chmod 400 /root/.ssh/authorized_keys
# workaround - end

rm -v $0
