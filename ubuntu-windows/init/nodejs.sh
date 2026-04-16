#!/usr/bin/env bash

echo "Installing NodeJS..."
curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.40.2/install.sh | bash
\. "$HOME/.config/nvm/nvm.sh"
nvm install 23
node -v
nvm current
npm -v
