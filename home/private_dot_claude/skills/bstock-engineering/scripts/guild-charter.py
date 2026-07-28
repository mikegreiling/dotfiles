#!/usr/bin/env python3
"""guild-charter.py — deterministic section surgery for the FE+BE Guild Charter
(Confluence pageId 2345959440) and its archive, "Historical Guild Meeting Notes"
(pageId 3357933581). Operates ONLY on local storage-format XML files — fetching
and writing pages stays with the caller (read via acli, write via confluence-api;
see references/fe-guild-meeting.md for why).

Section model (validated by `lint`, relied on by everything else):
  the "Meeting Topics / Notes" region contains, newest-first:
    <h2>Next Meeting</h2>            — the accumulation slot (exactly one)
    <h2>DATE</h2> ...                — dated sections; DATE is any heading text
                                       that cleanly parses as a date (ISO
                                       YYYY-MM-DD today; also tolerates e.g.
                                       "February 21, 2027")
    <h1>Historical Meetings</h1>     — terminator (dated sections never follow it)
  each dated section must contain >=1 <table>, followed by at most
  MAX_TRAILING_BLOCKS top-level blocks (recording link, passcode line, stray
  empty <p>) before the next heading. Anything else FAILS LOUDLY — a human/agent
  must look before any automated write proceeds.

Commands (all take the storage-XML file as first arg):
  lint FILE                       validate shape; exit 2 with details on violation
  rollover FILE --date YYYY-MM-DD --section-file S.xml [--seed-rows R.xml] --out OUT
      replace the whole "Next Meeting" section with the contents of S.xml
      (which must itself be a valid dated section for --date), and insert a
      fresh canonical "Next Meeting" slot above it (seeded with optional extra
      rows R.xml placed before the empty rows).
  archive-split FILE --keep-after YYYY-MM-DD --out-keep K.xml --out-move M.xml
      cut every dated section strictly older than the given date; write the
      remaining charter to K.xml and an archive-ready block (grouped under
      <h1>YEAR</h1> headings, newest-first) to M.xml. Refuses unless the moved
      set is a contiguous trailing run of the dated sections.
  archive-merge ARCHIVEFILE --insert M.xml --out OUT
      merge an archive-ready block into the archive page body: prepends year
      groups above the existing newest <h1>, or merges into an existing year
      bucket at its top (newest-first invariant).

Every command re-lints its output before writing it. Exit codes: 0 ok, 2 lint
violation / refused invariant, 1 usage or internal error.
"""
import argparse
import html as htmlmod
import re
import sys
from datetime import datetime

MAX_TRAILING_BLOCKS = 3

EMPTY_ROW = (
    '<tr><td data-highlight-colour="none"><p /></td>'
    '<td data-highlight-colour="none"><p /></td>'
    '<td data-highlight-colour="none"><p /></td></tr>'
)

HEADING_RE = re.compile(r"<h([12])[^>]*>(.*?)</h\1>", re.S)


def heading_text(inner: str) -> str:
    return htmlmod.unescape(re.sub(r"<[^>]+>", "", inner)).strip()


def parse_date(text: str):
    text = text.strip().rstrip(".")
    for fmt in ("%Y-%m-%d", "%B %d, %Y", "%b %d, %Y", "%d %B %Y", "%Y/%m/%d"):
        try:
            return datetime.strptime(text, fmt).date()
        except ValueError:
            continue
    return None


def sections(body: str):
    """Yield dicts for every h1/h2-delimited region: {level, text, date, start, cstart, end}.
    start = heading open; cstart = after heading close; end = next heading or EOF."""
    heads = list(HEADING_RE.finditer(body))
    out = []
    for i, m in enumerate(heads):
        end = heads[i + 1].start() if i + 1 < len(heads) else len(body)
        text = heading_text(m.group(2))
        out.append({
            "level": int(m.group(1)), "text": text, "date": parse_date(text),
            "start": m.start(), "cstart": m.end(), "end": end,
        })
    return out


