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

# ---------- Проверка pipx ----------
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

# ---------- GUI инструменты ----------
GUI_TOOLS=(
  "🐳 Docker Desktop — контейнеризация с интерфейсом:brew install --cask docker"
  "☁️ Google Cloud SDK — CLI-инструменты для Google Cloud:brew install --cask google-cloud-sdk"
  "📝 Visual Studio Code — редактор кода:brew install --cask visual-studio-code"
  "💻 iTerm2 Terminal — улучшенный терминал:brew install --cask iterm2"
  "🔒 Tailscale VPN — mesh-сеть VPN:brew install --cask tailscale"
  "🌐 Ngrok Tunnel — проброс портов в интернет:brew install --cask ngrok"
)

# ---------- CLI инструменты (с категориями) ----------
CLI_TOOLS=(
  # Kubernetes
  "🧭 [Kubernetes] kubectl — управление кластерами:brew install kubectl"
  "🧭 [Kubernetes] helm — менеджер пакетов:brew install helm"
  "🧭 [Kubernetes] minikube — локальный кластер:brew install minikube"
  "🧭 [Kubernetes] kind — Kubernetes в Docker:brew install kind"
  "🧭 [Kubernetes] k9s — интерфейс для кластеров:brew install k9s"

  # IaC
  "🏗️ [IaC] terraform — инфраструктура как код:brew install terraform"
  "🏗️ [IaC] terragrunt — надстройка над Terraform:brew install terragrunt"
  "🏗️ [IaC] terraform-docs — генерация документации:brew install terraform-docs"
  "🏗️ [IaC] tfsec — анализ безопасности Terraform:brew install tfsec"
  "🏗️ [IaC] pre-commit — хуки и проверки кода:brew install pre-commit"

  # Cloud
  "☁️ [Cloud] AWS CLI — управление AWS:brew install awscli"
  "☁️ [Cloud] Azure CLI — управление Azure:brew install azure-cli"
  "☁️ [Cloud] GCloud CLI — Google Cloud CLI:brew install google-cloud-sdk"

  # Git & Docker
  "🐙 [Git] GitLab CLI — инструмент для GitLab:brew install glab"
  "🐳 [Docker] Docker CLI — клиент Docker:brew install docker"
  "⚡ [Git] lazygit — улучшенный git-интерфейс:brew install lazygit"

  # Tools
  "🧰 [Tools] Python + pipx — окружение для DevOps-скриптов:brew install python && brew install pipx && pipx ensurepath"
  "🔍 [Tools] fzf — fuzzy поиск в терминале:brew install fzf"
  "🧪 [Tools] bat — улучшенная cat с подсветкой:brew install bat"
  "📊 [Tools] htop — мониторинг процессов:brew install htop"
  "📁 [Tools] ncdu — анализ использования диска:brew install ncdu"
  "🌳 [Tools] tree — древовидный вывод файлов:brew install tree"
)

# ---------- Пропуск GUI-инструментов в CI-среде ----------
if [[ "$CI" == "true" ]]; then
  info "CI-среда обнаружена — GUI-инструменты будут пропущены"
  GUI_TOOLS=()
  [[ "$MODE" == "all" || "$MODE" == "gui" ]] && info "Установка GUI невозможна в CI — переключаемся на CLI"
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
      "===== 🛠️ CLI инструменты =====" \
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
    success "$TOOL_NAME уже установлен, пропускаю."
  else
    gum spin --title "Устанавливаю $TOOL_NAME..." -- bash -c "$TOOL_CMD"
    success "$TOOL_NAME установлен"
  fi
done

# ---------- Финал ----------
echo -e "\n${GREEN}Установка всех выбранных инструментов завершена!${NC}"
