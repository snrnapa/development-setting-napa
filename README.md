# development-setting-napa

devcontainer（`mcr.microsoft.com/devcontainers/base:bookworm`、ユーザー vscode）の中で
tmux + Claude Code を使う個人開発環境を、コンテナ内でコマンドを打って再現するためのスクリプト集。
リビルドで `$HOME` が消えても、このリポジトリを clone してスクリプトを流せば戻る。

- 対象: Debian bookworm・Ubuntu 24.04 / x86_64・arm64 / passwordless sudo
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
| `scripts/install-tmux.sh` | tmux 本体の導入 + `config-tmux.sh` の呼び出し（導入済みでも設定は反映） | 作成済み |
| `scripts/config-tmux.sh` | `config/tmux/.tmux.conf` を `~/.tmux.conf` に symlink。起動中の tmux があれば再読み込み | 作成済み |
| `scripts/install-lazygit.sh` / `config-lazygit.sh` | lazygit 導入と設定（tmux prefix+g で popup） | 未 |
| `scripts/install-search-tools.sh` | fzf / fd / ripgrep | 未 |
| `scripts/install-neovim.sh` | Neovim 本体（公式 tarball、v0.12.5 固定・sha256 検証。`/opt/nvim-<ver>` → `/usr/local/bin/nvim`） | 作成済み |
| `scripts/config-neovim.sh` | `config/nvim/` を `~/.config/nvim` に symlink し、プラグインを事前取得。最小構成（lazy.nvim + nvim-tree + telescope） | 作成済み |
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
| install-tmux | `tmux -V` が `tmux 3.3a` を返す。2 回目の実行は skip（本体）と already linked（設定）と表示される |
| config-tmux | `ls -l ~/.tmux.conf` が `config/tmux/.tmux.conf` への symlink。tmux 内で `prefix + |` が左右分割 |
| install-neovim | `nvim --version` が `NVIM v0.12.5`。2 回目の実行は skip と表示される |
| config-neovim | `nvim` で `<C-p>` がファイル検索、`<leader>e`（leader=Space）がファイルツリー。2 回目は already linked と表示される |

## Neovim メモ

- キー: `<C-p>` ファイル名検索 / `<leader>e` ファイルツリー開閉 / `<leader>fg` 文字列検索（要 ripgrep）/ `<leader>fb` バッファ / `<leader>fr` 最近のファイル
- 要件は Neovim >= 0.11（telescope.nvim）。apt 版（Ubuntu 24.04 は 0.9.5、bookworm は 0.7 系）では動かないので install-neovim.sh を使う
- アイコンは Nerd Font 無しでも崩れないよう無効化している
- `config/nvim/lazy-lock.json` はプラグインのバージョン固定。更新したい時は `nvim` で `:Lazy update` して差分をコミットする
- バージョン上書き: `NVIM_VERSION=v0.12.6 NVIM_SHA256=<tarball の sha256> bash scripts/install-neovim.sh`
