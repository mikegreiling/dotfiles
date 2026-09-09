---
name: launchdarkly-cli
description: Read and manage B-Stock's LaunchDarkly feature flags with the official `ldcli` CLI — look up a flag's on/off state and targeting per environment, list flags by maintainer/tag/recency, check evaluation status, read a flag's audit history, and toggle or patch flags on Mike's behalf. Use whenever a task mentions LaunchDarkly, LD, a feature flag, "flag status", "is X enabled in prod/dev/qa", "turn on/off the flag", or flag hygiene/retirement.
---

# LaunchDarkly via `ldcli`

`ldcli` (Homebrew, `launchdarkly/homebrew-tap/ldcli`, v3.11.0 as of 2026-09-09) is the official LaunchDarkly CLI. Its resource commands mirror the REST API one-to-one, so anything in <https://launchdarkly.com/docs/api> maps to `ldcli <resource> <verb> --flag ...`. Output is JSON automatically when stdout is not a TTY (i.e. always, from an agent) — pipe into `jq`, never parse plaintext.

## Stable B-Stock facts (verified 2026-09-09)

| Fact | Value |
|------|-------|
| Project key | `default` (display name "B-Stock Solutions") — the **only** project, so always pass `--project default` |
| Environment keys | `development`, `qa`, `staging`, `production`, `test` ("Local (Test)" — local dev SDK env) |
| Env ↔ hostname | `development` → bstock-dev.com · `qa` → bstock-qa.com · `staging` → bstock-staging.com · `production` → bstock.com |
| Flag key convention | kebab-case (enforced by project `namingConvention`) |
| Flag count | ~228 |
| Auth | personal token created by `ldcli login` (token name "LDCLI access token for bstock-mbp"), stored in `~/.config/ldcli/config.yml` |
| Mike's member ID | `69f8f08d9afc500cc8fc1ff9` |
| Alvaro Ferreira member ID | `68128f8d797a680a434ee4d0` (admin; maintains most foundation-pod flags) |

Liveness probe: `ldcli whoami` (JSON: `memberId`, `tokenName`). If it fails, ask Mike to run `ldcli login` — don't script it.

**Never run `ldcli config --list`** — it prints the raw access token into the transcript. Nothing else needs the token; the CLI reads it from the config file.

## Read recipes

