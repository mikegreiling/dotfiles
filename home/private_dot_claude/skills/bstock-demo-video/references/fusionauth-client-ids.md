# FusionAuth client IDs & auth hosts (per environment)

Used by `global-setup.ts` to mint a session. Source: `fe-scripts/src/api/Context.ts`
`getFAClientId()` (client IDs) + observed home-portal dev OAuth requests (hosts).

| env | FA client_id | auth host | notes |
|-----|--------------|-----------|-------|
| dev | `d05d5cfb-7a1f-49c7-8edd-e27104c3c2f8` | `https://auth-integ.bstock.com` | **battle-tested** |
| qa | `ac89ac23-e588-4743-a6f0-7cc78b871262` | `https://auth-integ.bstock.com` | host unverified — confirm before relying |
| staging | `7e3f9663-1e37-4472-b25e-d6234cc91207` | `https://auth.bstock-staging.com` | host unverified |
| prod | `1b094c5f-c8a6-416c-8c62-4dc77ca88ce9` | `https://auth.bstock.com` | **do not** record demos against prod |
| localhost | `003cac24-2e16-4d3b-bbaf-a85aeff14d16` | `http://localhost:9011` | local FusionAuth (dev-deps setup) |

- `redirect_uri` is always `<baseUrl>/acct/login` (must be registered for the FA
  client — it is, since the portal itself uses it).
- Only **dev** has been verified end-to-end. If qa/staging fails at the login POST,
  the auth host is the first thing to check (capture the real `/oauth2/authorize`
  redirect host from the portal in that env and update the map in `global-setup.ts`).
  When you confirm one, update this table and commit (skill is version-controlled).
