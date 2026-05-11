#!/usr/bin/env bash
#
# bootstrap.sh — provision dotfiles + tools brew can't install.
#
# Run AFTER `./brew.sh`. Idempotent — safe to re-run.
#
# Usage:
#   source bootstrap.sh         # interactive (asks before touching $HOME)
#   source bootstrap.sh -f      # skip confirmation prompt

set -e
cd "$(dirname "${BASH_SOURCE}")"

# Fast-forward if it's a real git repo
if [ -d .git ]; then
    git pull origin main || true
fi

# --- helpers ---
have() { command -v "$1" >/dev/null 2>&1; }
ask()  { read -p "$1 (y/n) " -n 1 -r; echo ""; [[ $REPLY =~ ^[Yy]$ ]]; }

install_oh_my_zsh() {
    if [ ! -d "$HOME/.oh-my-zsh" ]; then
        echo "Installing oh-my-zsh…"
        RUNZSH=no KEEP_ZSHRC=yes \
            sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended
    fi
    # Note: zsh-autosuggestions and zsh-syntax-highlighting are installed via
    # brew (see Brewfile) and sourced directly from /opt/homebrew/share/ in
    # .zshrc — NOT loaded as oh-my-zsh custom plugins.
}

install_vim_runtime() {
    if [ ! -d "$HOME/.vim_runtime" ]; then
        echo "Cloning vim_runtime fork…"
        git clone --depth 1 https://github.com/Ramneet-Singh/vimrc.git "$HOME/.vim_runtime"
    fi
}

install_nvm() {
    if [ ! -d "$HOME/.nvm" ]; then
        if ask "Install nvm (Node Version Manager)?"; then
            local nvm_tag
            nvm_tag=$(curl -fsSL https://api.github.com/repos/nvm-sh/nvm/releases/latest \
                | grep -m1 '"tag_name"' | cut -d '"' -f 4)
            nvm_tag="${nvm_tag:-master}"   # fall back to master if API call failed
            curl -o- "https://raw.githubusercontent.com/nvm-sh/nvm/${nvm_tag}/install.sh" | bash
            # Load nvm into the current shell so subsequent installers (npm) work
            export NVM_DIR="$HOME/.nvm"
            [ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"
            if ask "Install latest LTS Node now?"; then
                nvm install --lts
            fi
        fi
    fi
}

install_uv() {
    if ! have uv; then
        if ask "Install uv (Astral's Python package manager)?"; then
            curl -LsSf https://astral.sh/uv/install.sh | sh
        fi
    fi
}

install_copilot_cli() {
    if ! have copilot; then
        if have npm; then
            if ask "Install GitHub Copilot CLI globally via npm?"; then
                npm install -g @github/copilot
            fi
        else
            echo "(skipping Copilot CLI — npm not on PATH; install nvm + node first)"
        fi
    fi
}

install_claude_code() {
    if ! have claude; then
        if ask "Install Claude Code?"; then
            curl -fsSL https://claude.ai/install.sh | bash
        fi
    fi
}

install_miniconda_note() {
    if [ ! -d "/opt/homebrew/Caskroom/miniconda/base" ] && [ ! -d "/usr/local/Caskroom/miniconda/base" ]; then
        echo "(miniconda not installed — install via 'brew install --cask miniconda' if you want it)"
    fi
}

doIt() {
    # 1) Top-level dotfiles → $HOME (excludes repo metadata, scripts, configs handled separately)
    rsync \
        --exclude ".git/" \
        --exclude ".DS_Store" \
        --exclude ".macos" \
        --exclude "bootstrap.sh" \
        --exclude "brew.sh" \
        --exclude "update.sh" \
        --exclude "Brewfile*" \
        --exclude "README.md" \
        --exclude "LICENSE-MIT.txt" \
        --exclude "config/" \
        --exclude "bin/" \
        --exclude "*.example" \
        -avh --no-perms . ~

    # 2) XDG configs → ~/.config/
    if [ -d config ]; then
        mkdir -p ~/.config
        rsync -avh --no-perms config/ ~/.config/
    fi

    # 3) Personal scripts → ~/bin/
    if [ -d bin ]; then
        mkdir -p ~/bin
        rsync -avh --no-perms bin/ ~/bin/
    fi

    # 4) Seed local-only files from templates if missing
    [ -f ~/.extra ] || { cp .extra.example ~/.extra; echo "Created ~/.extra — edit it to add your git identity & secrets."; }
    [ -f ~/.path  ] || cp .path.example  ~/.path

    # 5) Tools brew can't install
    install_oh_my_zsh
    install_vim_runtime
    install_nvm           # node version manager (loads nvm into current shell)
    install_uv            # Astral's Python package manager
    install_copilot_cli   # GitHub Copilot CLI (needs npm; nvm-installed node provides it)
    install_claude_code   # Claude Code
    install_miniconda_note

    # 6) Reload login shell (skipped when sourced from update.sh,
    #    which sets DOTFILES_NO_RELOAD=1 to keep its own process alive)
    if [ -z "$DOTFILES_NO_RELOAD" ]; then
        exec zsh -l
    fi
}

if [ "$1" == "--force" ] || [ "$1" == "-f" ]; then
    doIt
else
    read -p "This may overwrite existing files in your home directory. Are you sure? (y/n) " -n 1
    echo ""
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        doIt
    fi
fi
unset doIt
