#!/usr/bin/env bash
set -euo pipefail

export PYTHONUNBUFFERED=1

uname -r
cat /etc/os-release
python3 --version

apt-get update -qq && apt-get install -qq -y systemd-container

# # TODO: create zpool with virtual disks, create jailmaker dataset and test jlmkr.py from there
# # https://medium.com/@abaddonsd/zfs-usage-with-virtual-disks-62898064a29b
# apt-get install -y -qq zfsutils-linux
# modinfo zfs | grep version
# zfs --version
# zpool --version

# TODO: create a path and/or zfs pool with a space in it to test if jlmkr.py still works properly when ran from inside
# mkdir -p "/tmp/path with space/jailmaker"

chown 0:0 jlmkr.py
chmod +x jlmkr.py

# Setup NAT to give the jail access to the outside network
# https://wiki.archlinux.org/title/systemd-nspawn#Use_a_virtual_Ethernet_link
iptables -t nat -A POSTROUTING -o eth0 -j MASQUERADE
iptables -I DOCKER-USER -m conntrack --ctstate RELATED,ESTABLISHED -j ACCEPT
iptables -I DOCKER-USER -i ve-+ -o eth0 -j ACCEPT
iptables -A INPUT -i ve-+ -p udp -m udp --dport 67 -j ACCEPT

# TODO: test jlmkr.py from inside another working directory, with a relative path to a config file to test if it uses the config file (and doesn't look for it relative to the jlmkr.py file itself)
./jlmkr.py create --start --config=./templates/docker/config test --network-veth --system-call-filter='add_key' --system-call-filter='bpf' --system-call-filter='keyctl'
./jlmkr.py exec test docker run hello-world

# TODO: many more test cases and checking if actual output (text, files on disk etc.) is correct instead of just a 0 exit code