#!/bin/sh

set -ex

cleanup () {
    echo "clean"
}
trap cleanup EXIT

mkdir -p tmp
cd tmp
# from https://packages.ubuntu.com/noble/amd64/qemu-user-static/download
wget -c http://kr.archive.ubuntu.com/ubuntu/pool/universe/q/qemu/qemu-user-static_8.2.2+ds-0ubuntu1_amd64.deb
sudo dpkg -i qemu-user-static_8.2.2+ds-0ubuntu1_amd64.deb
