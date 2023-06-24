{%- from "../lib/map.jinja" import mapdata as params with context %}
{%- set is_master = grains.id == 'kube01' %}

{%- for item in [ '/etc/containerd' ] %}
preparing the directory - {{ item }}:
  file.directory:
    - name: {{ item }}
    - makedirs: true
{%- endfor %}

{%- for item in ([ 'ca.crt', 'ca.key' ] if is_master else [ 'ca.crt' ]) %}
kubeadm {{ item }}:
  file.managed:
    - name: /{{ 'etc/kubernetes/pki' if is_master else 'tmp' }}/{{ item }}
    - contents: |
        -----{{ 'BEGIN CERTIFICATE' if item == 'ca.crt' else 'BEGIN RSA PRIVATE KEY' }}-----
        {%- for i in params['kubeadm'][item] | batch(64) %}
        {{ i | join }}{% endfor %}
        -----{{ 'END CERTIFICATE' if item == 'ca.crt' else 'END RSA PRIVATE KEY' }}-----
    - makedirs: true
{%- endfor %}

{%- for item in [
  'net.bridge.bridge-nf-call-ip6tables',
  'net.bridge.bridge-nf-call-iptables',
  'net.ipv4.ip_forward',
] %}
enabling sysctl parameter - {{ item }}:
    sysctl.present:
    - name: {{ item }}
    - value: 1
{%- endfor %}

enabling modules:
  kmod.present:
    - mods:
      - overlay
      - br_netfilter

mount tmpfs to containerd:
  mount.mounted:
    - name: /var/lib/containerd
    - device: tmpfs
    - fstype: tmpfs
    - mkmnt: true

setup misc packages:
  pkg.installed:
    - install_recommends: false
    - pkgs:
        - apparmor
        - apt-transport-https
        - ca-certificates
        - containerd
        - curl
        - gnupg2
        - ifupdown
        - jq
        - netcat

{%- if is_master %}
  {%- set default_interface = salt['network.default_route']('inet')[0].interface %}

define ip address:
  network.managed:
    - name: {{ default_interface }}:1
    - enabled: True
    - proto: static
    - type: eth
    - ipaddr: {{ params['kubeadm']['apiServer'] }}
{%- endif %}

{%- for item in params['apt_repos'] %}
  {%- set to_add = true if 'only_master' not in item else (true if is_master else false) %}
  {%- if to_add %}
adding apt repo - {{ item.name }}:
  pkgrepo.managed:
    - name: deb [signed-by=/etc/apt/trusted.gpg] {{ item.repo }}
    - file: /etc/apt/sources.list.d/{{ item.name }}.list
    - humanname: {{ item.name }}
    - key_url: {{ item.key }}
    - refresh: true
  {%- endif %}
{%- endfor %}

setup kube packages:
  pkg.installed:
    - hold: true
    - install_recommends: false
    - pkgs:
        - kubeadm
        - kubectl
        - kubelet

copy gpg files to rootfs:
  cmd.run:
    - name: >-
        containerd config default |
        sed 's|SystemdCgroup = .*|SystemdCgroup = true|g'
        > /etc/containerd/config.toml

restart containerd:
  service.running:
    - name: containerd
    - enable: true
    - restart: true
    - watch:
        - cmd: copy gpg files to rootfs

disabling apparmor:
  service.dead:
    - name: apparmor
    - enable: false
