{%- from "../lib/map.jinja" import mapdata as params with context %}

{%- for item in [
  params['multistrap']['rootfs'] ~ '/etc/apt',
] %}
preparing the directory - {{ item }}:
  file.directory:
    - name: {{ item }}
    - makedirs: true
{%- endfor %}

multistrap config:
  file.managed:
    - source: salt://tftp/files/multistrap.conf.jinja
    - name: /etc/multistrap.conf
    - template: jinja
    - defaults: {{ params['multistrap'] }}

{%- for item in [ 'dev', 'proc' ] %}
mount {{ item }} to rootfs:
  mount.mounted:
    - name: {{ params['multistrap']['rootfs'] ~ '/' ~ item }}
    - device: /{{ item }}
    - fstype: {{ item }}
    - mkmnt: true
    - opts:
      - bind
{%- endfor %}

copy gpg files to rootfs:
  cmd.run:
    - name: cp -vr /etc/apt/trusted.gpg.d {{ params['multistrap']['rootfs'] }}/etc/apt

building rootfs:
  cmd.run:
    - name: multistrap -f /etc/multistrap.conf

{%- for item, dest in {
  '90_dpkg.cfg':       '/etc/cloud/cloud.cfg.d/90_dpkg.cfg',
  'meta-data':         '/opt/meta-data',
  'rootfs-prepare.sh': '/tmp/rootfs-prepare.sh',
  'user-data.jinja':   '/opt/user-data',
}.items() %}
copying files to rootfs - {{ item }}:
  file.managed:
    - source: salt://tftp/files/{{ item }}
    - name: {{ params['multistrap']['rootfs'] ~ dest }}
    - template: jinja
    - defaults: {{ params }}
{%- endfor %}

preparing rootfs:
  cmd.run:
    - name: /bin/bash /tmp/rootfs-prepare.sh
    - root: {{ params['multistrap']['rootfs'] }}

{%- for item in [ '/dev', '/proc' ] %}
umount {{ item }} to rootfs:
  mount.unmounted:
    - name: {{ params['multistrap']['rootfs'] ~ item }}
{%- endfor %}

building squashfs:
  cmd.run:
    - name: >-
        mksquashfs {{ params['multistrap']['rootfs'] }}
        /srv/tftp/images/{{ params['multistrap']['squashfs'] }}.squashfs
        -noappend -always-use-fragments

removing rootfs:
  file.absent:
    - name: {{ params['multistrap']['rootfs'] }}

reset the owner to tftp:
  file.directory:
    - name: /srv/tftp
    - user: dnsmasq
    - recurse:
      - user
