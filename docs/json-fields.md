# Available JSON Fields

Claude Code pipes session data as JSON to your statusline script's stdin on every update. Below is the complete field reference.

## Session & Workspace

| Field | Type | Availability | Description |
|-------|------|:------------:|-------------|
| `session_id` | string | Always | Unique session identifier |
| `session_name` | string | Optional | Custom session name (set with `--name` or `/rename`) |
| `workspace.current_dir` | string | Always | Current working directory |
| `workspace.project_dir` | string | Always | Directory where Claude Code was launched |
| `workspace.added_dirs` | array | Always | Additional directories added via `/add-dir` |
| `workspace.git_worktree` | string | Optional | Git worktree name (only in linked worktrees) |
| `cwd` | string | Always | **Deprecated** — use `workspace.current_dir` |

## Model & Version

| Field | Type | Availability | Description |
|-------|------|:------------:|-------------|
| `model.id` | string | Always | Model identifier (e.g., `claude-opus-4-6`) |
| `model.display_name` | string | Always | Display name (e.g., `Opus 4.6`) |
| `version` | string | Always | Claude Code version |
| `output_style.name` | string | Always | Current output style name |

## Context Window & Tokens

| Field | Type | Availability | Description |
|-------|------|:------------:|-------------|
| `context_window.total_input_tokens` | number | Always | Cumulative input tokens (entire session) |
| `context_window.total_output_tokens` | number | Always | Cumulative output tokens (entire session) |
| `context_window.context_window_size` | number | Always | Max context window (200000 or 1000000) |
| `context_window.used_percentage` | number | Nullable | Context window usage (0-100). Null early in session |
| `context_window.remaining_percentage` | number | Nullable | Remaining context percentage |
| `context_window.current_usage.input_tokens` | number | Nullable | Input tokens from last API call |
| `context_window.current_usage.output_tokens` | number | Nullable | Output tokens from last API call |
| `context_window.current_usage.cache_creation_input_tokens` | number | Nullable | Tokens written to cache |
| `context_window.current_usage.cache_read_input_tokens` | number | Nullable | Tokens read from cache |
| `exceeds_200k_tokens` | boolean | Always | Whether total tokens exceed 200K |

> **Note**: `used_percentage` is calculated from input tokens only:
> `(input_tokens + cache_creation + cache_read) / context_window_size * 100`
> Output tokens are NOT included.

## Cost & Timing

| Field | Type | Availability | Description |
|-------|------|:------------:|-------------|
| `cost.total_cost_usd` | number | Always | Total session cost in USD |
| `cost.total_duration_ms` | number | Always | Wall-clock time since session start |
| `cost.total_api_duration_ms` | number | Always | Time spent waiting for API responses |
| `cost.total_lines_added` | number | Always | Lines of code added |
| `cost.total_lines_removed` | number | Always | Lines of code removed |

## Rate Limits

> Only available for Claude.ai Pro/Max subscribers after first API response.

| Field | Type | Availability | Description |
|-------|------|:------------:|-------------|
| `rate_limits.five_hour.used_percentage` | number | Optional | 5-hour window usage (0-100) |
| `rate_limits.five_hour.resets_at` | number | Optional | Unix epoch when 5h window resets |
| `rate_limits.seven_day.used_percentage` | number | Optional | 7-day window usage (0-100) |
| `rate_limits.seven_day.resets_at` | number | Optional | Unix epoch when 7d window resets |

## UI & Mode

| Field | Type | Availability | Description |
|-------|------|:------------:|-------------|
| `permission_mode` | string | Always | Current permission mode |
| `transcript_path` | string | Always | Path to conversation transcript |
| `vim.mode` | string | Optional | Current vim mode (`NORMAL`, `INSERT`) |

## Worktree Sessions

| Field | Type | Availability | Description |
|-------|------|:------------:|-------------|
| `worktree.name` | string | Optional | Active worktree name |
| `worktree.path` | string | Optional | Worktree directory path |
| `worktree.branch` | string | Optional | Git branch for worktree |
| `worktree.original_cwd` | string | Optional | Directory before entering worktree |
| `worktree.original_branch` | string | Optional | Branch before entering worktree |

## Agent Sessions

| Field | Type | Availability | Description |
|-------|------|:------------:|-------------|
| `agent.name` | string | Optional | Agent name (when using `--agent`) |

## Update Triggers

The statusline script is re-executed when:

- After each new assistant message
- When permission mode changes
- When vim mode toggles
- Debounced at 300ms (rapid changes batch together)

If `refreshInterval` is set, additionally runs every N seconds.
