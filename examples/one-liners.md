# One-Liner Statuslines

Copy any of these directly into your `~/.claude/settings.json`. No script file needed.

## Basic: Model + Context %

```json
{
  "statusLine": {
    "type": "command",
    "command": "jq -r '\"[\\(.model.display_name)] \\(.context_window.used_percentage // 0 | floor)%\"'"
  }
}
```
Output: `[Opus 4.6] 42%`

## Model + Directory + Cost

```json
{
  "statusLine": {
    "type": "command",
    "command": "jq -r '\"[\\(.model.display_name)] \\(.workspace.current_dir | split(\"/\") | .[-1]) | $\\(.cost.total_cost_usd // 0 | . * 100 | floor / 100)\"'"
  }
}
```
Output: `[Opus 4.6] my-app | $0.83`

## Context % with Emoji Alert

```json
{
  "statusLine": {
    "type": "command",
    "command": "jq -r '(.context_window.used_percentage // 0 | floor) as $p | if $p >= 90 then \"\\u001b[31m\" elif $p >= 70 then \"\\u001b[33m\" else \"\\u001b[32m\" end + \"[\\(.model.display_name)] \\($p)% context\\u001b[0m\"'"
  }
}
```
Output: `[Opus 4.6] 42% context` (green/yellow/red based on %)

## Token Counter

```json
{
  "statusLine": {
    "type": "command",
    "command": "jq -r '((.context_window.total_input_tokens // 0) + (.context_window.total_output_tokens // 0)) as $t | if $t >= 1000000 then \"\\($t / 1000000 | . * 10 | floor / 10)M\" elif $t >= 1000 then \"\\($t / 1000 | floor)K\" else \"\\($t)\" end | \"[\\(.model.display_name)] \\(.) tokens | $\\(.cost.total_cost_usd // 0 | . * 100 | floor / 100)\"'"
  }
}
```
Output: `[Opus 4.6] 1.2M tokens | $0.83`

## Rate Limits Only

```json
{
  "statusLine": {
    "type": "command",
    "command": "jq -r '[\"5h: \\(.rate_limits.five_hour.used_percentage // \"--\" | tostring)%\", \"7d: \\(.rate_limits.seven_day.used_percentage // \"--\" | tostring)%\"] | join(\" | \")'"
  }
}
```
Output: `5h: 12% | 7d: 7%`

## Session Timer

```json
{
  "statusLine": {
    "type": "command",
    "command": "jq -r '(.cost.total_duration_ms // 0 | . / 1000 | floor) as $s | \"\\($s / 3600 | floor)h \\($s % 3600 / 60 | floor)m \\($s % 60)s\"'",
    "refreshInterval": 1
  }
}
```
Output: `1h 23m 45s` (updates every second)

## Lines Changed

```json
{
  "statusLine": {
    "type": "command",
    "command": "jq -r '\"\\u001b[32m+\\(.cost.total_lines_added // 0)\\u001b[0m \\u001b[31m-\\(.cost.total_lines_removed // 0)\\u001b[0m lines\"'"
  }
}
```
Output: `+142 -38 lines`
