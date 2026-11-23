---
name: recap
description: Shows a post-match screen for the user's last week (or N days) with Claude Code, counted from Claude Code's own session logs on this computer: tasks finished, errors, longest win streak, time Claude was busy, and how long it sat waiting for the user. Use when the user asks for a recap, stats, a scoreboard or a post-match screen, or how long Claude waited for them.
argument-hint: "[days]"
---

Run this with the Bash tool. If the user gave a number of days (`$ARGUMENTS`), add it after the script path; otherwise leave it out (the default is 7 days).

```bash
node "${CLAUDE_PLUGIN_ROOT}/scripts/post-match.mjs" $ARGUMENTS
```

Show the user the screen exactly as printed, in a code block, then one short line on the number that stands out (usually how long Claude waited for them). Don't add anything else.

If it says there are no logs, they may be using a different config folder (`CLAUDE_CONFIG_DIR`), or have no sessions in that time.
