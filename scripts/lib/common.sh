#!/usr/bin/env bash
# 共通関数。直接実行せず、各スクリプトから source して使う。
# 呼び出し側で `set -euo pipefail` を設定しておくこと。

# shellcheck disable=SC2034  # 呼び出し側スクリプトが使う
REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"

log()  { printf '[%s] %s\n' "$(basename "$0")" "$*"; }
warn() { printf '[%s] WARN: %s\n' "$(basename "$0")" "$*" >&2; }
die()  { printf '[%s] ERROR: %s\n' "$(basename "$0")" "$*" >&2; exit 1; }

have_cmd() { command -v "$1" >/dev/null 2>&1; }

# アーキテクチャ判定。リリースごとに表記が違うので両方持つ。
#   ARCH_DEB: amd64 / arm64      ARCH_GNU: x86_64 / aarch64
case "$(uname -m)" in
  x86_64|amd64)  ARCH_DEB=amd64; ARCH_GNU=x86_64  ;;
  aarch64|arm64) ARCH_DEB=arm64; ARCH_GNU=aarch64 ;;
  *) die "unsupported architecture: $(uname -m)" ;;
esac

# root なら sudo 不要、それ以外は sudo 必須
if [ "$(id -u)" -eq 0 ]; then
  SUDO=""
else
  have_cmd sudo || die "sudo not found (run as root or install sudo)"
  SUDO="sudo"
fi

_APT_UPDATED=0
apt_install() {
  if [ "$_APT_UPDATED" -eq 0 ]; then
    $SUDO apt-get update -qq
    _APT_UPDATED=1
  fi
  $SUDO env DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends "$@"
}

# 単体バイナリ・symlink の置き場所
BIN_DIR="/usr/local/bin"

# GitHub release などの tar.gz を取得し、中の実行ファイル 1 つを $BIN_DIR/<name> に置く。
#   install_tarball_binary <url> <sha256（空なら検証しない）> <tarball 内のパス> <name>
# 一時ディレクトリの後始末に trap を使うので、呼び出し側の trap を壊さないようサブシェルで動かす。
install_tarball_binary() (
  url="$1" sha256="$2" member="$3" name="$4"
  have_cmd curl || apt_install curl ca-certificates

  tmp="$(mktemp -d)"
  trap 'rm -rf "$tmp"' EXIT

  log "downloading $name: $url"
  curl -fsSL -o "$tmp/pkg.tar.gz" "$url"
  if [ -n "$sha256" ]; then
    echo "$sha256  $tmp/pkg.tar.gz" | sha256sum -c --quiet - || die "checksum mismatch: $url"
    log "checksum ok"
  fi

  tar -xzf "$tmp/pkg.tar.gz" -C "$tmp" "$member"
  $SUDO install -m 0755 "$tmp/$member" "$BIN_DIR/$name"
)

# バージョン上書き時の checksum 決定（install-neovim.sh と同じ規則）。
#   resolve_sha256 <指定バージョン> <既定バージョン> <既定 sha256> <上書き用 sha256> <上書き用変数名>
resolve_sha256() {
  if [ "$1" = "$2" ]; then
    printf '%s' "${4:-$3}"
  else
    [ -n "$4" ] || warn "バージョンを上書きしたが $5 が未指定: checksum は検証されません"
    printf '%s' "$4"
  fi
}
