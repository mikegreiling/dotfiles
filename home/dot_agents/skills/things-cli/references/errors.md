# The error contract (deep reference)

A failed `--json` call carries `ok: false`, `kind: "error"`, and an `error` object with a machine-readable `code`, a human `message`, an optional `likelyCause` and `remediation`, and at most one structured `detail`. The exit code mirrors the family (see [contracts.md](contracts.md)). A nonzero exit is informative, not a dead end — the change did not silently half-apply, and the message usually names the fix.

## Candidates — self-correcting from an ambiguous or missing ref

When a name or partial-uuid resolves to more than one row, or to none, `error.detail.candidates` offers a disambiguation list so you self-correct without another round-trip. Each entry is ONE fixed, slim shape:

- `uuid` and `title` — always. `type` (`"project" | "heading" | "area" | "tag"`) — present for those kinds only; **absent `type` = to-do** (the same convention the item wire uses).
- A container hint `area` and/or `project` as a TITLE string — only when set.
- `stage` / `when` (the same derivations as the item wire) — only for a to-do/project candidate whose row carries them. A trashed/logged candidate needs no boolean: `stage` already reads `"trash"` / `"logbook"`.
- NOTHING else — no notes, counts, dates, or raw fields.

The shape is **flag-invariant**: `--full` / `--all` never widen it (an error payload is the most determinism-critical surface). The list is **capped at 8**; when more matched, the `message` states the total (e.g. "matches 12 projects … 4 more"). `ambiguous` carries the candidate list; `not-found` carries `candidates: []`.

**Fused refs and decorated input.** On a TTY the human candidate lines render each entry in the fused form **`Title [8charPrefix]`** (a duplicate-titled project/to-do candidate also gets a `· started YYYY-MM-DD` tail so recurring twins are distinguishable). That fused string is itself a valid **decorated ref**: `<ref>` slots everywhere (CLI flags, `--to-project` / `--to-heading` / `--area`, MCP args, library refs) accept **`Title [ref]`** — the bracketed segment (a uuid or ≥6-char partial-uuid) is resolved and the title half is an ignored comment, so a stale copy keeps working after a rename. Copy a fused candidate straight back as the ref. A *literal* title that really looks like `Name [abcd1234]` still wins (exact-title resolution outranks the bracket parse); the empty-title form `[prefix]` (a titleless heading) is legal.

**Live-scoped pool + dead-row hints.** By default candidates are LIVE rows only — a trashed or logged row never appears as a "did you mean". A trash/logbook-domain op (e.g. `project restore`) widens its own pool to that domain. When a name matches ZERO live rows but a DEAD row exists, the `message` gains an honest tail ("1 trashed item matches this name — see `things trash`", or the logbook equivalent) and `candidates` stays `[]` — no dangling-ref invitation. A write whose only name-match is a completed/logged project resolves to nothing by name (target it by uuid if intended); this prevents stranding an open child inside an invisible done project.

**Read-side liveness (project name resolution).** The SAME live-only law governs names on the read side, so `things "X"` (the bare-ref shorthand) and `things project show X` always agree, and an ambiguity's count always matches its candidate list. A NAME resolves against live (untrashed) rows only; an explicit uuid / partial-uuid still reaches a trashed project (viewing one by id is unchanged). Three read-only consequences:

- **Unique-dead fallback.** A name matching zero live rows but exactly ONE trashed project resolves to it and the view discloses it (the card's `(trashed)` marker / the JSON node's `stage: "trash"`). Several trashed-only twins → not-found with the dead-row hint above.
- **Trash disclosure on ambiguity.** `"X" matches N projects` counts only live rows (equal to the candidate list); extra trashed twins are disclosed — `… also matched: N in the trash — \`things trash\` lists them, a uuid reaches one directly` — never folded into the count. The error `code` is `ambiguous`, with the live candidates under `detail.candidates`.
- **Cross-kind merge.** The shorthand's namespace spans to-dos, areas, and projects. A unique winner follows the chain uuid → area → project; but an AMBIGUOUS subject with live matches at more than one kind refuses with the candidates MERGED across kinds (each carries its `type`) — `"X" matches 2 areas and 3 projects — use \`things area show\` / \`things project show\`, or a ref below` — so the shorthand never hides an option the narrower command would show.

