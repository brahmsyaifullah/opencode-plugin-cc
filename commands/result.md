Retrieve the result from a completed Opencode session.

Supported arguments:
- `<session-id>`: The specific session ID to retrieve (optional, defaults to most recent)

To execute:
1. If a session ID is provided:
   ```bash
   opencode export <session-id> 2>/dev/null
   ```

2. If no session ID, export the most recent session:
   ```bash
   opencode export 2>/dev/null || echo "No session results available"
   ```

3. Parse and present the results in a readable format
