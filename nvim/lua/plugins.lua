-- plugins.lua — настройка lazy.nvim и всех плагинов

local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
if not vim.loop.fs_stat(lazypath) then
  vim.fn.system({
    "git", "clone", "--filter=blob:none",
    "https://github.com/folke/lazy.nvim.git",
    lazypath
  })
end
vim.opt.rtp:prepend(lazypath)

require("lazy").setup({
  -- LSP и автоформатирование
  { "neovim/nvim-lspconfig" },
  { "williamboman/mason.nvim", build = ":MasonUpdate" },
  { "williamboman/mason-lspconfig.nvim" },
  { "jose-elias-alvarez/null-ls.nvim" },

  -- Автодополнение
  { "hrsh7th/nvim-cmp" },
  { "hrsh7th/cmp-nvim-lsp" },

  -- DevOps / IaC
  { "hashivim/vim-terraform" },
  { "pearofducks/ansible-vim" },
  { "b0o/schemastore.nvim" },
  { "gennaro-tedesco/nvim-jqx" },         -- JSON viewer
  { "tadmccorkle/markdown.nvim" },        -- Markdown if needed
  { "nvim-treesitter/nvim-treesitter", build = ":TSUpdate" },

  -- Kubernetes & Docker
  { "towolf/vim-helm" },
  { "stevearc/dressing.nvim" },
  { "vim-scripts/kubernetes.vim" },
  { "ekalinin/Dockerfile.vim" },

  -- Интерфейс и удобство
  { "nvim-lualine/lualine.nvim" },
  { "nvim-telescope/telescope.nvim", tag = "0.1.3", dependencies = { "nvim-lua/plenary.nvim" } },
  { "folke/trouble.nvim" },
  { "folke/which-key.nvim" },
})
