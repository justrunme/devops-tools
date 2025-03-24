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
  info "Устанавливаю gum..."
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
  "🧭 [Kubernetes] kubectl:brew install kubectl"
  "🧭 [Kubernetes] helm:brew install helm"
  "🧭 [Kubernetes] minikube:brew install minikube"
  "🧭 [Kubernetes] kind:brew install kind"
  "🧭 [Kubernetes] k9s:brew install k9s"
  "🏗️ terraform:brew install terraform"
  "🏗️ terragrunt:brew install terragrunt"
  "🏗️ terraform-docs:brew install terraform-docs"
  "🏗️ tfsec:brew install tfsec"
  "🏗️ pre-commit:brew install pre-commit"
  "☁️ awscli:brew install awscli"
  "☁️ azure-cli:brew install azure-cli"
  "☁️ gcloud:brew install google-cloud-sdk"
  "☁️ doctl:brew install doctl"
  "☁️ flyctl:brew install flyctl"
  "☁️ doppler:brew install dopplerhq/cli/doppler"
  "🐙 gh:brew install gh"
  "🐙 glab:brew install glab"
  "🐳 docker:brew install docker"
  "⚡ lazygit:brew install lazygit"
  "🧰 python + pipx:brew install python && brew install pipx && pipx ensurepath"
  "🔍 fzf:brew install fzf"
  "🧪 bat:brew install bat"
  "📊 htop:brew install htop"
  "📁 ncdu:brew install ncdu"
  "🌳 tree:brew install tree"
  "🧾 yq:brew install yq"
  "🔐 sops:brew install sops"
  "📘 tldr:brew install tldr"
  "📁 eza:brew install eza"
  "📝 neovim + lazy.nvim + конфиг:brew install neovim && mkdir -p ~/.config/nvim/lua && curl -fsSL https://raw.githubusercontent.com/justrunme/devops-tools/main/nvim/init.lua -o ~/.config/nvim/init.lua && curl -fsSL https://raw.githubusercontent.com/justrunme/devops-tools/main/nvim/lua/plugins.lua -o ~/.config/nvim/lua/plugins.lua && git clone https://github.com/folke/lazy.nvim ~/.local/share/nvim/lazy/lazy.nvim"
)

# ---------- Пропуск GUI в CI-среде ----------
if [[ "$CI" == "true" ]]; then
  GUI_TOOLS=()
  [[ "$MODE" == "gui" ]] && MODE="cli"
fi

# ---------- Сбор инструментов ----------
case "$MODE" in
  all) FINAL_LIST=("${GUI_TOOLS[@]}" "${CLI_TOOLS[@]}") ;;
  gui) FINAL_LIST=("${GUI_TOOLS[@]}") ;;
  cli) FINAL_LIST=("${CLI_TOOLS[@]}") ;;
  *) FINAL_LIST=($(printf "%s\n" "${GUI_TOOLS[@]}" "${CLI_TOOLS[@]}" | grep -v '^$' | gum choose --no-limit --height=40 --header="Выбери инструменты для установки:")) ;;
esac

# ---------- Установка ----------
for item in "${FINAL_LIST[@]}"; do
  TOOL_CMD=$(echo "$item" | cut -d ':' -f2-)
  TOOL_ID=$(echo "$TOOL_CMD" | awk '{print $3}')
  if brew list "$TOOL_ID" &>/dev/null || brew list --cask "$TOOL_ID" &>/dev/null; then
    success "$TOOL_ID уже установлен"
  else
    gum spin --title "Устанавливаю $TOOL_ID..." -- bash -c "$TOOL_CMD"
    success "$TOOL_ID установлен"
  fi
done

# ---------- Oh My Zsh + Конфиг из GitHub ----------
if [[ ! -d "$HOME/.oh-my-zsh" ]]; then
  info "Устанавливаю Oh My Zsh и плагины..."
  sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended
  git clone --depth=1 https://github.com/romkatv/powerlevel10k.git ~/.oh-my-zsh/custom/themes/powerlevel10k
  git clone https://github.com/zsh-users/zsh-autosuggestions ~/.oh-my-zsh/custom/plugins/zsh-autosuggestions
  git clone https://github.com/zsh-users/zsh-syntax-highlighting ~/.oh-my-zsh/custom/plugins/zsh-syntax-highlighting
  git clone https://github.com/zsh-users/zsh-completions ~/.oh-my-zsh/custom/plugins/zsh-completions
  git clone https://github.com/agkozak/zsh-z ~/.oh-my-zsh/custom/plugins/zsh-z

  info "Загружаю конфиги из GitHub..."
  curl -fsSL https://raw.githubusercontent.com/justrunme/devops-tools/main/dotfiles/.zshrc -o ~/.zshrc
  curl -fsSL https://raw.githubusercontent.com/justrunme/devops-tools/main/dotfiles/.p10k.zsh -o ~/.p10k.zsh
  success ".zshrc и .p10k.zsh установлены"
else
  success "Oh My Zsh уже установлен"
fi

# ---------- Zsh по умолчанию ----------
if [[ "$SHELL" != *zsh ]]; then
  info "Делаю Zsh shell'ом по умолчанию..."
  chsh -s "$(which zsh)"
fi

# ---------- Автозагрузка iTerm2 с Zsh ----------
if [[ -d "/Applications/iTerm.app" ]]; then
  defaults write com.googlecode.iterm2 "LoadPrefsFromCustomFolder" -bool true
  defaults write com.googlecode.iterm2 "PrefsCustomFolder" -string "$HOME"
  info "Настроена автозагрузка iTerm2 с Zsh"
fi

# ---------- Автозапуск команд ----------
info "Применяю .zshrc и запускаю Neovim..."
zsh -c "source ~/.zshrc && nvim +Lazy"

# ---------- Финал ----------
echo -e "\n${GREEN}✅ Установка завершена!${NC}"
echo -e "${YELLOW}➡️ Терминал настроен с Oh My Zsh и Powerlevel10k${NC}"
echo -e "${YELLOW}➡️ Перезапусти терминал, если не открывается автоматически${NC}"
