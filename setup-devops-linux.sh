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
  if command -v apt &>/dev/null; then echo "apt"
  elif command -v dnf &>/dev/null; then echo "dnf"
  elif command -v pacman &>/dev/null; then echo "pacman"
  else echo "unsupported"
  fi
}
PKG_MANAGER=$(detect_package_manager)
if [[ "$PKG_MANAGER" == "unsupported" ]]; then
  error "Неизвестный пакетный менеджер. Поддерживаются apt, dnf, pacman."
  exit 1
fi

# ---------- Утилита установки ----------
install_pkg() {
  case "$PKG_MANAGER" in
    apt) sudo apt-get install -y "$@" ;;
    dnf) sudo dnf install -y "$@" ;;
    pacman) sudo pacman -S --noconfirm "$@" ;;
  esac
}

# ---------- Обязательные зависимости ----------
info "Устанавливаю базовые пакеты..."
install_pkg curl wget git unzip neovim zsh

# ---------- Установка gum ----------
if ! command -v gum &>/dev/null; then
  info "Устанавливаю gum..."
  GUM_URL=$(curl -s https://api.github.com/repos/charmbracelet/gum/releases/latest |
    grep browser_download_url | grep linux_amd64.deb | cut -d '"' -f 4 | head -n1)

  if [[ -z "$GUM_URL" ]]; then
    echo -e "${YELLOW}[WARN]${NC} Не удалось получить .deb файл gum. Использую fallback версию..."
    GUM_URL="https://github.com/charmbracelet/gum/releases/download/v0.13.0/gum_0.13.0_linux_amd64.deb"
  fi

  wget -q "$GUM_URL" -O gum.deb
  sudo dpkg -i gum.deb
  rm -f gum.deb
  success "gum установлен"
fi

# ---------- Установка pipx ----------
if ! command -v pipx &>/dev/null; then
  info "Устанавливаю pipx..."
  install_pkg python3-pip
  python3 -m pip install --user pipx
  python3 -m pipx ensurepath
fi

# ---------- Установка Homebrew (по желанию) ----------
if ! command -v brew &>/dev/null; then
  info "Устанавливаю Homebrew..."
  NONINTERACTIVE=1 bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
  eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)"
fi

# ---------- Установка Flatpak ----------
if ! command -v flatpak &>/dev/null; then
  info "Устанавливаю Flatpak..."
  install_pkg flatpak
  flatpak remote-add --if-not-exists flathub https://flathub.org/repo/flathub.flatpakrepo || true
fi

# ---------- GUI инструменты ----------
GUI_TOOLS=(
  "VSCode:flatpak install --noninteractive --user -y flathub com.visualstudio.code"
  "Teleport:flatpak install --noninteractive --user -y flathub com.goteleport.Teleport"
  "PgAdmin 4:flatpak install --noninteractive --user -y flathub io.pgadmin.pgadmin4"
  "DB Browser for SQLite:flatpak install --noninteractive --user -y flathub io.github.sqlitebrowser.sqlitebrowser"
  "Lens (K8s GUI):flatpak install --noninteractive --user -y flathub dev.k8slens.OpenLens"
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
  "tldr:install_pkg tldr"
  "eza:install_pkg eza"
  "yq:install_pkg yq"
  "sops:install_pkg sops"
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

# ---------- Oh My Zsh ----------
if [[ ! -d "$HOME/.oh-my-zsh" ]]; then
  info "Устанавливаю Oh My Zsh..."
  sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended
  git clone --depth=1 https://github.com/romkatv/powerlevel10k.git ~/.oh-my-zsh/custom/themes/powerlevel10k
  git clone https://github.com/zsh-users/zsh-autosuggestions ~/.oh-my-zsh/custom/plugins/zsh-autosuggestions
  git clone https://github.com/zsh-users/zsh-syntax-highlighting ~/.oh-my-zsh/custom/plugins/zsh-syntax-highlighting
  git clone https://github.com/zsh-users/zsh-completions ~/.oh-my-zsh/custom/plugins/zsh-completions
  git clone https://github.com/agkozak/zsh-z ~/.oh-my-zsh/custom/plugins/zsh-z
fi

# ---------- Конфиги из GitHub ----------
info "Подгружаю .zshrc и .p10k.zsh из GitHub..."
curl -fsSL https://raw.githubusercontent.com/justrunme/devops-tools/main/dotfiles/.zshrc -o ~/.zshrc
curl -fsSL https://raw.githubusercontent.com/justrunme/devops-tools/main/dotfiles/.p10k.zsh -o ~/.p10k.zsh
success "Zsh-конфиги установлены"

# ---------- Конфиги Neovim ----------
mkdir -p ~/.config/nvim/lua
curl -fsSL https://raw.githubusercontent.com/justrunme/devops-tools/main/nvim/init.lua -o ~/.config/nvim/init.lua
curl -fsSL https://raw.githubusercontent.com/justrunme/devops-tools/main/nvim/lua/plugins.lua -o ~/.config/nvim/lua/plugins.lua
git clone https://github.com/folke/lazy.nvim ~/.local/share/nvim/lazy/lazy.nvim || true

# ---------- Сменить shell на Zsh ----------
if [[ "$SHELL" != "$(which zsh)" ]]; then
  info "Делаю zsh shell'ом по умолчанию..."
  chsh -s "$(which zsh)" || echo -e "${YELLOW}[WARN] Не удалось сменить shell — возможно не интерактивная сессия.${NC}"
fi

# ---------- Neovim Lazy sync ----------
info "Синхронизирую плагины Neovim (Lazy.nvim)..."
nvim --headless "+Lazy! sync" +qa || true

# ---------- Финал ----------
echo -e "\n${GREEN}✅ Установка завершена!${NC}"
echo -e "${YELLOW}➡️ Проверь: nvim + :Lazy и source ~/.zshrc${NC}"
