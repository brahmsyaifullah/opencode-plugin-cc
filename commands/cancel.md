Cancel a running Opencode session.

Supported arguments:
- `<session-id>`: The specific session to cancel (optional)

To execute:
1. If a session ID is provided:
   ```bash
   opencode session delete <session-id> 2>/dev/null && echo "Session cancelled" || echo "Failed to cancel session"
   ```

2. If no session ID, show available sessions and ask the user which to cancel:
   ```bash
   opencode session list 2>/dev/null
   ```

3. Confirm the cancellation to the user