Flag payloads are large (every environment's full targeting config). Always narrow with `jq`, and use `--env <key>` on `flags get` when only one environment matters.

```bash
# Summary of one flag in every environment: on/off, fallthrough, rule/target counts, last change
ldcli flags get --project default --flag <key> | jq '{key,name,kind,temporary,tags,
  maintainer:._maintainer.email, creationDate:(.creationDate/1000|todate),
  envs:(.environments|to_entries|map({env:.key,on:.value.on,fallthrough:.value.fallthrough,
    offVariation:.value.offVariation,rules:(.value.rules|length),
    targets:((.value.targets|length)+(.value.contextTargets|length)),
    lastModified:(.value.lastModified/1000|todate)}))}'

# Single environment, full targeting detail (rules, clauses, targets)
ldcli flags get --project default --flag <key> --env production | jq '.environments.production'

# Evaluation status per env: "new" (never evaluated), "active", "inactive" (>7d idle), "launched" (100% one variation)
ldcli flags get-status-across-environments --project default --flag <key> \
  | jq '.environments|to_entries|map({env:.key,status:.value.name,lastRequested:.value.lastRequested})'

# Newest flags maintained by someone (maintainer ≠ creator — see audit log below)
ldcli flags list --project default --filter "maintainerId:<memberId>" --sort "-creationDate" \
  --limit 10 --summary true | jq -r '.items[]|[.key,.name,(.creationDate/1000|todate),(.temporary|tostring)]|@tsv'

# Other useful --filter fields: query:<substring of key/name>, tags:<tag>, status:<active|inactive|new|launched>
# (needs --env), type:temporary|permanent, hasExperiment:true. Combine with commas.
ldcli flags list --project default --filter "query:mfa" --summary true | jq -r '.items[].key'

# Who is who
ldcli members list | jq -r '.items[]|[._id,.email,.role]|@tsv' | grep -i <name>
ldcli environments list --project default | jq -r '.items[]|[.key,.name]|@tsv'
```

`--summary true` on `list` omits per-env targets/rules and keeps the response small; drop it only when you need targeting for many flags at once.

`environments[].lastModified` is when the config was last edited; `get-status…lastRequested` is when an SDK last *evaluated* the flag — different questions.

## Audit history (creator, who flipped what, when)

`ldcli` has **no audit-log command**. The bundled `scripts/ld-api` (a thin `curl` wrapper that reuses the CLI's stored token) covers this one gap; use it only for endpoints `ldcli` lacks.

```bash
# Every change to one flag, newest first (creation, toggles, rule edits) — who + when
scripts/ld-api "auditlog?spec=proj/default:env/*:flag/<key>&limit=20" \
  | jq -r '.items[]|[(.date/1000|todate),.member.email,.title]|@tsv'

# Restrict to one environment's toggles
scripts/ld-api "auditlog?spec=proj/default:env/production:flag/<key>&limit=20"
```

`ld-api METHOD? PATH [curl args…]` — PATH is relative to `/api/v2/`; METHOD defaults to GET. Read-only use only; all writes go through `ldcli`.

## Write recipes — governance first

Flag writes are visible to everyone in LaunchDarkly and are attributed to Mike's token. Before **any** write:

1. **Development (`development`, `test`)**: fine to do on Mike's instruction; still say what you're about to change.
2. **`qa` / `staging`**: confirm the exact flag + environment with Mike unless he named both explicitly.
3. **`production`**: never flip on your own judgment. Mike must explicitly request the prod change, and for buyer-facing flags the product go-ahead comes from Jeremy Walton (Director, Buyer Product); the flag's maintainer should know too. When in doubt, ask in `#feature-flags-launchdarkly`. Always `--dry-run` first and report the before-state.
4. Flag hygiene / retirement (archiving, removing temporary flags): Mary Gutierrez gates buyer-pod flag retirement; Alexandra Ash owns the buyer-pod flag process. Foundation-pod flags: Alvaro. Don't archive without a blessing.

```bash
# Validate without persisting (returns the flag as it would look)
ldcli flags toggle-on  --project default --environment development --flag <key> --dry-run
# Real toggle
ldcli flags toggle-on  --project default --environment development --flag <key>
ldcli flags toggle-off --project default --environment development --flag <key>

# Anything beyond on/off = semantic patch via `flags update --data`
# (instructions reference: ldcli flags update --help, or https://launchdarkly.com/docs/api#updates-using-semantic-patch)
ldcli flags update --project default --flag <key> --data '{
  "comment": "FP-1234: enable for internal testers",
  "environmentKey": "development",
  "instructions": [
    {"kind": "addTargets", "contextKind": "user", "variationId": "<variationId>", "values": ["user-key-1"]}
  ]
}'
# Common instruction kinds: turnFlagOn, turnFlagOff, addTargets, removeTargets, addRule, removeRule,
# updateFallthroughVariationOrRollout, updateOffVariation, addTags/removeTags (no environmentKey), updateDescription.
# Variation IDs come from `flags get … | jq '.variations[]|{name,_id}'`.
```

After a write, re-run the summary `jq` above and report the after-state. Put a Jira key in `comment` when one exists — it shows in the LD audit log.

## Gotchas

- `--limit`/`--offset` are strings on `list`; default page is 20 of ~228 flags — paginate or filter, never assume the first page is everything.
- `flags get` without `--env` returns **all** environments (~5 configs plus rules); a flag with many rules can be tens of KB. Filter with `jq` before it reaches the transcript.
- `--fields` (global flag) trims *top-level* keys only; it can't reach into `environments`.
- Maintainer is an editable field, not provenance. "Who added this flag" = the `created the flag` audit entry, not `_maintainer`.
- `temporary: true` is the default for new flags and drives LD's "ready to remove" nagging — irrelevant to runtime behavior.
- A flag showing `status: new` in an env has never been evaluated there (SDK never asked) — usually means the code isn't deployed to that env yet, not that the flag is off.
