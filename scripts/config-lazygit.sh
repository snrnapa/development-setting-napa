#!/usr/bin/env bash
# lazygit の設定配置のみ（本体は install-lazygit.sh。install-lazygit.sh からも呼ばれる）。
# config/lazygit/config.yml を ~/.config/lazygit/config.yml に symlink する。
# lazygit は同じディレクトリに state.yml を書くので、ディレクトリではなくファイル単位でリンクする。
# tmux の prefix + g（lazygit を popup で開く）は config/tmux/.tmux.conf 側に書いてある。
set -euo pipefail
# shellcheck source=lib/common.sh
source "$(dirname "${BASH_SOURCE[0]}")/lib/common.sh"

SRC="$REPO_ROOT/config/lazygit/config.yml"
DEST="${XDG_CONFIG_HOME:-$HOME/.config}/lazygit/config.yml"

[ -f "$SRC" ] || die "not found: $SRC"

if [ -L "$DEST" ] && [ "$(readlink -f "$DEST")" = "$(readlink -f "$SRC")" ]; then
  log "already linked, skip: $DEST -> $SRC"
else
  if [ -e "$DEST" ] || [ -L "$DEST" ]; then
    backup_dir="$HOME/.backup/$(date +%Y%m%d-%H%M%S)"
    mkdir -p "$backup_dir"
    mv "$DEST" "$backup_dir/lazygit-config.yml"
    log "existing config moved to: $backup_dir/lazygit-config.yml"
  fi
  mkdir -p "$(dirname "$DEST")"
  ln -s "$SRC" "$DEST"
  log "linked: $DEST -> $SRC"
fi

# 足りなくても配置自体は成功させ、警告だけ出す
have_cmd lazygit || warn "lazygit not found: scripts/install-lazygit.sh を実行してください"
have_cmd delta || warn "delta not found: lazygit の差分は '|' キーで git 標準表示に切り替えてください（scripts/install-lazygit.sh で導入されます）"
have_cmd nvim || warn "nvim not found: lazygit の 'e'（ファイルを開く）は nvim を使う設定です"
