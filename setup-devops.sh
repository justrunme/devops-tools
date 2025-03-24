#!/usr/bin/env bash
set -e

# ---------- Цвета и функции ----------
GREEN="\033[0;32m"
YELLOW="\033[1;33m"
RED="\033[0;31m"
NC="\033[0m"
function info()    { echo -e "${YELLOW}[INFO]${NC} $1"; }
function success() { echo -e "${GREEN}[OK]${NC} $1"; }
function error()   { echo -e "${RED}[ERROR]${NC} $1"; }

# ---------- Аргументы ----------
MODE=""
for arg in "$@"; do
  case "$arg" in
    --all|-a) MODE="all" ;;
    --gui)    MODE="gui" ;;
    --cli)    MODE="cli" ;;
    --debug)  set -x ;;
    --no-color) GREEN=""; YELLOW=""; RED=""; NC="" ;;
  esac
done

# ---------- Проверка gum ----------
if ! command -v gum &>/dev/null; then
  info "Устанавливаю gum (интерактивный интерфейс)..."
  brew install charmbracelet/tap/gum
fi

# ---------- Проверка pipx ----------
if ! command -v pipx &>/dev/null; then
  info "Устанавливаю pipx..."
  brew install pipx
  pipx ensurepath
fi

# ---------- GUI инструменты ----------
GUI_TOOLS=(
  "🐳 Docker Desktop — контейнеризация:brew install --cask docker"
  "☁️ Google Cloud SDK — CLI-инструменты GCP:brew install --cask google-cloud-sdk"
  "📝 Visual Studio Code — редактор кода:brew install --cask visual-studio-code"
  "💻 iTerm2 Terminal — расширенный терминал:brew install --cask iterm2"
  "🔒 Tailscale VPN — mesh-сеть:brew install --cask tailscale"
  "🌐 Ngrok Tunnel — проброс портов:brew install --cask ngrok"
)

# ---------- CLI инструменты ----------
CLI_TOOLS=(
  "🧭 [Kubernetes] kubectl — управление кластерами:brew install kubectl"
  "🧭 [Kubernetes] helm — менеджер пакетов:brew install helm"
  "🧭 [Kubernetes] minikube — локальный кластер:brew install minikube"
  "🧭 [Kubernetes] kind — Kubernetes в Docker:brew install kind"
  "🧭 [Kubernetes] k9s — терминал для кластеров:brew install k9s"
  "🏗️ [IaC] terraform — инфраструктура как код:brew install terraform"
  "🏗️ [IaC] terragrunt — надстройка Terraform:brew install terragrunt"
  "🏗️ [IaC] terraform-docs — генерация документации:brew install terraform-docs"
  "🏗️ [IaC] tfsec — аудит безопасности:brew install tfsec"
  "🏗️ [IaC] pre-commit — хуки для Git:brew install pre-commit"
  "☁️ [Cloud] AWS CLI — управление AWS:brew install awscli"
  "☁️ [Cloud] Azure CLI — управление Azure:brew install azure-cli"
  "☁️ [Cloud] GCloud CLI — GCP CLI:brew install google-cloud-sdk"
  "☁️ [Cloud] doctl — CLI для DigitalOcean:brew install doctl"
  "☁️ [Cloud] flyctl — CLI для Fly.io:brew install flyctl"
  "☁️ [Cloud] doppler — менеджер секретов:brew install dopplerhq/cli/doppler"
  "🐙 [Git] GitHub CLI — работа с GitHub:brew install gh"
  "🐙 [Git] GitLab CLI — работа с GitLab:brew install glab"
  "🐳 [Docker] Docker CLI — клиент Docker:brew install docker"
  "⚡ [Git] lazygit — улучшенный git:brew install lazygit"
  "🧰 [Tools] Python + pipx — окружение:brew install python && brew install pipx && pipx ensurepath"
  "🔍 [Tools] fzf — fuzzy поиск:brew install fzf"
  "🧪 [Tools] bat — cat с подсветкой:brew install bat"
  "📊 [Tools] htop — мониторинг процессов:brew install htop"
  "📁 [Tools] ncdu — анализ диска:brew install ncdu"
  "🌳 [Tools] tree — древовидная структура:brew install tree"
  "🧾 [Tools] yq — jq для YAML:brew install yq"
  "🔐 [Tools] sops — шифрование секретов:brew install sops"
  "📘 [Tools] tldr — упрощённые man:brew install tldr"
  "📁 [Tools] eza — улучшенный ls (exa fork):brew install eza"
  "📝 [DevOps] Neovim + lazy.nvim + конфиг:brew install neovim && curl -fsSL https://raw.githubusercontent.com/justrunme/devops-tools/main/nvim/init.lua -o ~/.config/nvim/init.lua && mkdir -p ~/.config/nvim/lua && curl -fsSL https://raw.githubusercontent.com/justrunme/devops-tools/main/nvim/lua/plugins.lua -o ~/.config/nvim/lua/plugins.lua && git clone https://github.com/folke/lazy.nvim ~/.local/share/nvim/lazy/lazy.nvim"
)

