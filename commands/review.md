Request a code review from Opencode on your current changes.

This command sends your uncommitted changes (or branch diff) to Opencode for a thorough code review.

Supported flags:
- `--base <ref>`: Compare against a specific branch (default: current uncommitted changes)
- `--background`: Run the review in background mode

To execute:
1. Determine what to review:
   - If `--base` is provided, get the diff: `git diff <base>...HEAD`
   - Otherwise, get uncommitted changes: `git diff` and `git diff --staged`

2. Construct the review prompt with the diff context

3. Run:
   ```bash
   opencode run --auto "You are a senior code reviewer. Review the following code changes thoroughly. Look for:
   - Bugs and logic errors
   - Security vulnerabilities
   - Performance issues
   - Code style and best practices
   - Missing error handling
   - Potential edge cases

   Here are the changes:
   $(git diff)
   $(git diff --staged)

   Provide a structured review with severity levels (critical/warning/suggestion) for each finding."
   ```

4. Return the review findings to the user

Note: This command is read-only and will not make any changes to your code.
