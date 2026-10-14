#!/usr/bin/env bash
# Remmina（RDP クライアント）の導入と、接続プロファイルの反映（配置の実体は config-remmina.sh）。
# GUI 環境（Ubuntu Desktop 等）向け。devcontainer では不要。
set -euo pipefail
# shellcheck source=lib/common.sh
source "$(dirname "${BASH_SOURCE[0]}")/lib/common.sh"

if have_cmd remmina && dpkg -s remmina-plugin-rdp >/dev/null 2>&1; then
  log "already installed, skip: $(dpkg-query -W -f='remmina ${Version}' remmina)"
else
  log "installing remmina via apt ..."
  apt_install remmina remmina-plugin-rdp
  log "installed: $(dpkg-query -W -f='remmina ${Version}' remmina)"
fi

# 導入済みでも設定は毎回反映する（冪等）
bash "$(dirname "${BASH_SOURCE[0]}")/config-remmina.sh"
