#!/bin/bash
set -e

# ---------- Проверка gum ----------
if ! command -v gum &>/dev/null; then
  echo "Устанавливаю gum..."
  brew install charmbracelet/tap/gum
fi

# ---------- Цвета ----------
GREEN="\033[0;32m"
YELLOW="\033[1;33m"
NC="\033[0m"
function info()    { echo -e "${YELLOW}[INFO]${NC} $1"; }
function success() { echo -e "${GREEN}[OK]${NC} $1"; }

# ---------- Категории + тулзы ----------
CHOICES=$(
gum choose --no-limit --height=30 --header="Выбери инструменты для установки:" <<EOF
🛠️ [CORE] brew — Пакетный менеджер для macOS
🛠️ [CORE] git — Система контроля версий
🛠️ [CORE] zsh — Современный терминал
🛠️ [CORE] oh-my-zsh — Конфигурация оболочки zsh
🛠️ [CORE] fzf — Fuzzy-поиск в CLI
🛠️ [CORE] jq — JSON-парсер для CLI
🛠️ [CORE] bat — Подсветка в терминале (альтернатива cat)
🛠️ [CORE] tree — Вывод дерева каталогов

🐳 [DOCKER] docker — Контейнеризация
🐳 [DOCKER] docker-compose — Мультисервисная сборка
🐳 [DOCKER] lazydocker — TUI для Docker

☸️ [KUBERNETES] kubectl — CLI для Kubernetes
☸️ [KUBERNETES] helm — Менеджер чартов
☸️ [KUBERNETES] k9s — TUI-интерфейс Kubernetes
☸️ [KUBERNETES] minikube — Локальный кластер
☸️ [KUBERNETES] kind — Kubernetes в Docker
☸️ [KUBERNETES] kubectx — Переключение кластеров
☸️ [KUBERNETES] kubens — Переключение namespace
☸️ [KUBERNETES] skaffold — Автодеплой при разработке
☸️ [KUBERNETES] kustomize — Kubernetes overlay'и

☁️ [CLOUD] awscli — AWS CLI
☁️ [CLOUD] gcloud — Google Cloud CLI
☁️ [CLOUD] az — Azure CLI
☁️ [CLOUD] gh — GitHub CLI
☁️ [CLOUD] glab — GitLab CLI

⚙️ [DEVTOOLS] pipx — Изолированная установка Python CLI
⚙️ [DEVTOOLS] ansible — Автоматизация
⚙️ [DEVTOOLS] visual-studio-code — Редактор кода
⚙️ [DEVTOOLS] iterm2 — Расширенный терминал

⚡ [EXTRAS] act — Локальный запуск GitHub Actions
⚡ [EXTRAS] tilt — Быстрый CI для Kubernetes
⚡ [EXTRAS] tailscale — Приватный VPN
⚡ [EXTRAS] ngrok — Проброс портов наружу

📦 [INFRA] terraform — Инфраструктура как код
📦 [INFRA] tfsec — Анализ безопасности Terraform
📦 [INFRA] tflint — Линтер Terraform
📦 [INFRA] terragrunt — Обёртка над Terraform

🔧 [UTILITIES] direnv — Управление переменными
🔧 [UTILITIES] zoxide — Быстрый переход по директориям
🔧 [UTILITIES] httpie — curl с душой
🔧 [UTILITIES] cheat — CLI-шпаргалки
🔧 [UTILITIES] btop — Красивый монитор ресурсов
EOF
)

# ---------- Обработка установки ----------
for item in $CHOICES; do
  TOOL=$(echo "$item" | awk '{print $3}')
  DESCRIPTION=$(echo "$item" | cut -d '—' -f2-)
  gum spin --title "Устанавливаю $TOOL ($DESCRIPTION)" -- brew install --quiet "$TOOL" || brew install --cask --quiet "$TOOL" || true
  success "$TOOL установлен"
done

# ---------- Финал ----------
echo -e "\n${GREEN}Установка завершена! Перезапусти терминал или выполни: source ~/.zshrc${NC}"
