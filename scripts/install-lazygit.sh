#!/usr/bin/env bash
# lazygit（Git の TUI）と delta（差分の整形表示。lazygit の差分表示に使う）の導入と、
# 設定の反映（配置の実体は config-lazygit.sh）。どちらも公式リリースの単体バイナリを /usr/local/bin に置く。
#   LAZYGIT_VERSION=0.66.1  LAZYGIT_SHA256=<hex>   lazygit のバージョンと tarball の sha256
#   DELTA_VERSION=0.20.1    DELTA_SHA256=<hex>     delta のバージョンと tarball の sha256
#   （バージョンを上書きした時は、対応する *_SHA256 を指定した時のみ checksum を検証する）
set -euo pipefail
# shellcheck source=lib/common.sh
source "$(dirname "${BASH_SOURCE[0]}")/lib/common.sh"

# 既定バージョンの tarball の sha256（GitHub release の asset digest）
LAZYGIT_DEFAULT_VERSION="0.66.1"
DELTA_DEFAULT_VERSION="0.20.1"
case "$ARCH_GNU" in
  x86_64)
    LAZYGIT_ARCH="x86_64"
    LAZYGIT_DEFAULT_SHA256="7b3f30c2c06a42cf575280f907e58d7ea08411408b6b62bc926bc91cbc6c3f46"
    DELTA_DEFAULT_SHA256="50f08c879f84c81ceb220e476491a7f492d2c9c671e79918cc44badf961a6240"
    ;;
  aarch64)
    LAZYGIT_ARCH="arm64"
    LAZYGIT_DEFAULT_SHA256="add91327af13343f37d2d610512d0982ef5c75da5cc962b5159748adc8a11a86"
    DELTA_DEFAULT_SHA256="da7f4338f593572ff426ae153e0870e2fdc72729416eff551b40cdeb67940db8"
    ;;
esac

# --- lazygit ---
LAZYGIT_VERSION="${LAZYGIT_VERSION:-$LAZYGIT_DEFAULT_VERSION}"
if have_cmd lazygit && lazygit --version | grep -qF "version=$LAZYGIT_VERSION,"; then
  log "already installed, skip: lazygit $LAZYGIT_VERSION"
else
  sha="$(resolve_sha256 "$LAZYGIT_VERSION" "$LAZYGIT_DEFAULT_VERSION" "$LAZYGIT_DEFAULT_SHA256" "${LAZYGIT_SHA256:-}" LAZYGIT_SHA256)"
  asset="lazygit_${LAZYGIT_VERSION}_linux_${LAZYGIT_ARCH}.tar.gz"
  install_tarball_binary \
    "https://github.com/jesseduffield/lazygit/releases/download/v$LAZYGIT_VERSION/$asset" \
    "$sha" "lazygit" "lazygit"
  hash -r
  log "installed: lazygit $(lazygit --version | sed -n 's/.*version=\([^,]*\),.*/\1/p')"
fi

# --- delta ---
DELTA_VERSION="${DELTA_VERSION:-$DELTA_DEFAULT_VERSION}"
if have_cmd delta && [ "$(delta --version)" = "delta $DELTA_VERSION" ]; then
  log "already installed, skip: delta $DELTA_VERSION"
else
  sha="$(resolve_sha256 "$DELTA_VERSION" "$DELTA_DEFAULT_VERSION" "$DELTA_DEFAULT_SHA256" "${DELTA_SHA256:-}" DELTA_SHA256)"
  dir="delta-${DELTA_VERSION}-${ARCH_GNU}-unknown-linux-gnu"
  install_tarball_binary \
    "https://github.com/dandavison/delta/releases/download/$DELTA_VERSION/$dir.tar.gz" \
    "$sha" "$dir/delta" "delta"
  hash -r
  log "installed: $(delta --version)"
fi

# 導入済みでも設定は毎回反映する（冪等）
bash "$(dirname "${BASH_SOURCE[0]}")/config-lazygit.sh"
