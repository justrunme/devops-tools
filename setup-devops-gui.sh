#!/bin/bash
set -e

# ---------- Цвета и функции ----------
GREEN="\033[0;32m"
YELLOW="\033[1;33m"
NC="\033[0m"
function info()    { echo -e "${YELLOW}[INFO]${NC} $1"; }
function success() { echo -e "${GREEN}[OK]${NC} $1"; }

# ---------- Проверка gum ----------
if ! command -v gum &>/dev/null; then
  info "Устанавливаю gum..."
  brew install charmbracelet/tap/gum
fi

# ---------- Проверка pipx ----------
if ! command -v pipx &>/dev/null; then
  info "Устанавливаю pipx..."
  brew install pipx
  pipx ensurepath
fi

# ---------- Маппинг тулзов на команды ----------
declare -A INSTALL_COMMANDS=(
  [brew]="brew install brew"
  [git]="brew install git"
  [zsh]="brew install zsh"
  [oh-my-zsh]="sh -c \"\$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)\""
  [fzf]="brew install fzf"
  [jq]="brew install jq"
  [bat]="brew install bat"
  [tree]="brew install tree"
  [docker]="brew install --cask docker"
  [docker-compose]="pipx install docker-compose"
  [lazydocker]="brew install lazydocker"
  [kubectl]="brew install kubectl"
  [helm]="brew install helm"
  [k9s]="brew install k9s"
  [minikube]="brew install minikube"
  [kind]="brew install kind"
  [kubectx]="brew install kubectx"
  [kubens]="brew install kubens"
  [skaffold]="brew install skaffold"
  [kustomize]="brew install kustomize"
  [awscli]="pipx install awscli"
  [gcloud]="brew install --cask google-cloud-sdk"
  [az]="brew install azure-cli"
  [gh]="brew install gh"
  [glab]="brew install glab"
  [pipx]="brew install pipx && pipx ensurepath"
  [ansible]="pipx install ansible"
  [visual-studio-code]="brew install --cask visual-studio-code"
  [iterm2]="brew install --cask iterm2"
  [act]="brew install act"
  [tilt]="brew install tilt"
  [tailscale]="brew install --cask tailscale"
  [ngrok]="brew install --cask ngrok"
  [terraform]="brew install terraform"
  [tfsec]="brew install tfsec"
  [tflint]="brew install tflint"
  [terragrunt]="brew install terragrunt"
  [direnv]="brew install direnv"
  [zoxide]="brew install zoxide"
  [httpie]="brew install httpie"
  [cheat]="brew install cheat"
  [btop]="brew install btop"
)

# ---------- Список с категориями ----------
CHOICES=$(gum choose --no-limit --height=40 --header="Выбери инструменты для установки:" <<EOF
🛠️ [CORE] brew
🛠️ [CORE] git
🛠️ [CORE] zsh
🛠️ [CORE] oh-my-zsh
🛠️ [CORE] fzf
🛠️ [CORE] jq
🛠️ [CORE] bat
🛠️ [CORE] tree
🐳 [DOCKER] docker
🐳 [DOCKER] docker-compose
🐳 [DOCKER] lazydocker
☸️ [KUBERNETES] kubectl
☸️ [KUBERNETES] helm
☸️ [KUBERNETES] k9s
☸️ [KUBERNETES] minikube
☸️ [KUBERNETES] kind
☸️ [KUBERNETES] kubectx
☸️ [KUBERNETES] kubens
☸️ [KUBERNETES] skaffold
☸️ [KUBERNETES] kustomize
☁️ [CLOUD] awscli
☁️ [CLOUD] gcloud
☁️ [CLOUD] az
☁️ [CLOUD] gh
☁️ [CLOUD] glab
⚙️ [DEVTOOLS] pipx
⚙️ [DEVTOOLS] ansible
⚙️ [DEVTOOLS] visual-studio-code
⚙️ [DEVTOOLS] iterm2
⚡ [EXTRAS] act
⚡ [EXTRAS] tilt
⚡ [EXTRAS] tailscale
⚡ [EXTRAS] ngrok
📦 [INFRA] terraform
📦 [INFRA] tfsec
📦 [INFRA] tflint
📦 [INFRA] terragrunt
🔧 [UTILITIES] direnv
🔧 [UTILITIES] zoxide
🔧 [UTILITIES] httpie
🔧 [UTILITIES] cheat
🔧 [UTILITIES] btop
EOF
)

# ---------- Установка выбранных тулзов ----------
for item in $CHOICES; do
  TOOL=$(echo "$item" | awk '{print $3}')
  CMD="${INSTALL_COMMANDS[$TOOL]}"
  if [[ -n "$CMD" ]]; then
    gum spin --title "Устанавливаю $TOOL..." -- bash -c "$CMD"
    success "$TOOL установлен"
  else
    info "$TOOL не найден в INSTALL_COMMANDS — пропущен"
  fi
done

# ---------- Финал ----------
echo -e "\n${GREEN}Установка завершена! Перезапусти терминал или выполни: source ~/.zshrc${NC}"
