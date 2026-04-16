#!/usr/bin/env bash

echo "Installing system dependencies..."
sudo apt update
# Necessary packages (by myself)
sudo apt install -y git software-properties-common zstd 
# From Zen (.github/workflows/src/release-build.sh)
sudo apt install -y python3 python3-launchpadlib python3-pip dos2unix yasm nasm upx-ucl build-essential libgtk2.0-dev libpython3-dev m4 uuid libasound2-dev libcurl4-openssl-dev libdbus-1-dev libdrm-dev libdbus-glib-1-dev libgtk-3-dev libpulse-dev libx11-xcb-dev libxt-dev xvfb lld llvm --fix-missing
sudo add-apt-repository -y ppa:kisak/kisak-mesa
sudo apt update
sudo apt install -y xvfb libnvidia-egl-wayland1 mesa-utils libgl1-mesa-dri
# From myself
sudo apt install -y lld libc++-dev-wasm32 libclang-rt-dev-wasm32 libclang-rt-dev-wasm64
# Fix cargo download
wget http://nz2.archive.ubuntu.com/ubuntu/pool/main/o/openssl/libssl1.1_1.1.1f-1ubuntu2_amd64.deb
sudo dpkg -i libssl1.1_1.1.1f-1ubuntu2_amd64.deb
rm libssl1.1_1.1.1f-1ubuntu2_amd64.deb
