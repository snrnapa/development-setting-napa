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
