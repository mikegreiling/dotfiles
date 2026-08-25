# Contacts over CardDAV — why, and how

Mike consumes his Fastmail contacts primarily through **Apple Contacts** (iOS/macOS) over CardDAV. The Fastmail MCP contact *writers* produce vCards that Apple mangles, so all contact writes go through `scripts/carddav-contact`. Everything below was verified against raw vCards on 2026-08-25.

## Verified MCP failure modes

- `create_contact` takes `name` only as a flat string. Fastmail stores it as JSContact `name.full` with no components, so the vCard 3.0 CardDAV serves has `FN:Waldemar Dziubek` but an empty `N:;;;;`. Apple Contacts treats empty-`N` + `ORG` as a **company card**: it shows the org ("B-Stock") as the contact's name and ignores `FN` entirely.
- MCP-written `TEL` / `EMAIL` carry only a `PROP-ID=<hash>` parameter and no `TYPE=`, so Apple labels the phone field literally "PROP-ID". `ORG` is emitted under a hashed group prefix (`fec2c614085b502e.ORG;PROP-ID=…:B-Stock`).
- `update_contact` **with `name` set wipes `N` back to `;;;;`** — even on a card that was previously clean.
- `update_contact` *without* `name` (a notes/phones/emails delta) preserves an existing `N` and existing `TYPE=` params; it still re-serializes the card (adding `PROP-ID`s and the hashed `ORG` group), which Apple renders acceptably.
- `update_contact` with `notes: ""` leaves an empty `NOTE:` property on the card. Omit the field instead, or clear the note over CardDAV.
- A proper vCard 3.0 written over CardDAV fixes everything, and Fastmail stores and serves it back **verbatim**: `N:Dziubek;Waldemar;;;`, `FN`, `ORG:B-Stock`, `TEL;TYPE=CELL,VOICE:…`, `EMAIL;TYPE=INTERNET,HOME,PREF:…`, optional `NOTE:`. MCP `search_contacts` reads CardDAV-written cards fine.

## The four rules in detail

1. **Never use MCP `create_contact`.** Create contacts with `scripts/carddav-contact new`. There is no argument shape that makes `create_contact` emit a populated `N`, so a card it creates always needs a follow-up CardDAV repair — skip the round trip.
2. **Never pass `name` to MCP `update_contact`.** For a name change or any structural edit, round-trip through CardDAV: `carddav-contact get <name> > c.vcf` → edit the file → `carddav-contact put c.vcf`. `put` uses the UID inside the file to name the resource and sends `If-Match` with the current etag, so a concurrent change elsewhere fails loudly instead of clobbering.
3. **An emails / phones / notes delta via MCP `update_contact` is tolerable, but prefer CardDAV.** If you do use it: do not pass `name`, and do not pass `notes: ""`. Expect the card to come back re-serialized with `PROP-ID`s and a hashed `ORG` group; that form renders correctly in Apple Contacts, it is just noisy.
4. **MCP `search_contacts` remains the right tool for reads and lookups.** See the id-mapping note below.

## `search_contacts` ids vs CardDAV UIDs

`search_contacts` returns `id` values that are Fastmail contact ids (e.g. `D-Ork`). They are **not** the CardDAV UID, and they are not stable — do not persist them or pass them to `carddav-contact`. Map one to the other with `carddav-contact get <text>` (or `carddav-contact list`), which prints the UID for each matching card. The `name` field `search_contacts` returns is derived from the JSContact name components, so it can differ from the card's `FN`.

Fastmail contact ids *are* the right identifier for the MCP `_commit_delete_contact` path documented in SKILL.md; CardDAV UIDs are the right identifier for `carddav-contact get|delete`.

## Endpoint

```
https://carddav.fastmail.com/dav/addressbooks/user/<login-email>/Default/
```

Displayname "Personal"; serves vCard 3.0 and 4.0. The resource filename is `<uid>.vcf` — i.e. the vCard's own UID.

## `carddav-contact --help`

