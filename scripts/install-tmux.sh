#!/usr/bin/env bash
# tmux 本体の導入のみ（設定は config-tmux.sh）。bookworm の apt 版 (3.3a) を使う。
set -euo pipefail
# shellcheck source=lib/common.sh
source "$(dirname "${BASH_SOURCE[0]}")/lib/common.sh"

if have_cmd tmux; then
  log "already installed, skip: $(tmux -V)"
  exit 0
fi

log "installing tmux via apt ..."
apt_install tmux
log "installed: $(tmux -V)"
