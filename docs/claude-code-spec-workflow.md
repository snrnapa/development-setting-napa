# Claude Code での個人開発の進め方

Claude Projects でアイデアを詰めてから Claude Code に移す二度手間をやめ、立ち上げ・壁打ち・実装を Claude Code だけで回すための手順。
自作の Skill は作らず、評価の高い既存のプラグインをそのまま使う。困りごとが実際に 2 回起きたら、そのとき道具を足す。

## セットアップ（一括）

```bash
bash scripts/install-claude-plugins.sh   # config/claude/plugins.txt のプラグインを user スコープで一括導入
```

導入後に Claude Code を再起動する。プラグインを足したり外したりするときは `config/claude/plugins.txt` を編集して流し直す（リストから消してもアンインストールはされないので、外すときは `claude plugin uninstall <id>`）。

| プラグイン | 役割 | 常時コスト |
|---|---|---|
| superpowers | 立ち上げの設計（brainstorming）、実装時の規律（TDD・デバッグ・完了前検証・worktree） | 約 840 tok |
| mattpocock-skills | 壁打ち（`/grill-me` `/grill-with-docs`）、ドメインモデリング | 約 1,600 tok |
| claude-md-management | `/revise-claude-md` でセッションの学びを CLAUDE.md に反映 | 約 180 tok |
| context7 | ライブラリの最新ドキュメントを参照（外部の mcp.context7.com に問い合わせる） | ほぼ 0 |
| frontend-design | UI の見た目の質（ありがちな AI っぽい見た目を避ける） | 約 80 tok |
| ui-ux-pro-max | UI/UX の知識ベース（スタイル・配色・フォント・UX ガイドライン）。python3 が必要 | 約 1,070 tok |
| playwright | ブラウザ操作・E2E テスト（MCP） | ほぼ 0 |
| security-guidance | 編集時の脆弱性パターン警告、ターン終了時の差分レビュー、コミット前レビュー | 0（hook のみ） |

常時コストは `claude plugin details <名前>` の値で、合計は約 3.8k tok。

## 場面ごとの使い方

| 場面 | やること |
|---|---|
| 新しいプロジェクトを立ち上げる | 作りたいものを普通に話す。superpowers の brainstorming が起動し、1 問ずつ質問して設計書を作る |
| 思いついたこと・気づいたことをさっと壁打ちする | `/grill-me <思いついたこと>`。論点がなくなるまで質問を重ねて形にする（ファイルは書かない） |
| 壁打ちの結論を記録に残す | `/grill-with-docs <論点>`。用語集（GLOSSARY.md）と決定記録（ADR）をその場で更新する |
| 実装する（在席） | 普通に頼む。superpowers の TDD・デバッグが必要に応じて効く |
| 実装する（離席） | `おまかせ`（`~/.claude/CLAUDE.md` の自律オーケストレーション） |
| 条件を満たすまで回す | `/goal <完了条件>`（例: `/goal test/ の全テストが通り lint がクリーン。または 20 ターンで停止`） |
| CLAUDE.md を整える | `/revise-claude-md` |

### 専門の Skill は Claude が自動で選ぶ

UI を作る・直すといった依頼をすると、frontend-design や ui-ux-pro-max のような専門の Skill を Claude が説明文から判断して自動で使う。
確実に使わせたいときは「ui-ux-pro-max を使って」のように名前を出す。

## 他の人と一緒に開発するとき

設定を 2 層に分ける。

| 層 | 置き場所 | 中身 |
|---|---|---|
| 個人の作業環境 | このリポジトリ（development-setting-napa） | 自分が使うプラグイン一式、tmux・Neovim など。参考として共有はするが、相手に強制しない |
| プロジェクトのルール | プロジェクトのリポジトリ（例: hogoneko-repo） | CLAUDE.md、docs/（設計書・用語集・ADR）、`.claude/settings.json` |

プロジェクトで必須のプラグインは、プロジェクトの `.claude/settings.json` に書いてコミットする。
フォルダを信頼すると、マーケットプレイスは自動で登録される。プラグインは、各自がインストールする必要がある場合がある。

```json
{
  "extraKnownMarketplaces": {
    "ui-ux-pro-max-skill": {
      "source": { "source": "github", "repo": "nextlevelbuilder/ui-ux-pro-max-skill" }
    }
  },
  "enabledPlugins": {
    "superpowers@claude-plugins-official": true,
    "mattpocock-skills@claude-plugins-official": true,
    "frontend-design@claude-plugins-official": true,
    "ui-ux-pro-max@ui-ux-pro-max-skill": true
  }
}
```

個人だけで使うものはプロジェクト側に書かない（各自の `~/.claude` に任せる）。プロジェクトで有効になっているプラグインを自分だけ外すときは、`.claude/settings.local.json` で `false` にする。

## 注意

- `/grill-with-docs` は、リポジトリごとに一度 `/setup-matt-pocock-skills` が必要な場合がある（README に記載。未検証）
- mattpocock-skills の `tdd` `code-review` `diagnosing-bugs` は superpowers と役割が重なる。どちらが起動しても大きな害はないが、気になったら外す
- security-guidance はターン終了時に差分をレビューするので、応答が遅く感じたら最初に外す候補
- ui-ux-pro-max のマーケットプレイスは GitHub から SSH で clone される。SSH 鍵のない環境で失敗したら `claude plugin marketplace add https://github.com/nextlevelbuilder/ui-ux-pro-max-skill` を先に流す

## 入れないもの

| プラグイン | 理由 |
|---|---|
| feature-dev | 探索→質問→設計→実装→レビューの流れが superpowers・おまかせと重複する |
| ralph-loop | `/goal` と重複する |
| code-review / code-simplifier | 組み込みの `/code-review` / `/simplify` と重複する |
| github | `gh` CLI で足りる |

## 参考

- [obra/superpowers](https://github.com/obra/superpowers)
- [mattpocock/skills](https://github.com/mattpocock/skills)
- [nextlevelbuilder/ui-ux-pro-max-skill](https://github.com/nextlevelbuilder/ui-ux-pro-max-skill)
- [Claude Code 公式: /goal](https://code.claude.com/docs/en/goal)
- [Claude Code 公式: settings（enabledPlugins / extraKnownMarketplaces）](https://code.claude.com/docs/en/settings-reference)
