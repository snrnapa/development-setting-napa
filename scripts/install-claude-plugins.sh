#!/usr/bin/env bash
# Claude Code プラグインの一括導入（user スコープ）。
#   - config/claude/plugins.txt に並べたプラグインを順に入れる
#     書式: <plugin>@<marketplace> [<marketplace の source（owner/repo 等）>]
#     source 省略時は claude-plugins-official（anthropics/claude-plugins-official）のみ自動で追加できる
#   - マーケットプレイス未登録なら追加、導入済みで無効なら有効化するだけ
#   - リストから消したプラグインはアンインストールしない（手で `claude plugin uninstall <id>`）
# Claude Code 本体は別途導入しておくこと。claude CLI の出力解析に jq を使う。
set -euo pipefail
# shellcheck source=lib/common.sh
source "$(dirname "${BASH_SOURCE[0]}")/lib/common.sh"

LIST="${CLAUDE_PLUGINS_LIST:-$REPO_ROOT/config/claude/plugins.txt}"

[ -f "$LIST" ] || die "not found: $LIST"
have_cmd claude || die "claude not found (install Claude Code first)"
have_cmd jq || { log "installing jq via apt ..."; apt_install jq; }

default_source() {
  case "$1" in
    claude-plugins-official) echo "anthropics/claude-plugins-official" ;;
    *) echo "" ;;
  esac
}

ensure_marketplace() {
  local name="$1" source="$2"
  if claude plugin marketplace list --json | jq -e --arg m "$name" 'any(.[]; .name == $m)' >/dev/null; then
    return 0
  fi
  [ -n "$source" ] || source="$(default_source "$name")"
  [ -n "$source" ] || die "marketplace '$name' is not added and no source given in $LIST"
  log "adding marketplace: $name ($source)"
  claude plugin marketplace add "$source"
}

ensure_plugin() {
  local id="$1" installed
  installed="$(claude plugin list --json | jq -c --arg id "$id" '[.[] | select(.id == $id and .scope == "user")][0] // empty')"
  if [ -z "$installed" ]; then
    log "installing: $id"
    claude plugin install "$id" --scope user
  elif [ "$(jq -r '.enabled' <<<"$installed")" != "true" ]; then
    log "installed but disabled, enabling: $id"
    claude plugin enable "$id"
  else
    log "already installed, skip: $id"
  fi
}

failed=()
# claude CLI が stdin を読まないよう、リストは fd 3 から読む
while read -r id source _ <&3; do
  case "$id" in ''|'#'*) continue ;; esac
  [[ "$id" == *@* ]] || die "invalid entry (need <plugin>@<marketplace>): $id"
  # 1 つ失敗しても残りは続ける
  if ! { ensure_marketplace "${id#*@}" "${source:-}" && ensure_plugin "$id"; }; then
    warn "failed: $id"
    failed+=("$id")
  fi
done 3< "$LIST"

log "installed plugins (user scope):"
claude plugin list --json | jq -r '.[] | select(.scope == "user") | "  \(.id) \(.version) \(if .enabled then "enabled" else "disabled" end)"'
[ "${#failed[@]}" -eq 0 ] || die "failed: ${failed[*]}"
log "done（実行中のセッションは再起動で反映）"
