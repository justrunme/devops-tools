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
warn()    { echo -e "${YELLOW}[WARN]${NC} $1"; }

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

# ---------- Проверка CI (для Flatpak и GUI) ----------
if [[ "$CI" == "true" ]]; then
  info "CI-среда: GUI инструменты и Flatpak будут пропущены"
  MODE="cli"
  SKIP_GUI=true
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
  error "❌ Неизвестный пакетный менеджер. Поддерживаются apt, dnf, pacman."
  exit 1
fi

# ---------- Обёртка для установки пакетов ----------
install_pkg() {
  case "$PKG_MANAGER" in
    apt) sudo apt-get update && sudo apt-get install -y "$@" ;;
    dnf) sudo dnf install -y "$@" ;;
    pacman) sudo pacman -Sy --noconfirm "$@" ;;
  esac
}

# ---------- pipx + Python ----------
info "Устанавливаю pipx и Python..."
install_pkg python3 python3-pip python3-venv zsh wget curl git unzip
python3 -m pip install --user pipx
export PATH="$HOME/.local/bin:$PATH"
python3 -m pipx ensurepath || true

# ---------- gum ----------
if ! command -v gum &>/dev/null; then
  info "Устанавливаю gum..."
  GUM_VERSION="0.12.0"
  GUM_URL="https://github.com/charmbracelet/gum/releases/download/v${GUM_VERSION}/gum_${GUM_VERSION}_linux_amd64.tar.gz"
  TMP_DIR=$(mktemp -d)
  cd "$TMP_DIR"
  if curl -fsSLO "$GUM_URL"; then
    tar -xzf gum_${GUM_VERSION}_linux_amd64.tar.gz
    sudo mv gum /usr/local/bin/
    success "gum установлен"
  else
    warn "⚠️ gum не удалось скачать. Продолжим без интерактивного выбора"
  fi
  cd -
fi

# ---------- Flatpak (если не в CI) ----------
if [[ "$SKIP_GUI" != "true" && ! $(command -v flatpak) ]]; then
  info "Устанавливаю Flatpak..."
  install_pkg flatpak
  sudo flatpak remote-add --if-not-exists flathub https://flathub.org/repo/flathub.flatpakrepo || true
fi

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

# ---------- GUI инструменты (если не в CI) ----------
if [[ "$SKIP_GUI" != "true" ]]; then
  GUI_TOOLS=(
    "VSCode:flatpak install -y flathub com.visualstudio.code"
    "PgAdmin:flatpak install -y flathub io.pgadmin.pgadmin4"
    "SQLite Browser:flatpak install -y flathub io.github.sqlitebrowser.sqlitebrowser"
    "Lens:flatpak install -y flathub dev.k8slens.OpenLens"
  )
else
  GUI_TOOLS=()
fi

# ---------- Выбор инструментов ----------
select_tools() {
  if [[ -n "$MODE" ]]; then
    case "$MODE" in
      all) FINAL_LIST=("${CLI_TOOLS[@]}" "${GUI_TOOLS[@]}") ;;
      cli) FINAL_LIST=("${CLI_TOOLS[@]}") ;;
      gui) FINAL_LIST=("${GUI_TOOLS[@]}") ;;
    esac
  elif command -v gum &>/dev/null; then
    CHOICES=$(printf "%s\n\n%s\n\n%s" \
      "===== 🖥️ GUI =====" "${GUI_TOOLS[@]}" \
      "===== 🛠️ CLI =====" "${CLI_TOOLS[@]}" |
      grep -v '^$' |
      gum choose --no-limit --height=40 --header="Выбери DevOps-инструменты:")
    FINAL_LIST=($CHOICES)
  else
    FINAL_LIST=("${CLI_TOOLS[@]}")
  fi
}

select_tools

# ---------- Установка ----------
for item in "${FINAL_LIST[@]}"; do
  TOOL_NAME=$(echo "$item" | cut -d ':' -f1)
  TOOL_CMD=$(echo "$item" | cut -d ':' -f2-)
  echo -e "\n🔧 Установка: $TOOL_NAME"
  bash -c "$TOOL_CMD" && success "$TOOL_NAME установлен"
done

# ---------- Oh My Zsh ----------
if [[ ! -d "$HOME/.oh-my-zsh" ]]; then
  info "Устанавливаю Oh My Zsh..."
  if ! command -v zsh &>/dev/null; then
    error "Zsh не установлен. Установка завершена с ошибкой."
    exit 1
  fi
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

# ---------- Zsh как shell ----------
if [[ "$SHELL" != *zsh* ]]; then
  chsh -s "$(command -v zsh)" || warn "Не удалось сменить shell на zsh"
fi

# ---------- Neovim + Lazy.nvim ----------
info "Настройка Neovim..."
mkdir -p ~/.config/nvim/lua
curl -fsSL https://raw.githubusercontent.com/justrunme/devops-tools/main/nvim/init.lua -o ~/.config/nvim/init.lua
curl -fsSL https://raw.githubusercontent.com/justrunme/devops-tools/main/nvim/lua/plugins.lua -o ~/.config/nvim/lua/plugins.lua
git clone https://github.com/folke/lazy.nvim ~/.local/share/nvim/lazy/lazy.nvim || true
nvim --headless "+Lazy! sync" +qa || true

# ---------- Готово ----------
echo -e "\n${GREEN}✅ Установка завершена!${NC}"
echo -e "${YELLOW}➡️ Проверь: source ~/.zshrc и nvim + :Lazy${NC}"
