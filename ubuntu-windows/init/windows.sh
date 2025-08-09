#!/usr/bin/env bash

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
echo "Setting up MSVC..."
./mach python --virtualenv build taskcluster/scripts/misc/get_vs.py build/vs/vs2022.yaml ~/win-cross/vs2022
cd ..
