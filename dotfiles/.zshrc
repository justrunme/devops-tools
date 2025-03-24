# ----- Powerlevel10k Instant Prompt -----
if [[ -r "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh" ]]; then
  source "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh"
fi

# ----- Oh My Zsh -----
export ZSH="$HOME/.oh-my-zsh"
ZSH_THEME="powerlevel10k/powerlevel10k"

plugins=(
  git
  docker
  kubectl
  helm
  terraform
  ansible
  aws
  gcloud
  zsh-autosuggestions
  zsh-syntax-highlighting
  zsh-completions
  zsh-z
  fzf
)

source $ZSH/oh-my-zsh.sh

# ----- Powerlevel10k Config -----
[[ -f ~/.p10k.zsh ]] && source ~/.p10k.zsh

# ----- DevOps Aliases -----
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

# ----- Path for pipx and other tools -----
export PATH="$HOME/.local/bin:$PATH"
