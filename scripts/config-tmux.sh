#!/usr/bin/env bash
# tmux の設定配置のみ（本体は install-tmux.sh。install-tmux.sh からも呼ばれる）。
# config/tmux/.tmux.conf を ~/.tmux.conf に symlink する。
set -euo pipefail
# shellcheck source=lib/common.sh
source "$(dirname "${BASH_SOURCE[0]}")/lib/common.sh"

SRC="$REPO_ROOT/config/tmux/.tmux.conf"
DEST="$HOME/.tmux.conf"

[ -f "$SRC" ] || die "not found: $SRC"

if [ -L "$DEST" ] && [ "$(readlink -f "$DEST")" = "$(readlink -f "$SRC")" ]; then
  log "already linked, skip: $DEST -> $SRC"
else
  if [ -e "$DEST" ] || [ -L "$DEST" ]; then
    backup_dir="$HOME/.backup/$(date +%Y%m%d-%H%M%S)"
    mkdir -p "$backup_dir"
    mv "$DEST" "$backup_dir/.tmux.conf"
    log "existing config moved to: $backup_dir/.tmux.conf"
  fi
  ln -s "$SRC" "$DEST"
  log "linked: $DEST -> $SRC"
fi

# 起動中の tmux があれば再読み込み（失敗しても配置自体は成功扱い）
if have_cmd tmux && tmux list-sessions >/dev/null 2>&1; then
  if tmux source-file "$DEST" 2>/dev/null; then
    log "reloaded running tmux server"
  else
    warn "reload failed: tmux 内で prefix + r を実行してください"
  fi
fi
