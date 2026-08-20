# Move and reorder (deep reference)

Two verbs, kept strictly apart:

- **move** changes WHAT an item belongs to — a to-do's project/area/heading, a project's area.
- **reorder** changes only the ARRANGEMENT of items already sharing a container and bucket — never membership. Unmentioned siblings keep their order.

The SKILL.md summary is enough for most calls; this page is the full contract. Exact flags always come from `things todo move --help`, `things project move --help`, and `things reorder --help` (current for the binary you invoke).

## Move — changing membership

**To-dos** (`things todo move <refs…> [destination] [position]`, one destination):

- `--to-project <ref>` · `--to-heading <sel>` · `--to-area <ref>` — place into a container.
- Detach family: `--no-heading` (leave the heading, stay in the project) · `--loose` (leave heading, project, AND area) · `--inbox` (back to the Inbox — this also DROPS the schedule).
- There is no `--detach` (removed) and no `--no-area` on a to-do — a to-do's area is inherited, so use `--loose`.

**Projects** (`things project move <refs…> [--to-area <ref> | --no-area] [position]`): `--no-area` is a project's detach (the to-do word `--loose` is refused on a project).

**`--to-heading` scoping.** A heading selector (exact title or uuid) resolves within the movees' shared project; when the movees are not already all in that project, name it with `--to-project`. A heading belongs to one project and cannot hold projects.

## Reorder — changing arrangement

`things reorder <refs…> [--start | --end | --before <ref> | --after <ref>] [--in <target>]` is the ONE reorder verb across EVERY kind — to-dos, projects, a project's headings, AND sidebar areas — dispatching the protocol by kind (it replaced the old `todo reorder` subcommand and the raw `reorder --scope`). All refs must be one KIND; only to-dos and projects intermix, and only on the shared Today/Evening/day axes.

