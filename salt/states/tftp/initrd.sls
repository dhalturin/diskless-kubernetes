set initramfs modules:
  file.managed:
    - name: /usr/share/initramfs-tools/modules.d/pxe
    - contents:
      - br_netfilter
      - overlay
      - squashfs

copying initrd pxe script:
  file.managed:
    - source: salt://tftp/files/pxe-init-script
    - name: /usr/share/initramfs-tools/scripts/pxe

updating initrd:
  cmd.run:
    - name: update-initramfs -c -k all

copying initrd to tftp:
  cmd.run:
    - name: |
        find /boot/ -name "initrd.img-*" -exec cp -v {} /srv/tftp \;
        find /boot/ -name "vmlinuz-*" -exec cp -v {} /srv/tftp \;
