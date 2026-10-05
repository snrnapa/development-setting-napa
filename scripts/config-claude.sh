#!/usr/bin/env bash
# Claude Code の設定配置のみ（本体は別途導入）。
#   - config/claude/statusline.sh を ~/.claude/statusline.sh に symlink
#   - ~/.claude/settings.json の statusLine キーだけを設定（他のキーは触らない）
# ステータスラインは jq に依存するため、無ければ apt で導入する。
set -euo pipefail
# shellcheck source=lib/common.sh
source "$(dirname "${BASH_SOURCE[0]}")/lib/common.sh"

SRC="$REPO_ROOT/config/claude/statusline.sh"
CLAUDE_DIR="$HOME/.claude"
DEST="$CLAUDE_DIR/statusline.sh"
SETTINGS="$CLAUDE_DIR/settings.json"

[ -f "$SRC" ] || die "not found: $SRC"

have_cmd jq || { log "installing jq via apt ..."; apt_install jq; }

mkdir -p "$CLAUDE_DIR"

# --- statusline.sh の配置（冪等） ---
if [ -L "$DEST" ] && [ "$(readlink -f "$DEST")" = "$(readlink -f "$SRC")" ]; then
  log "already linked, skip: $DEST -> $SRC"
else
  if [ -e "$DEST" ] || [ -L "$DEST" ]; then
    backup_dir="$HOME/.backup/$(date +%Y%m%d-%H%M%S)"
    mkdir -p "$backup_dir"
    mv "$DEST" "$backup_dir/statusline.sh"
    log "existing file moved to: $backup_dir/statusline.sh"
  fi
  ln -s "$SRC" "$DEST"
  log "linked: $DEST -> $SRC"
fi

# --- settings.json の statusLine（冪等。他のキーは保持） ---
WANT='{"type":"command","command":"~/.claude/statusline.sh","refreshInterval":60}'
if [ -f "$SETTINGS" ]; then
  jq -e . "$SETTINGS" >/dev/null 2>&1 || die "invalid JSON, not touching: $SETTINGS"
  if jq -e --argjson want "$WANT" '.statusLine == $want' "$SETTINGS" >/dev/null; then
    log "statusLine already set, skip: $SETTINGS"
    exit 0
  fi
  backup_dir="$HOME/.backup/$(date +%Y%m%d-%H%M%S)"
  mkdir -p "$backup_dir"
  cp -p "$SETTINGS" "$backup_dir/settings.json"
  log "settings.json backed up to: $backup_dir/settings.json"
  tmp="$(mktemp "$SETTINGS.XXXXXX")"
  jq --argjson want "$WANT" '.statusLine = $want' "$SETTINGS" > "$tmp"
  chmod --reference="$SETTINGS" "$tmp"
  mv "$tmp" "$SETTINGS"
else
  jq -n --argjson want "$WANT" '{statusLine: $want}' > "$SETTINGS"
fi
log "statusLine set in: $SETTINGS（実行中のセッションは再起動で反映）"