Never guess between candidates for a destructive action — inspect details or ask.

## Guarded writes and their acknowledgments

Some writes have a cascading or permanent effect. Each is refused BEFORE touching the app until you pass the flag that names the consequence; a `--dry-run` shows the same refusal. The CLI describes each by its consequence, but the JSON error's `blocked:<hazard>` code is the machine-readable handle:

- **Delete a NON-EMPTY area** → `--allow-non-empty`. Deleting an area sends its to-dos AND its projects (with their children) to the Trash and destroys the area row permanently. A delete pre-counts live members and refuses with the counts ("the area is not empty — it contains 3 projects and 12 to-dos"), naming both remediations: empty the area first, or pass `--allow-non-empty`. An empty area is unaffected (still just `--dangerously-permanent`). Code: `blocked:H-AREA-NOT-EMPTY`.
- **Permanent delete** (an area; emptying the Trash) → `--dangerously-permanent`. There is no inverse; `undo` names the manual one rather than pretending. Code: `blocked:H-PERMANENT-DELETE`.
- **Drive the live UI** (the ops the app offers nowhere else — e.g. `area reorder`, and some heading/repeat ops) → the two-key gate: the `--dangerously-drive-gui` flag AND `things config set ui-enabled true` (plus Accessibility granted to the process). These visibly drive the Things window. Code: `blocked:H-UI-DRIVE`. (Separately, the `--allow-disruptive` / `--allow-very-disruptive` flags raise the process's disruption ceiling for any op that steals focus or drives the UI.)
- **Reopen or reuse a resolved project** — moving or adding an OPEN child into a completed/canceled project reopens it via the app; that is acknowledged (`blocked:H-REOPEN-RESOLVED-PROJECT`) so it is never a silent side effect.
- Other guards name their own consequence the same way (heading cascades, backdating an open item, checklist replacement, repeat scheduling, tag-subtree delete, …).

`things capabilities` lists every operation's support and preconditions; `--dry-run` previews any plan. If a request needs a capability the tool reports as unsupported, say so plainly rather than improvising through unrelated commands.

## The error-code families

Every `error.code` is drawn from a frozen registry. Route on the code, and for the two template families route on the prefix:

| Family | Meaning | Exit |
|---|---|---|
| `usage` | Bad flags/arguments, mutually-exclusive flags, an unparseable date, or a move that meant to schedule. | 2 |
| `not-found` | A ref or subject resolved to nothing (`candidates: []`). | 2 |
| `ambiguous` | A name/partial-uuid matched several rows (carries `candidates`). | 2 |
| `unsupported` | No available write vector supports the operation (`detail.considered`). | 6 |
| `environment` | Database not found, Things not installed, or a permission problem. | 7 |
| `unexpected` | An internal error (a bug) — stop and report. | 1 |
| `verify-failed:<reason>` | A single mutation executed but the read-back check failed. `<reason>` ∈ `timeout | mismatch | silent-noop`. | 3 |
| `blocked:<suffix>` | Refused before dispatch — a hazard id (above) or a reason (`disruption-tier`, `lock`, `scope`, `clock`, `environment`, `drift`). `blocked:drift` is exit 5; all other `blocked:` are exit 4. | 4 / 5 |
| `bounce-aborted` | A reorder bounce aborted part-way (`detail.placed`/`remaining`/`cause`). | 3 |
| `verify-failed` | A multi-leg move/reorder failed mid-way (`detail.failed`/`completed`). | 3 |

A consumer that does not recognize a specific suffix routes on the prefix (`blocked:` / `verify-failed:`) and the exit code.

## A failure is never a license to bypass the CLI

Whatever the error, do not fall back to hand-built `things:///` URLs, AppleScript, or Shortcuts calls — those bypass the validation, verification, and undo/audit layers this tool exists to provide, and several raw shapes crash the app or fail silently. Refusals that support an override name their acknowledgment flag in the message; that flag system is the only sanctioned escape hatch. Anything else the CLI cannot do is a reportable finding (see the main skill document), not an invitation to improvise.
