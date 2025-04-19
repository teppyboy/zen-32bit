#!/usr/bin/env bash

set -e
source ./ubuntu-windows/env.sh
echo "Building Zen Browser..."
echo "If this fails then you may try 'npm run build -- --verbose' to see more output."
cd ./zen-browser/desktop
npm run build
echo "Setting the brand to Twilight for packaging..."
# We only set the brand here because we don't want to include official Zen update tracking and etc.
npm run surfer -- ci --brand twilight
echo "Packaging Zen Browser..."
# We set +e because "npm run package" will "fail" but we still have the archive anyway
set +e
npm run package
