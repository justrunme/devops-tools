#!/usr/bin/env bash
set -e

# ---------- Цвета и функции ----------
GREEN="\033[0;32m"
YELLOW="\033[1;33m"
RED="\033[0;31m"
NC="\033[0m"
info()    { echo -e "${YELLOW}[INFO]${NC} $1"; }
success() { echo -e "${GREEN}[OK]${NC} $1"; }
error()   { echo -e "${RED}[ERROR]${NC} $1"; }

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

# ---------- Пропуск GUI в CI-среде ----------
if [[ "$CI" == "true" ]]; then
  info "CI-среда — GUI-инструменты пропущены"
  GUI_TOOLS=()
  [[ "$MODE" == "all" || "$MODE" == "gui" ]] && MODE="cli"
fi

# ---------- Определение пакетного менеджера ----------
detect_package_manager() {
  if command -v apt &>/dev/null; then
    echo "apt"
  elif command -v dnf &>/dev/null; then
    echo "dnf"
  elif command -v pacman &>/dev/null; then
    echo "pacman"
  else
    echo "unsupported"
  fi
}

PKG_MANAGER=$(detect_package_manager)
if [[ "$PKG_MANAGER" == "unsupported" ]]; then
  error "Неизвестный пакетный менеджер. Поддерживаются apt, dnf, pacman."
  exit 1
fi

# ---------- Обёртка для установки пакетов ----------
install_pkg() {
  case "$PKG_MANAGER" in
    apt) sudo apt-get install -y "$@" ;;
    dnf) sudo dnf install -y "$@" ;;
    pacman) sudo pacman -S --noconfirm "$@" ;;
  esac
}

# ---------- Проверка gum ----------
if ! command -v gum &>/dev/null; then
  info "Устанавливаю gum..."
  sudo apt-get update && sudo apt-get install -y wget tar
  curl -s https://api.github.com/repos/charmbracelet/gum/releases/latest |
    grep browser_download_url |
    grep linux_amd64.tar.gz |
    cut -d '"' -f 4 |
    wget -qi - -O /tmp/gum.tar.gz
  mkdir -p /tmp/gum && tar -xzf /tmp/gum.tar.gz -C /tmp/gum
  sudo mv /tmp/gum/gum /usr/local/bin/
  rm -rf /tmp/gum /tmp/gum.tar.gz
  success "gum установлен"
fi

# ---------- Проверка pipx ----------
if ! command -v pipx &>/dev/null; then
  info "Устанавливаю pipx..."
  install_pkg python3-pip
  python3 -m pip install --user pipx
  python3 -m pipx ensurepath
fi

# ---------- GUI инструменты ----------
GUI_TOOLS=(
  "Docker Engine:install_pkg docker.io"
  "Google Cloud SDK:install_pkg google-cloud-sdk"
  "Visual Studio Code:flatpak install -y flathub com.visualstudio.code"
  "Tailscale VPN:install_pkg tailscale"
  "Ngrok Tunnel:sudo snap install ngrok"
  "PgAdmin 4:flatpak install -y flathub io.pgadmin.pgadmin4"
  "DB Browser for SQLite:flatpak install -y flathub io.github.sqlitebrowser.sqlitebrowser"
  "Lens (K8s GUI):flatpak install -y flathub dev.k8slens.OpenLens"
  # Teleport временно пропускаем из-за проблем установки
)

# ---------- CLI инструменты ----------
CLI_TOOLS=(
  "kubectl:install_pkg kubectl"
  "helm:install_pkg helm"
  "kind:install_pkg kind"
  "k9s:install_pkg k9s"
  "terraform:install_pkg terraform"
  "terragrunt:install_pkg terragrunt"
  "terraform-docs:install_pkg terraform-docs"
  "tfsec:install_pkg tfsec"
  "pre-commit:install_pkg pre-commit"
  "awscli:install_pkg awscli"
  "azure-cli:install_pkg azure-cli"
  "google-cloud-sdk:install_pkg google-cloud-sdk"
  "doctl:install_pkg doctl"
  "flyctl:install_pkg flyctl"
  "glab:install_pkg glab"
  "docker:install_pkg docker"
  "lazygit:install_pkg lazygit"
  "python/pipx:install_pkg python3 && python3 -m pip install --user pipx && pipx ensurepath"
  "fzf:install_pkg fzf"
  "bat:install_pkg bat"
  "htop:install_pkg htop"
  "ncdu:install_pkg ncdu"
  "tree:install_pkg tree"
  "yq:install_pkg yq"
  "sops:install_pkg sops"
  "tldr:install_pkg tldr"
  "eza:install_pkg eza"
  "Neovim + конфиг:install_pkg neovim && mkdir -p ~/.config/nvim/lua && curl -fsSL https://raw.githubusercontent.com/justrunme/devops-tools/main/nvim/init.lua -o ~/.config/nvim/init.lua && curl -fsSL https://raw.githubusercontent.com/justrunme/devops-tools/main/nvim/lua/plugins.lua -o ~/.config/nvim/lua/plugins.lua && git clone https://github.com/folke/lazy.nvim ~/.local/share/nvim/lazy/lazy.nvim"
)

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

# ---------- Установка инструментов ----------
for item in "${FINAL_LIST[@]}"; do
  TOOL_NAME=$(echo "$item" | cut -d ':' -f1)
  TOOL_CMD=$(echo "$item" | cut -d ':' -f2-)
  gum spin --title "Устанавливаю $TOOL_NAME..." -- bash -c "$TOOL_CMD"
  success "$TOOL_NAME установлен"
done

# ---------- Установка Oh My Zsh + DevOps плагины ----------
if [[ ! -d "$HOME/.oh-my-zsh" ]]; then
  info "Устанавливаю Oh My Zsh..."
  sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended
  git clone --depth=1 https://github.com/romkatv/powerlevel10k.git ~/.oh-my-zsh/custom/themes/powerlevel10k
  git clone https://github.com/zsh-users/zsh-autosuggestions ~/.oh-my-zsh/custom/plugins/zsh-autosuggestions
  git clone https://github.com/zsh-users/zsh-syntax-highlighting ~/.oh-my-zsh/custom/plugins/zsh-syntax-highlighting
  git clone https://github.com/zsh-users/zsh-completions ~/.oh-my-zsh/custom/plugins/zsh-completions
  git clone https://github.com/agkozak/zsh-z ~/.oh-my-zsh/custom/plugins/zsh-z
fi

info "Загружаю конфиги из GitHub..."
curl -fsSL https://raw.githubusercontent.com/justrunme/devops-tools/main/dotfiles/.zshrc -o ~/.zshrc
curl -fsSL https://raw.githubusercontent.com/justrunme/devops-tools/main/dotfiles/.p10k.zsh -o ~/.p10k.zsh
success ".zshrc и .p10k.zsh установлены"

# ---------- Смена shell на Zsh (если не в CI) ----------
if [[ "$CI" != "true" ]]; then
  info "Делаю Zsh shell'ом по умолчанию..."
  chsh -s $(which zsh)
fi

# ---------- Автоматический запуск Neovim для Lazy.nvim ----------
info "Автозапускаю Neovim (headless) для Lazy.nvim..."
nvim --headless "+Lazy! sync" +qa || true

# ---------- Финал ----------
echo -e "\n${GREEN}✅ Установка завершена!${NC}"
echo -e "${YELLOW}➡️ Проверь Neovim: nvim + :Lazy${NC}"
echo -e "${YELLOW}➡️ Перезапусти терминал или выполни: source ~/.zshrc${NC}"
