# The `fastmail-carddav` credential — provenance and re-mint runbook

## What it is

A **Fastmail app password**, scoped to **Contacts (CardDAV) only** — not mail, not calendar, not the JMAP API. It is the sole credential `scripts/carddav-contact` uses. Created **2026-08-25** by Mike in the Fastmail web UI: Settings → Privacy & Security → Integrations → New app password, access limited to Contacts (CardDAV).

It was stored by Mike running this in a **real terminal** (never through an agent, so the secret never entered a transcript):

```bash
security add-generic-password -s fastmail-carddav -a mike@greiling.me -w '<app-password>'
```

Fastmail app passwords do **not** expire on a schedule. They stop working only when revoked or deleted in that same Integrations screen.

## Where it lives

- macOS **login keychain**, generic password item
- service: `fastmail-carddav`
- account: `mike@greiling.me` (the Fastmail login email)

Keychain items do not migrate automatically to a new Mac unless iCloud Keychain or Migration Assistant carries the login keychain across. **Assume a new MacBook needs a re-mint** (or at least a re-add) before `carddav-contact` works.

## How the script reads it

```bash
security find-generic-password -s fastmail-carddav -w        # password
security find-generic-password -s fastmail-carddav           # account is the "acct" blob
```

`FASTMAIL_CARDDAV_USER` / `FASTMAIL_CARDDAV_PASS` override the keychain for a one-off run (used for testing the failure path; not for normal operation).

## Why not the mcporter OAuth token

The mcporter Fastmail OAuth token is scoped `https://www.fastmail.com/dev/mcp*` with audience `https://api.fastmail.com/mcp` — it returns 401 on both CardDAV and JMAP, and the scope cannot be broadened from the client side. Never reuse it outside mcporter, and never try it as a fallback when the app password fails.

## Symptoms of a missing or dead credential

- Missing: the script prints `carddav-contact: no Fastmail CardDAV credentials found.` and exits 1.
- Revoked/wrong: the script prints `carddav-contact: addressbook-query REPORT failed with HTTP 401`, a response body of `Incorrect username, password or access token.`, and the hint line pointing at this file. Exit code 1.

Either way, **stop and ask Mike**. Do not work around it.

## What an agent must NOT do

- Do **not** look for the password in 1Password. An `op` invocation triggers an authorization prompt Mike will deny; whether or not he keeps a copy there, the keychain item is the only sanctioned source for agents.
- Do **not** print, echo, or paste the password (or any candidate password) into the conversation, a file, a commit, or a command an agent runs.
- Do **not** substitute the mcporter OAuth token, a Fastmail account password, or any other credential.
- Do **not** run `security add-generic-password` with a secret on an agent-issued command line — the secret would land in the transcript and the shell history. Mike runs that himself.

## Re-mint procedure (Mike does this; the agent only guides)

1. Fastmail web UI → **Settings → Privacy & Security → Integrations**.
2. Revoke/delete the old `fastmail-carddav` app password if it still shows there.
3. **New app password**; set the access scope to **Contacts (CardDAV)** only. Name it something recognizable (e.g. `carddav-contact CLI`). Copy the generated password — Fastmail shows it once.
4. In a real terminal, remove the stale keychain item if one exists, then add the new one:

   ```bash
   security delete-generic-password -s fastmail-carddav   # only if an item already exists
   security add-generic-password -s fastmail-carddav -a mike@greiling.me -w '<new-app-password>'
   ```

   (Leading space on the `add` line keeps it out of shell history when `HIST_IGNORE_SPACE` is on.)
5. Verify — this one is safe for an agent to run:

   ```bash
   ~/.agents/skills/fastmail/scripts/carddav-contact list
   ```

   Expect one `UID<TAB>FN<TAB>ORG` line per card.

Update the creation date at the top of this file whenever the credential is re-minted, and `chezmoi add` the change.
