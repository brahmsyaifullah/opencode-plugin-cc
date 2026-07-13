# opencode-plugin-cc

Use [Opencode](https://opencode.ai) from inside [Claude Code](https://claude.ai/code) to review code, ask questions, or delegate tasks to the open source coding agent.

This plugin lets Claude Code users access Opencode's capabilities without leaving their existing workflow — similar to how [codex-plugin-cc](https://github.com/openai/codex-plugin-cc) integrates OpenAI Codex.

## What You Get

| Command | Description |
|---------|-------------|
| `/opencode:setup` | Verify Opencode is installed and ready |
| `/opencode:ask` | Ask Opencode a question about your codebase |
| `/opencode:review` | Get a code review from Opencode |
| `/opencode:delegate` | Hand off a development task to Opencode |
| `/opencode:status` | Check Opencode session status |
| `/opencode:result` | Retrieve results from a completed session |
| `/opencode:cancel` | Cancel a running session |

Plus the `opencode:opencode-worker` subagent for complex multi-step task delegation.

## Requirements

- [Claude Code](https://claude.ai/code) with plugin support
- [Opencode](https://opencode.ai) CLI installed (`npm i -g opencode-ai@latest`)
- Node.js 18 or later
- An API key configured in Opencode (run `opencode auth login`)

## Install

Add the marketplace in Claude Code:

```
/plugin marketplace add brahmsyaifullah/opencode-plugin-cc
```

Install the plugin:

```
/plugin install opencode@community-opencode
```

Reload plugins:

```
/reload-plugins
```

Then verify:

```
/opencode:setup
```

## Quick Start

```
/opencode:setup
/opencode:ask How does this project's build system work?
/opencode:review
/opencode:delegate Fix the failing tests in the auth module
```

## Architecture

This plugin bridges Claude Code to Opencode via the CLI (`opencode run --auto`).

```
Claude Code → /opencode:command → opencode run --auto "prompt" → Opencode → Results
```

For advanced usage, you can start an Opencode headless server (`opencode serve`) for faster responses and session persistence.

## Configuration

Environment variables:

| Variable | Default | Description |
|----------|---------|-------------|
| `OPENCODE_CMD` | `opencode` | Path to the Opencode CLI |
| `OPENCODE_URL` | `http://127.0.0.1:4096` | Headless server URL |
| `OPENCODE_MODEL` | (Opencode default) | Model to use (e.g., `anthropic/claude-sonnet-4-20250514`) |

## License

MIT
