#!/usr/bin/env bash

set -e

echo "Patching mozconfigs..."
cd zen-browser/desktop
cp -f ../../desktop/configs/windows/mozconfig ./configs/windows/mozconfig

if command -v dos2unix >/dev/null 2>&1; then
    dos2unix ./configs/windows/mozconfig
fi

echo "Applied Windows mozconfig options:"
grep -n "ac_add_options" ./configs/windows/mozconfig || true
