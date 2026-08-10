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

# Agents that skills get installed for. The "universal" ones (codex,
# github-copilot, opencode, cursor) read ~/.agents/skills directly; claude-code
# and pi need per-skill symlinks. `cursor` covers both the Cursor IDE and the
# Cursor CLI — `cursor-cli` is NOT a valid target, it exists only in the CLI's
# agent *detection* map and is folded into `cursor`.
SKILL_AGENTS=(claude-code codex github-copilot pi opencode cursor)

# Distinct third-party sources recorded in the skill lock, so adding a new
# source needs no edit here. Ramneet-Singh/dotfiles is deliberately excluded:
# this repo IS the store, so re-adding it as a source with --skill '*' would
# re-point every vendored skill's `source` back at dotfiles and cut them off
# from their real upstream.
skill_sources() {
    local lock="$PWD/.agents/.skill-lock.json"
    [ -f "$lock" ] || return 0
    python3 - "$lock" <<'PY' 2>/dev/null || true
import json, sys
with open(sys.argv[1]) as f:
    lock = json.load(f)
sources = {s.get("source") for s in lock["skills"].values() if s.get("source")}
print("\n".join(sorted(sources - {"Ramneet-Singh/dotfiles"})))
PY
}

update_skills() {
    # `npx skills` writes through the ~/.agents/skills symlink into the repo's
    # .agents/ tree, so the resulting diff is committed back to dotfiles.
    # Needs npx (provided by nvm-installed node).
    have npx || return 0
    echo "==> Updating AI agent skills…"

    # 1) Refresh the content of skills already in the lock.
    npx -y skills update -g -y || true

    # 2) `update` only touches what's already in the lock — it never picks up
    #    skills newly published to a source, and never creates the per-agent
    #    symlinks for them. Re-adding each source with --skill '*' does both.
    local agent_args=() a src
    for a in "${SKILL_AGENTS[@]}"; do
        agent_args+=(-a "$a")
    done
    for src in $(skill_sources); do
        echo "    → resyncing $src"
        npx -y skills add "$src" -g "${agent_args[@]}" --skill '*' -y || true
    done
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
    update_skills

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
