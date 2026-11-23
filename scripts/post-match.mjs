#!/usr/bin/env node
// A post-match screen for your week with Claude Code. One file, nothing to install: node claude-post-match.mjs [days]
//
// It reads Claude Code's own session logs on your computer (~/.claude/projects) and prints totals. It counts who spoke
// and when. It glances at how each message starts only to tell what you typed from notes the app adds, and never
// prints, saves or sends any of it. It doesn't look at which folder a session was in or what any tool did.
//
//   a task     one thing you asked for, and everything Claude did until your next message
//   win        a task where Claude's last word wasn't an error
//   defeat     a task that ended on an API error ("stopped" are the ones you interrupted)
//   busy       time with something happening in a task: gaps between log lines, counted when 5 minutes or less
//   waited     from Claude finishing to your next message, counted only when it's under 15 minutes
//
//   node claude-post-match.mjs        the last 7 days
//   node claude-post-match.mjs 1      today
//   node claude-post-match.mjs --json the numbers only
import fs from "node:fs";
import os from "node:os";
import path from "node:path";
import readline from "node:readline";

const args = process.argv.slice(2);
const DAYS = +args.find((a) => /^\d+$/.test(a)) || 7;
const WAIT_CAP = 15 * 60, IDLE = 5 * 60, since = Date.now() - DAYS * 864e5;
const root = path.join(os.homedir(), ".claude", "projects");

const textOf = (e) => {
  const c = e.message && e.message.content;
  return typeof c === "string" ? c : Array.isArray(c) ? c.filter((p) => p && p.type === "text").map((p) => p.text).join("\n") : "";
};
function typed(e) {            // a message a person sent, not a tool result or a note from the app
  if (e.type !== "user" || e.isMeta || e.isSidechain) return false;
  const t = textOf(e).trim();
  return Boolean(t) && !t.startsWith("<") && !t.startsWith("[Request interrupted") && !t.startsWith("This session is being continued") && !t.startsWith("Caveat:");
}

async function session(file) {
  const tasks = [];
  let cur = null, tools = 0, last = 0, stopped = 0;
  for await (const line of readline.createInterface({ input: fs.createReadStream(file), crlfDelay: Infinity })) {
    if (!line.includes('"timestamp"')) continue;
    let e; try { e = JSON.parse(line); } catch { continue; }
    const t = Date.parse(e.timestamp);
    if (!t || t < since || e.isSidechain) continue;
    if (e.type === "user" && textOf(e).startsWith("[Request interrupted")) stopped++;
    if (typed(e)) { if (cur) tasks.push(cur); cur = { start: t, end: null, error: false, active: 0 }; }
    else if (cur && last && t > last && t - last <= IDLE * 1000) cur.active += (t - last) / 1000;
    if (t > last) last = t;
    if (e.type === "assistant" && cur) {
      cur.end = t; cur.error = Boolean(e.isApiErrorMessage);
      const c = e.message && e.message.content;
      if (Array.isArray(c)) tools += c.filter((p) => p && p.type === "tool_use").length;
    }
  }
  if (cur) tasks.push(cur);
  return { tasks: tasks.filter((k) => k.end), tools, stopped };
}

if (!fs.existsSync(root)) { console.error(`No Claude Code logs found at ${root}`); process.exit(1); }
const s = { days: DAYS, sessions: 0, tasks: 0, wins: 0, defeats: 0, stopped: 0, streak: 0, busy: 0, waited: 0, waits: 0, longest: 0, tools: 0 };
for (const dir of fs.readdirSync(root)) {
  const d = path.join(root, dir);
  if (!fs.statSync(d).isDirectory()) continue;
  for (const f of fs.readdirSync(d)) {
    const file = path.join(d, f);
    if (!f.endsWith(".jsonl") || fs.statSync(file).mtimeMs < since) continue;
    const { tasks, tools, stopped } = await session(file);
    if (!tasks.length) continue;
    s.sessions++; s.tools += tools; s.stopped += stopped;
    let run = 0;
    tasks.forEach((k, i) => {
      s.tasks++; s.busy += k.active; s.longest = Math.max(s.longest, k.active);
      if (k.error) { s.defeats++; run = 0; } else { s.wins++; run++; s.streak = Math.max(s.streak, run); }
      const next = tasks[i + 1];
      if (next) { const gap = (next.start - k.end) / 1000; if (gap >= 0 && gap <= WAIT_CAP) { s.waited += gap; s.waits++; } }
    });
  }
}
if (args.includes("--json")) { console.log(JSON.stringify(s)); process.exit(0); }

const n = (v) => v.toLocaleString("en-GB");
const hm = (sec) => { const m = Math.round(sec / 60); return m >= 60 ? `${Math.floor(m / 60)} h ${String(m % 60).padStart(2, "0")} m` : `${m} min`; };
const W = 20, cell = (t) => " " + String(t).slice(0, W - 1).padEnd(W - 1);
const row = (a, b, c) => "  │" + cell(a) + "│" + cell(b) + "│" + cell(c) + "│";
const rule = (l, m, r) => "  " + l + ["", "", ""].map(() => "─".repeat(W)).join(m) + r;
console.log([
  "",
  `  POST-MATCH · my ${DAYS === 7 ? "week" : DAYS === 1 ? "day" : DAYS + " days"} with claude code`,
  `  ${n(s.sessions)} sessions · ${n(s.tasks)} things asked · ${n(s.tools)} tool calls · last ${DAYS} day${DAYS === 1 ? "" : "s"}`,
  "",
  rule("┌", "┬", "┐"),
  row("WINS", "DEFEATS", "LONGEST STREAK"),
  row(n(s.wins), n(s.defeats), n(s.streak)),
  row("tasks it finished", `+${n(s.stopped)} i stopped`, "wins in a row"),
  rule("├", "┼", "┤"),
  row("CLAUDE WAS BUSY", "IT WAITED FOR ME", "LONGEST TASK"),
  row(hm(s.busy), hm(s.waited), hm(s.longest)),
  row("working", `${n(s.waits)} times`, "in one task"),
  rule("└", "┴", "┘"),
  "  counted from claude code's own logs on this computer: who spoke and when,",
  "  never what was said. a wait counts under 15 min; busy skips gaps over 5 min.",
  "",
].join("\n"));
