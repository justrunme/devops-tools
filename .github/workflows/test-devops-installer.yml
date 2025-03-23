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

# ---------- Аргументы ----------
ALL=false
for arg in "$@"; do
  [[ "$arg" == "--all" ]] && ALL=true
  [[ "$arg" == "-a" ]] && ALL=true
done

# ---------- Список тулзов ----------
TOOL_LIST=(
  "git"
  "zsh"
  "fzf"
  "jq"
  "bat"
  "tree"
  "kubectl"
  "helm"
  "k9s"
  "terraform"
  "awscli"
  "az"
  "gh"
  "glab"
  "pipx"
  "ansible"
  "act"
  "direnv"
  "zoxide"
  "httpie"
  "cheat"
  "btop"
)

# ---------- Выбор инструментов ----------
if $ALL; then
  CHOICES=("${TOOL_LIST[@]}")
else
  CHOICES=$(gum choose --no-limit --height=30 --header="Выбери CLI-инструменты для установки:" "${TOOL_LIST[@]}")
fi

# ---------- Установка выбранных тулзов ----------
for TOOL in $CHOICES; do
  case "$TOOL" in
    awscli)      CMD="pipx install awscli" ;;
    pipx)        CMD="brew install pipx && pipx ensurepath" ;;
    ansible)     CMD="pipx install ansible" ;;
    docker-compose) CMD="pipx install docker-compose" ;;
    *)           CMD="brew install $TOOL" ;;
  esac

  gum spin --title "Устанавливаю $TOOL..." -- bash -c "$CMD"
  success "$TOOL установлен"
done

# ---------- Финал ----------
echo -e "\n${GREEN}Установка завершена! Перезапусти терминал или выполни: source ~/.zshrc${NC}"
