# Claude Code で仕様の壁打ちから実装まで進める

個人開発で、Claude Projects でアイデアを詰めてから Claude Code に移す、という二度手間をやめるための手順メモ。
仕様も Claude Code 上で対話しながら固め、決まったことはリポジトリ内の Markdown に残す。

（2026-10-14 時点の調査）

## 方針

- 仕様・コード・決定理由を同じリポジトリに置き、git で管理する
- Claude Code の会話は次のセッションに残らない。前提を毎回話さないで済むよう、決定事項は都度ファイルに書き戻す
- Claude Projects が向くのは、コードと関係ないアイデア出しや資料の読み込みだけ。スマホからも claude.ai/code で Claude Code が使える

| Claude Projects | Claude Code での置き場所 |
|---|---|
| カスタム指示 | プロジェクトの `CLAUDE.md`（毎回自動で読み込まれる） |
| ナレッジ（資料） | `docs/` 配下の Markdown |
| 会話で仕様を詰める進め方 | Skill / プラグイン（下記の Superpowers） |

## 使える既存の仕組み

| 名前 | 特徴 | 向き |
|---|---|---|
| Superpowers（obra/superpowers） | brainstorming スキルが 1 問ずつ質問し、2〜3 案を推奨付きで出し、設計を区切りごとに承認させて `docs/superpowers/specs/` に設計書を書く。その後 writing-plans → 実装へ進む | 壁打ちで仕様を固めたい（第一候補） |
| cc-sdd | Kiro 風の仕様駆動開発。要件 → 設計 → タスクの順に文書化。日本語対応 | 型の決まった仕様書がほしい |
| GitHub Spec Kit | `/specify` → `/plan` → `/tasks`。対応エージェントが多い | 堅めに進めたい |
| BMAD Method | 役割別エージェントが多数 | 個人開発には重い |

## 手順

### 1. Superpowers を導入する

```bash
bash scripts/install-superpowers.sh
```

Anthropic 公式マーケットプレイス `claude-plugins-official` から user スコープで入れる（中身は `claude plugin install superpowers@claude-plugins-official --scope user`）。導入後は Claude Code を再起動する。
作者のマーケットプレイス（`obra/superpowers-marketplace`）からも入れられるが、公式の方を使う。

### 2. 新しいプロジェクトで壁打ちする

1. 空のリポジトリを作り `git init` する
2. Claude Code を起動し、作りたいものを伝える（例: 「保護猫団体が保護から譲渡までを管理するアプリを作りたい」）
3. brainstorming が起動し、Claude が質問してくるので答える。設計は区切りごとに承認する
4. できた設計書をコミットする

Claude Projects で話した内容がある場合は、Projects 側で「ここまでの決定事項を全部まとめて」と出力させ、最初に貼り付ける。

### 3. 実装する

次のどちらかに寄せる（役割が重なるので混ぜない）。

- Superpowers の流れのまま writing-plans → 実装まで進める
- 仕様までを Superpowers で作り、実装は `おまかせ`（`~/.claude/CLAUDE.md` の自律オーケストレーション）に渡す。この場合、`おまかせ` のフェーズ0は設計書を読んで足りない点だけ聞くように直すと二度手間にならない

大きめの作業は `/goal <完了条件>` で、条件を満たすまで回すこともできる（例: `/goal test/ の全テストが通り lint がクリーン`）。

## 参考

- [Superpowers deep dive](https://www.heyuan110.com/posts/ai/2026-02-01-superpowers-deep-dive/)
- [Claude brainstorming skill guide](https://mcp.directory/blog/claude-brainstorming-skill-guide)
- [Spec Kit vs OpenSpec vs BMAD vs Superpowers](https://developertoolkit.ai/en/ecosystem/frameworks/spec-driven-frameworks/)
- [仕様駆動開発ツール比較（Spec Kit・Kiro・cc-sdd・OpenSpec・Tessl）](https://www.issoh.co.jp/tech/details/8732/)
- [Claude Code 公式: /goal](https://code.claude.com/docs/en/goal)
