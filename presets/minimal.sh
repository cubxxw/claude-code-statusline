#!/bin/bash
# ╔══════════════════════════════════════════════════════════╗
# ║  claude-code-statusline — Minimal Preset                ║
# ║  Single line: model, dir, context%, cost                ║
# ╚══════════════════════════════════════════════════════════╝
#
# Output: [Opus 4.6] my-app ━━━━━── 42% $0.83

input=$(cat)

MODEL=$(echo "$input" | jq -r '.model.display_name // "Claude"' | sed -E 's/^Claude //')
DIR=$(echo "$input"   | jq -r '.workspace.current_dir // .cwd // ""')
COST=$(echo "$input"  | jq -r '.cost.total_cost_usd // 0')
PCT=$(echo "$input"   | jq -r '.context_window.used_percentage // 0' | cut -d. -f1)

C='\033[36m'; G='\033[32m'; Y='\033[33m'; R='\033[31m'
BOLD='\033[1m'; DIM='\033[2m'; RST='\033[0m'

dir_name="${DIR##*/}"; [ -z "$dir_name" ] && dir_name="/"

# Progress bar
BAR_W=8; FILLED=$((PCT * BAR_W / 100))
[ "$FILLED" -gt "$BAR_W" ] && FILLED=$BAR_W
if   [ "$PCT" -ge 90 ]; then BAR_C="$R"
elif [ "$PCT" -ge 70 ]; then BAR_C="$Y"
else                          BAR_C="$G"; fi
BAR=""; i=0
while [ $i -lt $FILLED ];  do BAR="${BAR}━"; i=$((i+1)); done
while [ $i -lt "$BAR_W" ]; do BAR="${BAR}─"; i=$((i+1)); done

COST_FMT=$(printf '$%.2f' "$COST")

printf "%b" "${C}${BOLD}[${MODEL}]${RST} ${BOLD}${dir_name}${RST} ${BAR_C}${BAR}${RST} ${PCT}% ${Y}${COST_FMT}${RST}\n"
