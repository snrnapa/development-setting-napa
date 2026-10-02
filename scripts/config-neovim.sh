#!/usr/bin/env bash
# Neovim の設定配置のみ（本体は install-neovim.sh）。
# config/nvim/ を ~/.config/nvim に symlink し、プラグインを事前取得する。
#   NVIM_SKIP_SYNC=1 でプラグイン取得をスキップ（オフライン時など）
set -euo pipefail
# shellcheck source=lib/common.sh
source "$(dirname "${BASH_SOURCE[0]}")/lib/common.sh"

SRC="$REPO_ROOT/config/nvim"
DEST="${XDG_CONFIG_HOME:-$HOME/.config}/nvim"

[ -f "$SRC/init.lua" ] || die "not found: $SRC/init.lua"

# --- 設定の配置（冪等） ---
if [ -L "$DEST" ] && [ "$(readlink -f "$DEST")" = "$(readlink -f "$SRC")" ]; then
  log "already linked, skip: $DEST -> $SRC"
else
  if [ -e "$DEST" ] || [ -L "$DEST" ]; then
    backup_dir="$HOME/.backup/$(date +%Y%m%d-%H%M%S)"
    mkdir -p "$backup_dir"
    mv "$DEST" "$backup_dir/nvim"
    log "existing config moved to: $backup_dir/nvim"
  fi
  mkdir -p "$(dirname "$DEST")"
  ln -s "$SRC" "$DEST"
  log "linked: $DEST -> $SRC"
fi

# --- 前提の確認（足りなくても配置自体は成功させ、警告だけ出す） ---
have_cmd git || warn "git not found: lazy.nvim / プラグインの取得に必要です"
if ! have_cmd rg; then
  warn "ripgrep (rg) not found: <leader>fg (文字列検索) が使えません。ファイル検索 (<C-p>) は rg 無しでも動きます"
fi

if ! have_cmd nvim; then
  warn "nvim not found: 先に scripts/install-neovim.sh を実行してください（プラグイン取得はスキップ）"
  exit 0
fi

# telescope.nvim が 0.11 以上を要求する（nvim-tree は 0.10 以上）
nvim_ver="$(nvim --version | sed -n '1s/^NVIM v//p')"
if [ "$(printf '%s\n0.11\n' "${nvim_ver%%-*}" | sort -V | head -1)" != "0.11" ]; then
  warn "nvim $nvim_ver is too old (>= 0.11 required): scripts/install-neovim.sh で更新してください。このままだとプラグインがエラーになります"
fi

# --- プラグインの事前取得（初回起動を待たせないため） ---
if [ "${NVIM_SKIP_SYNC:-0}" = "1" ]; then
  log "NVIM_SKIP_SYNC=1, skip plugin sync"
else
  log "syncing plugins (lazy.nvim) ..."
  if nvim --headless "+Lazy! sync" +qa 2>&1; then
    echo
    log "plugins synced"
  else
    warn "plugin sync failed: 次回 nvim 起動時に lazy.nvim が再試行します"
  fi
fi

log "done: $(nvim --version | head -1)"
