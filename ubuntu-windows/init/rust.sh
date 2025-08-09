#!/usr/bin/env bash

echo "Installing Rust and Rust applications..."
curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y
source $HOME/.cargo/env
rustup target add i686-pc-windows-msvc
curl -L --proto '=https' --tlsv1.2 -sSf https://raw.githubusercontent.com/cargo-bins/cargo-binstall/main/install-from-binstall-release.sh | bash 
cargo binstall -y cargo-download --locked
cargo binstall -y cbindgen --locked
cargo binstall -y sccache --locked
cargo binstall -y cargo-download --locked
cargo download -x windows=0.58.0
export CARGO_INCREMENTAL=0
