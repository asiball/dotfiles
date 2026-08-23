#!/usr/bin/env bash
# -------------------------------------------------------------------------
# Claude Code CLI Status Line
#
# https://code.claude.com/docs/ja/statusline
# -------------------------------------------------------------------------

# 表示のON/OFF (0/1)
SHOW_USER_HOST=0    # bashrc の PS1 風に user@host を先頭へ
SHOW_GIT=1
SHOW_GIT_DIFF=1    # HEAD との差分行数 (git diff HEAD の集計)
SHOW_CTX=1
SHOW_CTX_BAR=0     # ctx は数値のみ (1 にするとバーも出す)
SHOW_COST=1
SHOW_LIMITS=1
SHOW_RESET=1       # レート制限のリセットまでの残り時間を () で添える
SHOW_DURATION=1

# プログレスバーの文字（フォントによって見え方が変わるので差し替え可）
BAR_FULL='▰'
BAR_EMPTY='▱'

input=$(cat)
timeout_cmd=""; command -v timeout >/dev/null && timeout_cmd="timeout 1s"   # macOS 標準には GNU timeout が無い

# ---- 🎨 ------------------------------------------------------------------
R=$'\033[0m'; DIM=$'\033[90m'; B=$'\033[1m'; C_LBL=$'\033[37m'
C_HOST=$'\033[01;32m'; C_DIR=$'\033[01;34m'; C_MODEL=$'\033[36m'
C_OK=$'\033[32m'; C_WARN=$'\033[33m'; C_BAD=$'\033[31m'; C_ACC=$'\033[35m'

