#!/usr/bin/env bash
set -e

# ---------- Цвета и функции ----------
GREEN="\033[0;32m"
YELLOW="\033[1;33m"
RED="\033[0;31m"
NC="\033[0m"
function info()    { echo -e "${YELLOW}[INFO]${NC} $1"; }
function success() { echo -e "${GREEN}[OK]${NC} $1"; }
function error()   { echo -e "${RED}[ERROR]${NC} $1"; }

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

# ---------- Проверка pipx ----------
if ! command -v pipx &>/dev/null; then
  info "Устанавливаю pipx..."
  sudo apt-get update && sudo apt-get install -y python3-pip
  python3 -m pip install --user pipx
  python3 -m pipx ensurepath
fi

# ---------- GUI инструменты ----------
GUI_TOOLS=(
  "Docker Engine:sudo apt-get install -y docker.io"
  "Google Cloud SDK:sudo apt-get install -y google-cloud-sdk"
  "Visual Studio Code:flatpak install -y flathub com.visualstudio.code"
  "Tailscale VPN:sudo apt-get install -y tailscale"
  "Ngrok Tunnel:sudo snap install ngrok"
  "PgAdmin 4:flatpak install -y flathub io.pgadmin.pgadmin4"
  "DB Browser for SQLite:flatpak install -y flathub io.github.sqlitebrowser.sqlitebrowser"
  "Lens (K8s GUI):flatpak install -y flathub dev.k8slens.OpenLens"
)

# ---------- CLI инструменты ----------
CLI_TOOLS=(
  "kubectl:sudo apt-get install -y kubectl"
  "helm:sudo apt-get install -y helm"
  "kind:sudo apt-get install -y kind"
  "k9s:sudo apt-get install -y k9s"
  "terraform:sudo apt-get install -y terraform"
  "terragrunt:sudo apt-get install -y terragrunt"
  "terraform-docs:sudo apt-get install -y terraform-docs"
  "tfsec:sudo apt-get install -y tfsec"
  "pre-commit:sudo apt-get install -y pre-commit"
  "awscli:sudo apt-get install -y awscli"
  "azure-cli:sudo apt-get install -y azure-cli"
  "google-cloud-sdk:sudo apt-get install -y google-cloud-sdk"
  "doctl:sudo apt-get install -y doctl"
  "flyctl:sudo apt-get install -y flyctl"
  "glab:sudo apt-get install -y glab"
  "docker:sudo apt-get install -y docker"
  "lazygit:sudo apt-get install -y lazygit"
  "python/pipx:sudo apt-get install -y python3 && python3 -m pip install --user pipx && pipx ensurepath"
  "fzf:sudo apt-get install -y fzf"
  "bat:sudo apt-get install -y bat"
  "htop:sudo apt-get install -y htop"
  "ncdu:sudo apt-get install -y ncdu"
  "tree:sudo apt-get install -y tree"
  "yq:sudo apt-get install -y yq"
  "sops:sudo apt-get install -y sops"
  "tldr:sudo apt-get install -y tldr"
  "eza:sudo apt-get install -y eza"
  "Neovim + конфиг:sudo apt-get install -y neovim && mkdir -p ~/.config/nvim/lua && curl -fsSL https://raw.githubusercontent.com/justrunme/devops-tools/main/nvim/init.lua -o ~/.config/nvim/init.lua && curl -fsSL https://raw.githubusercontent.com/justrunme/devops-tools/main/nvim/lua/plugins.lua -o ~/.config/nvim/lua/plugins.lua && git clone https://github.com/folke/lazy.nvim ~/.local/share/nvim/lazy/lazy.nvim"
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

if [[ "$CI" != "true" ]]; then
  info "Делаю Zsh shell'ом по умолчанию..."
  chsh -s $(which zsh)
fi

info "Автозапускаю Neovim (headless) для Lazy.nvim..."
nvim --headless "+Lazy! sync" +qa || true

echo -e "\n${GREEN}✅ Установка завершена!${NC}"
echo -e "${YELLOW}➡️ Проверь Neovim: nvim + :Lazy${NC}"
echo -e "${YELLOW}➡️ Перезапусти терминал или выполни: source ~/.zshrc${NC}"
