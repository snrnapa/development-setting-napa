#!/usr/bin/env bash
# Neovim 本体の導入のみ（設定は config-neovim.sh）。
# 公式リリースの tarball を /opt/nvim-<version> に展開し、/usr/local/bin/nvim へ symlink する。
# apt 版は distro ごとに古さがまちまち（bookworm は 0.7 系）で、プラグインが動かないため使わない。
#   NVIM_VERSION=v0.12.5   導入するバージョン（上書きすると checksum 検証は NVIM_SHA256 を指定した時のみ）
#   NVIM_SHA256=<hex>      上書き時の tarball の sha256
set -euo pipefail
# shellcheck source=lib/common.sh
source "$(dirname "${BASH_SOURCE[0]}")/lib/common.sh"

DEFAULT_VERSION="v0.12.5"
NVIM_VERSION="${NVIM_VERSION:-$DEFAULT_VERSION}"

# DEFAULT_VERSION の tarball の sha256（GitHub release の asset digest）
case "$ARCH_GNU" in
  x86_64)  ASSET="nvim-linux-x86_64.tar.gz"; DEFAULT_SHA256="bce0f56eda1f1b1db6eee8f4133d7a38813ea07933837dd1777411ca384c6875" ;;
  aarch64) ASSET="nvim-linux-arm64.tar.gz";  DEFAULT_SHA256="1aa5ca085249580ae0f91eb14f27ec0919773ff2d99a163d03f3d6c21ac29725" ;;
esac

if [ "$NVIM_VERSION" = "$DEFAULT_VERSION" ]; then
  SHA256="${NVIM_SHA256:-$DEFAULT_SHA256}"
else
  SHA256="${NVIM_SHA256:-}"
  [ -n "$SHA256" ] || warn "NVIM_VERSION を上書きしたが NVIM_SHA256 が未指定: checksum は検証されません"
fi

# 導入済みなら skip（apt 版など別バージョンが入っていても、指定バージョンに揃える）
if have_cmd nvim && nvim --version | head -1 | grep -qxF "NVIM $NVIM_VERSION"; then
  log "already installed, skip: $(nvim --version | head -1)"
  exit 0
fi

# tarball は glibc 依存。bookworm / Ubuntu 22.04 以降なら問題ない
have_cmd curl || apt_install curl ca-certificates

tmp="$(mktemp -d)"
trap 'rm -rf "$tmp"' EXIT

log "downloading neovim $NVIM_VERSION ($ASSET) ..."
curl -fsSL -o "$tmp/$ASSET" "https://github.com/neovim/neovim/releases/download/$NVIM_VERSION/$ASSET"

if [ -n "$SHA256" ]; then
  echo "$SHA256  $tmp/$ASSET" | sha256sum -c --quiet - || die "checksum mismatch: $ASSET"
  log "checksum ok"
fi

dest="/opt/nvim-$NVIM_VERSION"
$SUDO rm -rf "$dest"
$SUDO mkdir -p "$dest"
$SUDO tar -xzf "$tmp/$ASSET" -C "$dest" --strip-components=1
$SUDO ln -sfn "$dest/bin/nvim" /usr/local/bin/nvim

hash -r
log "installed: $(/usr/local/bin/nvim --version | head -1)"
