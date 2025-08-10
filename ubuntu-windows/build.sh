#!/usr/bin/env bash

set -e
source ./ubuntu-windows/env.sh
cd ./zen-browser/desktop
echo "Setting the brand to Twilight for packaging..."
npm run surfer -- ci --brand twilight || true
echo "Building Zen Browser..."
echo "If this fails then you may try 'npm run build -- --verbose' to see more output."
npm run build
echo "Packaging Zen Browser..."
# We set || true because "npm run package" will "fail" but we still have the archive anyway
npm run package || true
echo "Zen Browser packaged successfully."
