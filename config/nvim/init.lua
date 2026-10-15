-- 最小構成の Neovim 設定（lazy.nvim + nvim-tree + telescope + git 差分 + Markdown 表示）
-- 目的: VS Code 相当の「ファイルツリー」「Ctrl+P でファイルジャンプ」「Git の差分・履歴」
-- 「Markdown プレビュー」だけを持つ。補完・LSP などは必要になった時点で plugins に足す。

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

  -- 変更行の印（VS Code の左端の色帯相当）と hunk 単位の操作
  {
    "lewis6991/gitsigns.nvim",
    event = { "BufReadPre", "BufNewFile" },
    opts = {
      on_attach = function(bufnr)
        local gs = require("gitsigns")
        local function map(lhs, rhs, desc)
          vim.keymap.set("n", lhs, rhs, { buffer = bufnr, desc = desc })
        end
        map("]c", function() gs.nav_hunk("next") end, "次の変更箇所")
        map("[c", function() gs.nav_hunk("prev") end, "前の変更箇所")
        map("<leader>hp", gs.preview_hunk, "変更箇所の差分をプレビュー")
        map("<leader>hr", gs.reset_hunk, "変更箇所を元に戻す")
        map("<leader>hb", function() gs.blame_line({ full = true }) end, "この行の blame")
      end,
    },
  },

  -- VS Code の Source Control / Git Graph 相当: 左にファイル一覧、右に左右並びの差分
  {
    "sindrets/diffview.nvim",
    cmd = { "DiffviewOpen", "DiffviewFileHistory", "DiffviewClose" },
    keys = {
      { "<leader>gd", "<cmd>DiffviewOpen<cr>", desc = "作業中の変更を差分表示" },
      { "<leader>gh", "<cmd>DiffviewFileHistory<cr>", desc = "コミット履歴（リポジトリ全体）" },
      { "<leader>gf", "<cmd>DiffviewFileHistory %<cr>", desc = "コミット履歴（このファイル）" },
      { "<leader>gq", "<cmd>DiffviewClose<cr>", desc = "差分表示を閉じる" },
    },
    opts = {
      -- Nerd Font 無しでも崩れないよう、nvim-tree と同じ記号にそろえる
      use_icons = false,
      icons = { folder_closed = "▸", folder_open = "▾" },
      signs = { fold_closed = "▸", fold_open = "▾", done = "✓" },
    },
  },

  -- Markdown をバッファ内で整形表示（見出し・表・チェックボックス・コードブロック）
  -- パーサ（markdown / markdown_inline）は Neovim 本体に同梱されているものを使う
  {
    "MeanderingProgrammer/render-markdown.nvim",
    ft = { "markdown" },
    keys = {
      { "<leader>mr", "<cmd>RenderMarkdown toggle<cr>", ft = "markdown", desc = "Markdown 整形表示の切り替え" },
    },
    opts = {
      -- 既定のアイコンは Nerd Font 前提なので、通常のフォントにある記号に置き換える
      heading = { icons = { "# ", "## ", "### ", "#### ", "##### ", "###### " } },
      checkbox = {
        unchecked = { icon = "☐ " },
        checked = { icon = "☑ " },
      },
      code = { sign = false, language_icon = false },
      link = { enabled = false }, -- リンク種別のアイコンは出さない（リンク自体はそのまま表示）
      callout = {
        note = { rendered = "Note" },
        tip = { rendered = "Tip" },
        important = { rendered = "Important" },
        warning = { rendered = "Warning" },
        caution = { rendered = "Caution" },
      },
    },
  },

  -- ブラウザでのライブプレビュー（画像・Mermaid を見たい時用）
  -- ブラウザが無い環境（devcontainer 等）では URL を表示するので、ポート転送して開く
  {
    "iamcco/markdown-preview.nvim",
    ft = { "markdown" },
    cmd = { "MarkdownPreview", "MarkdownPreviewStop", "MarkdownPreviewToggle" },
    keys = {
      { "<leader>mp", "<cmd>MarkdownPreviewToggle<cr>", ft = "markdown", desc = "ブラウザでプレビュー" },
    },
    -- 配布済みのビルドを取得する（node / yarn は不要）。build 時点では未読込なので先に読み込む
    build = function()
      require("lazy").load({ plugins = { "markdown-preview.nvim" } })
      vim.fn["mkdp#util#install"]()
    end,
    init = function(plugin)
      vim.g.mkdp_echo_preview_url = 1
      -- ポート転送しやすいよう固定（既定はランダム）。別の nvim で同時にプレビューすると
      -- ポートが衝突するので、その時は MKDP_PORT=8091 nvim のように変えて起動する
      vim.g.mkdp_port = vim.env.MKDP_PORT or "8090"

      -- 本文の幅はプラグインの page.css で 900px に制限されているので、ブラウザの幅いっぱいに広げる。
      -- 差し替え用 CSS は標準の markdown.css に上書きを 1 行足したもの（プラグイン更新にも追従する）
      local src = plugin.dir .. "/app/_static/markdown.css"
      if vim.uv.fs_stat(src) then
        local dest = vim.fn.stdpath("cache") .. "/markdown-preview-wide.css"
        local css = table.concat(vim.fn.readfile(src), "\n")
        vim.fn.writefile(vim.split(css .. "\n#page-ctn { max-width: none !important; }\n", "\n"), dest)
        vim.g.mkdp_markdown_css = dest
      end
    end,
  },
}, {
  -- 起動のたびの更新チェック通知は不要
  checker = { enabled = false },
  change_detection = { notify = false },
})
