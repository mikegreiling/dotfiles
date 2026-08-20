# The Things data model (deep reference)

Entities, relationships, and how the sidebar views are computed over them, as exposed by the `things` CLI. The SKILL.md "Data model" section is the summary; this is the full version.

## Entities

| Entity | Container | Can contain | Dates | Tags |
| --- | --- | --- | --- | --- |
| To-do | area, project, heading, or NONE (standalone) | checklist items | when, deadline, reminder | own + inherited |
| Checklist item | its to-do | — | — | — |
| Heading | its project | to-dos | — | none (inheritance passes through) |
| Project | area or standalone | headings, to-dos | when, deadline | own + inherited from area |
| Area | top level | projects, loose to-dos | — | own |
| Tag | tag hierarchy (may nest) | child tags | — | — |

## Rules

- A to-do has at most ONE container, and may have none — standalone to-dos (no project, no area) are normal and appear at the top level of Anytime/Someday/Upcoming. Moving changes the container; completing or trashing does not.
- The **Inbox is a state, not a container**: "in the Inbox" means untriaged — no container AND no schedule. Filing or scheduling an inbox to-do moves it out (filing promotes it to Anytime); moving a to-do TO the Inbox clears both its container and its schedule.
- A heading is a section label inside one project — not a task. It cannot be scheduled or tagged, and its lifecycle is **archive/unarchive ONLY** — a heading is never completed or canceled (it has no canceled state). In a `project show` view (read-shape v2) a heading is an entry of `headings[]` — `{ uuid, title, archived?, children }` — carrying no `status`/`stage`; it emits a presence-keyed **`archived`** (the ISO archive timestamp) when archived, absent when open. ALL headings live in that one `headings[]` array in order regardless of lifecycle class — open, archived-unswept, AND archived-swept; sweep state is NOT on the wire. A swept heading simply carries `archived` and its logged children ride ITS `children.logbook`; the GUI's grouping of swept headings into the logbook region is TTY-derived from that, not a separate wire array. Deleting/archiving a heading affects only the label, per the operation's contract.
- Tag inheritance flows downward: area → project → (through heading) → to-do. A to-do's *effective* tags = own tags ∪ project tags ∪ area tags. List output distinguishes own vs inherited tags.
- **Status**: open → completed or canceled (both land in the Logbook) or trashed (Trash; restorable until emptied). Reopen brings a logged item back.
- **when** (`today | evening | anytime | someday | YYYY-MM-DD`) controls which view an item appears in; **deadline** is an independent due date shown alongside the item; **reminder** is a time-of-day alert attached to a dated when.
- "Overdue" = open with a deadline strictly before today (a deadline of today is "due", not overdue).

## Views (queries over the model)

`things inbox|today|upcoming|anytime|someday|logbook|trash` mirror the app's sidebar. Each is a query over the rules above, not a stored list:

- **inbox** — untriaged to-dos (no container, no schedule).
- **today** — items scheduled for today, with the **This Evening** section beneath.
- **upcoming** — future-dated items, forward-ordered by date. JSON returns `data.sections = [{when, items, total?} …]` — chronological day blocks keyed by `when` (an ISO date), then a trailing `{when: null, items}` block of date-less recurring templates when any exist (flatten with `.data.sections[].items[]`).
- **anytime** — all active items kept without a specific date (standalone or filed). JSON returns `data.sections = [{area, items, total?} …]` — area-grouped sections (sidebar-rank order; `area` is `null` for the loose section), each carrying its inline `total` iff its rows were capped by `--area-limit`/`--project-limit` (flatten with `.data.sections[].items[]`).
- **someday** — items deliberately kept without a date. Same `data.sections = [{area, items, total?} …]` shape as anytime.
- **logbook** — completed/canceled items.
- **trash** — trashed items (restorable until the trash is emptied).

