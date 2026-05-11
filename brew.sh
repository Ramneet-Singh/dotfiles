#!/usr/bin/env bash
#
# brew.sh — install Homebrew (if missing) and run `brew bundle` against Brewfile.
# Run on a fresh Mac BEFORE bootstrap.sh.

set -e

# 1) Install Homebrew if missing
if ! command -v brew >/dev/null 2>&1; then
    echo "Installing Homebrew…"
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
    # Pick up brew on the current shell
    if [ -x /opt/homebrew/bin/brew ]; then
        eval "$(/opt/homebrew/bin/brew shellenv)"
    elif [ -x /usr/local/bin/brew ]; then
        eval "$(/usr/local/bin/brew shellenv)"
    fi
fi

# 2) Update brew
brew update

# 3) Tap the font cask
brew tap homebrew/cask-fonts 2>/dev/null || true

# 4) Install everything in Brewfile (idempotent)
brew bundle --file="$(dirname "${BASH_SOURCE}")/Brewfile"

# 5) Cleanup older versions
brew cleanup
