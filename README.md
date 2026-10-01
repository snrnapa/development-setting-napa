# development-setting-napa

devcontainer（`mcr.microsoft.com/devcontainers/base:bookworm`、ユーザー vscode）の中で
tmux + Claude Code を使う個人開発環境を、コンテナ内でコマンドを打って再現するためのスクリプト集。
リビルドで `$HOME` が消えても、このリポジトリを clone してスクリプトを流せば戻る。

- 対象: Debian bookworm / x86_64・arm64 / passwordless sudo
- プロジェクト側の `.devcontainer/` には一切触らない
- 個人用。秘密情報は置かない

## 使い方

```bash
git clone <this repo> ~/dev-setup && cd ~/dev-setup
bash install-all.sh                # 全部
bash scripts/install-tmux.sh       # 個別（実行権限が無くても bash 経由で動く）
```

## スクリプト

| スクリプト | 責務 | 状態 |
|---|---|---|
| `scripts/install-tmux.sh` | tmux 本体の導入のみ | 作成済み |
| `scripts/config-tmux.sh` | `~/.tmux.conf` の配置（本体は `config/tmux.conf`） | 未 |
| `scripts/install-lazygit.sh` / `config-lazygit.sh` | lazygit 導入と設定（tmux prefix+g で popup） | 未 |
| `scripts/install-search-tools.sh` | fzf / fd / ripgrep | 未 |
| `scripts/install-neovim.sh` / `config-neovim.sh` | Neovim（LazyVim） | 未 |
| `scripts/install-markdown-viewer.sh` | glow ほか | 未 |
| `install-all.sh` | 上を順に実行 | 未 |
| `scripts/lib/common.sh` | 共通関数（アーキ判定、sudo、apt、ログ） | 作成済み |

## 共通ルール

- 冪等（何度流しても安全）。既存設定は上書き前に `~/.backup/<timestamp>/` へ退避
- `set -euo pipefail`、導入済みならスキップ、終了時に導入バージョンを表示
- `uname -m` で amd64 / arm64 を切り替え
- バージョンは各スクリプト冒頭で固定（環境変数で上書き可）、checksum が配布されるものは検証
- 設定ファイルは symlink で配置（リポジトリを編集すれば即反映）

## 確認手順

| スクリプト | 確認 |
|---|---|
| install-tmux | `tmux -V` が `tmux 3.3a` を返す。2 回目の実行は skip と表示される |
