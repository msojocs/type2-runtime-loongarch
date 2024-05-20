#!/bin/sh

set -ex

if ! command -v apk; then
	echo "This script should be run in an Alpine container"
	exit 1
fi
uname -m
apk update
apk add alpine-sdk util-linux strace file autoconf automake libtool xz

# Build static libfuse3 with patch for https://github.com/AppImage/type2-runtime/issues/10
apk add eudev-dev gettext-dev linux-headers meson # From https://git.alpinelinux.org/aports/tree/main/fuse3/APKBUILD
wget -c -q "https://github.com/libfuse/libfuse/releases/download/fuse-3.15.0/fuse-3.15.0.tar.xz"
echo "70589cfd5e1cff7ccd6ac91c86c01be340b227285c5e200baa284e401eea2ca0  fuse-3.15.0.tar.xz" | sha256sum -c
tar xf fuse-3.*.tar.xz
cd fuse-3.*/
patch -p1 < ../patches/libfuse/mount.c.diff
mkdir build
cd build
meson setup --prefix=/usr ..
meson configure --default-library static
ninja install
cd ../../

# Minimize binary size
export CFLAGS="-ffunction-sections -fdata-sections -Os"

# Build static squashfuse
apk add zstd-dev zlib-dev zlib-static # fuse3-dev fuse3-static fuse-static fuse-dev
if [ "$ARCHITECTURE" == "loong64" ];then
	# only loong64 can install this package, other arch can not install it.
	apk add --no-cache zstd-static
fi
find / -name "libzstd.*" 2>/dev/null || true
wget -c -q "https://github.com/vasi/squashfuse/archive/e51978c.tar.gz"
echo "f544029ad30d8fbde4e4540c574b8cdc6d38b94df025a98d8551a9441f07d341  e51978c.tar.gz" | sha256sum -c
tar xf e51978c.tar.gz
cd squashfuse-*/
./autogen.sh
./configure --help
./configure CFLAGS="${CFLAGS} -no-pie" LDFLAGS=-static
make -j"$(nproc)"
make install
/usr/bin/install -c -m 644 ./*.h '/usr/local/include/squashfuse' # ll.h
cd -

# Build static AppImage runtime
GIT_COMMIT="$(cat src/runtime/version)"
export GIT_COMMIT
cd src/runtime
make runtime-fuse3 -j"$(nproc)"
file runtime-fuse3
strip runtime-fuse3
ls -lh runtime-fuse3
echo -ne 'AI\x02' | dd of=runtime-fuse3 bs=1 count=3 seek=8 conv=notrunc # magic bytes, always do AFTER strip
cd -

mkdir -p out
cp src/runtime/runtime-fuse3 "out/runtime-fuse3-${ARCHITECTURE}"
