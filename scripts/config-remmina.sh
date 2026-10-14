#!/usr/bin/env bash
# Remmina の RDP 接続プロファイルの配置のみ（本体は install-remmina.sh）。
#   - config/remmina/desktop-pc.remmina.template の @NAME@ / @SERVER@ / @USER@ を埋めて
#     ~/.local/share/remmina/desktop-pc.remmina を生成する
# サーバー IP とユーザー名は公開リポジトリに置かないため、テンプレートには入れない。
# 値は環境変数 REMMINA_RDP_NAME / REMMINA_RDP_SERVER / REMMINA_RDP_USER、または
# ~/.config/development-setting-napa/remmina.env（無ければ対話入力して保存、権限 600）から取る。
# パスワードは扱わない（接続時に Remmina が聞く）。
# Remmina が保存時に書き換えるため symlink ではなく生成ファイル。内容が同じなら何もしない。
set -euo pipefail
# shellcheck source=lib/common.sh
source "$(dirname "${BASH_SOURCE[0]}")/lib/common.sh"

SRC="$REPO_ROOT/config/remmina/desktop-pc.remmina.template"
DEST_DIR="$HOME/.local/share/remmina"
DEST="$DEST_DIR/desktop-pc.remmina"
ENV_FILE="${REMMINA_ENV_FILE:-$HOME/.config/development-setting-napa/remmina.env}"

[ -f "$SRC" ] || die "not found: $SRC"

# 環境変数が未指定のものだけ env ファイルから補う
if [ -f "$ENV_FILE" ]; then
  _name="${REMMINA_RDP_NAME:-}"; _server="${REMMINA_RDP_SERVER:-}"; _user="${REMMINA_RDP_USER:-}"
  # shellcheck disable=SC1090
  source "$ENV_FILE"
  REMMINA_RDP_NAME="${_name:-${REMMINA_RDP_NAME:-}}"
  REMMINA_RDP_SERVER="${_server:-${REMMINA_RDP_SERVER:-}}"
  REMMINA_RDP_USER="${_user:-${REMMINA_RDP_USER:-}}"
fi

if [ -z "${REMMINA_RDP_SERVER:-}" ] || [ -z "${REMMINA_RDP_USER:-}" ]; then
  [ -t 0 ] || die "REMMINA_RDP_SERVER / REMMINA_RDP_USER が未設定です（$ENV_FILE も無し）"
  read -r -p "接続先 (IP またはホスト名): " REMMINA_RDP_SERVER
  read -r -p "Windows のユーザー名: " REMMINA_RDP_USER
  save_env=1
fi
REMMINA_RDP_NAME="${REMMINA_RDP_NAME:-デスクトップPC}"

[[ "$REMMINA_RDP_SERVER" =~ ^[A-Za-z0-9._-]+$ ]] || die "invalid server: $REMMINA_RDP_SERVER"
case "$REMMINA_RDP_USER$REMMINA_RDP_NAME" in
  *$'\n'*|*$'\r'*) die "改行は使えません" ;;
esac
[ -n "$REMMINA_RDP_USER" ] || die "ユーザー名が空です"

if [ "${save_env:-0}" = 1 ]; then
  mkdir -p "$(dirname "$ENV_FILE")"
  ( umask 077
    printf 'REMMINA_RDP_NAME=%q\nREMMINA_RDP_SERVER=%q\nREMMINA_RDP_USER=%q\n' \
      "$REMMINA_RDP_NAME" "$REMMINA_RDP_SERVER" "$REMMINA_RDP_USER" > "$ENV_FILE" )
  log "saved: $ENV_FILE"
fi

content="$(cat "$SRC")"
content="${content//@NAME@/$REMMINA_RDP_NAME}"
content="${content//@SERVER@/$REMMINA_RDP_SERVER}"
content="${content//@USER@/$REMMINA_RDP_USER}"

mkdir -p "$DEST_DIR"
if [ -f "$DEST" ] && [ "$(cat "$DEST")" = "$content" ]; then
  log "already up to date, skip: $DEST"
  exit 0
fi

if [ -e "$DEST" ]; then
  backup_dir="$HOME/.backup/$(date +%Y%m%d-%H%M%S)"
  mkdir -p "$backup_dir"
  mv --backup=numbered "$DEST" "$backup_dir/desktop-pc.remmina"
  log "existing profile moved to: $backup_dir/desktop-pc.remmina"
fi
( umask 077; printf '%s\n' "$content" > "$DEST" )
log "generated: $DEST"
