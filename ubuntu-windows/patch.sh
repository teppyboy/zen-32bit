#!/usr/bin/env bash

set -e

echo "Patching mozconfigs..."
cd zen-browser/desktop
cp -f ../../desktop/configs/windows/mozconfig ./configs/windows/mozconfig

encoding_rs_file=./engine/third_party/rust/encoding_rs/src/x_user_defined.rs
if [ -f "$encoding_rs_file" ] && ! grep -q "use core::simd::Select;" "$encoding_rs_file"; then
    echo "Patching encoding_rs portable SIMD Select import..."
    perl -0pi -e 's/use core::simd::cmp::SimdPartialOrd;\n/use core::simd::cmp::SimdPartialOrd;\n        use core::simd::Select;\n/' "$encoding_rs_file"
fi

encoding_rs_checksum=./engine/third_party/rust/encoding_rs/.cargo-checksum.json
if [ -f "$encoding_rs_file" ] && [ -f "$encoding_rs_checksum" ]; then
    echo "Updating encoding_rs vendored checksum..."
    new_checksum=$(sha256sum "$encoding_rs_file" | cut -d ' ' -f 1)
    perl -0pi -e 's!("src/x_user_defined\.rs":"?)[0-9a-f]{64}!$1'"$new_checksum"'!' "$encoding_rs_checksum"
fi

if command -v dos2unix >/dev/null 2>&1; then
    dos2unix ./configs/windows/mozconfig
fi

echo "Applied Windows mozconfig options:"
grep -n "ac_add_options" ./configs/windows/mozconfig || true
