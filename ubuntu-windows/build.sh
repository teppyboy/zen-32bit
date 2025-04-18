#!/usr/bin/env bash

source ../ubuntu-windows/env.sh
echo "Building Zen Browser..."
echo "If this fails then you may try 'npm run build -- --verbose' to see more output."
cd ./zen-browser/desktop
npm run build
echo "Packaging Zen Browser..."
npm run package
