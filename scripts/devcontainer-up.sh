#!/usr/bin/env bash
# VS Code を使わずにプロジェクトの devcontainer を起動し、中の tmux に入る。
# 起動時にこのリポジトリを dotfiles として ~/dotfiles に clone させ、install-all.sh を実行させる
# （コンテナ作成時の 1 回だけ。再起動・2 回目以降の実行では走らない）。プロジェクトの .devcontainer/ は触らない。
#   使い方: bash scripts/devcontainer-up.sh [プロジェクトのディレクトリ（既定: カレント）]
#   DOTFILES_REPO=<url>              dotfiles のリポジトリ（既定: このリポジトリの GitHub）
#   DEVCONTAINER_CLI_VERSION=0.89.0  devcontainer CLI が未導入の時に npx で使う版
set -euo pipefail
# shellcheck source=lib/common.sh
source "$(dirname "${BASH_SOURCE[0]}")/lib/common.sh"

WORKSPACE="$(cd "${1:-.}" && pwd)"
DOTFILES_REPO="${DOTFILES_REPO:-https://github.com/snrnapa/development-setting-napa}"
DEVCONTAINER_CLI_VERSION="${DEVCONTAINER_CLI_VERSION:-0.89.0}"

if have_cmd devcontainer; then
  dc=(devcontainer)
elif have_cmd npx; then
  dc=(npx -y "@devcontainers/cli@$DEVCONTAINER_CLI_VERSION")
else
  die "devcontainer CLI も npx も見つかりません: npm i -g @devcontainers/cli で導入してください"
fi

log "starting devcontainer: $WORKSPACE (dotfiles: $DOTFILES_REPO)"
"${dc[@]}" up --workspace-folder "$WORKSPACE" \
  --dotfiles-repository "$DOTFILES_REPO" \
  --dotfiles-install-command install-all.sh

# tmux のセッション main に入る（あれば再接続）。tmux が無い時（導入失敗など）は bash
exec "${dc[@]}" exec --workspace-folder "$WORKSPACE" \
  sh -c 'if command -v tmux >/dev/null 2>&1; then exec tmux new-session -A -s main; else exec bash; fi'
