#!/bin/bash
# ╔══════════════════════════════════════════════════════════╗
# ║  claude-code-statusline — Powerline Preset              ║
# ║  Powerline-style segments with arrow separators         ║
# ╚══════════════════════════════════════════════════════════╝
#
# L1:  Opus 4.6  my-app  main +2 ~3  INS
# L2: ━━━━━━━──── 42% │ 1.2M ↑↓ │ $0.83 │ 56m13s
# L3: 5h ━━━━── 72% 1h30m │ 7d ━━━── 45% 48h

input=$(cat)

MODEL=$(echo "$input" | jq -r '.model.display_name // "Claude"' | sed -E 's/^Claude //')
DIR=$(echo "$input"   | jq -r '.workspace.current_dir // .cwd // ""')
COST=$(echo "$input"  | jq -r '.cost.total_cost_usd // 0')
PCT=$(echo "$input"   | jq -r '.context_window.used_percentage // 0' | cut -d. -f1)
DUR=$(echo "$input"   | jq -r '.cost.total_duration_ms // 0')
VIM_MODE=$(echo "$input" | jq -r '.vim.mode // empty')
TOK_IN=$(echo "$input"  | jq -r '.context_window.total_input_tokens // 0')
TOK_OUT=$(echo "$input" | jq -r '.context_window.total_output_tokens // 0')
RL5H_PCT=$(echo "$input"    | jq -r '.rate_limits.five_hour.used_percentage // empty')
RL5H_RESET=$(echo "$input"  | jq -r '.rate_limits.five_hour.resets_at // empty')
RL7D_PCT=$(echo "$input"    | jq -r '.rate_limits.seven_day.used_percentage // empty')
RL7D_RESET=$(echo "$input"  | jq -r '.rate_limits.seven_day.resets_at // empty')

# ANSI
C='\033[36m'; G='\033[32m'; Y='\033[33m'; R='\033[31m'
M='\033[35m'; BOLD='\033[1m'; DIM='\033[2m'; RST='\033[0m'
# Background colors for powerline segments
BG_C='\033[46m'; BG_B='\033[44m'; BG_G='\033[42m'; BG_M='\033[45m'
FG_BLK='\033[30m'

dir_name="${DIR##*/}"; [ -z "$dir_name" ] && dir_name="/"

# Git
GIT_SEG=""
if [ -n "$DIR" ] && git -C "$DIR" rev-parse --git-dir >/dev/null 2>&1; then
  BRANCH=$(git -C "$DIR" --no-optional-locks branch --show-current 2>/dev/null)
  [ -z "$BRANCH" ] && BRANCH=$(git -C "$DIR" --no-optional-locks rev-parse --short HEAD 2>/dev/null)
  STAGED=$(git -C "$DIR" --no-optional-locks diff --cached --numstat 2>/dev/null | wc -l | tr -d ' ')
  MODIFIED=$(git -C "$DIR" --no-optional-locks diff --numstat 2>/dev/null | wc -l | tr -d ' ')
  UNTRACKED=$(git -C "$DIR" --no-optional-locks ls-files --others --exclude-standard 2>/dev/null | wc -l | tr -d ' ')
  CHANGES=""
  [ "$STAGED"    -gt 0 ] 2>/dev/null && CHANGES=" +${STAGED}"
  [ "$MODIFIED"  -gt 0 ] 2>/dev/null && CHANGES="${CHANGES} ~${MODIFIED}"
  [ "$UNTRACKED" -gt 0 ] 2>/dev/null && CHANGES="${CHANGES} ?${UNTRACKED}"
  GIT_SEG=" ${DIM}│${RST} ${G}${BRANCH}${CHANGES}${RST}"
fi

# Vim
VIM_SEG=""
if [ -n "$VIM_MODE" ]; then
  case "$VIM_MODE" in
    NORMAL)  VIM_SEG=" ${DIM}│${RST} ${C}NOR${RST}" ;;
    INSERT)  VIM_SEG=" ${DIM}│${RST} ${G}${BOLD}INS${RST}" ;;
    VISUAL)  VIM_SEG=" ${DIM}│${RST} ${M}VIS${RST}" ;;
    *)       VIM_SEG=" ${DIM}│${RST} ${Y}${VIM_MODE}${RST}" ;;
  esac
fi