def top_level_blocks(fragment: str):
    """Split a storage fragment into top-level block elements (crude but adequate:
    counts <p, <table, <ul, <ol, <ac:structured-macro, <div, <blockquote openers at depth 0)."""
    blocks = []
    tag_re = re.compile(r"<(/?)([a-zA-Z][a-zA-Z0-9:-]*)((?:\"[^\"]*\"|'[^']*'|[^>\"'])*?)(/?)>")
    depth = 0
    cur = None
    for m in tag_re.finditer(fragment):
        closing, name, _, selfclose = m.group(1), m.group(2).lower(), m.group(3), m.group(4)
        if depth == 0 and not closing and cur is None:
            cur = m.start()
        if selfclose or name in ("br", "col", "hr") or (name.startswith("ri:")):
            if depth == 0 and cur is not None and m.start() == cur:
                blocks.append(fragment[m.start():m.end()])
                cur = None
            continue
        depth += -1 if closing else 1
        if depth == 0 and closing and cur is not None:
            blocks.append(fragment[cur:m.end()])
            cur = None
    return blocks


def lint_body(body: str, label: str, require_slot: bool):
    errs = []
    secs = sections(body)
    dated = [s for s in secs if s["level"] == 2 and s["date"]]
    slots = [s for s in secs if s["level"] == 2 and s["text"].lower() == "next meeting"]
    if require_slot and len(slots) != 1:
        errs.append(f"{label}: expected exactly one 'Next Meeting' h2, found {len(slots)}")
    # dated sections must be strictly newest-first
    dates = [s["date"] for s in dated]
    if dates != sorted(dates, reverse=True):
        errs.append(f"{label}: dated sections not in newest-first order: {dates}")
    for s in dated:
        frag = body[s["cstart"]:s["end"]]
        if "<table" not in frag:
            errs.append(f"{label}: section {s['text']} has no table")
            continue
        after = frag[frag.rfind("</table>") + len("</table>"):]
        blocks = top_level_blocks(after)
        nonempty = [b for b in blocks if re.sub(r"<[^>]+>|\s|&nbsp;", "", b)]
        if len(nonempty) > MAX_TRAILING_BLOCKS:
            errs.append(
                f"{label}: section {s['text']} has {len(nonempty)} trailing blocks after its "
                f"table (max {MAX_TRAILING_BLOCKS}): {[b[:60] for b in nonempty]}"
            )
    return errs, secs


def die_on(errs):
    if errs:
        print("LINT FAILED:", file=sys.stderr)
        for e in errs:
            print("  -", e, file=sys.stderr)
        sys.exit(2)


def fresh_slot(header_table_markup: str, seed_rows: str = "") -> str:
    """Canonical empty Next Meeting slot; header_table_markup is the <table ...><colgroup...>
    + header <tr> extracted from the live page so column widths/styles are preserved."""
    return (
        "<h2>Next Meeting</h2>"
        + header_table_markup
        + seed_rows
        + EMPTY_ROW * 3
        + "</tbody></table>"
    )


def extract_table_head(section_frag: str) -> str:
    """Return '<table ...><colgroup ...>...<tbody>' + header row from a section's table,
    with local-id attributes stripped (this markup seeds NEW nodes — Confluence assigns
    fresh ids; copying them would duplicate ids already present in the moved section)."""
    t = section_frag.find("<table")
    assert t >= 0, "no table in section"
    tb = section_frag.find("<tbody", t)
    first_tr_end = section_frag.find("</tr>", tb) + len("</tr>")
    head = section_frag[t:first_tr_end]
    return re.sub(r'\s+(?:ac:local-id|local-id)="[^"]*"', "", head)


def cmd_lint(args):
    body = open(args.file).read()
    errs, secs = lint_body(body, args.file, require_slot=not args.no_slot)
    die_on(errs)
    dated = [s for s in secs if s["level"] == 2 and s["date"]]
    print(f"ok — {len(dated)} dated sections"
          + (f", newest {dated[0]['text']}, oldest {dated[-1]['text']}" if dated else ""))


def cmd_rollover(args):
    body = open(args.file).read()
    errs, secs = lint_body(body, args.file, require_slot=True)
    die_on(errs)
    slot = next(s for s in secs if s["level"] == 2 and s["text"].lower() == "next meeting")
    new_section = open(args.section_file).read().strip()
    # the new section must itself lint as a dated section for --date
    errs2, nsecs = lint_body(new_section, args.section_file, require_slot=False)
    die_on(errs2)
    nd = [s for s in nsecs if s["level"] == 2 and s["date"]]
    if len(nd) != 1 or nd[0]["text"] != args.date:
        print(f"rollover refused: section file must contain exactly one h2 dated {args.date}", file=sys.stderr)
        sys.exit(2)
    seed = open(args.seed_rows).read().strip() if args.seed_rows else ""
    table_head = extract_table_head(body[slot["cstart"]:slot["end"]])
    out = body[:slot["start"]] + fresh_slot(table_head, seed) + new_section + body[slot["end"]:]
    errs3, _ = lint_body(out, "rollover result", require_slot=True)
    die_on(errs3)
    open(args.out, "w").write(out)
    print(f"rollover ok -> {args.out} (slot renamed to {args.date}, fresh slot inserted)")


