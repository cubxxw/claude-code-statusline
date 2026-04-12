#!/bin/bash
# ╔══════════════════════════════════════════════════════════╗
# ║  claude-code-statusline installer                       ║
# ║  One command to install a beautiful status line          ║
# ╚══════════════════════════════════════════════════════════╝

set -e

REPO_URL="https://raw.githubusercontent.com/cubxxw/claude-code-statusline/main"
INSTALL_DIR="$HOME/.claude"
SCRIPT_NAME="statusline-command.sh"
SETTINGS_FILE="$INSTALL_DIR/settings.json"

# ── Colors ───────────────────────────────────────────────────
RED='\033[31m'; GREEN='\033[32m'; YELLOW='\033[33m'; CYAN='\033[36m'
BOLD='\033[1m'; DIM='\033[2m'; RST='\033[0m'

info()  { printf "${CYAN}${BOLD}[INFO]${RST} %s\n" "$1"; }
ok()    { printf "${GREEN}${BOLD}[OK]${RST}   %s\n" "$1"; }
warn()  { printf "${YELLOW}${BOLD}[WARN]${RST} %s\n" "$1"; }
err()   { printf "${RED}${BOLD}[ERR]${RST}  %s\n" "$1"; exit 1; }

# ── Dependency check ────────────────────────────────────────
command -v jq  >/dev/null 2>&1 || err "jq is required. Install: brew install jq (macOS) or apt install jq (Linux)"
command -v git >/dev/null 2>&1 || warn "git not found — git status features will be disabled"

# ── Preset selection ────────────────────────────────────────
PRESET="${1:-full}"
VALID_PRESETS="minimal compact full powerline"

if ! echo "$VALID_PRESETS" | grep -qw "$PRESET"; then
  echo ""
  printf "${BOLD}Available presets:${RST}\n"
  echo ""
  printf "  ${CYAN}minimal${RST}    Single line: model, dir, context%%, cost\n"
  printf "  ${CYAN}compact${RST}    2 lines: + git, tokens, duration\n"
  printf "  ${CYAN}full${RST}       3 lines: + rate limits with countdown ${DIM}(default)${RST}\n"
  printf "  ${CYAN}powerline${RST}  3 lines: powerline-style segments\n"
  echo ""
  printf "Usage: ${BOLD}./install.sh [preset]${RST}\n"
  printf "  e.g. ${DIM}./install.sh compact${RST}\n"
  exit 0
fi

info "Installing preset: ${BOLD}${PRESET}${RST}"

# ── Create directory ────────────────────────────────────────
mkdir -p "$INSTALL_DIR"

# ── Download or copy preset ─────────────────────────────────
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

if [ -f "$SCRIPT_DIR/presets/${PRESET}.sh" ]; then
  # Local install (cloned repo)
  cp "$SCRIPT_DIR/presets/${PRESET}.sh" "$INSTALL_DIR/$SCRIPT_NAME"
  ok "Copied preset from local repo"
else
  # Remote install (curl one-liner)
  curl -fsSL "$REPO_URL/presets/${PRESET}.sh" -o "$INSTALL_DIR/$SCRIPT_NAME" \
    || err "Failed to download preset. Check your internet connection."
  ok "Downloaded preset from GitHub"
fi

chmod +x "$INSTALL_DIR/$SCRIPT_NAME"

# ── Configure settings.json ─────────────────────────────────
if [ -f "$SETTINGS_FILE" ]; then
  # Check if statusLine already exists
  if jq -e '.statusLine' "$SETTINGS_FILE" >/dev/null 2>&1; then
    # Update existing statusLine config
    TMP=$(mktemp)
    jq '.statusLine = {"type": "command", "command": "sh $HOME/.claude/statusline-command.sh"}' \
      "$SETTINGS_FILE" > "$TMP" && mv "$TMP" "$SETTINGS_FILE"
    ok "Updated statusLine in existing settings.json"
  else
    # Add statusLine to existing config
    TMP=$(mktemp)
    jq '. + {"statusLine": {"type": "command", "command": "sh $HOME/.claude/statusline-command.sh"}}' \
      "$SETTINGS_FILE" > "$TMP" && mv "$TMP" "$SETTINGS_FILE"
    ok "Added statusLine to existing settings.json"
  fi
else
  # Create new settings.json
  cat > "$SETTINGS_FILE" << 'SETTINGS'
{
  "statusLine": {
    "type": "command",
    "command": "sh $HOME/.claude/statusline-command.sh"
  }
}
SETTINGS
  ok "Created new settings.json"
fi

# ── Verify ──────────────────────────────────────────────────
echo ""
printf "${GREEN}${BOLD}Installation complete!${RST}\n"
echo ""
printf "  Preset:  ${CYAN}${PRESET}${RST}\n"
printf "  Script:  ${DIM}${INSTALL_DIR}/${SCRIPT_NAME}${RST}\n"
printf "  Config:  ${DIM}${SETTINGS_FILE}${RST}\n"
echo ""
printf "  ${DIM}Restart Claude Code to see your new status line.${RST}\n"
echo ""

# ── Preview ─────────────────────────────────────────────────
info "Preview:"
echo '{"model":{"display_name":"Claude Opus 4.6"},"workspace":{"current_dir":"'$HOME'/my-project"},"cost":{"total_cost_usd":0.42,"total_duration_ms":1800000},"context_window":{"used_percentage":35,"total_input_tokens":520000,"total_output_tokens":180000},"vim":{"mode":"NORMAL"},"rate_limits":{"five_hour":{"used_percentage":18,"resets_at":'$(($(date +%s)+14400))'},"seven_day":{"used_percentage":8,"resets_at":'$(($(date +%s)+518400))'}}}' \
  | sh "$INSTALL_DIR/$SCRIPT_NAME"
echo ""
