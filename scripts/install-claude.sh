#!/usr/bin/env bash
# Claude Code 本体の導入のみ（設定は config-claude.sh、プラグインは install-claude-plugins.sh）。
# 公式のネイティブインストーラ（https://claude.ai/install.sh）で ~/.local/bin/claude に入れる。
# インストーラ自身が配布物の sha256 を検証する。sudo は不要。ログインは導入後に `claude` で行う。
#   CLAUDE_VERSION=stable   導入する版（stable / latest / 1.2.3 のようなバージョン）
# 既に claude コマンドがあれば（npm 版など導入方法を問わず）skip する。
set -euo pipefail
# shellcheck source=lib/common.sh
source "$(dirname "${BASH_SOURCE[0]}")/lib/common.sh"

CLAUDE_VERSION="${CLAUDE_VERSION:-stable}"
export PATH="$HOME/.local/bin:$PATH"

if have_cmd claude; then
  log "already installed, skip: claude $(claude --version 2>/dev/null | head -1)"
  exit 0
fi

have_cmd curl || apt_install curl ca-certificates

log "installing claude code ($CLAUDE_VERSION) via official installer ..."
curl -fsSL https://claude.ai/install.sh | bash -s "$CLAUDE_VERSION"

hash -r
have_cmd claude || die "claude not found after install: ~/.local/bin を PATH に入れてください"
log "installed: claude $(claude --version 2>/dev/null | head -1)（ログインは claude を起動して行う）"