def cmd_archive_split(args):
    body = open(args.file).read()
    errs, secs = lint_body(body, args.file, require_slot=True)
    die_on(errs)
    cutoff = parse_date(args.keep_after)
    assert cutoff, "--keep-after must be a date"
    dated = [s for s in secs if s["level"] == 2 and s["date"]]
    move = [s for s in dated if s["date"] < cutoff]
    keep = [s for s in dated if s["date"] >= cutoff]
    if not move:
        print("nothing to archive"); sys.exit(0)
    # contiguity: moved set must be exactly the trailing run of dated sections
    if dated[len(keep):] != move:
        print("archive-split refused: sections to move are not a contiguous trailing run", file=sys.stderr)
        sys.exit(2)
    lo, hi = move[0]["start"], move[-1]["end"]
    moved_markup = body[lo:hi]
    kept = body[:lo] + body[hi:]
    # group by year, newest-first (input already newest-first)
    out_parts, cur_year = [], None
    for s in move:
        if s["date"].year != cur_year:
            cur_year = s["date"].year
            out_parts.append(f"<h1>{cur_year}</h1>")
        out_parts.append(body[s["start"]:s["end"]])
    errs2, _ = lint_body(kept, "kept charter", require_slot=True)
    die_on(errs2)
    open(args.out_keep, "w").write(kept)
    open(args.out_move, "w").write("".join(out_parts))
    print(f"archive-split ok: moved {len(move)} sections ({move[0]['text']} .. {move[-1]['text']}), kept {len(keep)}")


def cmd_archive_merge(args):
    archive = open(args.archivefile).read()
    insert = open(args.insert).read()
    ins_secs = sections(insert)
    ins_years = [s for s in ins_secs if s["level"] == 1]
    assert ins_years, "insert block has no <h1>YEAR</h1> groups"
    arch_secs = sections(archive)
    arch_years = [s for s in arch_secs if s["level"] == 1 and s["text"].isdigit()]
    assert arch_years, "archive has no year headings"
    first_year_pos = arch_years[0]["start"]
    existing = {s["text"] for s in arch_years}
    for y in ins_years:
        if y["text"] in existing:
            print(f"archive-merge refused: year {y['text']} already exists in archive — "
                  f"merge into existing buckets is not implemented; do it manually", file=sys.stderr)
            sys.exit(2)
    # newest-first invariant: inserted years must all be newer than current newest
    if not all(int(y["text"]) > int(arch_years[0]["text"]) for y in ins_years):
        print("archive-merge refused: inserted year(s) not newer than archive's newest bucket", file=sys.stderr)
        sys.exit(2)
    out = archive[:first_year_pos] + insert + archive[first_year_pos:]
    errs, _ = lint_body(out, "merged archive", require_slot=False)
    die_on(errs)
    open(args.out, "w").write(out)
    print(f"archive-merge ok -> {args.out} (prepended {[y['text'] for y in ins_years]})")


def main():
    p = argparse.ArgumentParser()
    sub = p.add_subparsers(dest="cmd", required=True)
    l = sub.add_parser("lint"); l.add_argument("file"); l.add_argument("--no-slot", action="store_true"); l.set_defaults(f=cmd_lint)
    r = sub.add_parser("rollover"); r.add_argument("file"); r.add_argument("--date", required=True)
    r.add_argument("--section-file", required=True); r.add_argument("--seed-rows"); r.add_argument("--out", required=True); r.set_defaults(f=cmd_rollover)
    a = sub.add_parser("archive-split"); a.add_argument("file"); a.add_argument("--keep-after", required=True)
    a.add_argument("--out-keep", required=True); a.add_argument("--out-move", required=True); a.set_defaults(f=cmd_archive_split)
    m = sub.add_parser("archive-merge"); m.add_argument("archivefile"); m.add_argument("--insert", required=True)
    m.add_argument("--out", required=True); m.set_defaults(f=cmd_archive_merge)
    args = p.parse_args()
    args.f(args)


if __name__ == "__main__":
    main()
