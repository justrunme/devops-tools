# DevOps Installer for macOS

Автоматический установщик DevOps-инструментов и окружения для macOS (и CI). Включает CLI и GUI утилиты, Oh My Zsh с DevOps-конфигом, Neovim с Lazy.nvim и плагинами.

---

## 🚀 Возможности

- Установка CLI DevOps-инструментов: `kubectl`, `terraform`, `awscli`, `lazygit`, `k9s` и др.
- Установка GUI приложений: Docker, iTerm2, VS Code, Tailscale, PgAdmin4, Lens и др.
- Установка и настройка [Oh My Zsh](https://ohmyz.sh/) с Powerlevel10k, плагинами и DevOps алиасами
- Автоматическая загрузка `.zshrc` и `.p10k.zsh` из GitHub репозитория
- Установка [Neovim](https://neovim.io/) с [Lazy.nvim](https://github.com/folke/lazy.nvim) и DevOps-плагинами
- Поддержка интерактивного выбора инструментов (с помощью [gum](https://github.com/charmbracelet/gum))
- CI-поддержка в GitHub Actions: полная проверка установок и конфигураций

---

### **☁️ Cloud & DevOps**

| Инструмент | Тип | Описание |
|-----------|-----|----------|
| [awscli](https://github.com/aws/aws-cli) | CLI | AWS CLI |
| [azure-cli](https://github.com/Azure/azure-cli) | CLI | Azure CLI |
| [google-cloud-sdk](https://cloud.google.com/sdk) | CLI/GUI | GCP SDK & GUI |
| [doctl](https://github.com/digitalocean/doctl) | CLI | DigitalOcean CLI |
| [flyctl](https://github.com/superfly/flyctl) | CLI | Fly.io CLI |
| [doppler](https://github.com/DopplerHQ/cli) | CLI | Менеджер секретов |
| [kubectl](https://kubernetes.io/docs/tasks/tools/) | CLI | CLI для Kubernetes |
| [helm](https://helm.sh/) | CLI | Менеджер Helm-чартов |
| [minikube](https://github.com/kubernetes/minikube) | CLI | Локальный кластер Kubernetes |
| [kind](https://kind.sigs.k8s.io/) | CLI | Kubernetes в Docker |
| [k9s](https://github.com/derailed/k9s) | CLI | TUI-интерфейс для Kubernetes |
| [Lens](https://k8slens.dev/) | GUI | Kubernetes GUI |
| [Tailscale](https://tailscale.com/) | GUI | Mesh VPN через WireGuard |
| [Teleport](https://goteleport.com/) | GUI | Безопасный доступ к SSH, базам, Kubernetes |

---

### **🏗️ Infrastructure as Code**

| Инструмент | Тип | Описание |
|-----------|-----|----------|
| [terraform](https://www.terraform.io/) | CLI | Инфраструктура как код |
| [terragrunt](https://github.com/gruntwork-io/terragrunt) | CLI | DRY-надстройка над Terraform |
| [terraform-docs](https://github.com/terraform-docs/terraform-docs) | CLI | Документация из Terraform |
| [tfsec](https://github.com/aquasecurity/tfsec) | CLI | Security scanner для Terraform |

---

### **🐙 Git & CI/CD**

| Инструмент | Тип | Описание |
|-----------|-----|----------|
| [gh](https://cli.github.com/) | CLI | GitHub CLI |
| [glab](https://github.com/profclems/glab) | CLI | GitLab CLI |
| [lazygit](https://github.com/jesseduffield/lazygit) | CLI | TUI Git |
| [pre-commit](https://pre-commit.com/) | CLI | Git хуки и автоформатирование |

---

### **🐳 Docker & Containers**

| Инструмент | Тип | Описание |
|-----------|-----|----------|
| [docker](https://docs.docker.com/engine/reference/commandline/cli/) | CLI | Docker CLI |
| [Docker Desktop](https://www.docker.com/products/docker-desktop) | GUI | GUI и движок Docker |

---

### **🧠 Productivity & Terminal**

| Инструмент | Тип | Описание |
|-----------|-----|----------|
| [fzf](https://github.com/junegunn/fzf) | CLI | Fuzzy поиск |
| [bat](https://github.com/sharkdp/bat) | CLI | `cat` с подсветкой |
| [htop](https://htop.dev/) | CLI | TUI мониторинг |
| [ncdu](https://dev.yorhel.nl/ncdu) | CLI | Анализ диска |
| [tree](http://mama.indstate.edu/users/ice/tree/) | CLI | Деревья каталогов |
| [eza](https://github.com/eza-community/eza) | CLI | Расширенный `ls` |
| [tldr](https://tldr.sh/) | CLI | Упрощённые мануалы |
| [sops](https://github.com/mozilla/sops) | CLI | Шифрование YAML/JSON |
| [yq](https://github.com/mikefarah/yq) | CLI | YAML-парсер (jq-стиль) |
| [pipx](https://github.com/pypa/pipx) | CLI | Установка Python-инструментов |
| [python](https://www.python.org/) | CLI | Язык Python |

---

### **📝 Code & Editors**

| Инструмент | Тип | Описание |
|-----------|-----|----------|
| [Neovim](https://neovim.io/) | CLI | Editor + Lazy.nvim + DevOps конфиг |
| [VS Code](https://code.visualstudio.com/) | GUI | Мощный редактор от Microsoft |

---

### **🛢️ Database Tools**

| Инструмент | Тип | Описание |
|-----------|-----|----------|
| [PgAdmin 4](https://www.pgadmin.org/) | GUI | GUI для PostgreSQL |
| [DB Browser for SQLite](https://sqlitebrowser.org/) | GUI | SQLite GUI |

---

### **🌐 Networking & Tunneling**

| Инструмент | Тип | Описание |
|-----------|-----|----------|
| [Ngrok](https://ngrok.com/) | GUI | Проброс портов наружу |

---

## ⚙️ Установка

```bash
git clone https://github.com/justrunme/devops-tools.git
cd devops-tools
chmod +x setup-devops.sh
./setup-devops.sh --all

Аргументы:

--all: установить всё (CLI + GUI)

--cli: только CLI-инструменты

--gui: только GUI-инструменты

без аргументов: откроется выбор через gum



---

☁️ Устанавливаемые CLI-инструменты


---

🖥️ Устанавливаемые GUI-инструменты

Docker Desktop

Google Cloud SDK

Visual Studio Code

iTerm2 Terminal

Tailscale VPN

Ngrok

Teleport

PgAdmin 4

DB Browser for SQLite

Lens (GUI для Kubernetes)



---

🧠 Oh My Zsh и плагины

Автоматически устанавливаются:

Powerlevel10k (тема)

Плагины:


plugins=(
  # 🌐 DevOps & Cloud
  git docker kubectl helm terraform aws gcloud az

  # ⚙️ CLI улучшения
  zsh-autosuggestions zsh-syntax-highlighting zsh-completions zsh-z
  fzf command-not-found

  # 🧠 Удобство
  colored-man-pages extract history alias-finder safe-paste common-aliases

  # 🍎 Только для Mac
  macos
)

Алиасы DevOps:


alias k='kubectl'
alias kgp='kubectl get pods'
alias kgn='kubectl get nodes'
alias tf='terraform'
alias dc='docker compose'
alias dcu='docker compose up -d'
alias dcd='docker compose down'
alias lg='lazygit'
alias p='ping 8.8.8.8'


---

✨ Neovim + Lazy.nvim

Автоматически устанавливаются:

Neovim

Lazy.nvim

Конфиги init.lua и plugins.lua подтягиваются из GitHub


DevOps-плагины:

nvim-lspconfig, cmp-nvim-lsp, LuaSnip, lualine.nvim

nvim-treesitter, markdown-preview.nvim, kubernetes.vim, dockerfile.vim, ansible-vim и др.



---

✅ CI Проверка (GitHub Actions)

CI-пайплайн test-devops.yml:

Установка всех CLI и GUI инструментов

Проверка .zshrc и Powerlevel10k

Проверка установки OMZ-плагинов

Проверка DevOps алиасов

Проверка Neovim + Lazy.nvim


Пример CI лога


---

🧪 Тестирование вручную

source ~/.zshrc
nvim +Lazy


---

📂 Конфиги

Все конфиги (.zshrc, .p10k.zsh, init.lua, plugins.lua) хранятся в:

https://github.com/justrunme/devops-tools/tree/main/dotfiles

---

Oh My Zsh DevOps Plugins — Полный Список

🌐 Cloud & DevOps

git – Алиасы и функции для работы с Git

docker – Упрощённые команды для Docker

kubectl – Автодополнение и алиасы kubectl

helm – Поддержка Helm CLI

terraform – Утилиты и алиасы Terraform

aws – Интеграция с AWS CLI

gcloud – Интеграция с Google Cloud CLI

az – Azure CLI автодополнения


⚙️ CLI Улучшения

zsh-autosuggestions – Предиктивные предложения команд

zsh-syntax-highlighting – Подсветка синтаксиса команд

zsh-completions – Расширенные автодополнения

zsh-z – Быстрый переход по истории директорий

fzf – Fuzzy-поиск по истории, файлам и командам


🧠 Удобство

colored-man-pages – Цветные man-страницы

extract – Универсальная распаковка архивов (extract file.zip)

history – Управление историей команд

alias-finder – Интерактивное создание алиасов

safe-paste – Защита от случайного выполнения вставляемого текста

common-aliases – Базовые алиасы (ll, la, gst, и т.д.)


🍎 Только для macOS

macos – Утилиты и функции специфичные для macOS

---

Лицензия

MIT © justrunme
