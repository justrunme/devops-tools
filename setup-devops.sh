#!/usr/bin/env bash
set -e

# ---------- Цвета и функции ----------
GREEN="\033[0;32m"
YELLOW="\033[1;33m"
RED="\033[0;31m"
NC="\033[0m"
function info()    { echo -e "${YELLOW}[INFO]${NC} $1"; }
function success() { echo -e "${GREEN}[OK]${NC} $1"; }
function failure() { echo -e "${RED}[ERROR]${NC} $1"; }

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

# ---------- CLI-инструменты ----------
CLI_TOOLS=(
  git zsh fzf jq bat tree kubectl helm k9s terraform
  awscli az gh glab pipx ansible act direnv zoxide httpie cheat btop
)

declare -A CLI_COMMANDS=(
  [awscli]="pipx install awscli"
  [pipx]="brew install pipx && pipx ensurepath"
  [ansible]="pipx install ansible --include-deps"
  [docker-compose]="pipx install docker-compose"
)

# ---------- GUI-инструменты ----------
GUI_TOOLS=(
  "Docker Desktop"
  "Google Cloud SDK"
  "Visual Studio Code"
  "iTerm2 Terminal"
  "Tailscale VPN"
  "Ngrok Tunnel"
)

declare -A GUI_COMMANDS=(
  ["Docker Desktop"]="brew install --cask docker"
  ["Google Cloud SDK"]="brew install --cask google-cloud-sdk"
  ["Visual Studio Code"]="brew install --cask visual-studio-code"
  ["iTerm2 Terminal"]="brew install --cask iterm2"
  ["Tailscale VPN"]="brew install --cask tailscale"
  ["Ngrok Tunnel"]="brew install --cask ngrok"
)

# ---------- Аргументы ----------
MODE=""
for arg in "$@"; do
  [[ "$arg" == "--cli" ]] && MODE="cli"
  [[ "$arg" == "--gui" ]] && MODE="gui"
  [[ "$arg" == "--all" ]] && MODE="all"
  [[ "$arg" == "--debug" ]] && set -x
  [[ "$arg" == "--no-color" ]] && GREEN="" && YELLOW="" && RED="" && NC=""
done

# ---------- Выбор инструментов ----------
SELECTED_TOOLS=()
if [[ "$MODE" == "cli" ]]; then
  SELECTED_TOOLS=("${CLI_TOOLS[@]}")
elif [[ "$MODE" == "gui" ]]; then
  SELECTED_TOOLS=("${GUI_TOOLS[@]}")
elif [[ "$MODE" == "all" ]]; then
  SELECTED_TOOLS=("${CLI_TOOLS[@]}" "${GUI_TOOLS[@]}")
else
  ALL_TOOLS=(
    $(for tool in "${CLI_TOOLS[@]}"; do echo "🛠️ CLI: $tool"; done)
    $(for tool in "${GUI_TOOLS[@]}"; do echo "🖥️ GUI: $tool"; done)
  )
  readarray -t SELECTED < <(gum choose --no-limit --height=30 --header="Выбери инструменты для установки:" "${ALL_TOOLS[@]}")
  for item in "${SELECTED[@]}"; do
    SELECTED_TOOLS+=("$(echo "$item" | sed 's/^.*: //')")
  done
fi

# ---------- Установка ----------
for TOOL in "${SELECTED_TOOLS[@]}"; do
  if [[ -n "${CLI_COMMANDS[$TOOL]}" ]]; then
    CMD="${CLI_COMMANDS[$TOOL]}"
  elif [[ " ${CLI_TOOLS[*]} " == *" $TOOL "* ]]; then
    CMD="brew install $TOOL"
  elif [[ -n "${GUI_COMMANDS[$TOOL]}" ]]; then
    CMD="${GUI_COMMANDS[$TOOL]}"
  else
    failure "$TOOL — не найден в списках"
    continue
  fi

  info "Устанавливаю $TOOL..."
  if bash -c "$CMD"; then
    success "$TOOL установлен"
  else
    failure "$TOOL не удалось установить"
  fi

done

# ---------- Финал ----------
echo -e "\n${GREEN}Установка DevOps-инструментов завершена!${NC}"
