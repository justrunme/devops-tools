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
  info "Устанавливаю gum (интерфейс выбора)..."
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
  "Docker Desktop:brew install --cask docker"
  "Google Cloud SDK:brew install --cask google-cloud-sdk"
  "Visual Studio Code:brew install --cask visual-studio-code"
  "iTerm2 Terminal:brew install --cask iterm2"
  "Tailscale VPN:brew install --cask tailscale"
  "Ngrok Tunnel:brew install --cask ngrok"
  "Teleport:brew install teleport"
  "Lens — Kubernetes GUI:brew install --cask lens"
  "DB Browser for SQLite:brew install --cask db-browser-for-sqlite"
  "PgAdmin 4 — PostgreSQL GUI:brew install --cask pgadmin4"
)

# ---------- CLI инструменты ----------
CLI_TOOLS=(
  "kubectl:brew install kubectl"
  "helm:brew install helm"
  "minikube:brew install minikube"
  "kind:brew install kind"
  "k9s:brew install k9s"
  "terraform:brew install terraform"
  "terragrunt:brew install terragrunt"
  "terraform-docs:brew install terraform-docs"
  "tfsec:brew install tfsec"
  "pre-commit:brew install pre-commit"
  "awscli:brew install awscli"
  "azure-cli:brew install azure-cli"
  "google-cloud-sdk:brew install google-cloud-sdk"
  "doctl:brew install doctl"
  "flyctl:brew install flyctl"
  "doppler:brew install dopplerhq/cli/doppler"
  "gh:brew install gh"
  "glab:brew install glab"
  "docker:brew install docker"
  "lazygit:brew install lazygit"
  "python/pipx:brew install python && brew install pipx && pipx ensurepath"
  "fzf:brew install fzf"
  "bat:brew install bat"
  "htop:brew install htop"
  "ncdu:brew install ncdu"
  "tree:brew install tree"
  "yq:brew install yq"
  "sops:brew install sops"
  "tldr:brew install tldr"
  "eza:brew install eza"
  "Neovim + конфиг:brew install neovim && mkdir -p ~/.config/nvim/lua && curl -fsSL https://raw.githubusercontent.com/justrunme/devops-tools/main/nvim/init.lua -o ~/.config/nvim/init.lua && curl -fsSL https://raw.githubusercontent.com/justrunme/devops-tools/main/nvim/lua/plugins.lua -o ~/.config/nvim/lua/plugins.lua && git clone https://github.com/folke/lazy.nvim ~/.local/share/nvim/lazy/lazy.nvim"
)

# ---------- Пропуск GUI в CI-среде ----------
if [[ "$CI" == "true" ]]; then
  info "CI-среда — GUI-инструменты пропущены"
  GUI_TOOLS=()
  [[ "$MODE" == "all" || "$MODE" == "gui" ]] && MODE="cli"
fi

# ---------- Выбор инструментов ----------
case "$MODE" in
  all) FINAL_LIST=("${GUI_TOOLS[@]}" "${CLI_TOOLS[@]}") ;;
  gui) FINAL_LIST=("${GUI_TOOLS[@]}") ;;
  cli) FINAL_LIST=("${CLI_TOOLS[@]}") ;;
  *)
    CHOICES=$(printf "%s\n\n%s\n\n%s" \
      "===== GUI =====" "${GUI_TOOLS[@]}" \
      "===== CLI =====" "${CLI_TOOLS[@]}" |
      grep -v '^$' |
      gum choose --no-limit --height=40 --header="Выбери DevOps-инструменты:")
    FINAL_LIST=($CHOICES)
    ;;
esac

# ---------- Установка ----------
for item in "${FINAL_LIST[@]}"; do
  TOOL_NAME=$(echo "$item" | cut -d ':' -f1)
  TOOL_CMD=$(echo "$item" | cut -d ':' -f2-)
  TOOL_ID=$(echo "$TOOL_CMD" | awk '{print $3}')

  if brew list "$TOOL_ID" &>/dev/null || brew list --cask "$TOOL_ID" &>/dev/null; then
    success "$TOOL_NAME уже установлен"
  else
    gum spin --title "Устанавливаю $TOOL_NAME..." -- bash -c "$TOOL_CMD"
    success "$TOOL_NAME установлен"
  fi
done

# ---------- Установка Oh My Zsh + DevOps-плагины ----------
if [[ ! -d "$HOME/.oh-my-zsh" ]]; then
  info "Устанавливаю Oh My Zsh и DevOps плагины..."
  sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended
  git clone --depth=1 https://github.com/romkatv/powerlevel10k.git ~/.oh-my-zsh/custom/themes/powerlevel10k
  git clone https://github.com/zsh-users/zsh-autosuggestions ~/.oh-my-zsh/custom/plugins/zsh-autosuggestions
  git clone https://github.com/zsh-users/zsh-syntax-highlighting ~/.oh-my-zsh/custom/plugins/zsh-syntax-highlighting
  git clone https://github.com/zsh-users/zsh-completions ~/.oh-my-zsh/custom/plugins/zsh-completions
  git clone https://github.com/agkozak/zsh-z ~/.oh-my-zsh/custom/plugins/zsh-z
fi

# ---------- Конфиги Oh My Zsh с GitHub ----------
info "Загружаю конфиги из GitHub..."
curl -fsSL https://raw.githubusercontent.com/justrunme/devops-tools/main/dotfiles/.zshrc -o ~/.zshrc
curl -fsSL https://raw.githubusercontent.com/justrunme/devops-tools/main/dotfiles/.p10k.zsh -o ~/.p10k.zsh
success ".zshrc и .p10k.zsh установлены"

# ---------- Меняем shell на Zsh (если не CI) ----------
if [[ "$CI" != "true" ]]; then
  info "Делаю Zsh shell'ом по умолчанию..."
  chsh -s /bin/zsh
fi

# ---------- Автозапуск Neovim и применение конфигурации ----------
info "Автозапускаю nvim для установки плагинов..."
nvim --headless "+Lazy! sync" +qa || true

# ---------- Финал ----------
echo -e "\n${GREEN}✅ Установка завершена!${NC}"
echo -e "${YELLOW}➡️ Проверь Neovim: nvim + :Lazy${NC}"
echo -e "${YELLOW}➡️ Перезапусти терминал или выполни: source ~/.zshrc${NC}"
