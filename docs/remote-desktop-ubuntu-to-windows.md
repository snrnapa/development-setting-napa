# Ubuntu ノートPC から Windows 11 デスクトップへリモートデスクトップ接続する

自宅 LAN 内で、Ubuntu ノートPC (Remmina) から Windows 11 デスクトップ (RDP) に接続した時の手順メモ。
IP などは例。実際の値に読み替える（このリポジトリは秘密情報を置かない方針）。

- 前提: デスクトップとノートPCが同じ LAN（同じサブネット、Wi-Fi）にいる
- 以下のコマンドは、デスクトップの IP（Windows 側で `ipconfig` の IPv4 アドレス）を `DESKTOP_IP` に入れてから使う

## 1. 疎通確認（ノートPC側）

```bash
DESKTOP_IP=<デスクトップのIP>
ip -4 addr show                      # 自分のIP。相手と同じサブネットか
ping -c 4 "$DESKTOP_IP"             # 応答なしでも異常とは限らない（下記）
ip neigh show "$DESKTOP_IP"         # REACHABLE ならMACが取れており、相手は起動してLAN上にいる
for p in 22 3389 5900; do            # 待ち受けポートの確認
  timeout 3 bash -c "</dev/tcp/$DESKTOP_IP/$p" 2>/dev/null && echo "$p OPEN" || echo "$p closed/filtered"
done
```

読み方:

| 結果 | 意味 |
|---|---|
| ping 失敗 + ARP は REACHABLE | Windows の既定は ICMP を遮断する。起動はしている。ping の失敗だけで諦めない |
| 3389 が closed/filtered | Windows 側でリモートデスクトップが無効、またはファイアウォール |
| 3389 が OPEN | RDP で接続できる |

## 2. Windows 11 側の設定

- 「設定 → システム → リモートデスクトップ」をオンにする（3389 で待ち受け開始）
- **Pro 以上のエディションが必要**。Home は接続を受け付けられない
- Microsoft アカウントでサインインしている場合、ユーザー名はメールアドレス、パスワードはアカウントのパスワード（PIN は使えない）

## 3. ノートPC側の接続 (Remmina)

1. Remmina を起動し、プロトコルを RDP にしてサーバー欄に IP を入れて Enter
2. 証明書の警告は、自宅 LAN 内の自分の PC なら承認して進む

## 4. 接続後の調整

初期状態の問題と原因（`クイック接続` のプロファイルを確認して判明）:

| 症状 | 原因 | 直し方 |
|---|---|---|
| 画面が小さい | ウィンドウ 892x480 に縮小して接続している（`resolution_mode=2`） | 解像度をカスタム or クライアント解像度に。ツールバーのスケーリング/全画面も可 |
| 音が出ない | `sound=off` | 音声出力を「ローカル」にする (`sound=local`) |

Remmina の GUI での操作: 接続を切る → プロファイルを右クリック → 編集 → 基本タブ（解像度・色深度）/ 詳細タブ（音声出力）→ 保存。

> 注: 上記の変更後に実際に表示・音声が直ったかは、この時点では未確認。確認したらここを更新する。

## 5. 設定をコードで管理する（新しい環境への引き継ぎ）

```bash
REMMINA_RDP_SERVER=<デスクトップのIP> REMMINA_RDP_USER=<Windowsのユーザー名> bash scripts/install-remmina.sh
```

- `install-remmina.sh` が Remmina を apt で入れ、`config-remmina.sh` が接続プロファイルを生成する
- テンプレートは `config/remmina/desktop-pc.remmina.template`。IP とユーザー名は `@SERVER@` `@USER@` のままで、**このリポジトリは公開なので実際の値は入れない**
- 値は環境変数、または `~/.config/development-setting-napa/remmina.env`（権限 600、リポジトリ外）から読む。どちらも無ければ対話で聞いて env ファイルに保存する。2 回目以降は入力不要
- パスワードは保存しない。接続時に Remmina が聞く
- 証明書の警告を無視する設定は入れていない。初回接続時に承認する（自宅 LAN 内の自分の PC の場合）
- Remmina が保存時にファイルを書き換えるため、symlink ではなく生成ファイル。内容が同じなら何もせず、違えば既存を `~/.backup/<日時>/` に退避して作り直す。**GUI で変えた設定は、テンプレートに反映しないと次回の実行で上書きされる**

テンプレートの主な設定:

| キー | 値 | 意味 |
|---|---|---|
| `sound` | `local` | 音をノートPC側で鳴らす |
| `resolution_mode` | `1` | クライアント(ノートPC)の解像度を使う |
| `keyboard_grab` | `1` | キーボードを取り込み、Windows キーや Alt+Tab をリモート側へ送る |

> 注: `keyboard_grab` が Wayland で実際に効くかは未確認。効かなければ「Ubuntu on Xorg」セッションで試す。

プロファイルの場所と、手で編集するときの注意:

```
~/.local/share/remmina/desktop-pc.remmina
```

Remmina 起動中に手で編集すると上書きされることがあるので、閉じてから編集するか GUI で変更する。
実際の接続情報(IP・ユーザー名)を含むので、生成されたファイル自体はリポジトリに入れない。

## 6. 他の選択肢（未使用）

- 22 (SSH)・5900 (VNC) は今回は閉じており、使っていない
