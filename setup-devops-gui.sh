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
  info "Устанавливаю gum..."
  brew install charmbracelet/tap/gum
fi

# ---------- Проверка pipx ----------
if ! command -v pipx &>/dev/null; then
  info "Устанавливаю pipx..."
  brew install pipx
  pipx ensurepath
fi

# ---------- GUI-инструменты ----------
declare -A INSTALL_GUI_COMMANDS=(
  [Docker Desktop]="brew install --cask docker"
  [Google Cloud SDK]="brew install --cask google-cloud-sdk"
  [Visual Studio Code]="brew install --cask visual-studio-code"
  [iTerm2 Terminal]="brew install --cask iterm2"
  [Tailscale VPN]="brew install --cask tailscale"
  [Ngrok Tunnel]="brew install --cask ngrok"
)

# ---------- Аргументы ----------
ALL=false
for arg in "$@"; do
  [[ "$arg" == "--all" ]] && ALL=true
  [[ "$arg" == "-a" ]] && ALL=true
done

# ---------- Список GUI тулзов ----------
GUI_TOOL_LIST=(
  "🐳 Docker Desktop"
  "☁️ Google Cloud SDK"
  "📝 Visual Studio Code"
  "💻 iTerm2 Terminal"
  "🔒 Tailscale VPN"
  "🌐 Ngrok Tunnel"
)

# ---------- Выбор GUI инструментов ----------
if $ALL; then
  CHOICES="${GUI_TOOL_LIST[@]}"
else
  CHOICES=$(gum choose --no-limit --height=20 --header="Выбери GUI-инструменты для установки:" <<< "${GUI_TOOL_LIST[*]}")
fi

# ---------- Установка выбранных тулзов ----------
for item in $CHOICES; do
  TOOL=$(echo "$item" | cut -d ' ' -f2-)
  CMD="${INSTALL_GUI_COMMANDS[$TOOL]}"
  if [[ -n "$CMD" ]]; then
    gum spin --title "Устанавливаю $TOOL..." -- bash -c "$CMD"
    success "$TOOL установлен"
  else
    info "$TOOL не найден в INSTALL_GUI_COMMANDS — пропущен"
  fi
done

# ---------- Финал ----------
echo -e "\n${GREEN}Установка GUI-инструментов завершена!${NC}"
