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

# ---------- Маппинг тулзов на команды (CI-friendly only) ----------
declare -A INSTALL_COMMANDS=(
  [git]="brew install git"
  [zsh]="brew install zsh"
  [fzf]="brew install fzf"
  [jq]="brew install jq"
  [bat]="brew install bat"
  [tree]="brew install tree"
  [kubectl]="brew install kubectl"
  [helm]="brew install helm"
  [k9s]="brew install k9s"
  [terraform]="brew install terraform"
  [awscli]="pipx install awscli"
  [az]="brew install azure-cli"
  [gh]="brew install gh"
  [glab]="brew install glab"
  [pipx]="brew install pipx && pipx ensurepath"
  [ansible]="pipx install ansible"
  [act]="brew install act"
  [direnv]="brew install direnv"
  [zoxide]="brew install zoxide"
  [httpie]="brew install httpie"
  [cheat]="brew install cheat"
  [btop]="brew install btop"
)

# ---------- Список с категориями ----------
CHOICES=$(gum choose --no-limit --height=40 --header="Выбери инструменты для установки (CI-friendly):" <<EOF
🛠️ [CORE] git
🛠️ [CORE] zsh
🛠️ [CORE] fzf
🛠️ [CORE] jq
🛠️ [CORE] bat
🛠️ [CORE] tree
☸️ [KUBERNETES] kubectl
☸️ [KUBERNETES] helm
☸️ [KUBERNETES] k9s
📦 [INFRA] terraform
☁️ [CLOUD] awscli
☁️ [CLOUD] az
☁️ [CLOUD] gh
☁️ [CLOUD] glab
⚙️ [DEVTOOLS] pipx
⚙️ [DEVTOOLS] ansible
⚡ [EXTRAS] act
🔧 [UTILITIES] direnv
🔧 [UTILITIES] zoxide
🔧 [UTILITIES] httpie
🔧 [UTILITIES] cheat
🔧 [UTILITIES] btop
EOF
)

# ---------- Установка выбранных тулзов ----------
for item in $CHOICES; do
  TOOL=$(echo "$item" | awk '{print $3}')
  CMD="${INSTALL_COMMANDS[$TOOL]}"
  if [[ -n "$CMD" ]]; then
    gum spin --title "Устанавливаю $TOOL..." -- bash -c "$CMD"
    success "$TOOL установлен"
  else
    info "$TOOL не найден в INSTALL_COMMANDS — пропущен"
  fi
done

# ---------- Финал ----------
echo -e "\n${GREEN}Установка завершена! Перезапусти терминал или выполни: source ~/.zshrc${NC}"
