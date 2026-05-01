#!/usr/bin/env bash
#
# Make /dev/kvm world-accessible on the GitHub-hosted runner so the QEMU
# mesh launcher can use KVM acceleration. udev reload + trigger applies the
# rule to the existing device node, not just to future hot-plugs.

set -euo pipefail

echo 'KERNEL=="kvm", GROUP="kvm", MODE="0666", OPTIONS+="static_node=kvm"' \
  | sudo tee /etc/udev/rules.d/99-kvm-allow-all.rules >/dev/null
sudo udevadm control --reload-rules
sudo udevadm trigger --name-match=kvm
ls -l /dev/kvm
test -r /dev/kvm && test -w /dev/kvm