Beyond the sidebar mirror, **`things deadlines`** is a derived query view (not an app sidebar list): one flat `data.items[]` of every LIVE item — to-dos AND projects — that carries a deadline, ordered `deadline` ASC (most-overdue first), tie-broken by Today order then uuid. Its `stage` is KEPT (stage-mixed, like `search`/`changes`). It is presentation-ordered and **NON-SCOPE** — deadline order IS the view, so it is not reorderable (`reorder --in deadlines` is refused). A dismissed deadline nag does NOT hide a row here (dismissal only affects the Today pull, not the deadline). Deadline-bearing repeating items are PROJECTED at their next occurrence's deadline (the same projection the `upcoming` view uses); a deadline-less or unprojectable template is left out. Filters: `--today` (only current Today members, This-Evening included), `--overdue` (only open items already past today — never projections), `--project`/`--area`/`--tag`, `--limit`/`--all`. MCP: `read_view deadlines` with `today`/`overdue`/`project`/`area`/`tag` params.

`things projects`/`areas`/`tags` list containers; `things projects <ref>` / `things areas <ref>` / `things show <ref>` show one item's full detail — notes, checklist, effective tags — which the compact list rows do NOT display.

### Reading view membership from JSON — `stage` and `when`

Reads decompose an item's position onto two derived, presence-keyed words (they REPLACED the old `start`/`startDate`/`logged`/`trashed`/`todaySection` wire fields, which no longer appear):

