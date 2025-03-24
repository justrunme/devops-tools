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

# ---------- Безопасная обёртка для gum spin ----------
gum_spin_safe() {
  local title="$1"
  shift
  if [ -t 1 ]; then
    gum spin --title "$title" -- bash -c "$@"
  else
    echo "[INFO] $title"
    bash -c "$@"
  fi
}

# ---------- Проверка пакета ----------
detect_package_manager() {
  if command -v apt &>/dev/null; then echo "apt"
  elif command -v dnf &>/dev/null; then echo "dnf"
  elif command -v pacman &>/dev/null; then echo "pacman"
  else echo "unsupported"
  fi
}

PKG_MANAGER=$(detect_package_manager)
if [[ "$PKG_MANAGER" == "unsupported" ]]; then
  error "Неизвестный пакетный менеджер."
  exit 1
fi

install_pkg() {
  case "$PKG_MANAGER" in
    apt) sudo apt-get update && sudo apt-get install -y "$@" ;;
    dnf) sudo dnf install -y "$@" ;;
    pacman) sudo pacman -Sy --noconfirm "$@" ;;
  esac
}

# ---------- pipx, python, git ----------
install_pkg python3 python3-pip git curl unzip wget zsh
python3 -m pip install --upgrade pip
python3 -m pip install pipx --break-system-packages || true
pipx ensurepath || true

# ---------- Установка gum ----------
if ! command -v gum &>/dev/null; then
  info "Устанавливаю gum..."
  TMP_DIR=$(mktemp -d)
  GUM_VERSION="v0.14.1"
  GUM_URL="https://github.com/charmbracelet/gum/releases/download/${GUM_VERSION}/gum_${GUM_VERSION#v}_linux_amd64.tar.gz"

  if curl -fsSL "$GUM_URL" -o "$TMP_DIR/gum.tar.gz"; then
    tar -xzf "$TMP_DIR/gum.tar.gz" -C "$TMP_DIR"
    sudo mv "$TMP_DIR/gum" /usr/local/bin/gum
    sudo chmod +x /usr/local/bin/gum
    success "gum установлен"
  else
    error "Не удалось скачать gum с $GUM_URL"
    exit 1
  fi
fi

# ---------- Установка Flatpak ----------
if ! command -v flatpak &>/dev/null; then
  info "Устанавливаю Flatpak..."
  install_pkg flatpak
fi

if flatpak remotes | grep -q flathub; then
  info "Flathub уже добавлен"
else
  info "Добавляю flathub..."
  flatpak remote-add --if-not-exists flathub https://flathub.org/repo/flathub.flatpakrepo || true
fi

# ---------- GUI инструменты ----------
GUI_TOOLS=(
  "VSCode:flatpak install -y flathub com.visualstudio.code"
  "Teleport:flatpak install -y flathub com.goteleport.Teleport"
  "PgAdmin 4:flatpak install -y flathub io.pgadmin.pgadmin4"
  "DB Browser for SQLite:flatpak install -y flathub io.github.sqlitebrowser.sqlitebrowser"
  "Lens:flatpak install -y flathub dev.k8slens.OpenLens"
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
  "pre-commit:install_pkg pre-commit"
  "aws:install_pkg awscli"
  "azure-cli:install_pkg azure-cli"
  "gcloud:install_pkg google-cloud-cli"
  "doctl:install_pkg doctl"
  "flyctl:install_pkg flyctl"
  "doppler:install_pkg doppler"
  "gh:install_pkg gh"
  "glab:install_pkg glab"
  "docker:install_pkg docker.io"
  "lazygit:install_pkg lazygit"
  "bat:install_pkg bat"
  "fzf:install_pkg fzf"
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

# ---------- Установка выбранного ----------
for item in "${FINAL_LIST[@]}"; do
  TOOL_NAME=$(echo "$item" | cut -d ':' -f1)
  TOOL_CMD=$(echo "$item" | cut -d ':' -f2-)
  if [[ -n "$TOOL_CMD" ]]; then
    gum_spin_safe "Устанавливаю $TOOL_NAME..." "$TOOL_CMD"
    success "$TOOL_NAME установлен"
  fi
done

# ---------- Установка Oh My Zsh ----------
if [[ ! -d "$HOME/.oh-my-zsh" ]]; then
  info "Устанавливаю Oh My Zsh..."
  sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended
  git clone --depth=1 https://github.com/romkatv/powerlevel10k.git ~/.oh-my-zsh/custom/themes/powerlevel10k
  git clone https://github.com/zsh-users/zsh-autosuggestions ~/.oh-my-zsh/custom/plugins/zsh-autosuggestions
  git clone https://github.com/zsh-users/zsh-syntax-highlighting ~/.oh-my-zsh/custom/plugins/zsh-syntax-highlighting
  git clone https://github.com/zsh-users/zsh-completions ~/.oh-my-zsh/custom/plugins/zsh-completions
  git clone https://github.com/agkozak/zsh-z ~/.oh-my-zsh/custom/plugins/zsh-z
fi

info "Загружаю конфиги .zshrc и .p10k.zsh из GitHub..."
curl -fsSL https://raw.githubusercontent.com/justrunme/devops-tools/main/dotfiles/.zshrc -o ~/.zshrc
curl -fsSL https://raw.githubusercontent.com/justrunme/devops-tools/main/dotfiles/.p10k.zsh -o ~/.p10k.zsh
success "Конфиги загружены"

# ---------- Смена shell ----------
if [[ "$CI" != "true" ]]; then
  chsh -s "$(which zsh)"
fi

# ---------- Автозапуск Lazy.nvim ----------
info "Автозапускаю Neovim (headless) для Lazy.nvim..."
nvim --headless "+Lazy! sync" +qa || true

# ---------- Финал ----------
echo -e "\n${GREEN}✅ Установка завершена!${NC}"
echo -e "${YELLOW}➡️ source ~/.zshrc && nvim +Lazy${NC}"
