---
name: record-idea
description: Quick-capture an idea into the Things inbox using the `things` CLI. Use whenever Mike says "record an idea", "capture this idea", "add an idea", "note this idea down", "save this idea", or describes a thought, product concept, improvement, or plan he wants stashed in Things for later processing — even if it comes up mid-conversation about something else. Not for ordinary actionable to-dos ("remind me to X", "add a task to buy Y") unless he explicitly frames it as an idea.
---

# Record an Idea

Capture an idea into the Things inbox as a single to-do, for later GTD-style processing in Things. Speed and fidelity are the point: capture everything Mike said without making him repeat it, and don't over-organize — triage happens later, in Things, not here.

## Workflow

1. **Title.** Summarize the idea into a concise, descriptive title (roughly 5–12 words), prefixed with `idea: `. It should be recognizable in a long inbox list without opening the item.

2. **Notes.** The notes field renders markdown and can be multi-line. Write the full context of the idea:
   - Everything Mike stated — details, motivation, links, names, constraints. Clean up dictation artifacts, but don't compress away substance.
   - If the idea emerged from the current conversation, include the relevant context (what was being worked on, files/tools involved, the observation that sparked it).
   - Organize with plain markdown (short paragraphs, lists). No headers needed for short ideas.

3. **Candidate projects.** Check whether the idea plausibly relates to existing projects (`things projects`; `things areas` if helpful). If any match, append to the end of the notes:

   ```
   ---
   Candidate projects:
   - Project Name A
   - Project Name B
   ```

   List them by name only. This is a hint for later triage — **never** assign the to-do to a project or area, and never schedule it. The item must land in the Inbox and stay there until Mike processes it.

4. **Create it.** Use a heredoc for the notes so quotes, backticks, and newlines survive the shell:

   ```sh
   things todo add "idea: <title>" --notes "$(cat <<'EOF'
   <markdown notes>
   EOF
   )"
   ```

   No `--project`, `--area`, `--when`, `--deadline`, or `--tags` — inbox only, unscheduled, untagged.

5. **Confirm.** Reply with the final title and a one-line recap of what was captured. Offer `things open <uuid>` only if Mike seems to want to look at it; normally quick capture should end silently-fast.

## Example

Mike: "Record an idea: what if the libby tool could also fetch cover art from OpenLibrary when the export is missing it"

```sh
things todo add "idea: libby2m4b — fetch missing cover art from OpenLibrary" --notes "$(cat <<'EOF'
When a LibbyRip export folder lacks embedded cover art, libby2m4b could query the OpenLibrary covers API (by ISBN or title/author) and embed the result in the .m4b automatically.

Came up while discussing the libby2m4b CLI.

---
Candidate projects:
- libby2m4b
EOF
)"
```
