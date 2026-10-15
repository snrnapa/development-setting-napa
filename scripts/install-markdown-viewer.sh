#!/usr/bin/env bash
# ターミナル用の Markdown ビューア glow の導入。公式リリースの単体バイナリを /usr/local/bin に置く。
# Neovim 内での表示（render-markdown.nvim）とブラウザプレビュー（markdown-preview.nvim）は
# config-neovim.sh 側で入る。
#   GLOW_VERSION=3.0.0  GLOW_SHA256=<hex>   バージョンと tarball の sha256
#   （バージョンを上書きした時は GLOW_SHA256 を指定した時のみ checksum を検証する）
set -euo pipefail
# shellcheck source=lib/common.sh
source "$(dirname "${BASH_SOURCE[0]}")/lib/common.sh"

# 既定バージョンの tarball の sha256（GitHub release の asset digest）
GLOW_DEFAULT_VERSION="3.0.0"
case "$ARCH_GNU" in
  x86_64)  GLOW_ARCH="x86_64"; GLOW_DEFAULT_SHA256="13e05e4b2acc18d2aee44291aefe6325b077ec321b631a0cfa780e8e3bc33f78" ;;
  aarch64) GLOW_ARCH="arm64";  GLOW_DEFAULT_SHA256="810c39f4691feb75e675a5f5f54b9fa091354e7599d9cf9c9fc9b97e47a99759" ;;
esac

GLOW_VERSION="${GLOW_VERSION:-$GLOW_DEFAULT_VERSION}"
# glow --version の出力: "glow version 3.0.0 (add5e7a)"
if have_cmd glow && glow --version | grep -qE "^glow version $GLOW_VERSION( |$)"; then
  log "already installed, skip: glow $GLOW_VERSION"
  exit 0
fi

sha="$(resolve_sha256 "$GLOW_VERSION" "$GLOW_DEFAULT_VERSION" "$GLOW_DEFAULT_SHA256" "${GLOW_SHA256:-}" GLOW_SHA256)"
dir="glow_${GLOW_VERSION}_Linux_${GLOW_ARCH}"
install_tarball_binary \
  "https://github.com/charmbracelet/glow/releases/download/v$GLOW_VERSION/$dir.tar.gz" \
  "$sha" "$dir/glow" "glow"
hash -r
log "installed: $(glow --version)"
