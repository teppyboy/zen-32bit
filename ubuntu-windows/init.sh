#!/usr/bin/env bash

set -e
echo "This script will cross-compile Zen Browser for Windows 32-bit on Ubuntu."

cwd=$(realpath .)
source ./ubuntu-windows/env.sh

bash $cwd/ubuntu-windows/init/system.sh

echo "Cloning Zen Browser repository..."
if [ -d "zen-browser" ]; then
    echo "Zen Browser repository already exists, updating..."
    cd zen-browser/desktop/
    git reset --hard
    git pull
else
    mkdir zen-browser/
    git clone https://github.com/zen-browser/desktop/ zen-browser/desktop --recursive --depth 1
    cd zen-browser/desktop/
fi

bash $cwd/ubuntu-windows/init/nodejs.sh

echo "Initializing repository..."
npm install
npm run init
mkdir -p engine/

bash $cwd/ubuntu-windows/init/rust.sh
bash $cwd/ubuntu-windows/init/x86.sh
bash $cwd/ubuntu-windows/init/windows.sh

echo "Installing language packs..."
sh scripts/download-language-packs.sh

# Copying our config
echo "" >> ./configs/common/mozconfig
echo "export MOZ_WINDOWS_RS_DIR=$(pwd)/windows-0.58.0" >> ./configs/common/mozconfig
export PATH="/usr/lib/llvm-18/bin/:$PATH"
echo "Creating a commit to bypass the commit check..."
cd ./engine/
git config --global user.email "hello@example.com"
git config --global user.name "nobody"
git add -A
git commit -a -m "fuck Firefox"
cd ..

echo "Initialization complete! You may now build the browser."