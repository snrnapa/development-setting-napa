#!/usr/bin/env bash
# Claude Code プラグイン Superpowers（obra/superpowers）の導入（user スコープ）。
#   - Anthropic 公式マーケットプレイス claude-plugins-official から入れる
#   - マーケットプレイス未登録なら追加、導入済みで無効なら有効化するだけ
# Claude Code 本体は別途導入しておくこと。claude CLI の出力解析に jq を使う。
set -euo pipefail
# shellcheck source=lib/common.sh
source "$(dirname "${BASH_SOURCE[0]}")/lib/common.sh"

MARKETPLACE="${SUPERPOWERS_MARKETPLACE:-claude-plugins-official}"
MARKETPLACE_REPO="${SUPERPOWERS_MARKETPLACE_REPO:-anthropics/claude-plugins-official}"
PLUGIN_ID="superpowers@$MARKETPLACE"

have_cmd claude || die "claude not found (install Claude Code first)"
have_cmd jq || { log "installing jq via apt ..."; apt_install jq; }

# --- マーケットプレイス（冪等） ---
if claude plugin marketplace list --json | jq -e --arg m "$MARKETPLACE" 'any(.[]; .name == $m)' >/dev/null; then
  log "marketplace already added, skip: $MARKETPLACE"
else
  log "adding marketplace: $MARKETPLACE_REPO"
  claude plugin marketplace add "$MARKETPLACE_REPO"
fi

# --- プラグイン本体（冪等） ---
installed="$(claude plugin list --json | jq -c --arg id "$PLUGIN_ID" '[.[] | select(.id == $id and .scope == "user")][0] // empty')"
if [ -z "$installed" ]; then
  log "installing: $PLUGIN_ID"
  claude plugin install "$PLUGIN_ID" --scope user
elif [ "$(jq -r '.enabled' <<<"$installed")" != "true" ]; then
  log "installed but disabled, enabling: $PLUGIN_ID"
  claude plugin enable "$PLUGIN_ID"
else
  log "already installed, skip: $PLUGIN_ID"
fi

version="$(claude plugin list --json | jq -r --arg id "$PLUGIN_ID" '[.[] | select(.id == $id)][0].version // "unknown"')"
log "superpowers version: $version（実行中のセッションは再起動で反映）"