- **Bare (no position)**: the named items assemble as ONE block at the EARLIEST one's current slot, in argument order (`--start` is NOT implied). Partial selection is fine — unmentioned siblings keep their order.
- **Positioned**: `--start`/`--end` send the block to the start/end of its scope; `--before <ref>`/`--after <ref>` place it relative to an anchor.
- **Selection order = landing order** (reverse by naming the refs backwards).
- **Mixed to-do + project refs are allowed** in the Today/Evening/day buckets those kinds share; elsewhere reorder operates within one container+bucket. A heading or area NEVER mixes with another kind — a mixed-kind set is refused with one message.
- **Deadline-forecast rows sort on their Upcoming day too (projects too).** A someday/anytime to-do OR project with a future **deadline** and no start date renders in the Upcoming block on its deadline day. `things reorder` treats it as a first-class member of that day-group: it sorts on the same axis as the day's scheduled rows and interleaves with them, so you can reorder a mixed set of scheduled rows, deadline-forecast to-dos, and deadline-forecast projects in one call. This works with `allow-experimental` OFF — it rides a public-URL deadline-cycle, not the private surface (still gated by `bounce-enabled`, like every multi-leg reorder). An INBOX to-do that merely carries the same deadline is NOT on that day's axis and is refused with a message saying so (schedule it, or take it out of the Inbox, first).
- **Resolved to-do movees (LOGSORT ORD-13):** an UNSWEPT completed/canceled to-do — one still struck-through in its live container body, before the Logbook sweep boundary — CAN be reordered in place: it re-ranks by index only, staying resolved (no reopen). This is permitted ONLY on the pure-native index reorder (a project/area/inbox/someday re-rank, which needs `allow-experimental` ON); a mixed OPEN + unswept-resolved set is fine. A SWEPT completed/canceled to-do (a Logbook resident) is refused, pointing at `things todo reopen` (reactivation) or `--completed-at` (to re-date it in the Logbook — sort order can't express Logbook re-dating). An unswept-resolved movee that would have to ride an uncertified path (a bounce/move fallback — e.g. `allow-experimental` OFF — or an `--in <date>` day-axis target) is likewise refused, telling you to reopen it first.

Headings and areas are now first-class `reorder` operands (see the two sections below); the kind-specific spellings `things project move-heading` (which ALSO does cross-project moves / demotion — the placement verb) and `things area reorder` (a single sidebar area) remain.

## Reordering a project's headings (#V11)

`things reorder <heading-refs…> --start|--end|--before <h>|--after <h>` re-ranks a project's headings in place, dispatching onto the certified native heading-block wire (children follow their heading). All headings must be in ONE project (cross-project is refused). `--in` does not apply (a heading has no stage/day/view axis). Archived headings (completed — unswept OR swept) are reorderable UNGUARDED, exactly like the GUI: the engine composes the minimal wire so an archived heading that need not move stays untouched, but when the target order forces an archived heading to move it PROCEEDS and DISCLOSES that repositioning it brought it back to open (result warning + `--dry-run` leg plan) — never silent. `things project move-heading` remains for cross-project moves and demotion.

## Reordering sidebar areas

`things reorder <area-refs…> --start|--end|--before <area>|--after <area>` re-ranks sidebar areas. This drives the local Things app (a sidebar drag), so it needs `--dangerously-drive-gui` plus `things config set ui-enabled true`; a set of areas is a sequence of drags (non-atomic, disclosed). An area reorder needs a position (there is no bucket to assemble a block in). `things area reorder <ref>` is the single-area spelling.

## Anchors POSITION, never MIGRATE

A `--before`/`--after` anchor only says WHERE in a bucket — it never moves the anchor and never reschedules a movee to reach it. The anchor must already sit in the movees' container+bucket; a cross-container or cross-bucket anchor **fails closed** with a message naming where the rows and the anchor actually are (no silent rescheduling). For a global-axis bucket (today/evening/tomorrow/a future day-group) the anchor need only share the movees' day-group, not their structural container — the app permits exactly that drag.

## The dual axis and `--in` (fail-closed)

A Today/Evening member has TWO order slots: its slot in the Today VIEW (`todayIndex`) and its slot in its own CONTAINER (`index` — a project/area/heading child, or the loose Anytime bucket). When a set (and its anchor) is coherent on BOTH axes and no `--in` is given, the reorder is REFUSED with a message naming both readings and their exact `--in` spellings — this replaces any silent always-Today guess.

**The forecast day is a second dual axis (§9o dual-citizen).** A deadline-forecast row (someday/anytime, no start date, a future deadline) is BOTH a member of its Upcoming day-block (ordered on `todayIndex`) and a member of its container's someday/anytime list (ordered on `index`). So a set where every movee is a forecast member of ONE shared day AND they all share one direct container (same project/heading/area, or all loose) is dual-axis too: a bare reorder is REFUSED, naming the real date and the container/list spelling. A forecast set that spans containers, or a mix of scheduled + forecast rows on one day, is coherent on only the day axis (the day-block) and auto-routes there — no `--in` needed.

- `--in` accepts `today | evening | anytime | someday | inbox`, a project/area/heading ref (uuid or unique title), `upcoming` (the one future day the whole set shares), or a `YYYY-MM-DD` day-block. `loose` is refused (it is a read view, not a bucket).
  - `--in <YYYY-MM-DD>` names one exact Upcoming day-block: every movee must be on that day (scheduled for it, or carrying it as a deadline) and the date must be strictly future (a today/past date is refused, pointing you at `--in today`). `--in upcoming` is the proxy — it derives the single future day the set shares and refuses (listing the per-item days) if they span days. Neither needs a shared container — a day-block is ONE cross-container sortability bucket.
  - `--in someday` / `--in anytime` reorder within a shared container's stage list: every movee must BE that stage AND they must share one direct container (same project, heading, area, or all loose), else it is refused naming the mismatch. `--in inbox` needs only that every movee is inbox-stage.
  - **One KIND per index token.** A stage-list token (`anytime`/`someday`/`inbox`) or a container ref sorts each object kind in its own order-space, so all movees must be the SAME kind — a mixed to-do + project set is refused naming each movee's kind, *even when they share a container* (an area's someday to-dos and someday projects are different index buckets). The `today`/`evening`/`upcoming`/`<YYYY-MM-DD>` day-and-view tokens are the exception: those axes intermix to-dos and projects. A **heading** has no stage/day/view order of its own, so `--in` never applies to a heading set — reorder headings without `--in` (they dispatch onto the project's heading axis; see "Reordering a project's headings" above).
  - The container form of `--in` is POLYMORPHIC — it tries project → area → heading — so a heading whose title is shadowed by a project or area of the same name would resolve to the wrong kind. Pin it with the heading's **decorated ref** `Heading [ref]` (or a bare uuid). Decorated refs (`Title [ref]`) work in every `<ref>` slot: the bracketed uuid/partial-uuid resolves and the title is an ignored comment. A literal title that really contains brackets still wins over the bracket parse (exact-title resolves first).
- `--in someday` / `--in anytime` / a container ref on a same-day forecast set reorders its CONTAINER index (its someday/anytime list order), never the day-block — the explicit axis is honored, not overridden by the day route.
- Forcing the container index axis on a Today/Evening member PRESERVES the Today/Evening flag — a flag-safe move protocol routes it off the de-Today path. Only the someday/inbox loose axes still refuse a flagged member (their re-entry cannot preserve the flag).

**A Today reorder preserves the rest of Today's grouping.** The Today view groups rows by the day each ENTERED Today (its entry cohort), newest first, then manual order within a cohort. The app's native Today reorder can only pull a named row up to *today*'s cohort, so `things reorder` composes the MINIMAL wire that realizes your placement — it names only what must move, and every other Today row keeps its entry cohort and its visible position untouched. A `--first`/`--start` moves the named row(s) to the visible top, re-dating only THEIR entry cohort to today (inherent, expected). A `--before`/`--after`/`--end` that reaches across the grouping has to name the co-listed rows ABOVE the drop point too, which re-stamps THEIR entry cohort to today (changing only their Today grouping, never their schedule) — the result `warnings` + `--dry-run` disclose how many co-listed rows that is, so a broad cohort re-date is never silent. (A container reorder — project/area/heading/inbox/someday — has no entry-cohort dimension, so this note is Today/Evening-only.)

## Mixed-stage move placement

A `move` selection spanning stage sub-buckets (anytime + scheduled + someday + templates):

- `--before`/`--after` is REFUSED unless every movee shares the anchor's sub-bucket (remediation: split the call, or drop the anchor).
- `--first`/`--last` apply PER sub-bucket — each stage-group lands at the top/bottom of ITS matching bucket in the destination, and the result note states every group's placement outcome.

## Gates, caps, and automatic fallbacks

Three config knobs (`things config get/set …`) tune ordering; every default gives full sortability:

- **`allow-experimental`** (default `true`) — enables the private NATIVE re-rank command for the scopes only it can reach directly (`inbox`, `someday`, a project's unheaded children, an area's members, a container's same-day children, `tomorrow`). It is the off-switch, not an opt-in.
- **`bounce-enabled`** (default `true`) — permits the verified `when=`/move round-trip protocols the other scopes use. `false` REFUSES a bounce-dependent placement rather than degrading destructively.
- **`bounce-max-items`** (default `30`) — caps how many items one bounce may touch; a set larger than the cap is refused, not truncated.

**Automatic non-experimental fallbacks (SIT7).** When `allow-experimental` is off (or the native surface is unavailable), the native-only scopes DO NOT fail — each degrades to a proven, verified, flag-safe move protocol (park-and-re-home for `inbox`/`project`/`area`, a `when=` bounce for `someday` and day-groups). Collateral is preserved (Today/Evening flag, live reminder, deadline, container FKs). The result's `warnings` note discloses which fallback ran (e.g. "reordered via the non-experimental PROJROOT fallback because the native reorder is unavailable") — a native placement is never silently mistaken for a degraded one.

**Flag-aware routing (SIT6).** A reorder touching a Today/Evening-FLAGGED row never de-Todays it: the whole touched set swaps to a flag-safe MOVE protocol on the same axis (the `when=` bounce would strip the flag). This is transparent — you still call `things reorder`; the chosen strategy is disclosed in the result.

## Placement guarantees

"Top of bucket in selection order" is GUARANTEED wherever a lab-clean protocol exists: loose inbox/today/evening/someday/anytime; a project's or area's members (anytime AND someday); a heading's anytime/someday children; any container child's evening slot; area-less someday/anytime projects; and a whole future day-group across containers (including scheduled project rows, area'd ones too, and deadline-forecast rows — to-dos and projects — on their deadline day). The result's placement class names which guarantee you got, and a bounce that co-touches unnamed siblings to honor a `--before`/`--after` anchor lists them.

## Repeating templates in day-blocks

A repeating template's projected occurrence renders in an Upcoming day-block, and `things reorder` can now position it there — with two constraints, because a dated `when=`/`deadline=` leg CRASHES a template so the app's own private surface is the only safe writer.

- **On TOMORROW, full power.** When a template's next occurrence lands on tomorrow, BOTH to-do and project templates sort inline with the day's scheduled rows in one native `list "Tomorrow"` call — any position, exact order.
- **On a later future day, to-do templates sort; project templates hold their spot.** A TO-DO template front-inserts via a single-id `list "Upcoming"` native leg interleaved with the day's other rows, so it lands anywhere in the block. A PROJECT template has NO headless reach on a non-tomorrow day (only the Tomorrow call or a manual drag place it), so it stays byte-untouched at the bottom of the block and every other item sorts ABOVE it. A reorder that would need a project template above a movable row (or would re-order two project templates) is REFUSED, naming the arrangement it CAN reach — do that in the app by dragging, or reorder on the day it becomes tomorrow.
- **Templates need `allow-experimental` on.** Any day-group reorder that includes a template requires the private native surface (the to-do-template leg uses it). With `allow-experimental` off, such a reorder is REFUSED, naming the template(s) — it never silently skips them and never routes them onto a crash-path leg.
- A template's placement write is `userModificationDate`-SILENT (a sync/watcher keyed on that timestamp will not see the move); the result discloses it.

Everything non-template is sortable on every guaranteed surface above.

## MCP parity

The MCP server exposes reorder as the single **`reorder`** tool — `refs`, an optional position (`start`/`end`/`before`/`after`), an optional `in` axis, and `dangerously_drive_gui` for area drags — mirroring `things reorder` across every kind. It calls the same library entry the CLI does, so the kind dispatch, the mixed-kind / cross-container / cross-axis refusals, the #V11 heading disclosure, the dual-axis refusal, the flag-safe routing, and the automatic fallbacks behave identically. (`reorder_areas` was folded into this tool and removed — plan PR D.)
