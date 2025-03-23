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

# ---------- Массив команд для установки ----------

INSTALL_COMMANDS=(
  "git=brew install git"
  "zsh=brew install zsh"
  "fzf=brew install fzf"
  "jq=brew install jq"
  "bat=brew install bat"
  "tree=brew install tree"
  "kubectl=brew install kubectl"
  "helm=brew install helm"
  "k9s=brew install k9s"
  "terraform=brew install terraform"
  "awscli=pipx install awscli"
  "az=brew install azure-cli"
  "gh=brew install gh"
  "glab=brew install glab"
  "pipx=brew install pipx && pipx ensurepath"
  "ansible=pipx install ansible"
  "act=brew install act"
  "direnv=brew install direnv"
  "zoxide=brew install zoxide"
  "httpie=brew install httpie"
  "cheat=brew install cheat"
  "btop=brew install btop"
)

# ---------- Аргументы ----------
ALL=false
for arg in "$@"; do
  [[ "$arg" == "--all" ]] && ALL=true
  [[ "$arg" == "-a" ]] && ALL=true
done

# ---------- Список инструментов ----------
TOOL_LIST=(
  "🛠️ [CORE] git"
  "🛠️ [CORE] zsh"
  "🛠️ [CORE] fzf"
  "🛠️ [CORE] jq"
  "🛠️ [CORE] bat"
  "🛠️ [CORE] tree"
  "☸️ [KUBERNETES] kubectl"
  "☸️ [KUBERNETES] helm"
  "☸️ [KUBERNETES] k9s"
  "📦 [INFRA] terraform"
  "☁️ [CLOUD] awscli"
  "☁️ [CLOUD] az"
  "☁️ [CLOUD] gh"
  "☁️ [CLOUD] glab"
  "⚙️ [DEVTOOLS] pipx"
  "⚙️ [DEVTOOLS] ansible"
  "⚡ [EXTRAS] act"
  "🔧 [UTILITIES] direnv"
  "🔧 [UTILITIES] zoxide"
  "🔧 [UTILITIES] httpie"
  "🔧 [UTILITIES] cheat"
  "🔧 [UTILITIES] btop"
)

# ---------- Выбор инструментов ----------
if $ALL; then
  CHOICES="${TOOL_LIST[@]}"
else
  CHOICES=$(gum choose --no-limit --height=40 --header="Выбери инструменты для установки (CI-friendly):" <<< "${TOOL_LIST[*]}")
fi

# ---------- Установка выбранных инструментов ----------
for item in $CHOICES; do
  TOOL=$(echo "$item" | awk '{print $3}')
  
  # Проверка, установлен ли инструмент
  if command -v "$TOOL" &>/dev/null; then
    success "$TOOL уже установлен, пропускаю установку."
    continue
  fi

  # Установка инструмента, если он не установлен
  for cmd in "${INSTALL_COMMANDS[@]}"; do
    if [[ "$cmd" == "$TOOL"* ]]; then
      COMD=$(echo "$cmd" | cut -d '=' -f2-)
      gum spin --title "Устанавливаю $TOOL..." -- bash -c "$COMD"
      success "$TOOL установлен"
    fi
  done
done

# ---------- Финал ----------
echo -e "\n${GREEN}Установка завершена! Перезапусти терминал или выполни: source ~/.zshrc${NC}"
