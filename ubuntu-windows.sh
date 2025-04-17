#!/usr/bin/env bash

echo "This script will cross-compile Zen Browser for Windows 32-bit on Ubuntu."

echo "Installing dependencies..."
# Copied from Zen
sudo apt install -y python3 python3-pip dos2unix yasm nasm build-essential libgtk2.0-dev libpython3-dev m4 uuid libasound2-dev libcurl4-openssl-dev libdbus-1-dev libdrm-dev libdbus-glib-1-dev libgtk-3-dev libpulse-dev libx11-xcb-dev libxt-dev xvfb lld llvm --fix-missing
sudo apt install -y lld

echo "Installing Rust and Rust applications..."
curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh
source $HOME/.cargo/env
rustup target add i686-pc-windows-msvc
curl -L --proto '=https' --tlsv1.2 -sSf https://raw.githubusercontent.com/cargo-bins/cargo-binstall/main/install-from-binstall-release.sh | bash
cargo binstall cargo-download --locked
cargo binstall cbindgen --locked
cargo binstall sccache --locked
cargo binstall cargo-download --locked
cargo download -x windows=0.58.0
export CARGO_INCREMENTAL=0

echo "Installing x86 build tools..."
sudo dpkg --add-architecture i386
sudo apt update 
sudo apt install -y wine64 wine32 libasound2-plugins:i386 libsdl2-2.0-0:i386 libdbus-1-3:i386 libsqlite3-0:i386
sudo apt install -y g++-mingw-w64-i686 gcc-mingw-w64-i686 clang llvm clang-tools
export PATH="/usr/lib/llvm-18/bin/:$PATH"
echo "Fixing libclang_rt.builtins-wasm32.a..."
wget https://github.com/jedisct1/libclang_rt.builtins-wasm32.a/raw/refs/heads/master/precompiled/llvm-18/libclang_rt.builtins-wasm32.a
sudo mv libclang_rt.builtins-wasm32.a /usr/lib/llvm-18/lib/clang/18/lib/wasi/

echo "Setting up Windows dependencies..."
mkdir -p ~/win-cross
cd engine/
sudo add-apt-repository ppa:savoury1/backports
sudo apt update
sudo apt install -y python3-pip autoconf autoconf2.13 automake bison build-essential cabextract curl cmake flex gawk gcc-multilib git gnupg jq libbz2-dev libexpat1-dev libffi-dev libncursesw5-dev libsqlite3-dev libssl-dev libtool libucl-dev libxml2-dev msitools ninja-build openssh-client p7zip-full pkg-config procps python3-requests python3-toml scons subversion tar unzip uuid uuid-dev wget zip zlib1g-dev aria2
echo "Seting up Mozilla Wine..."
aria2c "https://firefox-ci-tc.services.mozilla.com/api/index/v1/task/gecko.cache.level-1.toolchains.v3.linux64-wine.latest/artifacts/public%2Fbuild%2Fwine.tar.zst" -o wine.tar.zst
tar --zstd -xf wine.tar.zst -C ~/win-cross
rm wine.tar.zst
echo "Setting up MSVC..."
./mach python --virtualenv build taskcluster/scripts/misc/get_vs.py build/vs/vs2022.yaml ~/win-cross/vs2022

echo "Building Zen Browser..."
export SURFER_PLATFORM="win32"
export ZEN_CROSS_COMPILING=1
export ZEN_RELEASE=1
mkdir zen-browser/
git clone https://github.com/zen-browser/desktop/ zen-browser/desktop --recursive --depth 1
cd zen-browser/desktop/
git submodule update --init --recursive
npm install
npm run init
python3 ./scripts/update_en_US_packs.py
# Copying our config
cp -f ../../desktop/configs/windows/mozconfig ./configs/windows/mozconfig
npm run build
