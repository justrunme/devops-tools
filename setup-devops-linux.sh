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

# ---------- Установка gum ----------
if ! command -v gum &>/dev/null; then
  info "Устанавливаю gum..."
  if [[ "$PKG_MANAGER" == "apt" ]]; then
    sudo mkdir -p /etc/apt/keyrings
    sudo apt-get update && sudo apt-get install -y unzip curl
    curl -s https://api.github.com/repos/charmbracelet/gum/releases/latest \
      | grep browser_download_url \
      | grep linux_amd64.deb \
      | cut -d '"' -f 4 \
      | wget -qi -
    sudo dpkg -i gum_*_linux_amd64.deb
  else
    install_pkg gum
  fi
fi

# ---------- Проверка Flatpak ----------
if ! command -v flatpak &>/dev/null; then
  info "Устанавливаю Flatpak..."
  install_pkg flatpak
  flatpak remote-add --if-not-exists flathub https://flathub.org/repo/flathub.flatpakrepo
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
  "lazygit:install_pkg lazygit"
  "fzf:install_pkg fzf"
  "bat:install_pkg bat"
  "htop:install_pkg htop"
  "ncdu:install_pkg ncdu"
  "tree:install_pkg tree"
  "neovim:install_pkg neovim"
)

# ---------- Выбор инструментов ----------
if [[ "$MODE" == "" ]]; then
  CHOICES=$(printf "%s\n\n%s\n\n%s" \
    "===== 🖥️ GUI инструменты =====" "${GUI_TOOLS[@]}" \
    "===== 🛠️ CLI инструменты =====" "${CLI_TOOLS[@]}" |
    grep -v '^$' |
    gum choose --no-limit --height=40 --header="Выбери инструменты:")
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

# ---------- Установка Oh My Zsh + плагины ----------
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
success "Конфиги загружены"

# ---------- Автозапуск Neovim Lazy.nvim ----------
info "Автозапускаю Neovim (headless) для Lazy.nvim..."
nvim --headless "+Lazy! sync" +qa || true

# ---------- Финал ----------
echo -e "\n${GREEN}✅ Установка завершена!${NC}"
echo -e "${YELLOW}➡️ Проверь: nvim + :Lazy и source ~/.zshrc${NC}"