```
carddav-contact — manage Fastmail contacts over CardDAV (Apple-Contacts-safe vCards)

USAGE
  carddav-contact list
  carddav-contact get <text|uid>
  carddav-contact new --given G --family F [options]
  carddav-contact put <file.vcf>
  carddav-contact delete <uid>
  carddav-contact --help

COMMANDS
  list              Every card in the Default address book as: UID<TAB>FN<TAB>ORG
  get <text|uid>    Raw vCard(s) whose FN, ORG or EMAIL contains <text>
                    (case-insensitive), each preceded by a "# etag: ..." line.
                    A bare UID is fetched directly by GET.
  new               Build a clean vCard 3.0 and create it (HTTP 201), then
                    print the UID and re-read the stored card.
  put <file.vcf>    Upload a hand-written vCard. The UID inside the file names
                    the resource; an existing resource is updated with If-Match,
                    a new one is created with If-None-Match: *. Prints the
                    re-read card.
  delete <uid>      DELETE the card (If-Match). DESTRUCTIVE AND IRREVERSIBLE —
                    only run it after the user has explicitly confirmed that
                    specific contact should be deleted.

OPTIONS for `new`
  --given G            Given (first) name          [required]
  --family F           Family (last) name          [required]
  --fn "Display Name"  FN override                 [default: "G F"]
  --org ORG            Organization
  --email ADDR[:TYPE]  Repeatable. TYPE default HOME; first email also gets PREF.
                       Emits EMAIL;TYPE=INTERNET,<TYPE>[,PREF]
  --phone NUM[:TYPE]   Repeatable. TYPE default CELL.
                       Emits TEL;TYPE=<TYPE>,VOICE
  --note TEXT          NOTE property

CREDENTIALS
  Read from the login keychain item with service name `fastmail-carddav`:
    security add-generic-password -s fastmail-carddav -a <login-email> -w '<app-password>'
  The password must be a Fastmail *app password* with Contacts (CardDAV) access
  (Fastmail Settings -> Privacy & Security -> Integrations -> New app password).
  The mcporter OAuth token is scoped to the MCP server only and will 401 here.
  Override with env FASTMAIL_CARDDAV_USER / FASTMAIL_CARDDAV_PASS.
  See references/carddav-credentials.md for the re-mint runbook.

ENDPOINT
  https://carddav.fastmail.com/dav/addressbooks/user/<login-email>/Default/

EXAMPLES
  carddav-contact list
  carddav-contact get "Waldemar"
  carddav-contact new --given Jane --family Doe --org B-Stock \
      --email jane@example.com --phone 555-123-4567:CELL --note "Met at KubeCon"
  carddav-contact get 0d1c...-uuid > jane.vcf && $EDITOR jane.vcf && carddav-contact put jane.vcf
```

## If you hand-roll curl instead

Prefer the script. If you must go direct:

- `addressbook-query` REPORT needs `Depth: 1` and `Content-Type: application/xml; charset=utf-8`; request `<card:address-data content-type="text/vcard" version="3.0"/>` inside `<d:prop>` or you get vCard 4.0 back. Success is **HTTP 207**, and per-card failures live inside the multistatus body, not the status line.
- `PUT` with `Content-Type: text/vcard; charset=utf-8` plus either `If-None-Match: *` (create → 201) or `If-Match: "<etag>"` (update → 204). Without a conditional header you can silently overwrite a concurrent change. The etag comes from the `ETag` response header on a `GET`, or from `<d:getetag>` in a REPORT multistatus.
- `DELETE` likewise takes `If-Match: "<etag>"`.
- The vCard body must use **CRLF** line endings, and continuation lines are folded with a leading space/tab — unfold before parsing.
- Run curl from **bash, not zsh**: zsh does not word-split `${var:+-H "..."}`, so a conditionally-included header collapses into a single mangled argument. Build header arguments as an array (`cond=(-H "If-Match: $etag")`) and expand `"${cond[@]}"`.
- Keep the password out of the process table: write `user = "<user>:<pass>"` into a `chmod 600` curl config and pass `-K <file>` instead of `-u`.
