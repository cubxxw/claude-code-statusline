#!/bin/bash
# ╔══════════════════════════════════════════════════════════╗
# ║  claude-code-statusline — Compact Preset                ║
# ║  2-line status: model/git, context/tokens/cost/time     ║
# ╚══════════════════════════════════════════════════════════╝
#
# L1: [Opus 4.6] my-app │ main +2 ~3 │ INS
# L2: ━━━━━──────── 42% │ 1.2M │ $0.83 │ 56m13s

input=$(cat)

MODEL=$(echo "$input" | jq -r '.model.display_name // "Claude"' | sed -E 's/^Claude //')
DIR=$(echo "$input"   | jq -r '.workspace.current_dir // .cwd // ""')
COST=$(echo "$input"  | jq -r '.cost.total_cost_usd // 0')
PCT=$(echo "$input"   | jq -r '.context_window.used_percentage // 0' | cut -d. -f1)
DUR=$(echo "$input"   | jq -r '.cost.total_duration_ms // 0')
VIM_MODE=$(echo "$input" | jq -r '.vim.mode // empty')
TOK_IN=$(echo "$input"  | jq -r '.context_window.total_input_tokens // 0')
TOK_OUT=$(echo "$input" | jq -r '.context_window.total_output_tokens // 0')

C='\033[36m'; G='\033[32m'; Y='\033[33m'; R='\033[31m'
M='\033[35m'; BOLD='\033[1m'; DIM='\033[2m'; RST='\033[0m'

dir_name="${DIR##*/}"; [ -z "$dir_name" ] && dir_name="/"

# Git
GIT_PART=""
if [ -n "$DIR" ] && git -C "$DIR" rev-parse --git-dir >/dev/null 2>&1; then
  BRANCH=$(git -C "$DIR" --no-optional-locks branch --show-current 2>/dev/null)
  [ -z "$BRANCH" ] && BRANCH=$(git -C "$DIR" --no-optional-locks rev-parse --short HEAD 2>/dev/null)
  STAGED=$(git -C "$DIR" --no-optional-locks diff --cached --numstat 2>/dev/null | wc -l | tr -d ' ')
  MODIFIED=$(git -C "$DIR" --no-optional-locks diff --numstat 2>/dev/null | wc -l | tr -d ' ')
  GIT_PART=" ${DIM}│${RST} ${G}${BRANCH}${RST}"
  [ "$STAGED"   -gt 0 ] 2>/dev/null && GIT_PART="${GIT_PART} ${G}+${STAGED}${RST}"
  [ "$MODIFIED" -gt 0 ] 2>/dev/null && GIT_PART="${GIT_PART} ${Y}~${MODIFIED}${RST}"
fi

# Vim
VIM_PART=""
if [ -n "$VIM_MODE" ]; then
  case "$VIM_MODE" in
    NORMAL)  VIM_PART=" ${DIM}│${RST} ${C}NOR${RST}" ;;
    INSERT)  VIM_PART=" ${DIM}│${RST} ${G}${BOLD}INS${RST}" ;;
    *)       VIM_PART=" ${DIM}│${RST} ${Y}${VIM_MODE}${RST}" ;;
  esac
fi

# Progress bar
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
if [ "$TOTAL_S" -ge 3600 ]; then TIME_STR="$((TOTAL_S/3600))h$((TOTAL_S%3600/60))m"
elif [ "$TOTAL_S" -ge 60 ]; then TIME_STR="$((TOTAL_S/60))m$((TOTAL_S%60))s"
else TIME_STR="${TOTAL_S}s"; fi

COST_FMT=$(printf '$%.2f' "$COST")

# Token
fmt_tok() {
  local n="$1"
  if [ "$n" -ge 1000000 ]; then printf "%d.%dM" "$((n/1000000))" "$(((n%1000000)/100000))"
  elif [ "$n" -ge 1000 ]; then printf "%dK" "$((n/1000))"
  else printf "%d" "$n"; fi
}
TOK_FMT=$(fmt_tok "$((TOK_IN + TOK_OUT))")

printf "%b" "${C}${BOLD}[${MODEL}]${RST} ${BOLD}${dir_name}${RST}${GIT_PART}${VIM_PART}\n"
printf "%b" "${BAR_C}${BAR}${RST} ${BOLD}${PCT}%${RST} ${DIM}│${RST} ${C}${TOK_FMT}${RST} ${DIM}│${RST} ${Y}${COST_FMT}${RST} ${DIM}│${RST} ${DIM}${TIME_STR}${RST}\n"
