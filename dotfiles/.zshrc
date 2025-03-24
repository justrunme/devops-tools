# Enable Powerlevel10k instant prompt (должно быть в начале)
if [[ -r "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh" ]]; then
  source "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh"
fi

# Путь к Oh My Zsh
export ZSH="$HOME/.oh-my-zsh"
ZSH_THEME="powerlevel10k/powerlevel10k"

# Плагины DevOps + usability
plugins=(
  # 🌐 Cloud & DevOps
  git docker kubectl helm terraform aws gcloud az

  # ⚙️ CLI улучшения
  zsh-autosuggestions
  zsh-syntax-highlighting
  zsh-completions
  zsh-z
  fzf
  command-not-found

  # 🧠 Удобство
  colored-man-pages
  extract
  history
  alias-finder
  safe-paste
  common-aliases

  # 🍎 Только для Mac (будет проигнорирован на Linux)
  macos
)

# Загружаем Oh My Zsh
source $ZSH/oh-my-zsh.sh

# Powerlevel10k конфиг
[[ -f ~/.p10k.zsh ]] && source ~/.p10k.zsh

# Установленный pipx
export PATH="$HOME/.local/bin:$PATH"

# DevOps Алиасы
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

# Предпочитаемый редактор
export EDITOR='nvim'

# История с временными метками
HIST_STAMPS="yyyy-mm-dd"

# Для Linux — command-not-found
if [ -f /etc/zsh_command_not_found ]; then
  source /etc/zsh_command_not_found
fi
