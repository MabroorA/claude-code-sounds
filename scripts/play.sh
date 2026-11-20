#!/usr/bin/env bash
# Plays a sound for a Claude Code moment. hooks/hooks.json calls it with a moment's CESP category:
#
#   play.sh task.complete                         plays the pack's sound for that moment, in the background
#   play.sh tour [pack] [volume] [own folder]     plays every moment in turn and says which is which (/sounds:try)
#
# Settings come from the plugin's options, which Claude Code passes to hooks as CLAUDE_PLUGIN_OPTION_PACK, _VOLUME and
# _OWN_SOUNDS. A sound's moment comes from the words in its file name (done, needs-you, error, start, got-it, full), the
# same rule for the packs and for your own folder. Hook runs print nothing and always exit 0, so a sound can never get
# in Claude's way. Works with macOS's bash 3.2.

root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
pack="${CLAUDE_PLUGIN_OPTION_PACK:-}"
volume="${CLAUDE_PLUGIN_OPTION_VOLUME:-}"
own="${CLAUDE_PLUGIN_OPTION_OWN_SOUNDS:-}"
mode="${1:-}"

if [ "$mode" = "tour" ]; then
  [ -n "${2:-}" ] && pack="$2"
  [ -n "${3:-}" ] && volume="$3"
  [ -n "${4:-}" ] && own="$4"
fi
[ -n "$pack" ] && [ -d "$root/packs/$pack/sounds" ] || pack="glimmet"
case "$volume" in '' | *[!0-9.]* | *.*.*) volume=70 ;; esac
[ -n "$own" ] && [ -d "$own" ] || own=""

# The moment a file is for, from the words in its name. The first list a word appears in wins.
moment_of() {
  local name word
  name="$(basename "$1")"
  name=" $(printf '%s' "${name%.*}" | tr '[:upper:]' '[:lower:]' | tr -c 'a-z0-9' ' ') "
  for word in $name; do case "$word" in needs | need | attention | question | input | call | alert | ask | waiting) echo input.required; return ;; esac; done
  for word in $name; do case "$word" in error | problem | fail | failed | hurt | lose | lost | wrong | oops) echo task.error; return ;; esac; done
  for word in $name; do case "$word" in full | limit | death | die | over | sleep | tired | compact) echo resource.limit; return ;; esac; done
  for word in $name; do case "$word" in start | hello | ready | power | wake | intro | growl) echo session.start; return ;; esac; done
  for word in $name; do case "$word" in got | ack | ok | okay | click | confirm | blip | yes | heard) echo task.acknowledge; return ;; esac; done
  for word in $name; do case "$word" in done | complete | completed | success | win | finish | finished | roar | point | yay) echo task.complete; return ;; esac; done
}

# One file for a moment: from your own folder if it has one, otherwise from the pack. Never the same one twice running.
pick() {
  local moment="$1" dir file count=0 choice last memo=""
  local -a found
  for dir in "$own" "$root/packs/$pack/sounds"; do
    [ -n "$dir" ] || continue
    for file in "$dir"/*.wav "$dir"/*.WAV "$dir"/*.mp3 "$dir"/*.MP3; do
      [ -f "$file" ] || continue
      if [ "$(moment_of "$file")" = "$moment" ]; then found[count]="$file"; count=$((count + 1)); fi
    done
    [ "$count" -gt 0 ] && break
  done
  [ "$count" -gt 0 ] || return 1
  choice=$((RANDOM % count))
  if [ -n "${CLAUDE_PLUGIN_DATA:-}" ] && mkdir -p "$CLAUDE_PLUGIN_DATA" 2>/dev/null; then
    memo="$CLAUDE_PLUGIN_DATA/last-$moment"
    last="$(cat "$memo" 2>/dev/null)"
    [ "$count" -gt 1 ] && [ "${found[choice]}" = "$last" ] && choice=$(((choice + 1) % count))
    printf '%s' "${found[choice]}" >"$memo" 2>/dev/null
  fi
  printf '%s' "${found[choice]}"
}

# Runs a player: in the background for hooks, to the end for the tour.
run() {
  if [ "$wait" = 1 ]; then "$@" >/dev/null 2>&1; else ("$@" >/dev/null 2>&1 &); fi
}

# Windows' own player, from Git Bash or WSL. It can't tell when a sound ends, so it waits 3 seconds before closing.
windows_play() {
  local path="${1//\'/\'\'}"
  run powershell.exe -NoProfile -NonInteractive -Command "Add-Type -AssemblyName PresentationCore; \$p = New-Object System.Windows.Media.MediaPlayer; \$p.Volume = $level; \$p.Open([Uri]'$path'); \$p.Play(); Start-Sleep -Milliseconds 3000; \$p.Close()"
}

play() {
  local file="$1" wait="${2:-0}" level
  level="$(awk -v v="$volume" 'BEGIN { if (v > 100) v = 100; printf "%.2f", v / 100 }')"
  [ "$level" = "0.00" ] && return 0
  # For testing: SOUNDS_LOG=<file> notes every sound, SOUNDS_DRY_RUN=1 skips playing it.
  [ -n "${SOUNDS_LOG:-}" ] && echo "$mode $file $level" >>"$SOUNDS_LOG"
  if [ -n "${SOUNDS_DRY_RUN:-}" ]; then return 0; fi
  case "$(uname -s)" in
    Darwin) run afplay -v "$level" "$file" ;;
    MINGW* | MSYS* | CYGWIN*) windows_play "$(cygpath -w "$file")" ;;
    Linux)
      if { [ -n "${WSL_DISTRO_NAME:-}" ] || grep -qi microsoft /proc/version 2>/dev/null; } && command -v powershell.exe >/dev/null 2>&1; then
        windows_play "$(wslpath -w "$file")"
      elif command -v paplay >/dev/null 2>&1 && [ "${file##*.}" != "mp3" ] && [ "${file##*.}" != "MP3" ]; then
        run paplay --volume="$(awk -v l="$level" 'BEGIN { printf "%d", l * 65536 }')" "$file"
      elif command -v pw-play >/dev/null 2>&1; then
        run pw-play --volume="$level" "$file"
      elif command -v ffplay >/dev/null 2>&1; then
        run ffplay -nodisp -autoexit -loglevel quiet -volume "$(awk -v l="$level" 'BEGIN { printf "%d", l * 100 }')" "$file"
      elif command -v mpv >/dev/null 2>&1; then
        run mpv --no-video --really-quiet --volume="$(awk -v l="$level" 'BEGIN { printf "%d", l * 100 }')" "$file"
      elif command -v aplay >/dev/null 2>&1; then
        run aplay -q "$file"
      fi
      ;;
  esac
}

if [ "$mode" = "tour" ]; then
  echo "Pack: $pack, volume $volume${own:+, your own sounds from $own}"
  for moment in session.start task.acknowledge task.complete input.required task.error resource.limit; do
    case "$moment" in
      session.start) label="Start (a session starts)" ;;
      task.acknowledge) label="Got it (you send a message)" ;;
      task.complete) label="Done (Claude finishes)" ;;
      input.required) label="Needs you (Claude needs your OK)" ;;
      task.error) label="Error (a turn stops on an error)" ;;
      resource.limit) label="Full (the context fills up)" ;;
    esac
    if file="$(pick "$moment")"; then
      echo "$label: $(basename "$file")"
      play "$file" 1
      sleep 0.4
    else
      echo "$label: no sound"
    fi
  done
  exit 0
fi

[ -n "$mode" ] && file="$(pick "$mode")" && play "$file" 0
exit 0
