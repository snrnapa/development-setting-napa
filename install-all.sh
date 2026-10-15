#!/usr/bin/env bash
# scripts/ の導入・設定スクリプトをまとめて実行する。各スクリプトは冪等なので何度流してもよい。
# 1 つ失敗しても残りは続行し、最後に結果の一覧を出す（失敗があれば終了コード 1）。
#   WITH_REMMINA=1   Remmina（GUI 環境向け。接続先を対話で聞く）も実行する。既定は実行しない
# Claude Code 本体が入っていなければ、Claude Code のプラグイン導入は skip する。
# devcontainer でホストの ~/.claude をマウントしている時は、ホスト側の設定を書き換えないよう
# Claude Code の設定・プラグイン導入をどちらも skip する（ホストで設定済みのものがそのまま使われる）。
# devcontainer の dotfiles 機能から自動実行される前提なので、対話入力を求めるものは含めない。
set -euo pipefail
# shellcheck source=scripts/lib/common.sh
source "$(dirname "${BASH_SOURCE[0]}")/scripts/lib/common.sh"

S="$REPO_ROOT/scripts"

# 実行順。neovim は本体 → 設定、他の install-*.sh は自分で config-*.sh を呼ぶ
steps=(
  install-tmux.sh
  install-search-tools.sh
  install-neovim.sh
  config-neovim.sh
  install-lazygit.sh
  install-markdown-viewer.sh
  config-claude.sh
  install-claude-plugins.sh
)
[ "${WITH_REMMINA:-0}" = "1" ] && steps+=(install-remmina.sh)

# ~/.claude がホストからのマウントか（mountpoint は util-linux。無い環境ではマウント無しとみなす）
claude_dir_mounted() { have_cmd mountpoint && mountpoint -q "$HOME/.claude"; }

results=()
failed=0
for step in "${steps[@]}"; do
  if [[ "$step" == *claude* ]] && claude_dir_mounted; then
    warn "~/.claude is a mount (host の設定), skip: $step"
    results+=("SKIP  $step（~/.claude がマウントされている）")
    continue
  fi
  if [ "$step" = "install-claude-plugins.sh" ] && ! have_cmd claude; then
    warn "claude not found, skip: $step（Claude Code を入れてから単体で実行してください）"
    results+=("SKIP  $step")
    continue
  fi

  log "===== $step ====="
  if bash "$S/$step"; then
    results+=("OK    $step")
  else
    warn "failed: $step"
    results+=("FAIL  $step")
    failed=1
  fi
done

[ "${WITH_REMMINA:-0}" = "1" ] || results+=("SKIP  install-remmina.sh（WITH_REMMINA=1 で実行）")

log "===== summary ====="
printf '  %s\n' "${results[@]}"
exit "$failed"
