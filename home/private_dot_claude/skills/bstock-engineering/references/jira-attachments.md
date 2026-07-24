# Jira Attachments & Media Embeds

How to upload files to Jira issues and surface them in rich-text bodies (comments, threaded replies, descriptions). All findings verified empirically on FP-77, 2026-07-24.

## Capability Matrix

| Operation | MCP | acli | `scripts/jira-attach` / raw API |
|---|---|---|---|
| Upload attachment | ❌ no tool exists | ❌ (`attachment` has only `list`/`delete`) | ✅ v3 multipart POST |
| List / delete attachments | ❌ | ✅ `acli jira workitem attachment list --key KEY` / `delete --id ID` | ✅ |
| Embed media in a comment | ❌ markdown can't produce media nodes | ❌ | ✅ v2 wiki markup |
| Threaded reply (with embeds) | ❌ | ❌ | ✅ v2 `parentId` |
| Embed media in description | ❌ (markdown `![](file)` becomes a broken external-blob node) | ❌ (`-d` plain text stores markup literally) | ✅ v2 PUT, or lossless append via laundering |
| Append to description/comment | ❌ | ❌ | ✅ `--append-*` modes |

Both MCP (`contentFormat: "adf"`) and acli (`--description` ADF mode) *accept* raw ADF, but authoring a `media` node needs the attachment's **media services UUID**, which no attachment API returns — see [The media UUID problem](#the-media-uuid-problem).

## The `jira-attach` script

Canonical copy: `scripts/jira-attach` in this skill (on PATH via a `~/.local/bin/jira-attach` symlink; both chezmoi-tracked).

```
jira-attach ISSUE-KEY FILE...                                  # attach only
jira-attach --comment TEXT [--reply-to ID] ISSUE-KEY FILE...   # attach + new comment embedding the files
jira-attach --append-description TEXT ISSUE-KEY FILE...        # attach + lossless append to description
jira-attach --append-comment ID TEXT ISSUE-KEY FILE...         # attach + lossless append to an existing comment
```

- Images embed inline as thumbnails; other file types embed as attachment cards.
- `--reply-to COMMENT_ID` makes the comment a **threaded reply** (requires `--comment`).
- The three body modes are mutually exclusive; TEXT may itself contain wiki markup (it goes through Jira's converter).
- Zero-risk alternative ("policy option 1"): attach only, and write "see attached FILE" in prose via the normal MCP comment/edit tools — no body-rewrite risk at all.

## Auth: reusing acli's OAuth token

acli stores its OAuth credentials in the macOS **login keychain**, service `acli`, as a `go-keyring-base64:`-prefixed gzip blob:

```bash
security find-generic-password -s acli -w | sed 's/^go-keyring-base64://' | base64 -d | gunzip | jq -r .access_token
```

- Tokens are Bearer, ~1 h lifetime. acli refreshes **and re-persists** its token on any authenticated command, so on a 401 the script runs a cheap `acli jira project list --limit 1` and re-reads the keychain.
- OAuth bearer tokens only work against the **`https://api.atlassian.com/ex/jira/{cloudId}/...`** gateway — never the `bstock.atlassian.net` vanity host (cloud ID: `8fd1c100-2018-43ac-bdc1-ca69369799c3`).
- Multipart uploads additionally need the `X-Atlassian-Token: no-check` header (XSRF-filter opt-out for non-browser clients).

## Mechanism notes

### Attachments belong to issues, not comments

Jira has no comment-level attachments. Files attach to the *issue*; comments and descriptions *embed* them by reference. "Attach a file to this comment" always means: upload to the issue, then embed.

### v2 wiki markup is the only filename→media conversion path

The **v2 API** (`POST/PUT /rest/api/2/issue/...`) accepts wiki markup in body fields and converts it server-side into real ADF media nodes, resolving attachments **by filename**:

- `!name.png|thumbnail!` → `mediaSingle` (inline image)
- `[^name.ext]` → `mediaGroup` (attachment card)

This is identical to a UI drag-and-drop. The v3 API does no such conversion, and neither MCP-markdown nor acli-plain-text input triggers it.

**Filename caveat**: resolution is by filename — a name colliding with an existing attachment on the issue may embed the wrong file. Use distinctive filenames.

### Threaded comments

`POST /rest/api/{2,3}/issue/{KEY}/comment` accepts `"parentId": "<comment id>"` to create a threaded reply. Verified: works on v2 (so replies can carry wiki-markup embeds), `parentId` is preserved through both v2 and v3 comment edits (PUT).

### The media UUID problem

An ADF `media` node references a media-services UUID (e.g. `306b712e-…`), which is a *different namespace* from the attachment ID and is **not returned by any attachment API**. You can only discover it by letting Jira resolve an embed (v2 conversion) and reading the ADF back. Hence:

### Lossless append via ADF laundering

To add embeds to an *existing* body without corrupting it (`--append-*` modes):

1. POST an **ephemeral v2 comment** containing the new text + wiki-markup embeds — Jira converts it to ADF.
2. GET the comment via **v3**; harvest its `body.content` node array (media UUIDs resolved, no hand-authored ADF).
3. DELETE the ephemeral comment.
4. GET the target (description or comment) via **v3** as raw ADF; append the harvested nodes to `content`; PUT back via v3.

The target body is never round-tripped through wiki markup, so nothing is lost (verified: original description restored byte-identical; appended nodes exact). Caveats:

- **Notifications**: watchers may receive a notification for the ephemeral comment before it's deleted.
- **Race**: read-modify-write with no version precondition — a concurrent edit of the same body in the window can be clobbered.

### Editing bodies safely (manual operations)

- v2 `PUT` **replaces the entire field**, and v2 `GET` returns existing rich content as *lossily converted* wiki markup — never read-modify-write through v2 on non-trivial bodies.
- Before any risky description/comment surgery, snapshot the **v3 ADF** (`?fields=description` / v3 comment GET) so you can restore losslessly:

```bash
curl -s -H "Authorization: Bearer $TOKEN" "$BASE/3/issue/KEY?fields=description" | jq '.fields.description' > backup.adf.json
jq -n --slurpfile d backup.adf.json '{fields: {description: $d[0]}}' | curl -s -X PUT -H "Authorization: Bearer $TOKEN" -H "Content-Type: application/json" -d @- "$BASE/3/issue/KEY"
```

- Deleting: comments via `DELETE /rest/api/2/issue/{KEY}/comment/{id}`; attachments via `acli jira workitem attachment delete --id ID`. Note Mike has **no issue-delete permission**, and deleting an attachment does not remove embeds pointing at it (they render as broken media).
