#!/usr/bin/env bash
# tmux 本体の導入と、設定の反映（配置の実体は config-tmux.sh）。bookworm の apt 版 (3.3a) を使う。
set -euo pipefail
# shellcheck source=lib/common.sh
source "$(dirname "${BASH_SOURCE[0]}")/lib/common.sh"

if have_cmd tmux; then
  log "already installed, skip: $(tmux -V)"
else
  log "installing tmux via apt ..."
  apt_install tmux
  log "installed: $(tmux -V)"
fi

# 導入済みでも設定は毎回反映する（冪等）
bash "$(dirname "${BASH_SOURCE[0]}")/config-tmux.sh"
