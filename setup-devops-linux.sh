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

install_pkg() {
  case "$PKG_MANAGER" in
    apt) sudo apt-get update && sudo apt-get install -y "$@" ;;
    dnf) sudo dnf install -y "$@" ;;
    pacman) sudo pacman -Syu --noconfirm "$@" ;;
  esac
}

# ---------- Установка zsh ----------
if ! command -v zsh &>/dev/null; then
  info "Устанавливаю zsh..."
  install_pkg zsh
fi

# ---------- Установка python, pipx ----------
install_pkg python3 python3-pip
python3 -m pip install --user pipx
python3 -m pipx ensurepath
export PATH="$HOME/.local/bin:$PATH"

# ---------- Установка gum ----------
if ! command -v gum &>/dev/null; then
  info "Устанавливаю gum..."
  GUM_VERSION="0.12.0"
  GUM_URL="https://github.com/charmbracelet/gum/releases/download/v${GUM_VERSION}/gum_${GUM_VERSION}_linux_amd64.tar.gz"
  TMP_DIR=$(mktemp -d)
  cd "$TMP_DIR"
  if curl -fsSL "$GUM_URL" -o gum.tar.gz; then
    tar -xzf gum.tar.gz
    sudo mv gum /usr/local/bin/
    success "gum установлен"
  else
    error "Не удалось скачать gum с $GUM_URL"
    exit 1
  fi
  cd - >/dev/null
fi

# ---------- Установка flatpak ----------
if ! command -v flatpak &>/dev/null; then
  info "Устанавливаю Flatpak..."
  install_pkg flatpak
fi

# ---------- GUI TOOLS ----------
GUI_TOOLS=(
  "VSCode:flatpak install -y flathub com.visualstudio.code"
  "Teleport:flatpak install -y flathub com.goteleport.Teleport"
  "PgAdmin 4:flatpak install -y flathub io.pgadmin.pgadmin4"
  "DB Browser for SQLite:flatpak install -y flathub io.github.sqlitebrowser.sqlitebrowser"
  "Lens (K8s GUI):flatpak install -y flathub dev.k8slens.OpenLens"
)

# ---------- CLI TOOLS ----------
CLI_TOOLS=(
  "kubectl:install_pkg kubectl"
  "helm:install_pkg helm"
  "k9s:install_pkg k9s"
  "terraform:curl -fsSL https://releases.hashicorp.com/terraform/1.7.5/terraform_1.7.5_linux_amd64.zip -o tf.zip && unzip tf.zip && sudo mv terraform /usr/local/bin/"
  "terragrunt:curl -L https://github.com/gruntwork-io/terragrunt/releases/latest/download/terragrunt_linux_amd64 -o terragrunt && chmod +x terragrunt && sudo mv terragrunt /usr/local/bin/"
  "terraform-docs:curl -sSL https://github.com/terraform-docs/terraform-docs/releases/latest/download/terraform-docs-linux-amd64.tar.gz | tar -xz && sudo mv terraform-docs /usr/local/bin/"
  "tfsec:curl -s https://raw.githubusercontent.com/aquasecurity/tfsec/master/scripts/install_linux.sh | bash"
  "glab:curl -s https://raw.githubusercontent.com/profclems/glab/trunk/scripts/install.sh | bash"
  "lazygit:install_pkg lazygit"
  "bat:install_pkg bat"
  "fzf:install_pkg fzf"
  "htop:install_pkg htop"
  "ncdu:install_pkg ncdu"
  "tree:install_pkg tree"
  "pre-commit:pipx install pre-commit"
  "doctl:curl -sL https://github.com/digitalocean/doctl/releases/latest/download/doctl-$(uname -s)-$(uname -m).tar.gz | tar -xz && sudo mv doctl /usr/local/bin/"
  "flyctl:curl -L https://fly.io/install.sh | sh"
  "sops:install_pkg sops"
  "tldr:npm install -g tldr || sudo npm install -g tldr"
  "yq:install_pkg yq"
  "eza:install_pkg eza"
  "neovim:install_pkg neovim && mkdir -p ~/.config/nvim/lua && curl -fsSL https://raw.githubusercontent.com/justrunme/devops-tools/main/nvim/init.lua -o ~/.config/nvim/init.lua && curl -fsSL https://raw.githubusercontent.com/justrunme/devops-tools/main/nvim/lua/plugins.lua -o ~/.config/nvim/lua/plugins.lua && git clone https://github.com/folke/lazy.nvim ~/.local/share/nvim/lazy/lazy.nvim"
)

# ---------- Выбор ----------
if [[ "$MODE" == "" ]]; then
  CHOICES=$(printf "%s\n\n%s\n\n%s" \
    "===== 🖥️ GUI инструменты =====" "${GUI_TOOLS[@]}" \
    "===== 🛠️ CLI инструменты =====" "${CLI_TOOLS[@]}" | \
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

info "Загружаю конфиги Zsh..."
curl -fsSL https://raw.githubusercontent.com/justrunme/devops-tools/main/dotfiles/.zshrc -o ~/.zshrc
curl -fsSL https://raw.githubusercontent.com/justrunme/devops-tools/main/dotfiles/.p10k.zsh -o ~/.p10k.zsh
success ".zshrc и .p10k.zsh загружены"

# ---------- Смена shell ----------
if [[ "$SHELL" != *zsh ]]; then
  info "Меняю shell на Zsh..."
  chsh -s $(which zsh)
fi

# ---------- Neovim Lazy.nvim ----------
info "Запускаю Neovim (headless)..."
nvim --headless "+Lazy! sync" +qa || true

# ---------- Финал ----------
echo -e "\n${GREEN}✅ Установка завершена!${NC}"
echo -e "${YELLOW}➡️ Перезапусти терминал или выполни: source ~/.zshrc${NC}"