- **`stage`** — the sidebar BUCKET: `inbox | upcoming | anytime | someday | logbook | trash`. Read view membership off it directly. It is dropped inside a section/catalogue that already states it (the stage-pure `inbox`/`anytime`/`someday`/`logbook`/`trash` lists and the `today` view's two `children` buckets) and kept everywhere it is not implied (the mixed `upcoming` day blocks — future-dated `upcoming` rows beside deadline-forecast `anytime`/`someday` ones — plus `search`, `changes`, `deadlines`, the projects/areas listings, and `detail`).
- **`when`** — the TIME POSITION: `today | evening | a future ISO date`, or absent (unscheduled and not in Today). `evening` implies today. Someday is a bucket, never a `when`. The `today` view returns `data.children = { today: {items, total?}, evening: {items, total?} }` — two keyed buckets (the bucket key states today/evening, so `when` is dropped inside them); the whole-view count rides `meta.counts` (`{dueOrOverdue, other}`).
- The two are DIFFERENT facts. A due deadline pulls an UNDATED row into Today: it reads `when: "today"` and derives `stage: "anytime"` — the app re-files a deadline-pulled Inbox/Someday row into Anytime at pull time (RS8/BANNER1b), so it drops out of the Inbox/Someday lists and joins Anytime while its `when` reads `today`. Completed/canceled → `stage: "logbook"`, trashed → `stage: "trash"`, regardless of any other hint.
- `provisional: true` marks a Today member the app has not yet materialized — see [banner.md](banner.md).

## Tiers — compact vs full (absence is meaningful)

Every row comes back at one of two densities, selected by view kind + flag, never by a caller-supplied field list:

- **Compact** (the list default) keeps identity + structural + non-default facts. A field at its default is OMITTED, so absence = the default: no `status` = open, no `checklist` = none, no `todos` = no child to-dos, no `when` = not in Today and unscheduled, no `provisional` = materialized. The full `notes` string is dropped and replaced by presence-keyed `hasNotes: true`; `startDate`, `created`, and `modified` are dropped.
- **Full** (`show`/`detail`, or a list forced with `--full`) is the whole record — the complete `notes`, the raw `startDate` substrate behind `when`, the checklist `items` array, and timestamps.
- Compact rows still carry the useful summaries: `checklist:{open,total}` on a to-do, `todos:{open,total}` on a project (app-maintained leaf-action counts — never headings, checklist items, or trashed rows), and `match:{field,text}` on a `search` hit whose match was NOT the title (`field` ∈ `heading | notes | checklist`).
- **Container absence rule:** inside a single-container node (a project/area card, an `anytime`/`someday` section, a `project show` `headings[]` entry) an item omits any ancestry the node already states, so absent `project`/`area`/`heading` there means *inherited from the enclosing node*. A mixed list (`inbox`/`today`/`search`/`changes`) still names each row's own `project`/`area` (the `heading` ref is compact-dropped outside a project view; `--full` keeps it). In a read-shape v2 **`project show`** view membership is fully STRUCTURAL: every bucket row — un-headed body children AND rows nested under a `headings[]` entry, INCLUDING each `children.logbook` row — drops its `heading` ref, because its position states it. A swept child of an OPEN heading rides that heading's `children.logbook`; a swept child of an ARCHIVED heading rides the archived heading's `children.logbook`; the GUI's PROJECT-vs-HEADING logbook sublabel is TTY-derived from that structural placement, not from a per-row ref.
- **Container ref shape:** a container ref is a bare **title string** (`"area": "Family"`, `"project": "Groceries"`, `"heading": "Backlog"`). A flat sibling `areaUuid` / `projectUuid` / `headingUuid` (the full uuid) rides alongside **only when the bare title would not resolve back** to that exact item — a duplicate title in the same resolution scope, or a title that is itself a valid uuid prefix. **To act on a ref, pass `.areaUuid // .area`** (same for project/heading): the uuid when present, else the title. For unattended pipelines or stored refs, use `--full` and key on the uuids — the full tier emits every `*Uuid` sibling unconditionally. A row whose container project is a repeating template carries a flat `projectIsTemplate: true` (the JSON twin of the TTY `↻` glyph) — acting on such a row edits the blueprint, affecting future occurrences, so target the intended copy via `projectUuid` (a same-titled occurrence exists alongside the hidden template).
- **`type` is presence-keyed:** **absent `type` = to-do.** A row omits `type` when it is a to-do; `type` is present for a `project`, `heading`, `area`, or `tag` ROW (including in the error `candidates` shape). This is scoped to ROWS/candidates — a positional keyed node whose kind is fixed by its slot (a `project show` `headings[]` entry) drops `type` too, since its position already states it is a heading.
- **Repeating templates vs instances (presence-keyed):** a repeating **template** (the hidden rule; list views hide it, `show` finds it) carries a nested `repeating: {paused?, deadlined?, rule?, latestInstance?}` — presence of `repeating` MEANS template; `rule`/`latestInstance` appear on a `show`/`detail` read only, and its projected next date rides the top-level `when`. A spawned **instance** (the visible occurrence) carries a flat `instanceOf: <templateUuid>` and NO `repeating` — presence of `instanceOf` MEANS instance. **On a `show`/`detail` read an instance ALSO carries `repeats: {rule?, next?, paused?}`** — its template's repeat context, the GUI's lower-corner "Repeats on Aug 19" / "Repeats 1 day after completion" caption: `rule` is the same decoded shape the template card emits, `next` the projected next occurrence for a **fixed** rule (ABSENT for after-completion — no successor date until the current instance completes), `paused: true` when the template is paused. It is read-only CONTEXT — `instanceOf` is the write handle (target the occurrence by it; the rule lives on the template). `repeats` is absent on list rows and when the template is unresolvable. A plain (non-repeating) row carries none of these.

## Filters over views

Read filters compose with AND: `--tag <name>` (repeatable) / `--untagged` / `--exact-tag` for tags (in single-container `project show` / `area show` these match the row's own tags; in flat views they include inherited tags), `--overdue` (open items whose deadline is before today), `--limit N`, and `--since`/`--until` where offered. `things search <words>` matches title/notes over open items — widen with `--all`, `--logged`, `--trashed`; narrow with `--type project`. `things changes --since <moment>` is the pull-based substitute for a watch mode. Exact flags per command: `things <group> --help` and `things help filters`.
