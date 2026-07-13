Delegate a task to Opencode for execution.

This hands off a development task to Opencode, which can read files, write code, run commands, and complete complex multi-step tasks.

Supported flags:
- `--model <provider/model>`: Specify model (e.g., `anthropic/claude-sonnet-4-20250514`)
- `--background`: Run in background
- `--continue`: Continue the last Opencode session
- `--session <id>`: Resume a specific session

To execute:
1. Take the task description from the command arguments
2. If `--continue` is specified, add `-c` flag
3. If `--session` is specified, add `-s <id>` flag
4. Run:
   ```bash
   opencode run --auto [--model <model>] [-c | -s <id>] "<TASK_DESCRIPTION>"
   ```
5. Return the result to the user

Examples:
- `/opencode:delegate Fix the failing unit tests in the auth module`
- `/opencode:delegate --model anthropic/claude-sonnet-4-20250514 Refactor the database connection pool`
- `/opencode:delegate --continue Apply the suggested fix from the last session`
