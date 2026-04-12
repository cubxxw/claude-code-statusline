#!/usr/bin/env python3
"""
Claude Code statusline — Python implementation.

More readable than bash for complex logic. Same features as full.sh preset.

Usage in settings.json:
{
  "statusLine": {
    "type": "command",
    "command": "python3 $HOME/.claude/statusline.py"
  }
}
"""

import json
import os
import subprocess
import sys
import time

# ── ANSI Colors ──────────────────────────────────────────────
C = "\033[36m"    # cyan
G = "\033[32m"    # green
Y = "\033[33m"    # yellow
R = "\033[31m"    # red
M = "\033[35m"    # magenta
BOLD = "\033[1m"
DIM = "\033[2m"
RST = "\033[0m"


def fmt_tokens(n: int) -> str:
    """Format token count: 500 → 500, 42000 → 42.0K, 1500000 → 1.5M"""
    if n >= 1_000_000:
        return f"{n / 1_000_000:.1f}M"
    elif n >= 1_000:
        return f"{n / 1_000:.1f}K" if n < 100_000 else f"{n // 1_000}K"
    return str(n)


def fmt_duration(ms: int) -> str:
    """Format duration: 3600000 → 1h0m0s"""
    s = ms // 1000
    if s >= 3600:
        return f"{s // 3600}h{s % 3600 // 60}m{s % 60}s"
    elif s >= 60:
        return f"{s // 60}m{s % 60}s"
    return f"{s}s"


def make_bar(pct: int, width: int = 15) -> tuple[str, str]:
    """Build progress bar and pick color. Returns (bar_string, ansi_color)."""
    pct = max(0, min(100, pct))
    filled = pct * width // 100
    bar = "━" * filled + "─" * (width - filled)
    color = R if pct >= 90 else Y if pct >= 70 else G
    return bar, color


def git_info(directory: str) -> str:
    """Get git branch and file status."""
    try:
        subprocess.run(
            ["git", "-C", directory, "rev-parse", "--git-dir"],
            capture_output=True, check=True,
        )
    except (subprocess.CalledProcessError, FileNotFoundError):
        return ""

    def git(*args):
        r = subprocess.run(
            ["git", "-C", directory, "--no-optional-locks", *args],
            capture_output=True, text=True,
        )
        return r.stdout.strip()

    branch = git("branch", "--show-current") or git("rev-parse", "--short", "HEAD")
    staged = len(git("diff", "--cached", "--numstat").splitlines()) if git("diff", "--cached", "--numstat") else 0
    modified = len(git("diff", "--numstat").splitlines()) if git("diff", "--numstat") else 0
    untracked = len(git("ls-files", "--others", "--exclude-standard").splitlines()) if git("ls-files", "--others", "--exclude-standard") else 0

    parts = [f" {DIM}│{RST} {G}{branch}{RST}"]
    if staged:    parts.append(f" {G}+{staged}{RST}")
    if modified:  parts.append(f" {Y}~{modified}{RST}")
    if untracked: parts.append(f" {R}?{untracked}{RST}")
    return "".join(parts)


def fmt_countdown(epoch: int) -> str:
    """Format countdown from unix epoch to now."""
    diff = epoch - int(time.time())
    if diff <= 0:
        return "now"
    h, m = diff // 3600, (diff % 3600) // 60
    return f"{h}h{m}m" if h >= 1 else f"{m}m"


def main():
    data = json.load(sys.stdin)

    # Parse fields
    model = data.get("model", {}).get("display_name", "Claude").removeprefix("Claude ")
    directory = data.get("workspace", {}).get("current_dir", data.get("cwd", ""))
    dir_name = os.path.basename(directory) or "/"
    cost = data.get("cost", {}).get("total_cost_usd", 0)
    duration = data.get("cost", {}).get("total_duration_ms", 0)
    pct = int(data.get("context_window", {}).get("used_percentage", 0) or 0)
    vim_mode = data.get("vim", {}).get("mode", "")
    tok_in = data.get("context_window", {}).get("total_input_tokens", 0)
    tok_out = data.get("context_window", {}).get("total_output_tokens", 0)

    rl5h = data.get("rate_limits", {}).get("five_hour", {})
    rl7d = data.get("rate_limits", {}).get("seven_day", {})

    # ── Line 1: [Model] dir │ branch ±N │ VIM ───────────────
    vim_part = ""
    if vim_mode:
        vim_colors = {"NORMAL": C, "INSERT": f"{G}{BOLD}", "VISUAL": M, "REPLACE": R}
        vim_labels = {"NORMAL": "NOR", "INSERT": "INS", "VISUAL": "VIS", "REPLACE": "REP"}
        vc = vim_colors.get(vim_mode, Y)
        vl = vim_labels.get(vim_mode, vim_mode)
        vim_part = f" {DIM}│{RST} {vc}{vl}{RST}"

    git_part = git_info(directory) if directory else ""
    print(f"{C}{BOLD}[{model}]{RST} {BOLD}{dir_name}{RST}{git_part}{vim_part}")

    # ── Line 2: bar pct% │ tokens ↑in ↓out │ $cost │ time ──
    bar, bar_c = make_bar(pct)
    tok_total = fmt_tokens(tok_in + tok_out)
    tok_in_s = fmt_tokens(tok_in)
    tok_out_s = fmt_tokens(tok_out)
    cost_s = f"${cost:.2f}"
    time_s = fmt_duration(duration)

    print(f"{bar_c}{bar}{RST} {BOLD}{pct}%{RST} {DIM}│{RST} {C}{tok_total}{RST} {DIM}↑{tok_in_s} ↓{tok_out_s}{RST} {DIM}│{RST} {Y}{cost_s}{RST} {DIM}│{RST} {DIM}{time_s}{RST}")

    # ── Line 3: Rate limits (optional) ──────────────────────
    if rl5h or rl7d:
        parts = []
        for label, rl in [("5h", rl5h), ("7d", rl7d)]:
            pct_val = rl.get("used_percentage")
            if pct_val is not None:
                bar_s, bar_color = make_bar(int(pct_val), width=8)
                reset_at = rl.get("resets_at")
                countdown = f" {DIM}{fmt_countdown(reset_at)}{RST}" if reset_at else ""
                parts.append(f"{DIM}{label}{RST} {bar_color}{bar_s}{RST} {int(pct_val)}%{countdown}")
        if parts:
            print(f" {DIM}│{RST} ".join(parts))


if __name__ == "__main__":
    main()
