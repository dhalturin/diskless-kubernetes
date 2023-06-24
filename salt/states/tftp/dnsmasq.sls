{%- from "../lib/map.jinja" import mapdata as params with context %}
{%- do salt["log.warning"]("parameters: " ~ params) %}

{%- for item in [
  '/srv/tftp/pxelinux.cfg',
  '/srv/tftp/images',
] %}
preparing the directory - {{ item }}:
  file.directory:
    - name: {{ item }}
    - makedirs: true
{%- endfor %}

disabling systemd-resolved:
  service.dead:
    - name: systemd-resolved
    - enable: false

setup packages:
  pkg.installed:
    - install_recommends: false
    - pkgs: {{ params['pkgs'] + ['linux-image-' ~ params['multistrap']['kernel_version']] }}

dnsmasq config:
  file.managed:
    - source: salt://tftp/files/dnsmasq.conf.jinja
    - name: /etc/dnsmasq.conf
    - template: jinja
    - defaults: {{ params['dnsmasq'] }}

preparing pxe:
  cmd.run:
    - name: |
        cp -v /usr/lib/PXELINUX/pxelinux.0 /srv/tftp

        find /usr/lib/syslinux/modules/bios -type f \( \
          -name menu.c32 -o \
          -name vesamenu.c32 -o \
          -name libutil.c32 -o \
          -name libcom32.c32 -o \
          -name ldlinux.c32 \) \
          -exec cp -v {} /srv/tftp \;

restart dnsmasq:
  service.running:
    - name: dnsmasq
    - enable: true
    - reload: true

copying pxe config:
  file.managed:
    - source: salt://tftp/files/pxe-config.jinja
    - name: /srv/tftp/pxelinux.cfg/default
    - template: jinja
    - defaults:
        image: {{ params['multistrap']['squashfs'] }}.squashfs
        ip: {{ salt['network.ip_addrs']() | first }}
        kernel_version: {{ params['multistrap']['kernel_version'] }}

replacing the root of the nginx:
  file.symlink:
    - name: /var/www/html
    - target: /srv/tftp
    - force: true
