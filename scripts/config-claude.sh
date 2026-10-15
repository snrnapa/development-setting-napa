#!/usr/bin/env bash
# Claude Code の設定配置のみ（本体は install-claude.sh、プラグインは install-claude-plugins.sh）。
#   - config/claude/CLAUDE.md（おまかせ等のグローバル指示）を ~/.claude/CLAUDE.md に symlink
#   - config/claude/agents/*.md（サブエージェント）を ~/.claude/agents/ に 1 ファイルずつ symlink
#     （他のエージェントは触らない）
#   - config/claude/statusline.sh を ~/.claude/statusline.sh に symlink
#   - ~/.claude/settings.json に次の 2 ファイルを反映する（他のキーは保持、変更前に退避）
#       settings.enforced.json  常にこの値に揃える（ステータスライン）。危険操作の deny は足りない分を必ず足す
#       settings.defaults.json  キーが無い時だけ入れる（model・effort 等。各 PC で変えた値は上書きしない）
#     settings.json は Claude Code 自身も書き換えるので symlink にはしない。
#     旧構成（napa-global-claude-config への symlink）なら、その内容を引き継いで通常のファイルに置き換える。
# jq に依存するため、無ければ apt で導入する。
set -euo pipefail
# shellcheck source=lib/common.sh
source "$(dirname "${BASH_SOURCE[0]}")/lib/common.sh"

SRC_DIR="$REPO_ROOT/config/claude"
CLAUDE_DIR="$HOME/.claude"
SETTINGS="$CLAUDE_DIR/settings.json"
ENFORCED="$SRC_DIR/settings.enforced.json"
DEFAULTS="$SRC_DIR/settings.defaults.json"

for f in CLAUDE.md statusline.sh settings.enforced.json settings.defaults.json; do
  [ -f "$SRC_DIR/$f" ] || die "not found: $SRC_DIR/$f"
done

have_cmd jq || { log "installing jq via apt ..."; apt_install jq; }

mkdir -p "$CLAUDE_DIR/agents"

# --- symlink（冪等） ---
link_file "$SRC_DIR/CLAUDE.md" "$CLAUDE_DIR/CLAUDE.md"
link_file "$SRC_DIR/statusline.sh" "$CLAUDE_DIR/statusline.sh"
for agent in "$SRC_DIR"/agents/*.md; do
  link_file "$agent" "$CLAUDE_DIR/agents/$(basename "$agent")"
done

# --- settings.json（defaults → 現在の値 → enforced の順に重ねる） ---
# permissions.deny だけは和集合にする（各 PC で足した deny を消さない。順序は現在の値を保ち、足りない分を末尾に足す）。
# そのため enforced から外した deny は自動では消えない（外す時は ~/.claude/settings.json からも手で消す）。
current='{}'
if [ -e "$SETTINGS" ]; then
  jq -e . "$SETTINGS" >/dev/null 2>&1 || die "invalid JSON, not touching: $SETTINGS"
  current="$(cat "$SETTINGS")"
fi
want="$(jq -s '
  (.[1].permissions.deny // []) as $cur | (.[2].permissions.deny // []) as $enf
  | (.[0] * .[1] * .[2]) | .permissions.deny = ($cur + ($enf - $cur))
' "$DEFAULTS" <(printf '%s' "$current") "$ENFORCED")"

if [ ! -L "$SETTINGS" ] && [ "$(jq -S . <<<"$current")" = "$(jq -S . <<<"$want")" ]; then
  log "settings already up to date, skip: $SETTINGS"
else
  if [ -e "$SETTINGS" ] || [ -L "$SETTINGS" ]; then
    backup_dir="$HOME/.backup/$(date +%Y%m%d-%H%M%S)"
    mkdir -p "$backup_dir"
    cp -pL "$SETTINGS" "$backup_dir/settings.json"
    log "settings.json backed up to: $backup_dir/settings.json"
  fi
  tmp="$(mktemp "$CLAUDE_DIR/settings.json.XXXXXX")"
  printf '%s\n' "$want" > "$tmp"
  chmod 600 "$tmp"
  mv -f "$tmp" "$SETTINGS"   # symlink だった場合もリンクではなく通常のファイルに置き換わる
  log "settings updated: $SETTINGS（実行中のセッションは再起動で反映）"
fi
