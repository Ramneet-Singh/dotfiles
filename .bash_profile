# .bash_profile — sourced for login bash shells.
# Bash is kept as a fallback; primary shell is zsh. Mirror the same split
# pattern so .extra etc. work in either shell.

for file in ~/.{path,exports,aliases,functions,extra}; do
    [ -r "$file" ] && [ -f "$file" ] && source "$file"
done
unset file

# Initialise Homebrew when running bash directly (zsh handles this in .zprofile)
if [ -x /opt/homebrew/bin/brew ]; then
    eval "$(/opt/homebrew/bin/brew shellenv)"
elif [ -x /usr/local/bin/brew ]; then
    eval "$(/usr/local/bin/brew shellenv)"
fi

# conda (only initialised if miniconda is installed)
if [ -d "/opt/homebrew/Caskroom/miniconda/base" ]; then
    __conda_setup="$('/opt/homebrew/Caskroom/miniconda/base/bin/conda' 'shell.bash' 'hook' 2> /dev/null)"
    if [ $? -eq 0 ]; then
        eval "$__conda_setup"
    elif [ -f "/opt/homebrew/Caskroom/miniconda/base/etc/profile.d/conda.sh" ]; then
        . "/opt/homebrew/Caskroom/miniconda/base/etc/profile.d/conda.sh"
    fi
    unset __conda_setup
fi

# Source .bashrc for interactive bash shells too
[ -f ~/.bashrc ] && source ~/.bashrc

[ -f "$HOME/.local/bin/env" ] && . "$HOME/.local/bin/env"
