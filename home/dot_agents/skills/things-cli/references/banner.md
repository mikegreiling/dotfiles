# The Today banner, provisional pips, and liveness (deep reference)

Things renders three presentation-layer facts that are NOT stored as their own bytes — the "new to-dos" banner, the evening section, and the reminder bell. The reader mirrors the app faithfully rather than reporting the raw columns. This page is the model behind the `provisional` field, the `•` pip, and reminder/evening liveness.

## The provisional `•` pip and the "N new to-dos" banner

When items arrive in Today on their own, Things shows a yellow "You have N new to-dos" banner and a yellow `•` pip on each such row. Those rows are **provisional** — Today members the app has not yet materialized.

- The wire emits presence-keyed **`provisional: true`** on exactly those rows, on every tier, and never drops it (the banner is not a section). The banner's `N` equals the count of `provisional` Today members, exactly — **the banner as data.**
- **What "new" means:** the flagged rows are the AUTONOMOUS entrants — a scheduled arrival (lands on its startDate), a repeat-instance spawn, or a due-deadline pull (no startDate yet). A USER-placed entrant (`add`/`update --when today`, which lands materialized) is never flagged. The wire hands you `provisional` directly, so you never compute it; the underlying law (what a raw-DB watcher would evaluate) is `start` is not `1` (active) OR `startDate IS NULL`.
- `provisional` reuses the same Today markers `when` does, so it can never disagree with the ★ the row would render.
- **The pip is Today-view-only.** In the app's Anytime list the same provisional row shows the ordinary Today ★ and no pip. So the TTY renders `•` only in `things today` (Today and This Evening sections); the wire `provisional` field is present on every surface, but the `•` glyph is not.

**A provisional row is already a full Today member** — visible, sortable, and mutable through every ordinary write. Model it as `stage: "anytime"` + `when: "today"` + `provisional: true`: at pull time the app re-files a deadline-pulled Inbox/Someday row into Anytime (RS8/BANNER1b), so it is EXCLUDED from the Inbox/Someday lists and INCLUDED in Anytime even though the user never chose to leave those buckets — the derived stage reflects where the app actually shows it.

## There is no `today ok` — dismissing the banner is a data mutation

`things today ok` (acknowledge the banner / clear the pips) is a DECIDED not-to-implement (⛔). Reasons worth knowing:

- Clicking **OK** in the app does exactly one thing: it MATERIALIZES the provisional rows — `start := 1` and `startDate := ` the cohort/deadline date where it was NULL — and writes nothing else, in no other table. There is no separate "reviewed" marker anywhere; acknowledgment IS the row mutation.
- That mutation is **not byte-reproducible** through a supported write (`--when today` no-ops on a provisional row; the OK'd `startDate` is a past date every URL write clamps; `--when anytime` is the only leg that flips the bucket but it ejects the row from Today), and it silently **de-inboxes / de-somedays** an untriaged pulled item (`start 0→1` / `2→1`). Approximating it would diverge silently from the app's own bytes, so it is not offered.

**The per-item dismiss you CAN drive (deadline-pulled rows):** rescheduling an overdue-deadline row out of Today to a no-startDate bucket — `things todo update <ref> --when someday` (or `anytime`) — auto-stamps the app's own suppression so the past deadline stops re-pulling it; or `things todo update <ref> --clear-deadline` removes the deadline outright. There is no dedicated "dismiss deadline" affordance in the app either — this reschedule side effect is it.

## What a watcher sees

A process polling the database must tolerate the app rewriting provisional rows' schedule bytes out from under it: when a human clicks OK (on this or any synced device), every listed row's `start`/`startDate` change (`start:=1`, `startDate:=` the cohort date). Nothing else moves. So a watcher should key "new/unreviewed" off the same derivation the reader uses (`start != 1 OR startDate IS NULL`), NOT off a stored marker (there is none), and expect those bytes to settle once the user acknowledges.

## Reminder and evening liveness (§9n)

The app shows a reminder bell and a "This Evening" placement only while the row's `startDate` is TODAY (or future, for a reminder). Once `startDate` goes strictly past, the app discards both at the presentation layer while leaving the raw columns in the database forever — nothing clears them, not a day-rollover, not the banner OK. The reader mirrors this:

- **Reminders.** A today- or future-dated reminder is reported (`reminder` present); a strictly-past one is OMITTED on every surface (list rows, detail, JSON, search, and the TTY `◷` chip). The stored byte is never touched. On the WRITE side a bare `--when` re-schedule auto-preserves a LIVE reminder but never RESURRECTS a stale one (so `--when evening` on a weeks-past row no longer re-arms an 18:00 bell the user believed gone).
- **Evening.** An arrived evening row whose `startDate` has gone past collapses to a plain Today member — `when` reads `"today"`, not `"evening"`. The evening section expires daily.
- **Reminder format:** the JSON wire carries `HH:MM` (24-hour); the human TTY chip renders 12-hour. Same fact, two renderings.
