#!/usr/bin/env bash

set -e

echo "Setting up Windows dependencies..."
mkdir -p ~/win-cross
cd engine/
sudo add-apt-repository -y ppa:savoury1/backports
sudo apt update
sudo apt install -y python3-pip autoconf autoconf2.13 automake bison build-essential cabextract curl cmake flex gawk gcc-multilib git gnupg jq libbz2-dev libexpat1-dev libffi-dev libncursesw5-dev libsqlite3-dev libssl-dev libtool libucl-dev libxml2-dev msitools ninja-build openssh-client p7zip-full pkg-config procps python3-requests python3-toml scons subversion tar unzip uuid uuid-dev wget zip zlib1g-dev aria2
echo "Seting up Mozilla Wine..."
aria2c "https://firefox-ci-tc.services.mozilla.com/api/index/v1/task/gecko.cache.level-1.toolchains.v3.linux64-wine.latest/artifacts/public%2Fbuild%2Fwine.tar.zst" -o wine.tar.zst
tar --zstd -xf wine.tar.zst -C ~/win-cross
rm wine.tar.zst
# wtf, why do i have to workaround shit that ain't by myself.
if [ ! -x ~/win-cross/wine/bin/wine64 ]; then
    echo "Workaround wine64 binary..."
    ln -sf ~/win-cross/wine/bin/wine ~/win-cross/wine/bin/wine64
    chmod +x ~/win-cross/wine/bin/wine64
fi
echo "Setting up MSVC..."
./mach python --virtualenv build taskcluster/scripts/misc/get_vs.py build/vs/vs2026.yaml ~/win-cross/vs2026

echo "Validating installed MSVC redist/toolset paths..."
redist_root=~/win-cross/vs2026/VC/Redist/MSVC
tools_root=~/win-cross/vs2026/VC/Tools/MSVC

echo "Detected MSVC tool versions:"
ls -1 "$tools_root" || true

echo "Detected MSVC redist versions:"
ls -1 "$redist_root" || true

latest_redist_dir=$(ls -d "$redist_root"/*/x86/Microsoft.VC*.CRT 2>/dev/null | sort -V | tail -n1)
if [ -z "$latest_redist_dir" ] || [ ! -d "$latest_redist_dir" ]; then
    echo "ERROR: Could not find x86 MSVC CRT redist directory under $redist_root" 1>&2
    exit 1
fi

echo "Using Win32 redist directory: $latest_redist_dir"
cd ..
