#!/usr/bin/env bash

echo "Installing x86 build tools..."
sudo dpkg --add-architecture i386
sudo apt update 
sudo apt install -y wine64 wine32 libasound2-plugins:i386 libsdl2-2.0-0:i386 libdbus-1-3:i386 libsqlite3-0:i386
sudo apt install -y g++-mingw-w64-i686 gcc-mingw-w64-i686 clang llvm clang-tools 
export PATH="/usr/lib/llvm-18/bin/:$PATH"
# This is dumb af but it works (for now)
echo "Fixing libclang_rt.builtins-wasm32.a..."
wget https://github.com/jedisct1/libclang_rt.builtins-wasm32.a/raw/refs/heads/master/precompiled/llvm-18/libclang_rt.builtins-wasm32.a
sudo mkdir -p /usr/lib/llvm-18/lib/clang/18/lib/wasi/
sudo mv libclang_rt.builtins-wasm32.a /usr/lib/llvm-18/lib/clang/18/lib/wasi/
