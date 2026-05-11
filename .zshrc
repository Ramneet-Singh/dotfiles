# Enable Powerlevel10k instant prompt. Should stay close to the top of ~/.zshrc.
# Initialization code that may require console input (password prompts, [y/n]
# confirmations, etc.) must go above this block; everything else may go below.
if [[ -r "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh" ]]; then
  source "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh"
fi

# Source split-out config files (path/exports/aliases/functions, then ~/.extra
# last so it can override anything). Each is optional.
for file in ~/.{path,exports,aliases,functions,extra}; do
    [ -r "$file" ] && [ -f "$file" ] && source "$file"
done
unset file

# --- oh-my-zsh ---
export ZSH="$HOME/.oh-my-zsh"
ZSH_THEME="robbyrussell"
plugins=(git colored-man-pages zsh-syntax-highlighting zsh-autosuggestions brew macos)
[ -f "$ZSH/oh-my-zsh.sh" ] && source "$ZSH/oh-my-zsh.sh"

# --- Powerlevel10k theme: prefer brew install, fall back to local clone ---
if [ -f /opt/homebrew/share/powerlevel10k/powerlevel10k.zsh-theme ]; then
    source /opt/homebrew/share/powerlevel10k/powerlevel10k.zsh-theme
elif [ -f /usr/local/share/powerlevel10k/powerlevel10k.zsh-theme ]; then
    source /usr/local/share/powerlevel10k/powerlevel10k.zsh-theme
elif [ -f "$HOME/powerlevel10k/powerlevel10k.zsh-theme" ]; then
    source "$HOME/powerlevel10k/powerlevel10k.zsh-theme"
fi

# To customize prompt, run `p10k configure` or edit ~/.p10k.zsh.
[ -f ~/.p10k.zsh ] && source ~/.p10k.zsh

# --- fzf (key bindings + fuzzy completion) ---
[ -f ~/.fzf.zsh ] && source ~/.fzf.zsh

# --- conda (only initialised if miniconda is installed) ---
if [ -d "/opt/homebrew/Caskroom/miniconda/base" ]; then
    __conda_setup="$('/opt/homebrew/Caskroom/miniconda/base/bin/conda' 'shell.zsh' 'hook' 2> /dev/null)"
    if [ $? -eq 0 ]; then
        eval "$__conda_setup"
    elif [ -f "/opt/homebrew/Caskroom/miniconda/base/etc/profile.d/conda.sh" ]; then
        . "/opt/homebrew/Caskroom/miniconda/base/etc/profile.d/conda.sh"
    fi
    unset __conda_setup
fi

# --- nvm (only initialised if installed) ---
export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"
[ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"

# --- ~/.local/bin/env (managed by `uv` / `rustup-init` etc., guarded) ---
[ -f "$HOME/.local/bin/env" ] && . "$HOME/.local/bin/env"
