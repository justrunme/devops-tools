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
    apt)
      sudo apt-get update
      sudo apt-get install -y "$@"
      ;;
    dnf)
      sudo dnf install -y "$@"
      ;;
    pacman)
      sudo pacman -Syu --noconfirm "$@"
      ;;
  esac
}

# ---------- Установка необходимых базовых пакетов ----------
info "Устанавливаю базовые пакеты..."
install_pkg curl wget unzip git zsh sudo

# ---------- Установка pipx + python ----------
if ! command -v pipx &>/dev/null; then
  info "Устанавливаю pipx..."
  install_pkg python3 python3-pip
  python3 -m pip install --user pipx
  python3 -m pipx ensurepath
  export PATH="$HOME/.local/bin:$PATH"
fi

# ---------- Установка gum ----------
if ! command -v gum &>/dev/null; then
  info "Устанавливаю gum..."
  GUM_VERSION="v0.14.1"
  GUM_TAR="gum_${GUM_VERSION#v}_Linux_x86_64.tar.gz"
  GUM_URL="https://github.com/charmbracelet/gum/releases/download/${GUM_VERSION}/${GUM_TAR}"
  TMP_DIR=$(mktemp -d)

  if curl -fsSL "$GUM_URL" -o "$TMP_DIR/$GUM_TAR"; then
    tar -xzf "$TMP_DIR/$GUM_TAR" -C "$TMP_DIR"
    GUM_BIN=$(find "$TMP_DIR" -type f -name gum | head -n1)
    if [[ -f "$GUM_BIN" ]]; then
      sudo mv "$GUM_BIN" /usr/local/bin/gum
      sudo chmod +x /usr/local/bin/gum
      success "gum установлен"
    else
      error "Не удалось найти бинарник gum в архиве"
      exit 1
    fi
  else
    error "Не удалось скачать gum с $GUM_URL"
    exit 1
  fi
fi

# ---------- GUI инструменты через Flatpak ----------
if ! command -v flatpak &>/dev/null; then
  info "Устанавливаю Flatpak..."
  install_pkg flatpak
fi

if flatpak remotes | grep -q flathub; then
  info "Flathub уже добавлен"
else
  info "Добавляю flathub..."
  sudo flatpak remote-add --if-not-exists flathub https://flathub.org/repo/flathub.flatpakrepo || true
fi

GUI_TOOLS=(
  "VSCode:flatpak install -y flathub com.visualstudio.code"
  "Teleport:flatpak install -y flathub com.goteleport.Teleport"
  "PgAdmin 4:flatpak install -y flathub io.pgadmin.pgadmin4"
  "DB Browser for SQLite:flatpak install -y flathub io.github.sqlitebrowser.sqlitebrowser"
  "Lens (K8s GUI):flatpak install -y flathub dev.k8slens.OpenLens"
)

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

# ---------- Установка выбранных инструментов ----------
for item in "${FINAL_LIST[@]}"; do
  TOOL_NAME=$(echo "$item" | cut -d ':' -f1)
  TOOL_CMD=$(echo "$item" | cut -d ':' -f2-)
  gum spin --title "Устанавливаю $TOOL_NAME..." -- bash -c "$TOOL_CMD"
  success "$TOOL_NAME установлен"
done

# ---------- Установка Oh My Zsh и плагинов ----------
if [[ ! -d "$HOME/.oh-my-zsh" ]]; then
  info "Устанавливаю Oh My Zsh..."
  sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended
  git clone --depth=1 https://github.com/romkatv/powerlevel10k.git ~/.oh-my-zsh/custom/themes/powerlevel10k
  git clone https://github.com/zsh-users/zsh-autosuggestions ~/.oh-my-zsh/custom/plugins/zsh-autosuggestions
  git clone https://github.com/zsh-users/zsh-syntax-highlighting ~/.oh-my-zsh/custom/plugins/zsh-syntax-highlighting
  git clone https://github.com/zsh-users/zsh-completions ~/.oh-my-zsh/custom/plugins/zsh-completions
  git clone https://github.com/agkozak/zsh-z ~/.oh-my-zsh/custom/plugins/zsh-z
fi

# ---------- Конфиги Oh My Zsh ----------
info "Подгружаю .zshrc и .p10k.zsh из GitHub..."
curl -fsSL https://raw.githubusercontent.com/justrunme/devops-tools/main/dotfiles/.zshrc -o ~/.zshrc
curl -fsSL https://raw.githubusercontent.com/justrunme/devops-tools/main/dotfiles/.p10k.zsh -o ~/.p10k.zsh
success "Конфиги установлены"

# ---------- chsh (смена shell) ----------
if [[ "$SHELL" != *zsh && "$CI" != "true" ]]; then
  info "Меняю shell на Zsh..."
  chsh -s "$(which zsh)"
fi

# ---------- Lazy.nvim ----------
info "Устанавливаю Lazy.nvim и конфиги Neovim..."
mkdir -p ~/.config/nvim/lua
curl -fsSL https://raw.githubusercontent.com/justrunme/devops-tools/main/nvim/init.lua -o ~/.config/nvim/init.lua
curl -fsSL https://raw.githubusercontent.com/justrunme/devops-tools/main/nvim/lua/plugins.lua -o ~/.config/nvim/lua/plugins.lua
git clone https://github.com/folke/lazy.nvim ~/.local/share/nvim/lazy/lazy.nvim

info "Синхронизирую плагины Neovim..."
nvim --headless "+Lazy! sync" +qa || true

# ---------- Финал ----------
echo -e "\n${GREEN}✅ Установка завершена!${NC}"
echo -e "${YELLOW}➡️ Перезапусти терминал или выполни: source ~/.zshrc${NC}"
echo -e "${YELLOW}➡️ Проверь Neovim: nvim + :Lazy${NC}"
