{%- from "../lib/map.jinja" import mapdata as params with context %}
{%- set is_master = grains.id == 'kube01' %}

{%- if is_master %}
{%- set user = salt['config.get']('user') %}
{%- set home = salt['user.info'](user).home %}

kubeadm init config:
  file.managed:
    - source: salt://kube/files/kubeadm-init.yaml.jinja
    - name: /tmp/kubeadm-init.yaml
    - template: jinja
    - defaults: {{ params['kubeadm'] }}

kubeadm init:
  cmd.run:
    - name: kubeadm init --config /tmp/kubeadm-init.yaml
    - creates: /var/lib/kubelet/config.yaml

kubelet wait:
  cmd.run:
    - name: until nc -zw 3 127.0.0.1 6443; do sleep 1; done
    - timeout: 10
    - onchanges:
      - cmd: kubeadm init

copying config:
  file.copy:
    - name: {{ home ~ '/.kube/config' }}
    - source: /etc/kubernetes/admin.conf
    - force: true
    - makedirs: true
    - mode: 400

updating resolv:
  cmd.run:
    - name: >-
        kubectl -n kube-system get svc
        -l k8s-app=kube-dns -o json |
        jq -r '.items[0].spec | [.clusterIP, "8.8.8.8"] | map("nameserver " + .) | join("\n")'
        | tee /etc/resolv.conf

removing init config:
  file.absent:
    - name: /tmp/kubeadm-init.yaml
{%- else %}
kubelet wait:
  cmd.run:
    - name: until nc -zw 3 {{ params['kubeadm']['apiServer'] }} 6443; do sleep 1; done
    - timeout: 600
    - creates: /var/lib/kubelet/config.yaml

kubeadm join:
  cmd.run:
    - name: >-
        kubeadm join {{ params['kubeadm']['apiServer'] }}:6443
        --token {{ params['kubeadm']['token'] }}
        --discovery-token-ca-cert-hash sha256:$(
          set -o pipefail &&
          openssl x509 -pubkey -in /tmp/ca.crt |
          openssl rsa -pubin -outform der 2>/dev/null |
          openssl dgst -sha256 -hex |
          sed 's/^.* //'
        )
    - shell: /bin/bash
    - onchanges:
      - cmd: kubelet wait
    - require:
      - cmd: kubelet wait

removing ca.crt:
  file.absent:
    - name: /tmp/ca.crt
{%- endif %}
