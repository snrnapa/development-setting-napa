#!/usr/bin/env bash
# Claude Code のステータスライン。stdin の JSON（Claude Code が渡す）を読んで 3 行を出す。
#   1行目: モデル / effort / ディレクトリ(git ブランチ) / 変更行数
#   2行目: コンテキスト使用率・トークン / セッション費用 / 経過時間
#   3行目: 5 時間制限・7 日制限の使用率とリセットまでの残り（Pro/Max 契約のみ。初回応答後に出る）
# 依存: jq のみ。無い場合は何も出さない。
export LC_ALL=C

command -v jq >/dev/null 2>&1 || { echo "statusline: jq not found"; exit 0; }

IFS=$'\t' read -r model effort dir ctx_pct ctx_tok ctx_max cost dur_ms lines_add lines_del h5 h5_reset d7 d7_reset < <(
  jq -r '[
    (.model.display_name // "?"),
    (.effort.level // "-"),
    (.workspace.current_dir // .cwd // "."),
    (.context_window.used_percentage // "-"),
    (.context_window.total_input_tokens // "-"),
    (.context_window.context_window_size // "-"),
    (.cost.total_cost_usd // "-"),
    (.cost.total_duration_ms // "-"),
    (.cost.total_lines_added // 0),
    (.cost.total_lines_removed // 0),
    (.rate_limits.five_hour.used_percentage // "-"),
    (.rate_limits.five_hour.resets_at // "-"),
    (.rate_limits.seven_day.used_percentage // "-"),
    (.rate_limits.seven_day.resets_at // "-")
  ] | @tsv' 2>/dev/null
)
[ -n "${model:-}" ] || { echo "statusline: bad input"; exit 0; }

RST=$'\033[0m'; DIM=$'\033[2m'; BOLD=$'\033[1m'
GRN=$'\033[32m'; YEL=$'\033[33m'; RED=$'\033[31m'; CYN=$'\033[36m'; MAG=$'\033[35m'
SEP="${DIM} │ ${RST}"

# 使用率(%) → 色
color_for() {
  local p=${1%.*}
  if   [ "$p" -ge 80 ]; then printf '%s' "$RED"
  elif [ "$p" -ge 50 ]; then printf '%s' "$YEL"
  else printf '%s' "$GRN"; fi
}

# 使用率(%) → 色付き 10 マスのバー + 数値
bar() {
  local p=${1%.*} filled i out=""
  [ "$p" -gt 100 ] && p=100
  filled=$(( p / 10 ))
  for ((i = 0; i < 10; i++)); do
    if [ "$i" -lt "$filled" ]; then out+="▓"; else out+="░"; fi
  done
  printf '%s%s %s%%%s' "$(color_for "$p")" "$out" "$p" "$RST"
}

# 12345 → 12.3k, 1500000 → 1.5M
human() {
  awk -v n="$1" 'BEGIN{ if (n>=1000000) printf "%.1fM", n/1000000; else if (n>=1000) printf "%.1fk", n/1000; else printf "%d", n }'
}

# epoch 秒 → "2h10m" / "3d4h" / "5m"
until_reset() {
  local s=$(( $1 - $(date +%s) ))
  [ "$s" -le 0 ] && { printf 'now'; return; }
  if   [ "$s" -ge 86400 ]; then printf '%dd%dh' $(( s / 86400 )) $(( s % 86400 / 3600 ))
  elif [ "$s" -ge 3600  ]; then printf '%dh%dm' $(( s / 3600 )) $(( s % 3600 / 60 ))
  else printf '%dm' $(( s / 60 )); fi
}

limit_seg() { # label pct reset_epoch
  if [ "$2" = "-" ]; then
    printf '%s%s --%s' "$DIM" "$1" "$RST"
  else
    printf '%s %s' "$1" "$(bar "$2")"
    [ "$3" != "-" ] && printf '%s (残り %s)%s' "$DIM" "$(until_reset "$3")" "$RST"
  fi
}

# --- 1行目 ---
line1="${BOLD}${CYN}[${model}]${RST}"
[ "$effort" != "-" ] && line1+=" ${DIM}${effort}${RST}"
line1+="${SEP}${MAG}${dir##*/}${RST}"
if branch=$(git -C "$dir" symbolic-ref --short -q HEAD 2>/dev/null || git -C "$dir" rev-parse --short HEAD 2>/dev/null); then
  dirty=""
  [ -n "$(git -C "$dir" status --porcelain -uno 2>/dev/null | head -1)" ] && dirty="*"
  line1+=" ${DIM}(${branch}${dirty})${RST}"
fi
if [ "$lines_add" != "0" ] || [ "$lines_del" != "0" ]; then
  line1+="${SEP}${GRN}+${lines_add}${RST} ${RED}-${lines_del}${RST}"
fi

# --- 2行目 ---
if [ "$ctx_pct" = "-" ]; then
  line2="ctx ${DIM}--${RST}"
else
  line2="ctx $(bar "$ctx_pct")"
  [ "$ctx_tok" != "-" ] && [ "$ctx_max" != "-" ] && line2+=" ${DIM}$(human "$ctx_tok")/$(human "$ctx_max")${RST}"
fi
[ "$cost" != "-" ] && line2+="${SEP}\$$(awk -v c="$cost" 'BEGIN{printf "%.2f", c}')"
if [ "$dur_ms" != "-" ]; then
  m=$(( ${dur_ms%.*} / 60000 ))
  if [ "$m" -ge 60 ]; then line2+="${SEP}$(( m / 60 ))h$(( m % 60 ))m"; else line2+="${SEP}${m}m"; fi
fi

# --- 3行目 ---
line3="$(limit_seg 5h "$h5" "$h5_reset")${SEP}$(limit_seg 7d "$d7" "$d7_reset")"

printf '%s\n%s\n%s\n' "$line1" "$line2" "$line3"
