---
name: atlassian-mcp-shim
description: Translation shim - the Atlassian MCP server is removed; this skill maps every mcp__atlassian__* tool call to its acli / jira-api / confluence-api equivalent. Load IMMEDIATELY whenever any skill, agent, or instruction references mcp__atlassian__ tools or "Atlassian MCP" (e.g. bstock-common jira-create-stories, jira-create-epics, jira-story-pointer, jira-epic-sizer, eaat-1-epic-breakdown), or when a workflow says to STOP because Atlassian MCP is unavailable - do not stop, use these equivalents instead.
---

# Atlassian MCP Shim

The Atlassian MCP server was removed **by design** (2026-07). Everything it did is now covered by `acli` plus two thin REST wrappers. When an instruction tells you to call `mcp__atlassian__X`, or to stop because Atlassian MCP is unavailable, **do not stop** — run the equivalent below.

## The three tools

| Tool | What it is | Use for |
|---|---|---|
| `acli jira …` / `acli confluence …` | Atlassian's official CLI, OAuth session | Almost all Jira reads/writes; Confluence page *reads* |
| `jira-api METHOD PATH` | authenticated curl wrapper (steals acli's OAuth token) | Anything acli can't do — see the edges below |
| `confluence-api METHOD PATH` | authenticated curl wrapper (personal API token) | All Confluence search/write |

Both wrappers live in `~/.claude/skills/bstock-engineering/scripts/` and are on PATH.

## General notes

- **Always pass `--json`** to acli. The default table output is unparseable. Write `--json` long-form in every command and doc — the short flags are inconsistent (on `workitem search`, **`-j` means `--jql`**, not `--json`).
- **`cloudId` is static**: `8fd1c100-2018-43ac-bdc1-ca69369799c3`. Any MCP tool signature that took a `cloudId` param — just drop it.
- **`contentFormat` / `responseContentFormat` have no equivalent.** acli comment and description bodies are either plain text or raw ADF (auto-detected). The MCP-era lore about omitting `contentFormat` is obsolete — ignore it.
- **ADF**: `acli … --description` / `--body` accept plain text *or* a full ADF doc. `--from-json` create payloads require ADF for `description`. Via `jira-api`, `/rest/api/3/…` is ADF and `/rest/api/2/…` is wiki markup (v2 converts wiki markup server-side — that's how `jira-attach` embeds media).
- **Liveness probe**: `acli jira auth status` (exit 0 + "✓ Authenticated"). If it fails, run `acli auth login` (browser flow) — prompt Mike, don't try to script it.
- **Always limit fields.** Unbounded issue reads are enormous. `workitem view` defaults to `key,issuetype,summary,status,assignee,description`; pass `--fields` explicitly.

## Jira

### 1. `getJiraIssue`

```bash
acli jira workitem view FP-2253 --fields "summary,status,assignee,customfield_10049" --json
```

`--fields` here is **unrestricted** — any field including `customfield_*`, plus `*all`, `*navigable`, and `-field` exclusions. **One key per call** (no comma lists). Always pass `--fields`; the default set includes the full description.

### 2. `searchJiraIssuesUsingJql`

If your fields are a subset of the acli allowlist — `key, issuetype, summary, status, assignee, priority, reporter, creator, labels, description` — use acli:

```bash
acli jira workitem search --jql "project = FP AND statusCategory != Done" \
  --fields "key,summary,status,assignee" --limit 50 --json
# also: --count (just the number), --paginate (fetch all pages), --csv
```

For **any other field** (`updated`, `created`, `parent`, `customfield_*`) acli rejects it. Use `jira-api` against the JQL search endpoint (verified 2026-07-28):

```bash
jira-api POST '/rest/api/3/search/jql' <<'EOF'
{"jql":"assignee = currentUser() AND statusCategory != Done",
 "fields":["summary","status","updated","customfield_10013"],
 "maxResults":50}
EOF
```

- The old `GET /rest/api/3/search` is **410 Gone** ("The requested API has been removed"). Only `/search/jql` works.
- **Pagination is token-based**, not `startAt`. The response has `nextPageToken` and `isLast`; `total` is always `null`. To page, re-POST with `"nextPageToken":"<token>"` until `isLast` is true.

### 3. `createJiraIssue`

```bash
# simple case
acli jira workitem create --project FP --type Story --summary "…" \
  --description "plain text or ADF" --assignee '@me' --label "a,b" --json

# full case (custom fields, ADF description) — start from the template:
acli jira workitem create --generate-json > /tmp/wi.json   # prints to stdout, safe
acli jira workitem create --from-json /tmp/wi.json --json
```

`--from-json` schema: `projectKey`, `type`, `summary`, `description` (**must be ADF**: `{"type":"doc","version":1,"content":[…]}`), `assignee`, `reporter`, `labels[]`, `parentIssueId` (sub-tasks only), and `additionalAttributes` — an object of arbitrary field ids, which is **the only way to set custom fields at create time**:

```json
"additionalAttributes": { "customfield_10049": 5, "customfield_10013": "FP-2200" }
```

### 4. `editJiraIssue`

Standard fields via acli:

```bash
acli jira workitem edit --key FP-2253 --summary "…" --description "…" \
  --assignee "user@bstock.com" --labels "a,b" --remove-labels "c" --type Task --yes --json
# also targets a set: --jql "…" or --filter 10001; --key accepts "KEY-1,KEY-2"
```

**`edit` cannot set custom fields** — its `--from-json` schema has no `additionalAttributes` (verified). For story points, sprint, epic link, or any `customfield_*`:

```bash
echo '{"fields":{"customfield_10049":5}}' | jira-api PUT '/rest/api/3/issue/FP-2253'
```

(Returns HTTP 204 with an empty body on success.) Known ids: Story Points `customfield_10049`, Sprint `customfield_10018`, Epic Link `customfield_10013`.

### 5. `lookupJiraAccountId`

```bash
jira-api GET '/rest/api/3/user/search?query=greiling' | jq -r '.[] | "\(.accountId)  \(.displayName)  \(.emailAddress)"'
```

Accepts a name fragment or an email. acli has no user-lookup command. Mike: `712020:102e13ca-76c4-4a0c-89e1-c9fc45369c5d`.

### 6. `createIssueLink`

```bash
acli jira workitem link create --out FP-123 --in FP-456 --type Blocks --yes
# bulk: --from-json links.json  (array of {outwardIssue, inwardIssue, type})
#       --from-csv links.csv    (out,in,type; first row ignored as header)
acli jira workitem link create --generate-json   # example structure, prints to stdout
```

**Direction semantics are the same as MCP's**: `--out` is the outward issue, `--in` the inward. `--type` takes the **outward description** ("Blocks", "Relates", "Splits to"), so `--out A --in B --type Blocks` reads "A blocks B". Getting these backwards silently produces the inverse relationship.

### 7. `getIssueLinkTypes`

```bash
acli jira workitem link type --json
```

(Also: `acli jira workitem link list --key KEY` to see an issue's existing links, `link delete` to remove one.)

### 8. `getVisibleJiraProjects`

```bash
acli jira project list --json            # add --limit N
acli jira project view --key FP --json
```

This tool also doubled as the **MCP liveness probe** in several skills. The replacement probe is `acli jira auth status` — cheaper and unambiguous.

### 9. `getJiraProjectIssueTypesMetadata`

```bash
acli jira project view --key FP --json | jq '.issueTypes[] | {id, name}'
```

FP as of 2026-07-28: Task `10006`, Sub-task `10007`, Story `10010`, Bug `10027`, Epic `10000`.

### 10. `getJiraIssueTypeMetaWithFields`

Both createmeta forms work (verified):

```bash
# issue types for a project
jira-api GET '/rest/api/3/issue/createmeta/FP/issuetypes' | jq '.issueTypes[] | {id, name}'
# fields for one issue type  (note: response key is .fields, paginated with .total)
jira-api GET '/rest/api/3/issue/createmeta/FP/issuetypes/10010' \
  | jq '.fields[] | {fieldId, name, required}'
# legacy one-shot form also still works
jira-api GET '/rest/api/3/issue/createmeta?projectKeys=FP&expand=projects.issuetypes.fields'
```

### 11. `getAccessibleAtlassianResources`

Unnecessary. Cloud ID is static: `8fd1c100-2018-43ac-bdc1-ca69369799c3` (site `bstock.atlassian.net`).

### 12. `addCommentToJiraIssue`

```bash
acli jira workitem comment create --key FP-2253 --body "text or ADF" --json
acli jira workitem comment create --key FP-2253 --body-file ./comment.txt --json
# --jql / --filter to comment on a set; --edit-last to amend your own last comment
```

The MCP-era "omit `contentFormat` or it breaks" lore is **obsolete** — there is no such parameter. Bodies are plain text or ADF. For threaded replies or media embeds use `jira-attach --comment … --reply-to ID` (see §20).

### 13. `transitionJiraIssue` / `getTransitionsForJiraIssue`

```bash
acli jira workitem transition --key FP-2253 --status "In Progress" --yes --json
# list what's available first (acli has no transition-listing command):
jira-api GET '/rest/api/3/issue/FP-2253/transitions' | jq '.transitions[] | {id, name, to:.to.name}'
```

acli takes the **target status name**, not a transition id.

### 14. `getJiraIssueRemoteIssueLinks`

```bash
jira-api GET '/rest/api/3/issue/FP-2253/remotelink'
```

### 15. `atlassianUserInfo`

```bash
jira-api GET '/rest/api/3/myself'
```

### 16. `addWorklogToJiraIssue`

```bash
echo '{"timeSpent":"2h","comment":"…"}' | jira-api POST '/rest/api/3/issue/FP-2253/worklog'
```

Unused at B-Stock (no time tracking).

### 17. Attachments

No MCP tool ever existed. Use `jira-attach` (uploads + embeds media in comments/descriptions; see `bstock-engineering/references/jira-attachments.md`) and `acli jira workitem attachment list --key KEY` / `attachment delete --id ID`.

### 18. `search` / `fetch` (Rovo)

No equivalent — Rovo natural-language search is not exposed by acli. Use structured queries instead: JQL via `workitem search` for Jira, CQL via `confluence-api` for Confluence.

## Confluence

**Reads work over acli's OAuth session. Everything else needs a personal API token.**

acli's OAuth grant carries only classic scopes: Confluence v2 rejects it, and the classic v1 content endpoints are 410-gone through the OAuth gateway. So `confluence-api` uses basic auth with a personal Atlassian API token from the keychain. **Mike has not minted this token yet** — every `confluence-api` call below will exit 1 with setup instructions until he does:

1. Mint at <https://id.atlassian.com/manage-profile/security/api-tokens>
2. `security add-generic-password -s atlassian-api-token -a mike.greiling@bstock.com -w '<token>'`

### 19. `getConfluencePage`

```bash
acli confluence page view --id 2345959440 --body-format storage --json
# --body-format: storage | atlas_doc_format | view
```

Verified working with the OAuth session. **Numeric page ID only** — take it from the page URL (`…/spaces/EN/pages/2345959440/Title`). acli has no page search, so there is no title→id lookup without `confluence-api` CQL.

Fallback (needs the API token): `confluence-api GET '/api/v2/pages/2345959440?body-format=storage'`

### 20. Confluence search & write family

All `confluence-api`, all requiring the API token:

| MCP tool | Replacement |
|---|---|
| `searchConfluenceUsingCql` | `confluence-api GET '/rest/api/content/search?cql=<urlencoded>&limit=25'` |
| `getConfluenceSpaces` | `confluence-api GET '/api/v2/spaces?limit=50'` |
| `getPagesInConfluenceSpace` | `confluence-api GET '/api/v2/spaces/<spaceId>/pages?limit=50'` |
| `getConfluencePageDescendants` | `confluence-api GET '/api/v2/pages/<id>/descendants?limit=50'` |
| `createConfluencePage` | `confluence-api POST '/api/v2/pages'` — body `{"spaceId":"…","status":"current","title":"…","parentId":"…","body":{"representation":"storage","value":"<p>…</p>"}}` |
| `updateConfluencePage` | `confluence-api PUT '/api/v2/pages/<id>'` — see version note below |
| `getConfluencePageFooterComments` | `confluence-api GET '/api/v2/pages/<id>/footer-comments'` |
| `getConfluencePageInlineComments` | `confluence-api GET '/api/v2/pages/<id>/inline-comments'` |
| `createConfluenceFooterComment` | `confluence-api POST '/api/v2/footer-comments'` — `{"pageId":"…","body":{"representation":"storage","value":"…"}}` |
| `createConfluenceInlineComment` | `confluence-api POST '/api/v2/inline-comments'` — same plus `inlineCommentProperties` |
| `getConfluenceCommentChildren` | `confluence-api GET '/api/v2/footer-comments/<id>/children'` |

**Update requires an incremented version** — read, bump, write:

```bash
v=$(confluence-api GET '/api/v2/pages/12345' | jq '.version.number')
jq -n --argjson v "$((v + 1))" --arg t "Title" --arg b "<p>new body</p>" \
  '{id:"12345", status:"current", title:$t, version:{number:$v},
    body:{representation:"storage", value:$b}}' \
  | confluence-api PUT '/api/v2/pages/12345'
```

Omitting or reusing the version number returns 409.
