# .zprofile — sourced for login zsh shells
# Initialise Homebrew (sets PATH/MANPATH/INFOPATH for /opt/homebrew or /usr/local)

if [ "$(arch)" = "arm64" ]; then
    eval "$(/opt/homebrew/bin/brew shellenv)"
else
    eval "$(/usr/local/bin/brew shellenv)"
fi
