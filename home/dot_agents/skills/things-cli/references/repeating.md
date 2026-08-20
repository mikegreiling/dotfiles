# Repeating series — the model, the scheduling vocabulary, and the deadline law

A repeating item is a **template** plus the **instances** it spawns. The template holds the rule (how often, on what calendar day, with what deadline/reminder/end bound); each occurrence the app materializes is a separate to-do (or project) you complete normally. Completing an instance never touches the template; the template keeps spawning the next occurrence on schedule.

## The verbs

- `things todo make-repeating <ref> --frequency … --interval …` — turn an existing plain to-do into a repeating series. This **REPLACES the item**: the original to-do disappears and a fresh template takes its place, so the uuid you get back is the TEMPLATE's, not the original's. Cannot be undone through the normal path (the original is moved to the Trash; `things undo` removes the new series and restores it).
- `things todo add-repeating "<title>" --frequency … --interval …` — create a new to-do already repeating, in one step.
- `things todo reschedule-repeat <ref> --frequency … --interval …` — change the rule of an EXISTING template in place (identity preserved). Only the fields you name change; an unnamed deadline/reminder/anchor is left as it was.
- `things todo pause-repeat <ref>` / `resume-repeat <ref>` — suspend/restart spawning without losing the rule.
- `things project …` mirrors all of the above for repeating projects.

All of these drive the Things app's own Repeat dialog, so they require `--dangerously-drive-gui` (and `things config set ui-enabled true`). See the operational rules at the bottom.

## The scheduling vocabulary

- **`--frequency`** `daily | weekly | monthly | yearly`, **`--interval N`** = every N of those units.
- **`--when <YYYY-MM-DD>`** — the date the FIRST occurrence APPEARS (its start). Later occurrences follow the rule's calendar anchor. If you omit `--when`, `make-repeating` starts from the item's own scheduled date.
- **The calendar anchor** — WHAT day the series recurs on, per frequency:
  - weekly → `--weekdays monday,wednesday,friday` (one or more).
  - monthly → `--on-day <1–31 | last>`, OR an nth-weekday with `--on-weekday <weekday> --on-ordinal <1–5 | last>`.
  - yearly → `--yearly-month <1–12>` plus `--on-day` (or the nth-weekday pair).
- **Derived anchor.** If you give `--when` but NO explicit anchor, the anchor is taken FROM `--when` (weekly → its weekday, monthly → its day-of-month, yearly → its month + day). So `make-repeating <ref> --frequency yearly --when 2028-10-16` recurs every October 16 with no anchor flags needed.

## Off-schedule first occurrence (a first-class pattern)

The first occurrence does NOT have to sit on the recurring grid. If `--when` disagrees with an explicit anchor, the series APPEARS on `--when` the first time and follows the anchor from the second occurrence on. Example: `--frequency weekly --weekdays wednesday --when <a Thursday>` = a Thursday first occurrence, then Wednesdays every week after. Weekly and yearly rules support this; the command discloses both halves of the landed pattern (`appears <date>; thereafter <rule>`) in its result and in `--dry-run`.

**One exception — monthly.** A monthly rule cannot start off its anchor day: the app snaps the first occurrence to the anchor's day-of-month, so an off-anchor monthly first is refused up front. Put `--when` on the anchor day, or omit the anchor to take it from `--when`.

## The deadline law (read this before combining `--deadline` with an anchor)

`--deadline` gives each occurrence a due date; `--start-days-earlier N` makes each occurrence APPEAR N days before it is DUE. The key rule: **in deadline mode the calendar anchor names the DUE date, and `--when` is still the APPEAR (start) date.** So an explicit anchor must name `when + N` (the due date), not `--when` itself.

Worked example — intent "appears October 16, due October 30" (a 14-day lead):

- Simplest: `--frequency yearly --when 2028-10-16 --deadline --start-days-earlier 14` with NO anchor flags — the due-date anchor is derived as October 30 and each occurrence appears 14 days earlier, on October 16.
- Explicit anchor equivalent: name the DUE date — `--yearly-month 10 --on-day 30 --when 2028-10-16 --deadline --start-days-earlier 14`.

If you instead write an explicit anchor on the APPEAR date (`--on-day 16` with the same `--when` and lead), you are asking for an off-schedule first occurrence relative to the due-date anchor — for weekly/yearly this is honored and disclosed (the first occurrence appears/dues on your `--when`, the ongoing series dues on the anchor); a monthly combination of this shape is refused as above. When you want the two to agree, either drop the anchor flags (derived) or set the anchor to the due date (`when + N`).

