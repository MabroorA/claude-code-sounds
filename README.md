# Sounds for Claude Code

Hear when Claude is done, when it needs your OK and when something goes wrong, so you can look away while it works.
Three original sound packs, free to use, made with [Sound Effects AI](https://www.sound-effects-ai.com/tools/claude-code-sounds). Or bring your own sounds.

**[Hear the packs](https://www.sound-effects-ai.com/tools/claude-code-sounds)**

## Install

In Claude Code:

```
/plugin marketplace add MabroorA/claude-code-sounds
/plugin install sounds@sound-effects-ai
```

Claude Code asks which pack you want and how loud. Then run `/sounds:try` to hear every sound in your pack.

From a terminal instead:

```bash
claude plugin marketplace add MabroorA/claude-code-sounds
claude plugin install sounds@sound-effects-ai
```

Installed from a terminal, it starts with `glimmet` at volume 70. Pick another pack with `/plugin configure sounds@sound-effects-ai` in Claude Code.

## When it plays

| Moment | When | Claude Code event |
|---|---|---|
| Done | Claude finishes | `Stop` |
| Needs you | Claude needs your OK (about six seconds after it asks, so you don't hear it while you're watching) | `Notification`: `permission_prompt`, `elicitation_dialog`, `agent_needs_input` |
| Error | A turn stops on an error | `StopFailure` (other than a rate limit) |
| Start | A session starts or resumes | `SessionStart`: `startup`, `resume` |
| Got it | You send a message | `UserPromptSubmit` |
| Full | The context fills up, or you hit a rate limit | `PreCompact` (`auto`), `StopFailure` (`rate_limit`) |

Every hook runs in the background (`async`), prints nothing and always exits cleanly, so a sound never slows Claude down or ends up in its context.

## The packs

| Pack | Sounds like |
|---|---|
| `glimmet` (default) | Glimmet, a cave critter the size of a cat. Its ears flick up when you send a message, and it trills when Claude is done. |
| `arcade` | Blips from a first arcade game. A point when Claude is done, a lost life when something breaks. |
| `quiet` | Soft wood and glass notes for open offices and late nights. |

## Settings

Open `/config` and find the Sounds options, or run `/plugin configure sounds@sound-effects-ai`:

- **Sound pack**: `glimmet`, `arcade` or `quiet`.
- **Volume**: 0 to 100. 0 is silent.
- **Your own sounds**: a folder of your own WAV files (see below).

To turn the sounds off altogether, disable the plugin in `/plugin`.

## Your own sounds

Put WAV files in a folder and choose it as **Your own sounds** in `/config`. Name each file after its moment:

`done.wav`, `needs-you.wav`, `error.wav`, `start.wav`, `got-it.wav`, `full.wav`

Give a moment two or more files (`done-1.wav`, `done-2.wav`) and they take turns. A moment without a file of its own keeps the pack's sound. The plugin also understands `win`, `lose`, `click`, `confirm`, `roar`, `call`, `hurt` and `death`, so sound sets from game tools work as they are. MP3 works on macOS and Windows; use WAV on Linux.

Make your own sounds from a few words at [Sound Effects AI](https://www.sound-effects-ai.com/text-sound).

## Works on

- **macOS**: out of the box (`afplay`).
- **Linux**: needs one of `paplay` (PulseAudio or PipeWire), `pw-play`, `ffplay`, `mpv` or `aplay`.
- **Windows**: with Git Bash, which comes with Git for Windows. WSL plays through Windows' own player.

## peon-ping and other players

Each pack in `packs/` is also a [CESP](https://github.com/PeonPing/openpeon) sound pack, with an `openpeon.json`, so peon-ping and other CESP players can use it too.

## Licence

The code is MIT ([LICENSE](LICENSE)). The sounds are [CC BY 4.0](packs/LICENSE.md): use them anywhere, and credit Sound Effects AI.

Sounds for Claude Code is made by Sound Effects AI. It isn't made by or affiliated with Anthropic. Claude and Claude Code are Anthropic's.
