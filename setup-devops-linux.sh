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

# ---------- Безопасный gum spin ----------
gum_spin() {
  if [ -t 1 ]; then
    gum spin --title="$1" -- bash -c "$2"
  else
    echo -e "${YELLOW}[INFO]${NC} $1"
    bash -c "$2"
  fi
}

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

# ---------- Пакетный менеджер ----------
detect_pm() {
  if command -v apt &>/dev/null; then echo "apt"
  elif command -v dnf &>/dev/null; then echo "dnf"
  elif command -v pacman &>/dev/null; then echo "pacman"
  else error "Не поддерживается пакетный менеджер"; exit 1
  fi
}
PM=$(detect_pm)

# ---------- Установка пакетов ----------
install_pkg() {
  case "$PM" in
    apt) sudo apt-get install -y "$@" ;;
    dnf) sudo dnf install -y "$@" ;;
    pacman) sudo pacman -S --noconfirm "$@" ;;
  esac
}

# ---------- Установка базовых зависимостей ----------
info "Установка базовых пакетов..."
install_pkg curl wget git unzip zsh python3 python3-pip flatpak

# ---------- Установка pipx ----------
if ! command -v pipx &>/dev/null; then
  info "Установка pipx..."
  python3 -m pip install --user pipx
  python3 -m pipx ensurepath
fi

# ---------- Установка Gum ----------
if ! command -v gum &>/dev/null; then
  info "Установка gum..."
  GUM_URL=$(curl -s https://api.github.com/repos/charmbracelet/gum/releases/latest \
    | grep browser_download_url | grep linux_amd64.tar.gz | cut -d '"' -f 4)
  if [[ -z "$GUM_URL" ]]; then
    GUM_URL="https://github.com/charmbracelet/gum/releases/download/v0.13.0/gum_0.13.0_Linux_x86_64.tar.gz"
  fi
  curl -sL "$GUM_URL" | sudo tar -C /usr/local/bin -xz gum
fi

# ---------- Flatpak flathub ----------
gum_spin "Добавляю flathub..." "sudo flatpak remote-add --if-not-exists flathub https://flathub.org/repo/flathub.flatpakrepo"

# ---------- GUI инструменты (Flatpak для user) ----------
GUI_TOOLS=(
  "VSCode:flatpak install -y flathub com.visualstudio.code"
  "Teleport:curl https://goteleport.com/static/install.sh | bash"
  "PgAdmin 4:flatpak install -y flathub io.pgadmin.pgadmin4"
  "DB Browser for SQLite:flatpak install -y flathub io.github.sqlitebrowser.sqlitebrowser"
  "Lens (K8s GUI):flatpak install -y flathub dev.k8slens.OpenLens"
)

# ---------- CLI инструменты ----------
CLI_TOOLS=(
  "kubectl:install_pkg kubectl"
  "helm:install_pkg helm"
  "k9s:install_pkg k9s"
  "kind:install_pkg kind"
  "terraform:install_pkg terraform"
  "terragrunt:install_pkg terragrunt"
  "terraform-docs:install_pkg terraform-docs"
  "tfsec:install_pkg tfsec"
  "awscli:install_pkg awscli"
  "azure-cli:install_pkg azure-cli"
  "google-cloud-sdk:install_pkg google-cloud-cli"
  "docker:install_pkg docker.io"
  "lazygit:install_pkg lazygit"
  "fzf:install_pkg fzf"
  "bat:install_pkg bat"
  "htop:install_pkg htop"
  "ncdu:install_pkg ncdu"
  "tree:install_pkg tree"
  "pre-commit:pipx install pre-commit"
  "doctl:pipx install doctl"
  "flyctl:pipx install flyctl"
  "sops:pipx install sops"
  "tldr:pipx install tldr"
  "yq:pipx install yq"
  "eza:install_pkg eza"
  "neovim:install_pkg neovim && mkdir -p ~/.config/nvim/lua && curl -fsSL https://raw.githubusercontent.com/justrunme/devops-tools/main/nvim/init.lua -o ~/.config/nvim/init.lua && curl -fsSL https://raw.githubusercontent.com/justrunme/devops-tools/main/nvim/lua/plugins.lua -o ~/.config/nvim/lua/plugins.lua && git clone https://github.com/folke/lazy.nvim ~/.local/share/nvim/lazy/lazy.nvim"
)

# ---------- Выбор инструментов ----------
if [[ "$MODE" == "" ]]; then
  CHOICES=$(printf "%s\n\n%s\n\n%s" \
    "===== 🖥️ GUI =====" "${GUI_TOOLS[@]}" \
    "===== 🛠️ CLI =====" "${CLI_TOOLS[@]}" |
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
  gum_spin "Устанавливаю $TOOL_NAME..." "$TOOL_CMD"
  success "$TOOL_NAME установлен"
done

# ---------- Oh My Zsh ----------
if [[ ! -d "$HOME/.oh-my-zsh" ]]; then
  info "Устанавливаю Oh My Zsh..."
  RUNZSH=no CHSH=no sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"
  git clone https://github.com/romkatv/powerlevel10k.git ~/.oh-my-zsh/custom/themes/powerlevel10k
  git clone https://github.com/zsh-users/zsh-autosuggestions ~/.oh-my-zsh/custom/plugins/zsh-autosuggestions
  git clone https://github.com/zsh-users/zsh-syntax-highlighting ~/.oh-my-zsh/custom/plugins/zsh-syntax-highlighting
  git clone https://github.com/zsh-users/zsh-completions ~/.oh-my-zsh/custom/plugins/zsh-completions
  git clone https://github.com/agkozak/zsh-z ~/.oh-my-zsh/custom/plugins/zsh-z
fi

info "Загружаю .zshrc и .p10k.zsh..."
curl -fsSL https://raw.githubusercontent.com/justrunme/devops-tools/main/dotfiles/.zshrc -o ~/.zshrc
curl -fsSL https://raw.githubusercontent.com/justrunme/devops-tools/main/dotfiles/.p10k.zsh -o ~/.p10k.zsh

# ---------- Установка Zsh по умолчанию ----------
if [ "$CI" != "true" ]; then
  info "Делаю Zsh shell'ом по умолчанию..."
  sudo chsh -s "$(which zsh)" "$(whoami)"
fi

# ---------- Neovim Lazy.nvim ----------
info "Запускаю Neovim для Lazy.nvim..."
nvim --headless "+Lazy! sync" +qa || true

# ---------- Завершение ----------
success "✅ Установка завершена!"
echo -e "${YELLOW}➡️ Проверь: source ~/.zshrc и nvim + :Lazy${NC}"
