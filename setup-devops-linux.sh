#!/usr/bin/env bash
set -e

# ---------- Цвета ----------
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

# ---------- Установка базовых утилит ----------
info "Обновляю пакеты и устанавливаю unzip, curl, wget..."
if [[ "$PKG_MANAGER" == "apt" ]]; then
  sudo apt-get update
fi
install_pkg unzip curl wget git

# ---------- Установка gum ----------
if ! command -v gum &>/dev/null; then
  info "Устанавливаю gum..."
  GUM_DEB=$(curl -s https://api.github.com/repos/charmbracelet/gum/releases/latest \
    | grep browser_download_url \
    | grep "gum_.*_linux_amd64.deb" \
    | cut -d '"' -f 4 | head -n1)

  if [[ -z "$GUM_DEB" ]]; then
    error "Не удалось получить ссылку на gum .deb файл"
    exit 1
  fi

  wget -O /tmp/gum.deb "$GUM_DEB"
  sudo dpkg -i /tmp/gum.deb || sudo apt-get install -f -y
  rm -f /tmp/gum.deb
fi

# ---------- Установка pipx + python ----------
if ! command -v pipx &>/dev/null; then
  info "Устанавливаю pipx и python..."
  install_pkg python3 python3-pip
  python3 -m pip install --user pipx
  python3 -m pipx ensurepath
fi

# ---------- Установка Flatpak ----------
if ! command -v flatpak &>/dev/null; then
  info "Устанавливаю Flatpak..."
  install_pkg flatpak
  flatpak remote-add --if-not-exists flathub https://flathub.org/repo/flathub.flatpakrepo || true
fi

# ---------- Установка Homebrew (Linuxbrew) ----------
if ! command -v brew &>/dev/null; then
  info "Устанавливаю Homebrew..."
  NONINTERACTIVE=1 /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
  eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)"
  echo 'eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)"' >> ~/.profile
fi

# ---------- GUI инструменты (через flatpak) ----------
GUI_TOOLS=(
  "VSCode:flatpak install -y flathub com.visualstudio.code"
  "Teleport:flatpak install -y flathub com.goteleport.Teleport"
  "PgAdmin 4:flatpak install -y flathub io.pgadmin.pgadmin4"
  "DB Browser for SQLite:flatpak install -y flathub io.github.sqlitebrowser.sqlitebrowser"
  "Lens:flatpak install -y flathub dev.k8slens.OpenLens"
)

# ---------- CLI инструменты (через apt/dnf/pacman/brew) ----------
CLI_TOOLS=(
  "kubectl:brew install kubectl"
  "helm:brew install helm"
  "k9s:brew install k9s"
  "terraform:brew install terraform"
  "terragrunt:brew install terragrunt"
  "tfsec:brew install tfsec"
  "terraform-docs:brew install terraform-docs"
  "pre-commit:brew install pre-commit"
  "awscli:brew install awscli"
  "azure-cli:brew install azure-cli"
  "google-cloud-sdk:brew install --cask google-cloud-sdk"
  "doctl:brew install doctl"
  "flyctl:brew install flyctl"
  "doppler:brew install doppler"
  "gh:brew install gh"
  "glab:brew install glab"
  "docker:brew install docker"
  "lazygit:brew install lazygit"
  "bat:brew install bat"
  "fzf:brew install fzf"
  "htop:brew install htop"
  "ncdu:brew install ncdu"
  "tree:brew install tree"
  "yq:brew install yq"
  "sops:brew install sops"
  "tldr:brew install tldr"
  "eza:brew install eza"
  "neovim + конфиг:brew install neovim && mkdir -p ~/.config/nvim/lua && curl -fsSL https://raw.githubusercontent.com/justrunme/devops-tools/main/nvim/init.lua -o ~/.config/nvim/init.lua && curl -fsSL https://raw.githubusercontent.com/justrunme/devops-tools/main/nvim/lua/plugins.lua -o ~/.config/nvim/lua/plugins.lua && git clone https://github.com/folke/lazy.nvim ~/.local/share/nvim/lazy/lazy.nvim"
)

# ---------- Выбор инструментов ----------
if [[ "$MODE" == "" ]]; then
  CHOICES=$(printf "%s\n\n%s\n\n%s" \
    "===== GUI =====" "${GUI_TOOLS[@]}" \
    "===== CLI =====" "${CLI_TOOLS[@]}" |
    grep -v '^$' |
    gum choose --no-limit --height=40 --header="Выбери DevOps-инструменты:")
  FINAL_LIST=($CHOICES)
elif [[ "$MODE" == "all" ]]; then
  FINAL_LIST=("${GUI_TOOLS[@]}" "${CLI_TOOLS[@]}")
elif [[ "$MODE" == "gui" ]]; then
  FINAL_LIST=("${GUI_TOOLS[@]}")
elif [[ "$MODE" == "cli" ]]; then
  FINAL_LIST=("${CLI_TOOLS[@]}")
fi

# ---------- Установка ----------
for item in "${FINAL_LIST[@]}"; do
  TOOL_NAME=$(echo "$item" | cut -d ':' -f1)
  TOOL_CMD=$(echo "$item" | cut -d ':' -f2-)
  gum spin --title "Устанавливаю $TOOL_NAME..." -- bash -c "$TOOL_CMD"
  success "$TOOL_NAME установлен"
done

# ---------- Oh My Zsh и DevOps-плагины ----------
if [[ ! -d "$HOME/.oh-my-zsh" ]]; then
  info "Устанавливаю Oh My Zsh и плагины..."
  sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended
  git clone --depth=1 https://github.com/romkatv/powerlevel10k.git ~/.oh-my-zsh/custom/themes/powerlevel10k
  git clone https://github.com/zsh-users/zsh-autosuggestions ~/.oh-my-zsh/custom/plugins/zsh-autosuggestions
  git clone https://github.com/zsh-users/zsh-syntax-highlighting ~/.oh-my-zsh/custom/plugins/zsh-syntax-highlighting
  git clone https://github.com/zsh-users/zsh-completions ~/.oh-my-zsh/custom/plugins/zsh-completions
  git clone https://github.com/agkozak/zsh-z ~/.oh-my-zsh/custom/plugins/zsh-z
fi

info "Загружаю .zshrc и .p10k.zsh..."
curl -fsSL https://raw.githubusercontent.com/justrunme/devops-tools/main/dotfiles/.zshrc -o ~/.zshrc
curl -fsSL https://raw.githubusercontent.com/justrunme/devops-tools/main/dotfiles/.p10k.zsh -o ~/.p10k.zsh
success "Конфиги установлены"

# ---------- Смена shell ----------
if [[ "$CI" != "true" ]]; then
  info "Делаю Zsh shell'ом по умолчанию..."
  chsh -s "$(which zsh)" || true
fi

# ---------- Lazy.nvim sync ----------
info "Синхронизация Lazy.nvim (headless)..."
nvim --headless "+Lazy! sync" +qa || true

# ---------- Финал ----------
echo -e "\n${GREEN}✅ Установка завершена!${NC}"
echo -e "${YELLOW}➡️ Проверь: nvim + :Lazy и source ~/.zshrc${NC}"
