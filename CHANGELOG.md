# Changelog

## 0.4.1 — 2026-07-13

- Proactive delegation triggers: the worker agent and delegate skill descriptions now
  encode the decision rule "delegate when the task can be written as a self-contained
  spec with a verification command" — orchestrator models (Opus/Fable) auto-delegate
  matching tasks without a slash command. Pair with a CLAUDE.md delegation policy for
  near-deterministic routing (see README).

## 0.4.0 — 2026-07-13

- `wait <job-id>` action: blocks until a job finishes, then prints its result. Run backgrounded, it turns job completion into an automatic notification — no polling.
- Version gate: bridge requires Opencode ≥ 1.17 (`--title`/`--attach`/`-f`) and says so instead of failing opaquely.
- Session mapping now uses `session list --format json` + `jq` (table-scrape fallback kept).
- `gc [days]` removes finished job dirs older than N days (default 7); runs opportunistically on each delegate. Running jobs are never touched.
- `cancel` also kills Opencode's child processes.

## 0.3.0 — 2026-07-13

- Optional headless server: `scripts/opencode-serve.sh` (start/stop/status/url) and `/opencode:serve`.
- Opportunistic attach: when a healthy server is found, all bridge calls use `--attach <url> --dir <cwd>`; transparent fallback to standalone CLI otherwise.
- `OPENCODE_ATTACH=off|<url>` override, `OPENCODE_SERVER_PORT` port config.

## 0.2.0 — 2026-07-13

- Background job model: `delegate` returns a JOB_ID immediately; job state (pid, prompt, log, exit code) in `~/.claude/opencode-jobs/<id>/`.
- `result` returns compact output (status + session ID + log tail); full transcripts stay on disk.
- Job ID doubles as the Opencode session title → 1:1 job-to-session mapping, `-s` resume.
- `review` passes diffs via temp file + `-f` attach (never argv, never context).
- Fixes from live testing: message-before-`-f` ordering (yargs array flag), `set +e` in the job supervisor (failed jobs no longer misreported as `dead`), real-worker pid tracking for cancel, started-marker race fix, stderr surfacing, PATH handling for non-interactive shells.
- Commands rewritten with frontmatter, `$ARGUMENTS`, `${CLAUDE_PLUGIN_ROOT}` wiring.

## 0.1.0 — 2026-07-13

- Initial skeleton: commands, agent, hooks, CLI bridge draft.
