-- 最小構成の Neovim 設定（lazy.nvim + nvim-tree + telescope）
-- 目的: VS Code 相当の「ファイルツリー」と「Ctrl+P でファイルジャンプ」だけを持つ。
-- 補完・LSP などは必要になった時点で plugins に足す。

vim.g.mapleader = " "

-- nvim-tree が netrw を置き換えるので、起動前に無効化しておく（nvim-tree 推奨）
vim.g.loaded_netrw = 1
vim.g.loaded_netrwPlugin = 1

-- ===== 基本設定 =====
local opt = vim.opt
opt.number = true
opt.ignorecase = true -- 検索は大文字小文字を区別しない…
opt.smartcase = true -- …ただし大文字を含めたら区別する
opt.termguicolors = true
opt.splitright = true
opt.splitbelow = true
opt.updatetime = 250
opt.undofile = true

-- クリップボード共有。プロバイダ（xclip / wl-copy / win32yank 等）が無い環境で
-- 有効にすると yank のたびに警告が出るので、使える時だけ有効にする。
vim.schedule(function()
  if vim.fn.has("clipboard") == 1 then
    opt.clipboard = "unnamedplus"
  end
end)

-- ===== lazy.nvim（プラグインマネージャ）の自動導入 =====
local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
if not (vim.uv or vim.loop).fs_stat(lazypath) then
  local out = vim.fn.system({
    "git", "clone", "--filter=blob:none", "--branch=stable",
    "https://github.com/folke/lazy.nvim.git", lazypath,
  })
  if vim.v.shell_error ~= 0 then
    vim.api.nvim_echo({ { "lazy.nvim の取得に失敗しました:\n" .. out, "ErrorMsg" } }, true, {})
    return
  end
end
vim.opt.rtp:prepend(lazypath)

-- ===== プラグイン =====
require("lazy").setup({
  -- ファイルツリー: <leader>e で開閉
  {
    "nvim-tree/nvim-tree.lua",
    keys = {
      { "<leader>e", "<cmd>NvimTreeToggle<cr>", desc = "ファイルツリー開閉" },
      { "<leader>E", "<cmd>NvimTreeFindFile<cr>", desc = "現在のファイルをツリーで表示" },
    },
    cmd = { "NvimTreeToggle", "NvimTreeFindFile", "NvimTreeOpen" },
    -- `nvim .` のようにディレクトリを開いた時にもツリーを出すため、起動時に読み込む
    lazy = false,
    opts = {
      view = { width = 35 },
      filters = { dotfiles = false },
      renderer = {
        -- Nerd Font が無い端末でも崩れないよう、アイコンは使わず記号のみにする
        icons = {
          show = { file = false, folder = false, folder_arrow = true, git = false },
          glyphs = { folder = { arrow_closed = "▸", arrow_open = "▾" } },
        },
      },
    },
  },

  -- あいまい検索: <C-p> でファイル名ジャンプ（VS Code の Ctrl+P 相当）
  {
    "nvim-telescope/telescope.nvim",
    branch = "master",
    dependencies = { "nvim-lua/plenary.nvim" },
    keys = {
      { "<C-p>", "<cmd>Telescope find_files<cr>", desc = "ファイル名で検索" },
      { "<leader>ff", "<cmd>Telescope find_files<cr>", desc = "ファイル名で検索" },
      { "<leader>fg", "<cmd>Telescope live_grep<cr>", desc = "文字列検索 (ripgrep 必須)" },
      { "<leader>fb", "<cmd>Telescope buffers<cr>", desc = "開いているバッファ" },
      { "<leader>fr", "<cmd>Telescope oldfiles<cr>", desc = "最近開いたファイル" },
    },
    opts = {
      defaults = {
        file_ignore_patterns = { "^%.git/", "node_modules/" },
      },
      pickers = {
        find_files = { hidden = true }, -- .env 等のドットファイルも対象にする
      },
    },
  },
}, {
  -- 起動のたびの更新チェック通知は不要
  checker = { enabled = false },
  change_detection = { notify = false },
})
