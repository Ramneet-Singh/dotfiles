# Ramneet's dotfiles

Personal macOS dotfiles, modeled on
[mathiasbynens/dotfiles](https://github.com/mathiasbynens/dotfiles).
Top-level filenames mirror `$HOME` paths; `bootstrap.sh` rsyncs them in,
`brew.sh` installs the package set, and `~/.extra` (gitignored) holds local
secrets like the git identity.

## Setup on a fresh Mac

```bash
# 1) Xcode CLI tools (one-time, brew needs this)
xcode-select --install

# 2) Clone this repo (and Mathias-style ~/dotfiles symlink for convenience)
git clone https://github.com/Ramneet-Singh/dotfiles.git ~/maverick-home/projects/dotfiles
ln -s ~/maverick-home/projects/dotfiles ~/dotfiles
cd ~/dotfiles

# 3) Install Homebrew + every formula/cask in Brewfile (powerlevel10k, fzf, miniconda, …)
./brew.sh

# 4) Copy dotfiles into $HOME, install oh-my-zsh + plugins, clone vim_runtime fork,
#    optionally install nvm. Re-execs zsh at the end.
source bootstrap.sh

# 5) Fill in your real git identity & secrets
$EDITOR ~/.extra
```

To update later, just `cd ~/dotfiles && source bootstrap.sh`. Add `-f` to skip
the confirmation prompt.

## Layout

```
dotfiles/
├── README.md
├── LICENSE-MIT.txt
├── bootstrap.sh           # rsync repo → $HOME, install oh-my-zsh + vim_runtime + nvm
├── brew.sh                # install Homebrew + run `brew bundle`
├── Brewfile               # declarative formulae & casks list
│
│  ── shell (zsh primary, bash kept as fallback) ──
├── .zshenv                # PATH dedup + EDITOR (loaded by EVERY zsh invocation)
├── .zprofile              # `brew shellenv` (login zsh shells)
├── .zshrc                 # interactive zsh: sources split files + plugins
├── .aliases               # personal aliases (brewr, leg, cppcompile)
├── .exports               # env vars (currently empty placeholder)
├── .functions             # shell functions (currently empty placeholder)
├── .extra.example         # template; real ~/.extra is gitignored
├── .path.example          # template; real ~/.path is gitignored
├── .bashrc, .bash_profile, .profile  # bash fallback
│
│  ── editors / git / misc ──
├── .vimrc                 # 14-line wrapper sourcing ~/.vim_runtime/
├── .p10k.zsh              # Powerlevel10k prompt config
├── .fzf.zsh               # fzf integration script
├── .gitconfig             # WITHOUT [user] (identity goes in ~/.extra)
├── .gitignore_global      # core.excludesfile target
├── .gitignore             # ignored INSIDE the repo (DS_Store, *.pyc, .extra, .path)
├── .gitattributes
└── config/                # rsynced into ~/.config/
    └── gh/                # GitHub CLI config (no auth tokens — those live in macOS keychain)
```

## What's NOT in here (and where it lives)

- **Secrets**: git identity, API tokens, work-only aliases — `~/.extra`
  (sourced last by `.zshrc`/`.bash_profile` so it can override anything).
- **`~/.ssh/`**: never tracked. Set up keys per-machine.
- **vim plugins**: separate fork at
  [Ramneet-Singh/vimrc](https://github.com/Ramneet-Singh/vimrc) — bootstrap
  clones it into `~/.vim_runtime/`. `.vimrc` here just sources from there.
- **oh-my-zsh + plugins**: installed by `bootstrap.sh` (its own installer +
  git-cloned `zsh-autosuggestions` & `zsh-syntax-highlighting` into
  `~/.oh-my-zsh/custom/plugins/`).
- **nvm + node versions**: bootstrap.sh prompts to install nvm (v0.40.4) then
  optionally `nvm install --lts`. Per-project switching via `nvm use`.
- **uv** (Astral's Python package manager): bootstrap.sh prompts to install
  via the official `astral.sh/uv/install.sh` script (puts `uv` + `uvx` in
  `~/.local/bin/`).
- **GitHub Copilot CLI**: `npm install -g @github/copilot` (needs nvm-installed
  node first; bootstrap handles ordering).
- **Claude Code**: `claude.ai/install.sh` (puts `claude` in
  `~/.local/share/claude/` with a symlink in `~/.local/bin/`).
- **miniconda & conda envs**: cask in Brewfile installs miniconda; envs are
  per-project (`conda create -n NAME …`).

## How the shell startup is split (Mathias's pattern, adapted for zsh)

| File | When it runs | What goes here |
|------|--------------|----------------|
| `.zshenv` | EVERY zsh invocation (incl. scripts) | Tiny — only `PATH` dedup + `EDITOR` |
| `.zprofile` | login zsh only | `brew shellenv` |
| `.zshrc` | interactive zsh | Sources `.path`, `.exports`, `.aliases`, `.functions`, `.extra` (in that order), then plugins, prompt, conda, nvm, etc. |
| `.aliases` / `.exports` / `.functions` | sourced by `.zshrc` | Splits keep `.zshrc` short and diff-friendly |
| `.extra` (gitignored) | sourced LAST by `.zshrc` | Local-only — overrides anything above |
| `.path` (gitignored) | sourced FIRST by `.zshrc` | Per-machine PATH additions |

Bash mirrors the same split via `.bash_profile`.

## Adding a new alias / function / env var

- Aliases → edit `.aliases`, commit
- Functions → edit `.functions`, commit
- Env vars used by every shell → edit `.zshenv`
- Env vars used only by interactive shells → edit `.exports`
- Secrets / per-machine → edit `~/.extra` (NEVER committed)
- Per-machine `$PATH` additions → edit `~/.path` (NEVER committed)

After editing, just open a new terminal — or `source ~/.zshrc`.

## Credits

Heavily inspired by
[mathiasbynens/dotfiles](https://github.com/mathiasbynens/dotfiles); the
`bootstrap.sh` rsync pattern and `~/.extra` convention come straight from
there.
