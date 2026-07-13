Show the status of Opencode sessions for the current project.

To execute:
1. List recent sessions:
   ```bash
   opencode session list 2>/dev/null || echo "No sessions found or Opencode not available"
   ```

2. If a headless server is running, check its status:
   ```bash
   curl -s http://127.0.0.1:4096/session 2>/dev/null | head -50 || echo "No headless server running"
   ```

3. Present the session list to the user with:
   - Session ID
   - Status (active/completed)
   - Timestamp
   - Brief summary if available
