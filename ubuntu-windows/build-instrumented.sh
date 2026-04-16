#!/usr/bin/env bash

# Stage 1 PGO build: compiles Zen with LLVM instrumentation.
# The resulting binary writes .profraw files when run, which are then collected
# on a Windows runner by profileserver.py and merged into merged.profdata.

set -e

source ./ubuntu-windows/env.sh
export ZEN_GA_GENERATE_PROFILE=1

cd ./zen-browser/desktop
echo "Building instrumented binary for PGO profile collection..."
echo "LTO is disabled for this stage to reduce build time."

npm run surfer -- ci --brand twilight || true
npm run build

echo "Packaging instrumented binary..."
# ZEN_GA_DISABLE_PGO prevents the package step from re-applying PGO flags
ZEN_GA_DISABLE_PGO=1 npm run package || true

echo "Instrumented build complete."
echo "Package contents:"
ls -lh dist/ || true
