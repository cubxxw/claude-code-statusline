# Configuration Guide

## Settings Location

Claude Code reads statusline configuration from `~/.claude/settings.json`.

## Configuration Format

```json
{
  "statusLine": {
    "type": "command",
    "command": "sh $HOME/.claude/statusline-command.sh",
    "padding": 0,
    "refreshInterval": 10
  }
}
```

| Field | Type | Required | Default | Description |
|-------|------|:--------:|---------|-------------|
| `type` | string | Yes | — | Must be `"command"` |
| `command` | string | Yes | — | Shell command or script path |
| `padding` | number | No | `0` | Extra horizontal padding (characters) |
| `refreshInterval` | number | No | — | Re-run every N seconds (min: 1) |

## Quick One-Liner Setup

If you just want the basics without a script file:

```json
{
  "statusLine": {
    "type": "command",
    "command": "jq -r '\"[\\(.model.display_name)] \\(.context_window.used_percentage // 0 | floor)% context | $\\(.cost.total_cost_usd // 0)\"'"
  }
}
```

## Script-Based Setup

For rich multi-line statuslines, use a script file:

```json
{
  "statusLine": {
    "type": "command",
    "command": "sh $HOME/.claude/statusline-command.sh"
  }
}
```

## Using refreshInterval

Set `refreshInterval` when your statusline displays time-based data (duration, clocks) or needs to detect external changes (background subagents changing git state):

```json
{
  "statusLine": {
    "type": "command",
    "command": "sh $HOME/.claude/statusline-command.sh",
    "refreshInterval": 5
  }
}
```

## Performance Tips

1. **Cache expensive operations** — Git commands can be slow in large repos. Use `session_id` for cache filenames:
   ```bash
   SESSION_ID=$(echo "$input" | jq -r '.session_id')
   CACHE="/tmp/statusline-$SESSION_ID"
   ```

2. **Use `--no-optional-locks`** for git commands to avoid conflicts:
   ```bash
   git -C "$DIR" --no-optional-locks branch --show-current
   ```

3. **Avoid unnecessary subshells** — Pipe multiple jq extractions in a single call when possible.

4. **Keep scripts fast** — Each execution should complete in <100ms.

## Platform Notes

### macOS
```json
{
  "statusLine": {
    "type": "command",
    "command": "sh $HOME/.claude/statusline-command.sh"
  }
}
```

### Linux
Same as macOS. Ensure `jq` is installed: `apt install jq` or `dnf install jq`.

### Windows (Git Bash)
```json
{
  "statusLine": {
    "type": "command",
    "command": "bash -c \"sh ~/.claude/statusline-command.sh\""
  }
}
```

### Windows (PowerShell)
```json
{
  "statusLine": {
    "type": "command",
    "command": "powershell -NoProfile -File $env:USERPROFILE\\.claude\\statusline.ps1"
  }
}
```
