#!/usr/bin/env bash
set -e

# ---------- Цвета и функции ----------
GREEN="\033[0;32m"
YELLOW="\033[1;33m"
NC="\033[0m"
function info()    { echo -e "${YELLOW}[INFO]${NC} $1"; }
function success() { echo -e "${GREEN}[OK]${NC} $1"; }

# ---------- Проверка gum ----------
if ! command -v gum &>/dev/null; then
  info "Устанавливаю gum (интерактивный интерфейс)..."
  brew install charmbracelet/tap/gum
fi

# ---------- Проверка pipx (для Python утилит) ----------
if ! command -v pipx &>/dev/null; then
  info "Устанавливаю pipx..."
  brew install pipx
  pipx ensurepath
fi

# ---------- Аргументы ----------
MODE=""
for arg in "$@"; do
  case "$arg" in
    --all|-a) MODE="all" ;;
    --gui)    MODE="gui" ;;
    --cli)    MODE="cli" ;;
  esac
done

# ---------- Списки тулзов ----------
GUI_TOOLS=(
  "🐳 Docker Desktop — контейнеризация с интерфейсом:brew install --cask docker"
  "☁️ Google Cloud SDK — CLI-инструменты для Google Cloud:brew install --cask google-cloud-sdk"
  "📝 Visual Studio Code — редактор кода:brew install --cask visual-studio-code"
  "💻 iTerm2 Terminal — улучшенный терминал:brew install --cask iterm2"
  "🔒 Tailscale VPN — mesh-сеть VPN:brew install --cask tailscale"
  "🌐 Ngrok Tunnel — проброс портов в интернет:brew install --cask ngrok"
)

CLI_TOOLS=(
  "⚙️ kubectl — управление Kubernetes:brew install kubectl"
  "⛵ helm — менеджер пакетов Kubernetes:brew install helm"
  "📦 minikube — локальный кластер Kubernetes:brew install minikube"
  "🐳 docker CLI — клиент Docker:brew install docker"
  "☁️ AWS CLI — управление AWS:brew install awscli"
  "🦊 GitLab CLI — инструмент GitLab:brew install glab"
  "🧠 Azure CLI — работа с Microsoft Azure:brew install azure-cli"
  "🐍 Python + pipx — для DevOps-скриптов:brew install python && brew install pipx && pipx ensurepath"
  "🧰 Kind — Kubernetes в Docker:brew install kind"
  "🔭 k9s — визуализация Kubernetes:brew install k9s"
  "⚡ lazygit — удобная CLI Git-оболочка:brew install lazygit"
  "🔍 fzf — fuzzy-поиск в терминале:brew install fzf"
  "🧪 bat — улучшенная cat с подсветкой:brew install bat"
  "📊 htop — мониторинг процессов:brew install htop"
  "📁 ncdu — анализ диска:brew install ncdu"
  "🌳 tree — древовидный вывод файлов:brew install tree"
)

# ---------- Объединение и фильтрация ----------
case "$MODE" in
  all) FINAL_LIST=("${GUI_TOOLS[@]}" "${CLI_TOOLS[@]}") ;;
  gui) FINAL_LIST=("${GUI_TOOLS[@]}") ;;
  cli) FINAL_LIST=("${CLI_TOOLS[@]}") ;;
  *)
    info "Выбери инструменты для установки:"
    CHOICES=$(printf "%s\n\n%s" "----- GUI -----" "${GUI_TOOLS[@]}" "----- CLI -----" "${CLI_TOOLS[@]}" |
      grep -v '^$' |
      gum choose --no-limit --height=30 --header="Выбери DevOps-инструменты для установки:")
    FINAL_LIST=($CHOICES)
    ;;
esac

# ---------- Установка выбранных инструментов ----------
for item in "${FINAL_LIST[@]}"; do
  TOOL_NAME=$(echo "$item" | cut -d '—' -f1 | sed 's/^[^ ]* //')
  TOOL_CMD=$(echo "$item" | cut -d ':' -f2-)

  TOOL_ID=$(echo "$TOOL_CMD" | awk '{print $3}')

  if brew list "$TOOL_ID" &>/dev/null || brew list --cask "$TOOL_ID" &>/dev/null; then
    success "$TOOL_NAME уже установлен, пропускаю."
  else
    gum spin --title "Устанавливаю $TOOL_NAME..." -- bash -c "$TOOL_CMD"
    success "$TOOL_NAME установлен"
  fi
done

# ---------- Финал ----------
echo -e "\n${GREEN}Установка DevOps-инструментов завершена!${NC}"
