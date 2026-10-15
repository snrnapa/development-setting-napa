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
bash install-all.sh                # 全部（Remmina 以外。失敗があっても続行し、最後に結果一覧を表示）
WITH_REMMINA=1 bash install-all.sh # Remmina も含める（GUI 環境向け）
bash scripts/install-tmux.sh       # 個別（実行権限が無くても bash 経由で動く）
```

## devcontainer で使う（dotfiles 方式）

他のリポジトリを devcontainer で開く時は、Dev Containers の dotfiles 機能でこのリポジトリを自動導入する。
コンテナ作成時に `~/dotfiles` へ clone して `install-all.sh` を実行する（リビルドの度に 1〜2 分。再起動では走らない）。プロジェクト側の `.devcontainer/` は触らない。

- VS Code で開く場合: ユーザー設定（`~/.config/Code/User/settings.json`）に以下を入れておくだけ
  ```json
  "dotfiles.repository": "https://github.com/snrnapa/development-setting-napa",
  "dotfiles.targetPath": "~/dotfiles",
  "dotfiles.installCommand": "install-all.sh"
  ```
- VS Code を使わない場合: プロジェクトのディレクトリで `bash <このリポジトリ>/scripts/devcontainer-up.sh`。コンテナを起動して tmux に入る（2 回目以降は既存コンテナの tmux に再接続）
- 反映されるのは GitHub に push 済みの内容。設定を変えたら push してからリビルドする
- コンテナ内に Claude Code 本体は入らない（install-all.sh は本体を導入しない）
- Markdown のブラウザプレビュー（8090）は VS Code なら自動でポート転送される。devcontainer CLI だけの場合は転送されない

## スクリプト

| スクリプト | 責務 | 状態 |
|---|---|---|
| `scripts/install-tmux.sh` | tmux 本体の導入 + `config-tmux.sh` の呼び出し（導入済みでも設定は反映） | 作成済み |
| `scripts/config-tmux.sh` | `config/tmux/.tmux.conf` を `~/.tmux.conf` に symlink。起動中の tmux があれば再読み込み | 作成済み |
| `scripts/config-claude.sh` | Claude Code のステータスライン。`config/claude/statusline.sh` を `~/.claude/statusline.sh` に symlink し、`~/.claude/settings.json` の `statusLine` だけを設定（他のキーは保持、変更前に退避）。jq が無ければ apt で導入 | 作成済み |
| `scripts/install-claude-plugins.sh` | `config/claude/plugins.txt` に並べた Claude Code プラグイン（superpowers / mattpocock-skills / claude-md-management / context7 / frontend-design / ui-ux-pro-max / playwright / security-guidance）を user スコープで一括導入。マーケットプレイス未登録なら追加、導入済みで無効なら有効化。リストから消してもアンインストールはしない。claude CLI が必要 | 作成済み |
| `scripts/install-remmina.sh` | Remmina（RDP クライアント）の導入（apt）+ `config-remmina.sh` の呼び出し。GUI 環境向け | 作成済み |
| `scripts/config-remmina.sh` | `config/remmina/desktop-pc.remmina.template` に接続先・ユーザー名を埋めて `~/.local/share/remmina/desktop-pc.remmina` を生成。値は環境変数か `~/.config/development-setting-napa/remmina.env`（無ければ対話入力して保存）。IP とユーザー名は公開リポジトリに置かないためテンプレートには入れない。パスワードは扱わない | 作成済み |
| `scripts/install-lazygit.sh` | lazygit（Git の TUI）と delta（差分の整形表示）の導入（公式 tarball、バージョン固定・sha256 検証。`/usr/local/bin`）+ `config-lazygit.sh` の呼び出し | 作成済み |
| `scripts/config-lazygit.sh` | `config/lazygit/config.yml` を `~/.config/lazygit/config.yml` に symlink（差分は delta で表示、`e` で nvim）。tmux の `prefix + g` で popup 起動（設定は `.tmux.conf` 側） | 作成済み |
| `scripts/install-search-tools.sh` | ripgrep（rg）/ fd / fzf の導入（apt）。Debian / Ubuntu の fd は `fdfind` という名前なので、`fd` が無ければ `/usr/local/bin/fd` に symlink | 作成済み |
| `scripts/install-neovim.sh` | Neovim 本体（公式 tarball、v0.12.5 固定・sha256 検証。`/opt/nvim-<ver>` → `/usr/local/bin/nvim`） | 作成済み |
| `scripts/config-neovim.sh` | `config/nvim/` を `~/.config/nvim` に symlink し、プラグインを `lazy-lock.json` の版で事前取得。最小構成（lazy.nvim + nvim-tree + telescope + gitsigns + diffview + render-markdown + markdown-preview） | 作成済み |
| `scripts/install-markdown-viewer.sh` | ターミナル用 Markdown ビューア glow の導入（公式 tarball、バージョン固定・sha256 検証。`/usr/local/bin`）。Neovim 内の表示・ブラウザプレビューは config-neovim 側 | 作成済み |
| `scripts/devcontainer-up.sh` | VS Code を使わずにプロジェクトの devcontainer を起動し、中の tmux（セッション main）に入る。起動時にこのリポジトリを dotfiles として clone させ `install-all.sh` を実行させる。devcontainer CLI が無ければ npx で版固定して使う | 作成済み |
| `install-all.sh` | tmux → 検索ツール → Neovim（本体・設定）→ lazygit → glow → Claude Code（ステータスライン・プラグイン）の順に実行。1 つ失敗しても続行し、最後に OK / FAIL / SKIP の一覧を出す（FAIL があれば終了コード 1）。claude CLI が無ければプラグイン導入は SKIP。`~/.claude` がマウント（devcontainer でホストの設定を共有）されていれば Claude Code の設定・プラグイン導入はどちらも SKIP（ホストの設定を書き換えないため）。Remmina は `WITH_REMMINA=1` の時だけ | 作成済み |
| `scripts/lib/common.sh` | 共通関数（アーキ判定、sudo、apt、ログ） | 作成済み |

## 手順メモ（docs/）

スクリプト化していない、または GUI 操作が中心の環境構築の手順メモ。

| ドキュメント | 内容 |
|---|---|
| `docs/remote-desktop-ubuntu-to-windows.md` | Ubuntu ノートPC (Remmina) から Windows 11 へ RDP 接続。疎通確認・Windows 側設定・画面/音声の調整 |
| `docs/claude-code-spec-workflow.md` | Claude Code での個人開発の進め方。プラグインの一括導入、場面ごとの使い方（立ち上げ・`/grill-me` での壁打ち・実装）、他の人と開発するときの設定の分け方 |

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
| config-claude | `~/.claude/settings.json` の `statusLine` が設定され、Claude Code を再起動すると 3 行表示（モデル/ディレクトリ・ctx/費用・5h/7d 制限）。2 回目は already linked / already set と表示される |
| install-claude-plugins | 最後の一覧に `plugins.txt` のプラグインがすべて enabled で出る。2 回目はすべて already installed と表示される |
| config-neovim | `nvim` で `<C-p>` がファイル検索、`<leader>e`（leader=Space）がファイルツリー、`<leader>gd` で作業中の差分、`.md` を開くと整形表示。2 回目は already linked と表示される |
| install-lazygit | `lazygit --version` に `version=0.66.1`、`delta --version` が `delta 0.20.1`。2 回目はどちらも skip と already linked と表示される。tmux 内で `prefix + g` で lazygit が popup で開き、差分が delta 表示になる |
| install-search-tools | `rg --version` / `fd --version` / `fzf --version` が通る。`nvim` で `<leader>fg` が使える。2 回目はすべて skip と表示される |
| install-markdown-viewer | `glow --version` が `glow version 3.0.0`。`glow README.md` で整形表示。2 回目は skip と表示される |
| config-remmina | 環境変数 `REMMINA_RDP_SERVER` `REMMINA_RDP_USER` を渡して実行すると `~/.local/share/remmina/desktop-pc.remmina` ができる。2 回目は already up to date と表示される。値を変えて流すと既存を `~/.backup/` に退避して作り直す。Remmina で接続し、Windows キー / Alt+Tab がリモート側に効く（未確認） |

## Neovim メモ

- キー: `<C-p>` ファイル名検索 / `<leader>e` ファイルツリー開閉 / `<leader>fg` 文字列検索（要 ripgrep）/ `<leader>fb` バッファ / `<leader>fr` 最近のファイル
- Git: `<leader>gd` 作業中の変更（左にファイル一覧・右に左右並びの差分）/ `<leader>gh` コミット履歴（全体）/ `<leader>gf` コミット履歴（このファイル）/ `<leader>gq` 閉じる。行番号横の印で変更行、`]c` `[c` で変更箇所へ移動、`<leader>hp` 差分プレビュー、`<leader>hr` 元に戻す、`<leader>hb` blame
- Markdown: `.md` を開くとバッファ内で整形表示（`<leader>mr` で切り替え）。画像・Mermaid は `<leader>mp` でブラウザプレビュー（相対パスの画像も表示される）。ポートは 8090 固定。ブラウザが無い環境（devcontainer 等）では URL が表示されるので、8090 をポート転送して開く。別の nvim で同時にプレビューするとポートが衝突するので `MKDP_PORT=8091 nvim` のように変える
- 要件は Neovim >= 0.11（telescope.nvim）。apt 版（Ubuntu 24.04 は 0.9.5、bookworm は 0.7 系）では動かないので install-neovim.sh を使う
- アイコンは Nerd Font 無しでも崩れないよう無効化している
- `config/nvim/lazy-lock.json` はプラグインのバージョン固定。config-neovim.sh はこの版で入れる（`:Lazy sync` は使わない）。更新したい時は `nvim` で `:Lazy update` して差分をコミットする
- バージョン上書き: `NVIM_VERSION=v0.12.6 NVIM_SHA256=<tarball の sha256> bash scripts/install-neovim.sh`

## lazygit メモ

- 起動: tmux 内で `prefix + g`（カレントディレクトリのリポジトリを popup で開く）、または `lazygit`。`q` で閉じる
- `4` でコミット一覧（グラフ表示）→ コミットで Enter で変更ファイル一覧 → ファイルを選ぶと右に差分。マウスクリックも可
- 差分は delta で表示。`|` で git 標準表示に切り替え。`e` でファイルを nvim で開く
- `git diff` などコマンドラインの差分には delta を設定していない（`~/.gitconfig` は触らない方針）。使いたい場合は `git config --global core.pager delta`
- バージョン上書き: `LAZYGIT_VERSION=x.y.z LAZYGIT_SHA256=<sha256> bash scripts/install-lazygit.sh`（delta は `DELTA_VERSION` / `DELTA_SHA256`、glow は `GLOW_VERSION` / `GLOW_SHA256`）

## Claude Code ステータスライン メモ

- 表示: 1 行目 モデル・effort・ディレクトリ(git ブランチ)・変更行数 / 2 行目 コンテキスト使用率とトークン・セッション費用・経過時間 / 3 行目 5 時間制限・7 日制限の使用率とリセットまでの残り
- 値は Claude Code が stdin で渡す JSON をそのまま使う（ccusage 等の外部集計は不要）。依存は jq のみ
- `rate_limits`（5h/7d）は claude.ai の Pro/Max 契約のみで、セッション最初の API 応答後に出る。それまで・API キー利用時は `--` 表示
- `cost` は list price からの概算で、実際の請求額とは異なる場合がある
- 使用率の色: 50% 未満=緑 / 80% 未満=黄 / 80% 以上=赤