### Repeating deadlines on `add-repeating`: two spellings for one geometry

A concrete `--deadline <date>` on `todo add-repeating` sets each occurrence's due date relative to its own start, and the RULE owns it: every occurrence is deadlined, the FIRST one due on the date you name. You state that geometry in ONE of two equivalent ways — the tool does the arithmetic:

- **Concrete** — `--deadline <date>` is the first occurrence's due date; the per-occurrence lead is derived as `deadline − --when`. Reach for this when you know both dates.
- **Relative** — `--start-days-earlier N` names the lead directly (each occurrence starts N days before its own deadline; the first deadline is derived as `--when + N`). Reach for this when the intent is genuinely relative ("due two weeks after it appears").

The steer: state the two dates you actually know, pick the spelling that matches your intent, and **give ONE form or the other, never both** — never compute one from the other yourself. Both need a concrete `--when` (and `--deadline` must be on or after it); the anchor names the DUE date as usual; neither applies to an after-completion series. The safety net: if you do pass both, they must agree (`deadline − --when == N`), and a mismatch is refused up front with a message naming both corrected spellings.

One call, no follow-up `reschedule-repeat`: `todo add-repeating "Taxes" --when 2027-03-15 --deadline 2027-05-31 --frequency yearly --yearly-month 5 --on-weekday monday --on-ordinal last` deadlines every occurrence with a 77-day lead. (A concrete `--deadline` now maps to the rule; historically it landed on the seed only and double-booked the first occurrence — see [docs/lab/dblspawn1-preserved-instance.md](../../../docs/lab/dblspawn1-preserved-instance.md).)

## Ends bounds, reminder, and limits worth knowing

- **Ends bound** (default: never): `--ends-after N` stops after N total occurrences (the ORIGINAL count, not a remaining tally — it does not tick down), or `--ends-on <date>` stops after that date. An exhausted series reads as `ended`.
- **Reminder**: `--reminder HH:mm` sets a time-of-day alert on each occurrence.
- **After-completion cadence**: `--after-completion` repeats N units AFTER each occurrence is completed, rather than on a fixed calendar. It has NO calendar anchor and takes NO end bound — those are refused.
- **Expressibility**: a rule can carry only ONE end bound (not both a date and a count), and a monthly/yearly rule only ONE calendar anchor. Reschedule cannot restore a rule shape the Repeat dialog itself cannot produce.

## Operational rules for the GUI-driven repeat commands

These commands visibly drive the Things app and are slow — often OVER A MINUTE on a large, syncing database. (This is the same guidance as the main skill page and `things help repeating`, condensed.)

- Allow a generous wrapper timeout — **at least 180s** where your harness permits (120s floor) — and pass `--verify-timeout 120000` or more so the app's own budget outlasts the drive.
- **A timeout, empty output, or a silent no-op is NOT success** — treat it as "outcome unknown". Before doing anything else, re-read the item with `things show <ref>` (and, on a dev checkout, the trace under `~/.local/state/things-api/trace/`) to learn what actually landed.
- **If your environment kills long commands** (a hard wall-time cap you cannot raise): pass `--op-id <key>` on the write, let the command die, then run **`things op-result <key>`** in a fresh command to read what actually happened — it reads the local change history the killed process already wrote and reports `found` (the final result + target), `intent-only` (started but no outcome recorded — still running or the process died mid-flight, outcome UNCERTAIN), or `unknown`. This is the recovery path for a capped harness; do NOT infer the outcome from the kill. (`--op-id` works on the single-op repeat verbs like `reschedule-repeat`; `make-repeating` / `add-repeating` are compounds — express them as a `batch` line with a per-line `opId` if you need this.)
- **Never fire an identical retry** after a timeout or a kill — a blind retry is how you get a duplicate or half-configured series (original trashed, wrong template created). Learn the real outcome first (`things op-result` / `things show`); if the state is wrong or ambiguous, STOP and file a bug with the trace.
- These ops need Things reachable on the current desktop (not a locked screen or a covering full-screen app); a session it cannot reach is refused cleanly with a remediation, touching nothing.
- A genuine success always returns a structured JSON result (with `--json`) naming the new/updated uuid.