# Context bar
BAR_W=12; FILLED=$((PCT * BAR_W / 100))
[ "$FILLED" -gt "$BAR_W" ] && FILLED=$BAR_W
if   [ "$PCT" -ge 90 ]; then BAR_C="$R"
elif [ "$PCT" -ge 70 ]; then BAR_C="$Y"
else                          BAR_C="$G"; fi
BAR=""; i=0
while [ $i -lt $FILLED ];  do BAR="${BAR}━"; i=$((i+1)); done
while [ $i -lt "$BAR_W" ]; do BAR="${BAR}─"; i=$((i+1)); done

# Duration
TOTAL_S=$((DUR / 1000))
if [ "$TOTAL_S" -ge 3600 ]; then TIME_STR="$((TOTAL_S/3600))h$((TOTAL_S%3600/60))m$((TOTAL_S%60))s"
elif [ "$TOTAL_S" -ge 60 ]; then TIME_STR="$((TOTAL_S/60))m$((TOTAL_S%60))s"
else TIME_STR="${TOTAL_S}s"; fi

COST_FMT=$(printf '$%.2f' "$COST")

# Token
fmt_tok() {
  local n="$1"
  if [ "$n" -ge 1000000 ]; then printf "%d.%dM" "$((n/1000000))" "$(((n%1000000)/100000))"
  elif [ "$n" -ge 1000 ]; then
    local k=$((n/1000))
    [ "$k" -ge 100 ] && printf "%dK" "$k" || printf "%d.%dK" "$k" "$(((n%1000)/100))"
  else printf "%d" "$n"; fi
}
TOK_TOTAL=$((TOK_IN + TOK_OUT))
TOK_FMT=$(fmt_tok "$TOK_TOTAL")
TOK_IN_FMT=$(fmt_tok "$TOK_IN")
TOK_OUT_FMT=$(fmt_tok "$TOK_OUT")

# Rate limit bar
make_rate_bar() {
  local pct; pct=$(printf "%.0f" "$1" 2>/dev/null || echo 0)
  local w=8 color bar="" i=0
  if   [ "$pct" -ge 90 ]; then color="$R"
  elif [ "$pct" -ge 70 ]; then color="$Y"
  else                          color="$G"; fi
  local filled=$(( pct * w / 100 ))
  while [ $i -lt $filled ]; do bar="${bar}━"; i=$((i+1)); done
  while [ $i -lt $w ];      do bar="${bar}─"; i=$((i+1)); done
  printf "%b%s%b %s%%" "$color" "$bar" "$RST" "$pct"
}

format_reset() {
  local now; now=$(date +%s); local diff=$(( $1 - now ))
  [ "$diff" -le 0 ] && printf "now" && return
  local h=$(( diff / 3600 )) m=$(( (diff % 3600) / 60 ))
  [ "$h" -ge 1 ] && printf "%dh%dm" "$h" "$m" || printf "%dm" "$m"
}

# ═══════════════════════════════════════════════════════════
# L1: Powerline segments
printf "%b" "${C}${BOLD} ${SHORT_MODEL} ${RST}${BOLD} ${dir_name}${RST}${GIT_SEG}${VIM_SEG}\n"

# L2: Context + tokens + cost + time
printf "%b" "${BAR_C}${BAR}${RST} ${BOLD}${PCT}%${RST} ${DIM}│${RST} ${C}${TOK_FMT}${RST} ${DIM}↑${TOK_IN_FMT} ↓${TOK_OUT_FMT}${RST} ${DIM}│${RST} ${Y}${COST_FMT}${RST} ${DIM}│${RST} ${DIM}${TIME_STR}${RST}\n"

# L3: Rate limits
if [ -n "$RL5H_PCT" ] || [ -n "$RL7D_PCT" ]; then
  LINE3=""
  if [ -n "$RL5H_PCT" ]; then
    RESET_5H=""; [ -n "$RL5H_RESET" ] && RESET_5H=" ${DIM}$(format_reset "$RL5H_RESET")${RST}"
    LINE3="${DIM}5h${RST} $(make_rate_bar "$RL5H_PCT")${RESET_5H}"
  fi
  if [ -n "$RL7D_PCT" ]; then
    RESET_7D=""; [ -n "$RL7D_RESET" ] && RESET_7D=" ${DIM}$(format_reset "$RL7D_RESET")${RST}"
    [ -n "$LINE3" ] && LINE3="${LINE3} ${DIM}│${RST} "
    LINE3="${LINE3}${DIM}7d${RST} $(make_rate_bar "$RL7D_PCT")${RESET_7D}"
  fi
  printf "%b" "${LINE3}\n"
fi
