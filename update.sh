#!/usr/bin/env bash
#
# update.sh — upgrade everything bootstrap.sh / brew.sh installed.
#
# Pulls latest dotfiles, updates Homebrew packages, upgrades non-brew tools
# (oh-my-zsh, vim_runtime, nvm, uv, GitHub Copilot CLI, Claude Code), then
# resyncs dotfiles into $HOME via bootstrap.sh.
#
# Idempotent. Tools that aren't installed are skipped — this only UPDATES
# existing installs. Use bootstrap.sh to install something new.
#
# Usage:
#   ./update.sh         # interactive (asks before starting)
#   ./update.sh -f      # skip confirmation prompt

set -e
cd "$(dirname "${BASH_SOURCE}")"

# --- helpers ---
have() { command -v "$1" >/dev/null 2>&1; }

# Load nvm (if installed) so npm/node are on PATH for npm-based updates
if [ -d "$HOME/.nvm" ]; then
    export NVM_DIR="$HOME/.nvm"
    [ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"
fi

update_oh_my_zsh() {
    if [ -d "$HOME/.oh-my-zsh" ]; then
        echo "==> Updating oh-my-zsh…"
        # upgrade.sh has a zsh shebang and uses `local` at top level — must be
        # run with zsh, not sh/bash, or it errors before its self-rexec kicks in.
        ZSH="$HOME/.oh-my-zsh" zsh "$HOME/.oh-my-zsh/tools/upgrade.sh" || true
    fi
}

update_vim_runtime() {
    if [ -d "$HOME/.vim_runtime/.git" ]; then
        echo "==> Updating vim_runtime…"
        git -C "$HOME/.vim_runtime" pull --ff-only || true
    fi
}

update_nvm() {
    # nvm is a git checkout in ~/.nvm; per nvm's manual-upgrade docs,
    # fetch tags and check out the latest release tag.
    if [ -d "$HOME/.nvm/.git" ]; then
        echo "==> Updating nvm…"
        git -C "$HOME/.nvm" fetch --tags --quiet origin || true
        local latest
        latest=$(git -C "$HOME/.nvm" describe --abbrev=0 --tags \
            --match "v[0-9]*" \
            "$(git -C "$HOME/.nvm" rev-list --tags --max-count=1)" 2>/dev/null || echo "")
        if [ -n "$latest" ]; then
            git -C "$HOME/.nvm" checkout --quiet "$latest"
            echo "    nvm now at $latest"
        fi
    fi
}

update_uv() {
    if have uv; then
        echo "==> Updating uv…"
        uv self update || true
    fi
}

update_copilot_cli() {
    if have copilot && have npm; then
        echo "==> Updating GitHub Copilot CLI…"
        npm install -g @github/copilot@latest || true
    fi
}

update_claude_code() {
    if have claude; then
        echo "==> Updating Claude Code…"
        # Re-run the official installer; it's idempotent and pulls the latest
        curl -fsSL https://claude.ai/install.sh | bash || true
    fi
}

do_update() {
    # 1) Pull latest dotfiles (so we get any new Brewfile entries / configs)
    if [ -d .git ]; then
        echo "==> Pulling latest dotfiles…"
        git pull origin main || true
    fi

    # 2) Brew formulae + casks
    echo "==> Updating Homebrew packages…"
    ./brew.sh

    # 3) Non-brew tools
    update_oh_my_zsh
    update_vim_runtime
    update_nvm
    update_uv
    update_copilot_cli
    update_claude_code

    # 4) Resync dotfiles into $HOME (bootstrap.sh handles rsync + ensures any
    #    newly-added install_* tools get installed). DOTFILES_NO_RELOAD=1 stops
    #    bootstrap from exec'ing zsh and replacing this process mid-script.
    echo "==> Resyncing dotfiles into \$HOME via bootstrap.sh…"
    DOTFILES_NO_RELOAD=1 source ./bootstrap.sh -f

    echo ""
    echo "✓ All updates complete."
    echo "  Open a new terminal (or run 'exec zsh -l') to load any shell config changes."
}

if [ "$1" == "--force" ] || [ "$1" == "-f" ]; then
    do_update
else
    read -p "Update all dotfiles tools and resync \$HOME? (y/n) " -n 1 -r
    echo ""
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        do_update
    fi
fi
