Ask Opencode a question about the current codebase or any coding topic.

This sends your question to Opencode for analysis. Opencode will have access to the current working directory and can read files, search code, and provide detailed answers.

To execute:
1. Take the user's question from the command arguments
2. Run the following command, replacing `<QUESTION>` with the user's actual question:
   ```bash
   opencode run --auto "<QUESTION>"
   ```
3. Return the output to the user as-is

If Opencode is not installed, suggest running `/opencode:setup` first.

Examples:
- `/opencode:ask How does the authentication system work in this project?`
- `/opencode:ask What are the main dependencies and their purposes?`
- `/opencode:ask Find potential security issues in the API routes`