# ---------- Пропуск GUI в CI-среде ----------
if [[ "$CI" == "true" ]]; then
  info "CI-среда обнаружена — GUI-инструменты пропущены"
  GUI_TOOLS=()
  [[ "$MODE" == "all" || "$MODE" == "gui" ]] && info "Переключение на CLI-режим"
  [[ "$MODE" == "gui" ]] && MODE="cli"
fi

# ---------- Определение финального списка ----------
case "$MODE" in
  all) FINAL_LIST=("${GUI_TOOLS[@]}" "${CLI_TOOLS[@]}") ;;
  gui) FINAL_LIST=("${GUI_TOOLS[@]}") ;;
  cli) FINAL_LIST=("${CLI_TOOLS[@]}") ;;
  *)
    CHOICES=$(printf "%s\n\n%s\n\n%s" \
      "===== 🖥️ GUI инструменты =====" \
      "${GUI_TOOLS[@]}" \
      "===== 🛠️ CLI + Neovim инструменты =====" \
      "${CLI_TOOLS[@]}" |
      grep -v '^$' |
      gum choose --no-limit --height=40 --header="Выбери DevOps-инструменты для установки:")
    FINAL_LIST=($CHOICES)
    ;;
esac

# ---------- Установка выбранных инструментов ----------
for item in "${FINAL_LIST[@]}"; do
  TOOL_NAME=$(echo "$item" | cut -d '—' -f1 | sed 's/.*] //;s/^[^ ]* //')
  TOOL_CMD=$(echo "$item" | cut -d ':' -f2-)
  TOOL_ID=$(echo "$TOOL_CMD" | awk '{print $3}')

  if brew list "$TOOL_ID" &>/dev/null || brew list --cask "$TOOL_ID" &>/dev/null; then
    success "$TOOL_NAME уже установлен"
  else
    gum spin --title "Устанавливаю $TOOL_NAME..." -- bash -c "$TOOL_CMD"
    success "$TOOL_NAME установлен"
  fi
done

# ---------- Установка Oh My Zsh и DevOps-плагинов ----------
if [[ ! -d "$HOME/.oh-my-zsh" ]]; then
  info "Устанавливаю Oh My Zsh..."
  sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended
  git clone --depth=1 https://github.com/romkatv/powerlevel10k.git ~/.oh-my-zsh/custom/themes/powerlevel10k
  git clone https://github.com/zsh-users/zsh-autosuggestions ~/.oh-my-zsh/custom/plugins/zsh-autosuggestions
  git clone https://github.com/zsh-users/zsh-syntax-highlighting ~/.oh-my-zsh/custom/plugins/zsh-syntax-highlighting
  git clone https://github.com/zsh-users/zsh-completions ~/.oh-my-zsh/custom/plugins/zsh-completions
  git clone https://github.com/agkozak/zsh-z ~/.oh-my-zsh/custom/plugins/zsh-z

  info "Настраиваю .zshrc..."
  cat <<EOF > ~/.zshrc
export ZSH="\$HOME/.oh-my-zsh"
ZSH_THEME="powerlevel10k/powerlevel10k"
plugins=(
  git
  docker
  kubectl
  helm
  terraform
  zsh-autosuggestions
  zsh-syntax-highlighting
  zsh-completions
  zsh-z
  fzf
)

source \$ZSH/oh-my-zsh.sh
[[ -f ~/.p10k.zsh ]] && source ~/.p10k.zsh
EOF

  info "Создаю .p10k.zsh по умолчанию..."
  curl -fsSL https://raw.githubusercontent.com/romkatv/powerlevel10k-media/master/config/p10k-classic.zsh -o ~/.p10k.zsh

  success "Oh My Zsh установлен и настроен"
else
  success "Oh My Zsh уже установлен"
fi

# ---------- Финал ----------
echo -e "\n${GREEN}✅ Установка всех выбранных инструментов завершена!${NC}"
echo -e "${YELLOW}➡️ Запусти nvim и выполни :Lazy для установки плагинов.${NC}"
echo -e "${YELLOW}➡️ Перезапусти терминал или выполни: source ~/.zshrc${NC}"
