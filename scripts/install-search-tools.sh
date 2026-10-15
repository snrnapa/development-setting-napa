#!/usr/bin/env bash
# 検索ツール ripgrep（rg）/ fd / fzf の導入（apt 版）。
#   - rg: Neovim の <leader>fg（文字列検索）に必要
#   - fd: Debian / Ubuntu ではコマンド名が fdfind になるので、fd が無ければ $BIN_DIR/fd に symlink する
#   - fzf: シェルでのあいまい検索（Ctrl-R の履歴検索などは各自のシェル設定で有効化）
set -euo pipefail
# shellcheck source=lib/common.sh
source "$(dirname "${BASH_SOURCE[0]}")/lib/common.sh"

# コマンド名:apt パッケージ名
tools=(rg:ripgrep fdfind:fd-find fzf:fzf)

missing=()
for t in "${tools[@]}"; do
  cmd="${t%%:*}" pkg="${t#*:}"
  # fd が既にあれば（別経路で導入済み）fd-find は入れない
  if [ "$cmd" = "fdfind" ] && have_cmd fd; then cmd=fd; fi
  if have_cmd "$cmd"; then
    log "already installed, skip: $cmd"
  else
    missing+=("$pkg")
  fi
done

if [ "${#missing[@]}" -gt 0 ]; then
  log "installing via apt: ${missing[*]} ..."
  apt_install "${missing[@]}"
  hash -r
fi

if ! have_cmd fd && have_cmd fdfind; then
  $SUDO ln -sfn "$(command -v fdfind)" "$BIN_DIR/fd"
  hash -r
  log "linked: $BIN_DIR/fd -> $(command -v fdfind)"
fi

log "installed: $(rg --version | head -1) / $(fd --version) / fzf $(fzf --version | cut -d' ' -f1)"
