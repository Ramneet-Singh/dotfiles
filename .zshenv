# .zshenv — sourced for ALL zsh invocations (login, interactive, scripts)
# Keep minimal: env vars only, no commands that produce output.

# Deduplicate $PATH and $path
typeset -U path PATH

# Preferred editor (used by git, less, etc.)
export EDITOR=vim
