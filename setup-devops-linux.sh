#!/usr/bin/env bash
set -e

# ---------- Цвета ----------
GREEN="\033[0;32m"
YELLOW="\033[1;33m"
RED="\033[0;31m"
NC="\033[0m"
info()    { echo -e "${YELLOW}[INFO]${NC} $1"; }
success() { echo -e "${GREEN}[OK]${NC} $1"; }
error()   { echo -e "${RED}[ERROR]${NC} $1"; exit 1; }

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
  if command -v apt &>/dev/null; then echo "apt"
  elif command -v dnf &>/dev/null; then echo "dnf"
  elif command -v pacman &>/dev/null; then echo "pacman"
  else echo "unsupported"
  fi
}

PKG_MANAGER=$(detect_package_manager)
if [[ "$PKG_MANAGER" == "unsupported" ]]; then
  error "Неизвестный пакетный менеджер. Поддерживаются apt, dnf, pacman."
fi

# ---------- Обёртка установки пакетов ----------
install_pkg() {
  case "$PKG_MANAGER" in
    apt) sudo apt-get update && sudo apt-get install -y "$@" ;;
    dnf) sudo dnf install -y "$@" ;;
    pacman) sudo pacman -Syu --noconfirm "$@" ;;
  esac
}

# ---------- pipx + python + git ----------
info "Устанавливаю python, pipx и git..."
install_pkg python3 python3-pip python3-venv wget unzip git curl zsh

python3 -m pip install --upgrade pip
python3 -m pip install pipx
pipx ensurepath

# ---------- Установка gum ----------
GUM_VERSION="0.14.1"
GUM_DEB="gum_${GUM_VERSION}_amd64.deb"
GUM_URL="https://github.com/charmbracelet/gum/releases/download/v${GUM_VERSION}/${GUM_DEB}"

if ! command -v gum &>/dev/null; then
  info "Устанавливаю gum v$GUM_VERSION..."
  wget -q "$GUM_URL" -O "/tmp/$GUM_DEB" || error "Не удалось скачать gum.deb с $GUM_URL"
  sudo dpkg -i "/tmp/$GUM_DEB" || sudo apt-get -f install -y
  success "gum установлен"
fi

# ---------- Установка Flatpak ----------
if ! command -v flatpak &>/dev/null; then
  info "Устанавливаю flatpak..."
  install_pkg flatpak
fi

if flatpak remote-list | grep -q flathub; then
  success "flathub уже добавлен"
else
  info "Добавляю flathub..."
  sudo flatpak remote-add --if-not-exists flathub https://flathub.org/repo/flathub.flatpakrepo
fi

# ---------- GUI инструменты ----------
GUI_TOOLS=(
  "VSCode:flatpak install -y flathub com.visualstudio.code"
  "Teleport:flatpak install -y flathub com.goteleport.Teleport"
  "PgAdmin 4:flatpak install -y flathub io.pgadmin.pgadmin4"
  "DB Browser for SQLite:flatpak install -y flathub io.github.sqlitebrowser.sqlitebrowser"
  "Lens (K8s GUI):flatpak install -y flathub dev.k8slens.OpenLens"
)

# ---------- CLI инструменты ----------
CLI_TOOLS=(
  "kubectl:install_pkg kubectl"
  "helm:install_pkg helm"
  "k9s:install_pkg k9s"
  "terraform:install_pkg terraform"
  "terragrunt:install_pkg terragrunt"
  "terraform-docs:install_pkg terraform-docs"
  "tfsec:install_pkg tfsec"
  "aws:install_pkg awscli"
  "gcloud:install_pkg google-cloud-cli"
  "az:install_pkg azure-cli"
  "docker:install_pkg docker.io"
  "doctl:install_pkg doctl"
  "flyctl:install_pkg flyctl"
  "glab:install_pkg glab"
  "pre-commit:install_pkg pre-commit"
  "lazygit:install_pkg lazygit"
  "fzf:install_pkg fzf"
  "bat:install_pkg bat"
  "htop:install_pkg htop"
  "ncdu:install_pkg ncdu"
  "tree:install_pkg tree"
  "yq:install_pkg yq"
  "sops:install_pkg sops"
  "tldr:install_pkg tldr"
  "eza:install_pkg eza"
  "neovim:install_pkg neovim && mkdir -p ~/.config/nvim/lua && curl -fsSL https://raw.githubusercontent.com/justrunme/devops-tools/main/nvim/init.lua -o ~/.config/nvim/init.lua && curl -fsSL https://raw.githubusercontent.com/justrunme/devops-tools/main/nvim/lua/plugins.lua -o ~/.config/nvim/lua/plugins.lua && git clone https://github.com/folke/lazy.nvim ~/.local/share/nvim/lazy/lazy.nvim"
)

# ---------- Выбор инструментов ----------
if [[ "$MODE" == "" ]]; then
  CHOICES=$(printf "%s\n\n%s\n\n%s" \
    "===== 🖥️ GUI инструменты =====" "${GUI_TOOLS[@]}" \
    "===== 🛠️ CLI инструменты =====" "${CLI_TOOLS[@]}" |
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
  if [[ -n "$TOOL_CMD" ]]; then
    gum spin --title "Устанавливаю $TOOL_NAME..." -- bash -c "$TOOL_CMD"
    success "$TOOL_NAME установлен"
  fi
done

# ---------- Oh My Zsh + плагины ----------
if [[ ! -d "$HOME/.oh-my-zsh" ]]; then
  info "Устанавливаю Oh My Zsh..."
  sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended
  git clone --depth=1 https://github.com/romkatv/powerlevel10k.git ~/.oh-my-zsh/custom/themes/powerlevel10k
  git clone https://github.com/zsh-users/zsh-autosuggestions ~/.oh-my-zsh/custom/plugins/zsh-autosuggestions
  git clone https://github.com/zsh-users/zsh-syntax-highlighting ~/.oh-my-zsh/custom/plugins/zsh-syntax-highlighting
  git clone https://github.com/zsh-users/zsh-completions ~/.oh-my-zsh/custom/plugins/zsh-completions
  git clone https://github.com/agkozak/zsh-z ~/.oh-my-zsh/custom/plugins/zsh-z
fi

info "Подгружаю .zshrc и .p10k.zsh из GitHub..."
curl -fsSL https://raw.githubusercontent.com/justrunme/devops-tools/main/dotfiles/.zshrc -o ~/.zshrc
curl -fsSL https://raw.githubusercontent.com/justrunme/devops-tools/main/dotfiles/.p10k.zsh -o ~/.p10k.zsh
success "Конфиги установлены"

# ---------- Смена shell ----------
if [[ "$CI" != "true" ]]; then
  info "Меняю shell на Zsh..."
  chsh -s "$(which zsh)"
fi

# ---------- Neovim Lazy.nvim ----------
info "Автозапуск Neovim + Lazy.nvim..."
nvim --headless "+Lazy! sync" +qa || true

# ---------- Финал ----------
echo -e "\n${GREEN}✅ Установка завершена!${NC}"
echo -e "${YELLOW}➡️ Проверь: source ~/.zshrc и nvim + :Lazy${NC}"
