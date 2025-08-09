#!/usr/bin/env bash

set -e
source ./ubuntu-windows/env.sh
echo "Setting the brand to Twilight for packaging..."
npm run surfer -- ci --brand twilight
echo "Building Zen Browser..."
echo "If this fails then you may try 'npm run build -- --verbose' to see more output."
cd ./zen-browser/desktop
npm run build
echo "Packaging Zen Browser..."
# We set || true because "npm run package" will "fail" but we still have the archive anyway
npm run package || true
echo "Zen Browser packaged successfully."