# ---- 入力 JSON をまとめて取り出す --------------------------------------
# 区切りは US(0x1f)。TAB は IFS 空白扱いなので空フィールドが詰められてしまう。
# 割合は小数があり得る(docs: 23.5)ので jq 側で floor しておく。整数比較で落ちるため。
IFS=$'\x1f' read -r cwd project_dir model_name effort fast_mode style \
                   ctx_pct cost dur_ms \
                   rl5 rl5_at rl7 rl7_at pr_num pr_state worktree < <(
  printf '%s' "$input" | jq -r '
    def pct: if . == null then -1 else (tonumber? // -1 | floor) end;
    def num: (tonumber? // 0 | floor);
    [ (.workspace.current_dir // .cwd // ""),
      (.workspace.project_dir // ""),
      (.model.display_name // "?"),
      (.effort.level // ""),
      (.fast_mode // false | tostring),
      (.output_style.name // ""),
      (.context_window.used_percentage | pct | tostring),
      (.cost.total_cost_usd // 0 | tostring),
      (.cost.total_duration_ms     | num | tostring),
      (.rate_limits.five_hour.used_percentage | pct | tostring),
      (.rate_limits.five_hour.resets_at       | num | tostring),
      (.rate_limits.seven_day.used_percentage | pct | tostring),
      (.rate_limits.seven_day.resets_at       | num | tostring),
      (.pr.number // "" | tostring),
      (.pr.review_state // ""),
      (.workspace.git_worktree // .worktree.name // "")
    ] | join("")' 2>/dev/null
)
[ -n "$cwd" ] || cwd=$PWD
[ -n "$model_name" ] || model_name="?"
# jq 自体が落ちた場合に備えて数値項目を既定値へ（整数比較でエラーになるのを防ぐ）
: "${ctx_pct:=-1}" "${rl5:=-1}" "${rl7:=-1}" "${rl5_at:=0}" "${rl7_at:=0}" "${dur_ms:=0}"

# ---- 端末幅に応じた密度 --------------------------------------------------
cols=${COLUMNS:-100}
if   [ "$cols" -ge 100 ]; then bw_ctx=12; bw_lim=8; compact=0
elif [ "$cols" -ge 76  ]; then bw_ctx=10; bw_lim=6; compact=0
else                           bw_ctx=8;  bw_lim=0; compact=1
fi

# ---- ヘルパ --------------------------------------------------------------------
# BAR にプログレスバーを組み立てる: mkbar <pct> <width>
mkbar() {
  local p=$1 w=$2 f fill="" pad=""
  [ "$w" -le 0 ] && { BAR=""; return; }
  [ "$p" -gt 100 ] && p=100; [ "$p" -lt 0 ] && p=0
  f=$(( p * w / 100 ))
  [ "$f" -eq 0 ] && [ "$p" -gt 0 ] && f=1  # わずかでも使っていれば1マスは点ける
  [ "$f" -gt 0 ] && { printf -v fill "%${f}s"; fill=${fill// /"$BAR_FULL"}; }
  [ $((w-f)) -gt 0 ] && { printf -v pad "%$((w-f))s"; pad=${pad// /"$BAR_EMPTY"}; }
  BAR="${fill}${pad}"
}
# COL に閾値色を入れる: pctcol <pct> [warn] [bad]
pctcol() {
  local p=$1 wa=${2:-60} ba=${3:-85}
  if   [ "$p" -ge "$ba" ]; then COL=$C_BAD
  elif [ "$p" -ge "$wa" ]; then COL=$C_WARN
  else COL=$C_OK; fi
}
# REM に「あと○」を入れる: remain <epoch>
remain() {
  local s=$(( $1 - $(printf '%(%s)T' -1) )) d h m
  REM=""
  [ "$s" -le 0 ] && return
  d=$((s/86400)); h=$((s%86400/3600)); m=$((s%3600/60))
  if   [ "$d" -gt 0 ]; then REM="${d}d${h}h"
  elif [ "$h" -gt 0 ]; then REM="${h}h${m}m"
  else                      REM="${m}m"; fi
}
join_segs() {  # 引数の配列名を | で連結して OUT へ
  local -n _a=$1; local s; OUT=""
  for s in "${_a[@]}"; do [ -n "$OUT" ] && OUT+=" ${DIM}|${R} "; OUT+="$s"; done
}

# ============================== 1行目 ============================================
l1=()

[ "$SHOW_USER_HOST" = 1 ] && l1+=("${C_HOST}$(whoami)@$(hostname -s)${R}")

# ---- カレントディレクトリ -------------------------------------------------
# プロジェクト配下なら「プロジェクト名/相対パス」、外なら ~ 置換。長ければ末尾3階層。
if [ -n "$project_dir" ] && [ "$cwd" = "$project_dir" ]; then
  disp=${project_dir##*/}
elif [ -n "$project_dir" ] && [[ $cwd == "$project_dir"/* ]]; then
  disp="${project_dir##*/}/${cwd#"$project_dir"/}"
else
  disp=$cwd
  [ "$disp" = "$HOME" ] && disp='~'
  [[ $disp == "$HOME"/* ]] && disp="~/${disp#"$HOME"/}"
fi
IFS='/' read -r -a _p <<< "$disp"
[ ${#_p[@]} -gt 4 ] && disp="…/${_p[-3]}/${_p[-2]}/${_p[-1]}"
[ -n "$worktree" ] && disp+="${DIM}@${worktree}${R}"
l1+=("${C_DIR}${disp}${R}")

# ---- git ------------------------------------------------------------------
if [ "$SHOW_GIT" = 1 ] &&
   gs=$($timeout_cmd git --no-optional-locks -C "$cwd" status --porcelain=v2 --branch 2>/dev/null); then
  read -r br ahead behind staged modif untrk confl <<< "$(
    awk '
      /^# branch\.head /{b=$3}
      /^# branch\.oid /{o=$3}
      /^# branch\.ab /{a=$3; d=$4; sub(/^\+/,"",a); sub(/^-/,"",d)}
      /^[12] /{x=substr($2,1,1); y=substr($2,2,1); if(x!=".")s++; if(y!=".")m++}
      /^u /{c++}
      /^\? /{u++}
      END{if(b=="(detached)")b="@" substr(o,1,7); print (b==""?"-":b),a+0,d+0,s+0,m+0,u+0,c+0}
    ' <<< "$gs"
  )"
  lim_br=24; [ "$compact" = 1 ] && lim_br=14
  [ ${#br} -gt $lim_br ] && br="${br:0:$((lim_br-1))}…"
  gcol=$C_OK; [ $(( staged + modif + untrk + confl )) -gt 0 ] && gcol=$C_WARN
  g="${gcol}${br}${R}"
  [ "$staged" -gt 0 ] && g+=" ${C_OK}+${staged}${R}"
  [ "$modif"  -gt 0 ] && g+=" ${C_WARN}~${modif}${R}"
  [ "$untrk"  -gt 0 ] && g+=" ${DIM}?${untrk}${R}"
  [ "$confl"  -gt 0 ] && g+=" ${C_BAD}!${confl}${R}"
  [ "$ahead"  -gt 0 ] && g+=" ${C_ACC}↑${ahead}${R}"
  [ "$behind" -gt 0 ] && g+=" ${C_ACC}↓${behind}${R}"
  # HEAD との差分行数。追跡ファイルに変更が無ければ diff を呼ぶまでもない。
  if [ "$SHOW_GIT_DIFF" = 1 ] && [ $(( staged + modif )) -gt 0 ]; then
    read -r add del <<< "$(
      $timeout_cmd git --no-optional-locks -C "$cwd" diff HEAD --numstat 2>/dev/null |
        awk '{a+=$1; d+=$2} END{print a+0, d+0}'
    )"
    [ "${add:-0}" -gt 0 ] || [ "${del:-0}" -gt 0 ] &&
      g+=" ${DIM}(${R}${C_OK}+${add}${R}${DIM}/${R}${C_BAD}-${del}${R}${DIM})${R}"
  fi
  l1+=("$g")
fi

# ---- PR (オープンPRがある時だけ) ------------------------------------------
if [ -n "$pr_num" ]; then
  case "$pr_state" in
    approved)          pc=$C_OK   ;;
    changes_requested) pc=$C_BAD  ;;
    pending)           pc=$C_WARN ;;
    *)                 pc=$DIM    ;;
  esac
  l1+=("${pc}#${pr_num}${R}")
fi

# ---- モデル ----------------------------------------------------------------
m="${C_MODEL}${model_name/ context)/)}${R}"
[ "$fast_mode" = true ] && m+="${C_WARN}⚡${R}"
[ -n "$effort" ] && [ "$effort" != medium ] && m+="${DIM}·${effort}${R}"
[ -n "$style" ]  && [ "$style"  != default ] && m+="${DIM}·${style}${R}"
l1+=("$m")

# ============================== 2行目 ============================================
l2=()

# ---- コンテキスト ----------------------------------------------------------
if [ "$SHOW_CTX" = 1 ] && [ "$ctx_pct" -ge 0 ]; then
  pctcol "$ctx_pct" 60 85
  BAR=""; [ "$SHOW_CTX_BAR" = 1 ] && mkbar "$ctx_pct" "$bw_ctx"
  s="${C_LBL}ctx${R} ${BAR:+${COL}${BAR}${R} }${COL}"
  [ "$ctx_pct" -ge 85 ] && s+="$B"
  l2+=("${s}${ctx_pct}%${R}")
fi

# ---- レート制限 ------------------------------------------------------------
if [ "$SHOW_LIMITS" = 1 ]; then
  lim=""
  for pair in "5h:$rl5:$rl5_at" "7d:$rl7:$rl7_at"; do
    IFS=: read -r lbl val at <<< "$pair"
    [ "${val:--1}" -ge 0 ] 2>/dev/null || continue
    pctcol "$val" 75 90; mkbar "$val" "$bw_lim"
    [ -n "$lim" ] && lim+=" "
    lim+="${C_LBL}${lbl}${R} ${BAR:+${COL}${BAR}${R} }${COL}${val}%${R}"
    if [ "$SHOW_RESET" = 1 ] && [ "$compact" = 0 ] && [ "${at:-0}" -gt 0 ]; then
      remain "$at"; [ -n "$REM" ] && lim+=" ${DIM} (${REM})${R}"
    fi
  done
  [ -n "$lim" ] && l2+=("$lim")
fi

# ---- コストと差分行数 ------------------------------------------------------
if [ "$SHOW_COST" = 1 ] && [ -n "$cost" ]; then
  l2+=("${DIM}$(printf '%s' "$cost" | awk '{printf "$%.2f", $1+0}')${R}")
fi

# ---- 経過時間 --------------------------------------------------------------
if [ "$SHOW_DURATION" = 1 ] && [ "$compact" = 0 ] && [ "${dur_ms:-0}" -gt 0 ]; then
  t=$((dur_ms/1000))
  if   [ $t -ge 3600 ]; then d=$(printf '%dh%02dm' $((t/3600)) $((t%3600/60)))
  elif [ $t -ge 60 ];   then d="$((t/60))m"
  else                       d="${t}s"; fi
  l2+=("${DIM} ${d}${R}")
fi

# ============================== 出力 ============================================
join_segs l1; line1=$OUT
join_segs l2; line2=$OUT
printf '%s\n' "$line1"
[ -n "$line2" ] && printf '%s\n' "$line2"
exit 0
