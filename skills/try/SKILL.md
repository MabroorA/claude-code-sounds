---
name: try
description: Plays every sound in the user's Claude Code sound pack, one after another, and explains how to switch packs, change the volume or use their own sounds. Use when the user asks to hear, test, change, mute or set up their Claude Code sounds.
argument-hint: "[glimmet|arcade|quiet]"
---

Play the user's sound pack so they can hear what each moment sounds like.

Their settings: pack `${user_config.pack}`, volume `${user_config.volume}`, own sounds folder `${user_config.own_sounds}`. If a setting above still reads as a placeholder or is empty, leave that argument out. If the user named a pack (`$ARGUMENTS`), use it instead of their pack.

Run this with the Bash tool, filling in the pack, the volume and the folder (in that order, each in double quotes):

```bash
bash "${CLAUDE_PLUGIN_ROOT}/scripts/play.sh" tour "<pack>" "<volume>" "<own sounds folder>"
```

Then tell them, in a few short lines:

- Which pack they just heard, and that the sounds play when a session starts, when they send a message, when Claude finishes, when Claude needs their OK, when a turn stops on an error, and when the context fills up.
- To switch packs (glimmet, arcade or quiet) or change the volume, they open `/config` and find the Sounds options. Volume 0 is silent; `/plugin` turns the sounds off altogether.
- To use their own sounds, they put WAV files in a folder, named after the moment (`done`, `needs-you`, `error`, `start`, `got-it`, `full`; `done-1` and `done-2` to have two that take turns), and choose that folder as "Your own sounds" in `/config`. Any moment without a file of its own keeps the pack's sound. They can make sounds like these at https://www.sound-effects-ai.com/text-sound?ref=claude-code.

If the tour printed "no sound" for every moment, or they heard nothing, ask whether their computer's sound is on. On Linux the plugin needs `paplay`, `pw-play`, `ffplay`, `mpv` or `aplay`; on Windows it needs Git Bash.
