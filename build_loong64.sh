#!/bin/bash

set -ex

repo_root="$(readlink -f "$(dirname "${BASH_SOURCE[0]}")"/.)"
# image="lcr.loongnix.cn/library/alpine:3.19"
image="quay.io/msojocs/alpine-loong64:3.19"
platform="linux/loong64"
uid="$(id -u)"
docker run \
    --platform "$platform" \
    --rm \
    -i \
    -e ARCH \
    -e GITHUB_ACTIONS \
    -e GITHUB_RUN_NUMBER \
    -e ARCHITECTURE="loong64" \
    -e OUT_UID="$uid" \
    -v "$repo_root":/source \
    -v "$PWD":/out \
    -w /out \
    "$image" \
    sh /source/build.sh
