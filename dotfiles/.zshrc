# Enable Powerlevel10k instant prompt. Should stay close to the top of ~/.zshrc.
if [[ -r "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh" ]]; then
  source "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh"
fi

# Path to your Oh My Zsh installation.
export ZSH="$HOME/.oh-my-zsh"

# Theme
ZSH_THEME="powerlevel10k/powerlevel10k"

# Plugins
plugins=(
  git
  docker
  kubectl
  terraform
  ansible
  zsh-autosuggestions
  zsh-syntax-highlighting
  fast-syntax-highlighting
)

# Load Oh My Zsh
source $ZSH/oh-my-zsh.sh

# Load Powerlevel10k config if it exists
[[ ! -f ~/.p10k.zsh ]] || source ~/.p10k.zsh

# Aliases
alias k='kubectl'
alias kgp='kubectl get pods'
alias kgn='kubectl get nodes'
alias tf='terraform'
alias dc='docker compose'
alias dcu='docker compose up -d'
alias dcd='docker compose down'
alias lg='lazygit'
alias k9='k9s'
alias p='ping 8.8.8.8'

# PATH additions
export PATH="$PATH:$HOME/.local/bin"

# Language and editor settings
export LANG="en_US.UTF-8"
export EDITOR="nvim"

# Uncomment if you want zsh to correct mistyped commands
# ENABLE_CORRECTION="true"

# Uncomment if you want command history timestamps
# HIST_STAMPS="yyyy-mm-dd"

# Optional: custom folder for additional configs
# ZSH_CUSTOM="$HOME/.oh-my-zsh/custom"

# Optional: set terminal title
# DISABLE_AUTO_TITLE="true"
