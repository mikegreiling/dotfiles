# People & Organization

Who's who at B-Stock: the org structure, cross-system identities, domain experts, service gatekeepers, and recurring meetings. Use this to answer questions like "who should I ask about X", "which team is Y on", "who gates access to Z", and to seed cross-platform catch-ups ("summarize my recent collaboration with Mary" → grab her IDs here, then sweep Slack/Jira/GitLab with them).

**This is a living document.** Amend it freely: when you learn a new stable ID, a person's role, who owns a service, or who the expert on a domain is — add it here. When reality contradicts this file, verify against the source system and correct the file. Two kinds of content coexist, treat them differently:

- **Stable caches** (Slack/GitLab/Jira IDs, emails, DM channel IDs): safe to rely on; verify only on visible failure.
- **Snapshots** (titles, team membership, current projects, "recent interaction" notes): dated where possible; presume drift after a few months. Refresh via live lookup when a decision hinges on one.

Verification recipes: `slack_search_users` (returns title + email + timezone), `GITLAB_HOST=gitlab.bstock.io glab api "users?search=<term>"`, Atlassian MCP `lookupJiraAccountId`. **Email is the reliable join key across systems.** For "recent interactions with person X", use the sync-since-cursor recipe in `slack-workflow.md` (`with:<@UID>` scoped to `im,mpim`, plus `from:<@UID>`), Jira JQL on their accountId, and `glab` MR activity on their GitLab username.

Bulk research for this file was done 2026-07-24 (Slack + Jira + Confluence sweeps); undated claims below are as of then.

## Quick routing — who to ask / who gates what

| Service / decision | Go to | Notes |
|---|---|---|
| Google Analytics (admin, access) | **Mary Gutierrez** | granted Mike GA admin 2026-07-24; previous owner Ryan Jenkins (departed) |
| Google Tag Manager | **Mike himself** (admin) | inherited from Ryan Jenkins; no Confluence-documented process |
| LaunchDarkly — flag flips (buyer product) | **Jeremy Walton** (PM) | gives the product go-ahead ("you've got my okay") |
| LaunchDarkly — flag hygiene/retirement | **Mary Gutierrez**; buyer-pod flag process owned by Alexandra Ash | questions → `#feature-flags-launchdarkly` |
| LaunchDarkly — access | `#feature-flags-launchdarkly` channel | no formal ticket process documented |
| Cloudflare (WAF, bot challenges, Turnstile) | **Parvinder Bhasin** | offers day-or-night phone escalation |
| GitLab accounts & tier/licensing decisions | accounts: manager emails `devops@bstock.com` · spend: **Parvinder Bhasin** | |
| GitLab `common/ci` changes | authored by **Orest Stetsiak** → approved by **Joe Spandrusyszyn + Mike** | Mike is one of two approvers |
| Datadog | auto-granted via `dev@bstock.com` list; escalation **Parvinder/Orest** | |
| Releases, patches, deployment manifests | **Susan Oakes** | ⚠️ she has no GitLab account — brief her in Slack prose, never MR/pipeline links |
| QA cycle start, hotfix/patch scheduling | **Sohil Sethi** | wants Jira IDs + service/version pairs |
| QA priority / release-blocking bug calls | **Sohil Sethi**, **James Han**, Susan Oakes | James makes the "does this block the release" call |
| QA automation (repos, confidence dashboard) | **Anthony Lombardo** | owns `qa/quality-live-portal`, `automation.bstock-qa.com/confidence` |
| AI Code Reviewer bot | **Patrick Spracklen** (owner), **Anthony Lombardo** (first-line debug) | |
| AI subscriptions / token budgets (Claude, OpenAI) | **Ken Shum**, with Mary Gutierrez + Patrick Spracklen | Ken administers OpenAI org billing |
| Jira permissions, app-level roles, prod service accounts | **David Chan** | per Justin James: "See David Chan for a production service account" |
| Data model / service boundaries / schema changes | **Damien Jones** (Web Architect) | get his sign-off on major data-model proposals (e.g. Campfire schema asks). Canonical position: `listing_id`, not `auction_id` |
| Contracts service | **Waldemar "Waldek" Dziubek** | per Justin James: "he's the guy" |
| FE architecture / DX direction | **Joe Spandrusyszyn** (senior-most FE) | Mike and Paul Robertson sit directly under him in seniority |
| Tech-debt backlog (Optimization Cabal, GLOB-1987) | **Joe Spandrusyszyn + Paul Robertson** (curators) | |
| agent-skills repo / ai-guild meeting | **Paul Robertson** (Mike is backup host) | |
| Product copy sign-off, shipping-vendor decisions | **Sarah Xu** (PM) | e.g. passed on Shippo 2026-07-23 |
| UX / design-system sign-off | **Fred Leung** (design), impl. **Helen Foutch** | |
| Figma access | **Vajira Nissanka** | |
| IT: hardware, Cylance, SaaS provisioning, Zoom accounts | **Jon Paul Hutchins** via [IT service desk portal 15](https://bstock.atlassian.net/servicedesk/customer/portal/15) | he does NOT own app dependencies — those go to `#tech-general` |
| Prod SSH (Teleport), CAS, DSK | `techsupport@bstock.com` or `devops@bstock.com` | |
| Sentry | undocumented — only stale 2018/2021 pages exist; ask in `#tech-general` or DevOps | |
| GA4 offline events / Campfire program | **Aziz Vahora** (internal program owner), **Tim Foster** (Campfire, external) | |
| Escalation on anything DevOps | Escalation Matrix: [TO space](https://bstock.atlassian.net/wiki/spaces/TO/pages/2729246813) | Parvinder (mgmt), David Chan + Orest (3MP/SRE), Anmol Anand/Nihit Jain (India hours) |

## Org structure

**VP of Engineering: Ken Shum** (`ken.shum@bstock.com` — Mike's earlier "Ken Shun" spelling is wrong). With **Yang Luan**, drives the AI-automation-workflow and velocity push of recent quarters. Velocity = closed story points over time; there are quarterly team and individual targets, and (per Mike's read — hedged, not official policy) it is likely the high-level metric many engineers are judged on.

Engineering is divided into three product **pods** (the Jira `GLOB` Pod field has exactly these three values) plus platform teams:

| Pod (Jira Pod value) | Eng leadership | PM | Domain boundaries (per Buyer Pod Tech Support Procedures, Confluence) |
|---|---|---|---|
| **Buyer** | **Mary Gutierrez** (Director of Engineering); **James Han** (Sr. EM / team lead) | **Jeremy Walton** | accounts incl. registration, auction/bidding, documents, locations, notifications, search + saved search, some permissions |
| **Seller** | **Al Veitas** (EM/lead) | **Yang Luan** | Client Ops Portal (COPS), Seller Portal, Listings, Ingestion |
| **Payment and Foundations** (Mike's pod) | **Justin James** (Sr Director of Engineering) + **Alvaro Ferreira** (Director, Engineering — Mike's manager) | unconfirmed — **Sarah Xu** is the strongest candidate (top epic reporter for the pod) | shipment, payment, orders, disputes, bridge, CS Portal, contracts |

Notes on the Foundations pod: it is a 2025 merger of Justin's former **"Mula"** team (Accounts Portal, disputes, payments, feature flags, shared `@bstock/*` libs — incl. Paul Robertson, Acker Apple, Patrick Fisher) and Alvaro's former **"Sprinters"** team (bridge, DSK, FusionAuth/SSO, Magento, shipment/logistics, search/Algolia — incl. Mike, James Han†, Alex Garcia, Cy Kong, Joe Ellis, Volodymyr Kelembet, Connor Finley, Tim Tate, Mike Talimonchuk). Team Sprinters formally dissolved early Oct 2025 (`#team-sprinters` went quiet 2025-10-08), but the name survives informally for the standup of Alvaro's direct reports (Tuesdays). Alvaro remains Mike's nominal manager within the merged pod. †James Han's current work is clearly Buyer-pod (LDP redesign, on-page bidding) despite the stale Jun-2025 roster listing him under Sprinters.

Legacy team names still seen on old Confluence pages: "Zero" = Buyer (Mary), "TBD" = Seller (Al), "Mula" + "Sprinters" = Payment and Foundations.

**Platform / non-pod teams:**

- **DevOps** — Director **Parvinder Bhasin**; David Chan (Sr DevOps Eng), Orest Stetsiak (Sr DevOps Eng), Terry Zhang (Solutions Eng, Platform Support), Jon Paul Hutchins (IT), contractors Nihit Jain + Anmol Anand (India hours). Point of contact for GitLab/Datadog/GCP/MongoDB/Cloudflare/prod support.
- **Data Engineering** — Director **Daehee Kim**; Ken Shum is active here too (DET project: BigQuery, Firestore/Cloud Run IAM, AI-agent eval infra); Mark Ma, Patrick Spracklen, Harish Verlekar, Louies Tam, Gavin Lang.
- **Architecture** — **Damien Jones**, Web Architect (works above sprint-ticket level).
- **Release/Program Management ("PjM")** — **Susan Oakes**, Senior Release Manager & PM.
- **QA** — **Sohil Sethi** (QA Engineering Manager); Anthony Lombardo (QA automation); QA engineers incl. Lana Kukharchyk, Anh Nguyen, Lam Tung Nguyen, Thanh Nguyen; Vinh Tran (QA PM, from Evizi).

**Org chart of record: Pingboard** — now "**Workleap Pingboard**" (Workleap acquired Pingboard Dec 2023): `https://b-stock.pingboard.com/org_chart`. There is no live org-chart page in Confluence. Programmatic access is a dead end for non-admins (old public API is gone; the new Workleap API is admin-key-gated and lacks org-chart/reports-to endpoints) — the practical path is Mike exporting from the UI (org chart → Download & Print as PNG/PDF incl. reporting chains, or CSV report export), which any employee can do. If an export is provided, fold official titles/reporting lines back into this file.

## Meetings & rituals

- **Weekly Deck Shuffle + Optimization Cabal** — Tuesdays 1:30–2:00pm CT. Informal tech-leads huddle: Al Veitas (de-facto chair), Alvaro, Justin James, Mary, James Han, Mike (seat inherited from Ryan Jenkins, who departed early 2026), Yang Luan sometimes. Channel: `#3mp-tactical-planning` (`C0873VC4FU2`). Content: goings-on across teams, migration timelines (AT&T AOMP, mobile), infra flare-ups, Jira workflow friction, upgrade coordination — plus nominally fielding Optimization Cabal tech-debt/perf/DX tickets to teams with bandwidth. Cancelled ~40–50% of the time (conflicts or empty agenda). Note: the **Optimization Cabal itself is a Jira board, not the meeting** — GLOB-1987, the tech-debt backlog, curated day-to-day by Joe Spandrusyszyn and Paul Robertson; Mike pulls from it when between priority assignments. See the `/optimization-cabal-prep` command for meeting prep.
- **Scrum of Scrums (SoS)** — weekly Fridays, headed by **Susan Oakes** with **Sohil Sethi**. Cross-team blockers and release coordination; Joe S uses it as the escalation lever ("so I could bring it up in Scrum of Scrums if I need to poke anybody"). Almost no Slack/Confluence footprint — a `#3mp-scrum_of_scrums` channel is referenced for release-timeline updates. To surface something there: tag Susan and Sohil.
- **Sprinters standup** — Tuesdays; the former-Sprinters crew (Alvaro's direct reports: Mike, Cy Kong, Joe Ellis, Alex Garcia, et al.). Survives the team's Oct-2025 dissolution into Foundations.
- **FE Guild meeting** — see `references/fe-guild-meeting.md` (agenda automation, Confluence notes). Channel `#fe-guild`.
- **ai-guild meeting** — co-run by Paul Robertson; Mike is the fallback host (hosted 2026-06-26). Channels `#ai-engineering`, `#mr-ai-agent-tiger-team`.
- **3MP Weekly Defect Triage** — rotating owner among the leads (Al usually), run out of `#3mp-tactical-planning`.
- **Monday cadence**: "Maker Day" + Mini-Pods on Mondays (introduced ~Jun 2026, the reason Deck Shuffle moved off Mondays); leadership `#monday-am-huddle` where Ken assigns work to directors.
- **Buyer-pod flag standup** — weekly Tuesdays, reviews/closes LaunchDarkly experiments (buyer pod process).

## Identity map — core collaborators

Stable cross-system IDs. GitLab = `gitlab.bstock.io` usernames. "—" = verified not found / n/a; blank-ish gaps marked `?` are simply not yet cached — resolve and fill them in when needed.

| Person | Role (snapshot) | Slack ID | Email | TZ | GitLab (id) | Jira accountId |
|---|---|---|---|---|---|---|
| Mike Greiling | Staff Frontend Engineer, Foundations | `U065SDTU138` | mike.greiling@bstock.com | America/Chicago | `mike.greiling` (421) | `712020:102e13ca-76c4-4a0c-89e1-c9fc45369c5d` |
| Alvaro Ferreira | Director, Engineering — Mike's manager | `UPMJC0VFH` | alvaro@bstock.com | America/Los_Angeles | `alvarobstock` (15) | `5acbb67101a2012a6c31de20` |
| Justin James | Sr Director of Engineering, Foundations | `U026ZL0E858` | justinjames@bstock.com (Slack) / justin.james@bstock.com (Jira) | America/Los_Angeles | `justinjames` (185) | `60df961fee648800689e976e` |
| Al Veitas | EM/lead, Seller pod | `U026WKB3KCM` | al@bstock.com | America/New_York | `al` (184) | `60df961f70941d006928808c` |
| Mary Gutierrez (she/her) | Director of Engineering, Buyer pod | `U0K2Y8D89` | mary@bstock.com | America/Chicago | `mary` (11) | `5acbf7ff780b8e2b9bc0a04b` |
| James Han | Sr. EM / team lead, Buyer pod | `U06REB92S` | james@bstock.com | America/Los_Angeles | `james` (19) | `5ade1691bda65b2df516f220` |
| Ken Shum | VP of Engineering | `U02AHHMLYBH` | ken.shum@bstock.com | America/Los_Angeles | `ken.shum` (205) | `611473c4eb7aef0069620dbc` |
| Yang Luan | PM, Seller pod / 3MP product leadership | `UFX01LDS4` | yang@bstock.com | America/Los_Angeles | `yang` (70) | `5c48dbed98c1ac41b4326ec7` |
| Jeremy Walton | PM, Buyer pod | `U0477MYGY` | jeremy@bstock.com | America/Los_Angeles | `jeremy` (253) | `5b47d1a41f33802cd1c7f518` |
| Sarah Xu | PM — 3MP parcel, seller/migrations | `U04QHRG8Q8G` | sarah@bstock.com | America/Los_Angeles | `sarah` (361) | `63ed4f0f07df05aa82766c7e` |
| Joe Spandrusyszyn | Senior-most FE engineer | `U049J4ALL69` | joseph.spandrusyszyn@bstock.com | America/New_York | `joseph.spandrusyszyn` (332) | `63659c17b7b39379d722512a` |
| Paul Robertson | Senior FE engineer, AI tooling lead | `U065LP1M6UX` | paul@bstock.com | America/Chicago | `paul` (419) | `712020:b9d94b10-920e-4d35-915b-9994724c9934` |
| Joe Ellis | Sr Software Engineer (BE), Foundations | `UDQ1PD1H6` | joe.ellis@bstock.com | America/New_York | `joe.ellis` (43) | `70121:46cb1856-1239-4833-b2b8-599729de54e8` |
| Cyrus "Cy" Kong | FE engineer / epic lead, Foundations | `UJBMM6K4N` | cyrus@bstock.com | America/Chicago | `Cy-Kong` (48) | `5cb8e545b01aec0e591d6c55` |
| Alex Garcia | Lead SWE, Logistics & Finance (Foundations) | `U013Y1Y4G5C` | alex.garcia@bstock.com | America/Chicago | `alex.garcia` (100) | `5ec7f4036c50620c1cb0fc61` |
| Helen Foutch | FE/full-stack engineer, Buyer pod | `U99JLJBDZ` | helen@bstock.com | America/Chicago | `helen` (16) | `5afb0999d1d9445cd3a60343` |
| Waldemar "Waldek" Dziubek | Engineer — contracts-service expert | `U075L0TF7PS` | waldemar.dziubek@bstock.com | ? | ? | ? |
| Patrick Spracklen | Data Eng — AI Code Reviewer owner | `U06LH6G34DS` | patrick.spracklen@bstock.com | ? | ? | ? |
| Aziz Vahora | Data/analytics program owner (Campfire GA4) | `U0B6WG6BK9A` | ? | ? | ? | ? |
| Damien Jones (he/him) | Web Architect | `U017YNCAP5G` | damien@bstock.com | America/New_York | `damien` (118) | `5f21dc81c9c094001c65cbd5` |
| Parvinder Bhasin | Director of DevOps & Cybersecurity | `U02PYTURXEH` | parvinder@bstock.com | Asia/Kolkata | `parvinder` (248) | `61b13eeed2e64c0071d5f478` |
| Orest Stetsiak | Sr DevOps Engineer | `U01DR3HGCF5` | orest@bstock.com | America/Los_Angeles | `orest` (123) | `5f9c7417c9b15a0078c56736` |
| David Chan | Sr DevOps Engineer (3MP/SRE, access grants) | `U016YQB317Y` | david.chan@bstock.com | America/Los_Angeles | `david.chan` (117) | `5f0f485d9d9a120029526368` |
| Susan Oakes | Senior Release Manager & PM | `UHBPZ9SUB` | susan@bstock.com | America/Los_Angeles | `skoakes` (55) | `5ca524d1bb353819f2b5ebac` |
| Sohil Sethi | QA Engineering Manager | `U01M2C9DRS4` | sohil@bstock.com | Asia/Kolkata | `sohil` (152) | `60144967e3a14d0071f45c3b` |
| Anthony Lombardo | QA automation engineer | `U05QBEQGE0N` | anthony.lombardo@bstock.com | America/New_York | `anthony.lombardo` (402) | `712020:aa4eb023-2612-4f9b-bfd5-37675c2f7dbf` |
| Jon Paul Hutchins | Solutions Engineer \| Resident IT Admin | `U01SWFMS1JA` | jonpaul@bstock.com | America/Los_Angeles | — (no GitLab) | `606600c2aee24000688b510c` |
| Fred Leung | UX Designer (design system, parcel) | `U0A0Y5MRHSL` | frederick.leung@bstock.com | America/Los_Angeles | `frederick.leung` (626) | `712020:0accc665-be14-4f4c-9914-796fffa4d0ca` |
| Lana Kukharchyk | QA Engineer — loudest P0/P1 escalation voice | `U080N3NKSFJ` | lana.kukharchyk@bstock.com | ? | ? | ? |
| Volodymyr "Vova" Kelembet | BE engineer (order-process, ETL), Foundations | `U01P9BBHKBN` | volodymyr@bstock.com | ? | ? | ? |
| Tim Foster | **EXTERNAL** — Campfire Analytics (GA4 spec) | `U4W4M341X` | tfoster@campfireanalytics.com | ? | — | — |

**Name disambiguation** (verify before acting on a bare first name):

- "Paul" → Paul Robertson (`U065LP1M6UX`), not Paul Angeles (`U075W4W0VDX`, Asia/Chongqing tz, no GitLab/Jira activity — likely non-engineering).
- "Joe" → Joe Spandrusyszyn ("Joe S.") or Joe Ellis depending on context (FE/tooling vs BE/parcel). Joe Dube (`U9B885U90`, Amsterdam, GitLab deactivated, no Jira activity) is inactive.
- "Sarah" → Sarah Xu (PM). Sarah Robinson (`U08MNCH285Q`, Denver, no GitLab/Jira) is someone else.
- "Helen" → Helen Foutch (engineer, Buyer pod). Helen Holyk (`U02DM3XAWQ6`, UX Designer, Europe/Amsterdam, UXD project) is a different person.
- "Anthony" → Anthony Lombardo (QA automation). Anthony Campetti (`U05MCB9H34Y`) is an Account Manager, no engineering overlap.
- "Alex" → Alex Garcia (engineer). Beware: `alex@bstock.com` belongs to a *different* person (Lead Product Manager/Strategy, Slack `UCF85FWRW`); Alex Cadalso does product/business-rules work on SP/XLTR; Alex Vasylyk (`alex@startupsoft.com`) is an external contractor account.
- "Ken" → Ken Shum. Searching Slack for "Cy" false-positives on Parvinder (matches "Cybersecurity" in his title).
- "Mike"/"Michael" is heavily overloaded: Mike Greiling, Mike Feldman (Buyer pod SWE), Michael Ruth (Backend Engineering Lead), Mike Talimonchuk, Michael Ilchuk.

## Dossiers

Format: what they do → when to reach out → surfaces (DM channel IDs are stable caches) → dated snapshot of recent collaboration.

### Leadership

**Ken Shum — VP of Engineering.** Drives the AI-automation and velocity agenda; administers AI tooling spend (OpenAI org billing, Claude MAX/Team right-sizing with Mary + Patrick Spracklen); hands-on in Data Engineering (DET project: BigQuery, agentic-QA infra). Assigns work to directors in `#monday-am-huddle`. Reach out for: AI subscription/licensing needs, escalations above director level. Surfaces: DM `D096EB8KT46`; group DM with Damien + Mike `C0B849UFBPC` (GA-events backend workstream). Snapshot 2026-06-03: chased the backend GA-event meeting outcome in that group DM; 2026-07-10 asked the guild for token-usage data to right-size subscriptions.

**Yang Luan — PM, Seller pod; 3MP product leadership** (Fred calls Yang + Ken "our fearless leaders"). Seller-facing data/migration escalations, marketplace-integration roadmap (Amazon split inventory, Costco, automated lotting). Escalation pattern to anticipate: `@here` screenshot spot-checks in `#foundation-pod` ("Did we work on this?"). Rarely DMs — engage in `#3mp-migrations`, `#foundation-pod`, or via group DMs. Snapshot: last direct thread with Mike Nov 2025 (disputes CSV export).

**Mary Gutierrez (she/her) — Director of Engineering, Buyer pod.** Gatekeeper for Google Analytics admin, LD flag retirement, Bug Triage Agent; co-manages AI budget lists with Ken. Decides initiative bucketing with Susan. Reach out for: GA/analytics access, buyer-pod coordination, flag-removal blessings. Surfaces: DM `D06AV0BMD1U` (active), `#team-buyer-pod`, `#ai-engineering`. Snapshot 2026-07-24: granted Mike GA admin (closing the gap Ryan Jenkins left); 2026-07-21 blessed removing the Zoom-chat-widget LD flag ("probably safe to pull it out whenever you're ready").

**Justin James — Sr Director of Engineering, Foundations pod.** Deep backend/data-model authority (NetSuite POs, seller-proceeds, order amounts, AlloyDB, Canadian tax). Owns FP board 678 config; triages P0s in `#foundation-pod`; excellent router to the right owner. Reach out for: payments/orders domain questions, board/process issues, "who owns this?" routing. Surfaces: DM `D06QLD6CWBF` (low volume, high value), leads group DM `C0B6J1HQGHY`. Snapshot 2026-06-09: routed Mike — contracts → Waldek, prod service account → David Chan.

**Alvaro Ferreira — Director, Engineering; Mike's manager** (ex-Sprinters EM). Owns Mike's priority stack and sprint ceremony (retros, demo rotation); arbitrates priority conflicts; watches prod infra; enforces LD-flag discipline. Weekly 1:1. Reach out for: prioritization, PTO, anything blocking. Surfaces: 1:1 DM `D0664RHDF9D` (primary, terse, directive); group DM with Joe Ellis `C079FD6GZEH` (parcel/epic handoffs). When he's on PTO, Sohil is his designated contact. Snapshot 2026-06-30: rescheduling the 1:1 around Mike's PTO; BUGS-5341 merge reported; Mike pitched the Claude bug-repro-video workflow.

**Al Veitas — EM/lead, Seller pod** (Boston). Seller integrations/migrations (AT&T AOMP cutover, T-Mobile/Samsung/GameStop mobile migration, COPS, Sunrise/Magento). De-facto chair of Deck Shuffle; drives 3MP Weekly Defect Triage rotation. Runs Claude himself — posts agent-authored RCAs to `#team-seller-pod`. Reach out for: seller-pod scope, migration timelines, defect-triage. Surfaces: DM `D06DAKAMZC2`, leads group DM `C0B6J1HQGHY`, `#3mp-tactical-planning`. Snapshot 2026-05-28: seller-portal ship-to-address P0 → BUGS-5202 ("Big Thanks Mike!").

**James Han — Sr. EM / team lead, Buyer pod.** Release-blocking bug triage and incident comms (ran the 2026-05-04 outage war room); drove the React+Next upgrade merge decision. Makes "does this block the release" calls with Susan + Sohil. Reach out for: buyer-pod release risk, incident coordination. Surfaces: DM `D0773H3LTA5` (sparse), leads group DM `C0B6J1HQGHY`, `#3mp-bug-triage-team`.

### Foundations pod — Mike's peers

**Joe Spandrusyszyn — senior-most FE engineer; Mike's closest senior peer.** FE platform & tooling: Vitest migration, Node/React/Next upgrades, dependency hygiene, CI consolidation, Datadog log cleanup, CSP triage. Co-curates Optimization Cabal; one of two `common/ci` approvers (the other is Mike). Go-to for important FE-architectural decisions and DX changes. Surfaces: DM `D066H7SSFK9` (frequent, informal), group DM with Paul R `C066XPKEAEN` (FE tech-debt strategy), group DM with Parvinder + Orest `C0BERD4144D` (GitLab/CI governance). Snapshot 2026-07-15: asked Mike to take the Cylance remote session; on vacation until ~2026-07-27.

**Paul Robertson — senior FE engineer; the org's AI-tooling thought leader.** Owns `common/agent-skills` repo structure; co-runs ai-guild (Mike is backup host); AI code-reviewer rollout; Jest-transform perf. Heavy in `#ai-engineering`, `#mr-ai-agent-tiger-team`. Also looped in by Parvinder/Ken for Cloudflare/Turnstile bypass validation. Surfaces: DM `D0692M1E77E` (light), group DMs `C066XPKEAEN` (Joe S), `C09LDUNP1EH` (Alex Garcia, agent-skills). Snapshot 2026-06-26: agent-skills MR !79 debate; handed ai-guild hosting to Mike.

**Joe Ellis — Sr Software Engineer (BE), Boston.** Mike's highest-volume backend counterpart: order-process, shipment/Shippo parcel rates, listings-summary, NetSuite item provisioning, shipping-insurance backend (GLOB-4613). Feeds Mike the FE side of parcel epics. Runs Claude for backend spelunking. Surfaces: group DMs `C079FD6GZEH` (with Alvaro), `C0BAVNNQ2GP` (with Alex Garcia + Volodymyr, parcel/Shippo), `C09JKAFSW8G` (with Cy). Snapshot 2026-06-30: flagged GLOB-4613 insurance epic entering technical review, FE planning needed.

**Cy Kong (Cyrus) — FE engineer, ex-Sprinters.** cs-portal, home-portal, CSP config, quotes endpoints; epic-level owner of the Enterprise-systems decommission (GLOB-4017/4922). Mike's mutual MR-approval pact partner — they trade approvals and re-approvals when pushes reset them. Surfaces: DM `D066KTSBF7C` (daily-ish), `#fe-guild`. Snapshot 2026-07-24: raised (unanswered) rising post-merge CI failures across cs-portal/home-portal in `#fe-guild`.

**Alex Garcia — Lead SWE, Logistics & Finance.** Disputes service, ERP/NetSuite billing reliability (GLOB-4942), stuck-loads autofix, risk service. Active AI-tooling contributor (agent-skills). Surfaces: group DMs `C09LDUNP1EH` (agent-skills, with Paul R), `C0BAVNNQ2GP` (parcel), `C09R0QDRMPU` (disputes, with Yang/Justin/Alvaro). Snapshot 2026-06-26: conceded to Mike's blocking feedback on agent-skills MR !79.

**Waldemar "Waldek" Dziubek — contracts-service expert** ("he's the guy" — Justin). Also in an AI/process group DM with Joe S + Paul + Mike. Reach out for anything touching the contracts service (e.g. fixedTerm/buyerAccountId semantics).

**Volodymyr "Vova" Kelembet — BE engineer.** Order-process + ETL; does CI validation for Orest.

**Others in the pod orbit:** Acker Apple (SWE, ex-Mula), Patrick Fisher (ex-Mula), Tim Tate (SWE, ex-Sprinters), Mike Talimonchuk (ex-Sprinters), Jorge Castillo (Sr FE dev, ex-Sprinters), Connor Finley (ex-Sprinters, now seller-adjacent), Michael Ruth (Backend Engineering Lead — Buyer side).

### Buyer pod

**Jeremy Walton — PM.** Buyer product: First Dibs (GLOB-4598), Hot Deal/FMV badging, LDP redesign, watchlist, marketing-tracking features. Gives product go-ahead on LD flag flips; trialing LD data-export. Surfaces: `#team-buyer-pod`, group DM `C0A966PKSJ1` (with Mary + Alvaro — OneTrust/chat-widget). Snapshot 2026-07-17: approved re-enabling a flag in soft mode ("you've got my okay").

**Helen Foutch — FE/full-stack engineer, high-velocity.** fe-core + home-portal daily; owns big features end-to-end (Auction Close Schedule "TV Guide", GLOB-4495); design-system color/typography implementation with Fred. Alvaro held her and Paul up as the velocity exemplars (>40 pts). Surfaces: DM `D07A1MVM1EZ` (light), design-system group DM `C0B98AJA3GX` (with Fred + Alyssa Shum).

**Alexandra Ash** — authored the Buyer Pod Tech Support Procedures and the LD flag process; owns flag-removal tickets; buyer-pod support rotation (with Michael Ruth, Yury, Eric Chu, Mike Feldman, Patrick Fisher, Jorge). **Mike Feldman** — Buyer Pod SWE.

### DevOps / Data / QA / Release / IT / Architecture

**Parvinder Bhasin — Director of DevOps & Cybersecurity** (India tz, works odd hours, offers day-or-night phone escalation). Cloudflare WAF/bot rules, GitLab tier/licensing decisions, SAST/dependency-scanning policy, GCP IAM audits. Surfaces: group DM `C0BERD4144D` (with Orest + Joe S + Mike — the standing CI/GitLab governance channel), `#tech-operations`. Snapshot 2026-07-02→10: SARIF/vulnerability-view work with Mike + Joe.

**Orest Stetsiak — Sr DevOps Engineer, hands-on CI operator.** GitLab upgrades, runners/job-token auth, `common/ci` pipeline config (needs Mike's or Joe S's approval on his MRs), FusionAuth updates on dev/qa, Datadog alert triage, Helm/deploy tuning. Surfaces: `C0BERD4144D`, `#tech-operations`, `#3mp-datadog-alerts-prod`. Snapshot 2026-07-10: DOCKER_AUTH_CONFIG removal verified clean.

**David Chan — Sr DevOps Engineer (3MP/SRE).** The access-grant person: app-level roles (granted Mike seller-admin), Jira permissions (fixed Mike's PS-project commenting), prod service accounts; also executes seller-onboarding/warehouse infra scripts (often at Susan's direction), GDPR deletions. Purely transactional DM `D067AGLBRAM` — state the request plainly. Snapshot 2026-06-10: permissions verified working after two rounds.

**Susan Oakes — Senior Release Manager & PM.** Compiles the production deployment manifest for approval; schedules patch releases; writes Confluence release notes; heads SoS; runs many Foundations meetings (and coordinates cross-pod). Coordinate with her so related MRs land in the same manifest. ⚠️ **No GitLab account** — always brief her in Slack prose. Surfaces: DM `D0B1ZAWDACR`, group DMs with Mary `C0ALMA1ND5W` and Sohil `C0AJNCBKGTV`. Snapshot 2026-05-27: walked her through the fe-core→seller-portal→deploy CI chain for a hotfix.

**Sohil Sethi — QA Engineering Manager.** The ping for QA priority: starts test cycles (wants Jira IDs + service/version pairs), assembles hotfixes, schedules patches with Susan. Alvaro's designated stand-in contact during his PTO. Also personally picks up BUGS fixes (home/seller portal). Surfaces: DM `D098W2BV33J`, `#foundation-pod` (constant). Snapshot 2026-03-11: fast-tracked FP-632 re-review.

**Anthony Lombardo — QA automation.** Warm, jokey rapport with Mike; happy to bounce ideas off. Owns `qa/quality-live-portal`, the confidence dashboard (`automation.bstock-qa.com/confidence`), the "Atlas" contract sweeps and Agentic Tester (QA-2054); first-line debugger of the AI Code Reviewer (found the MRs-titled-"drafts" trigger bug). NOT the person for manual QA-review audits — that's Sohil's org. Surfaces: DM `D06M3CZMB6W` (frequent, casual), `#mr-ai-agent-tiger-team`. Snapshot 2026-07-21: granted Mike access to quality-live-portal; joint CI/CD auto-deploy workstream pending priorities.

**Patrick Spracklen — Data Eng; owns the AI Code Reviewer bot** and Claude MAX plan pooling. Ping when the AI reviewer stops firing (Anthony first-line, Patrick owner).

**Jon Paul Hutchins — Solutions Engineer / Resident IT Admin.** IT tickets via service-desk portal 15; Cylance/Arctic Wolf endpoint compliance, hardware, credential management (Delinea), phishing, Zoom account provisioning (Mike's paid Zoom account = IT-2236). Self-declared scope limit: does NOT manage app dependencies ("I don't manage Axios") — those questions go to `#tech-general`. Escalation-matrix phone: 415-320-7017, 9–5 PST.

**Damien Jones (he/him) — Web Architect.** Final say on data model and service boundaries: listing/order/auction canonical identity (**`listing_id` is canonical, never `auction_id`** — directly relevant to GA4/Campfire work), pricing strategy, relist semantics, FIXED_TERMS/SPOT modeling. Get his sign-off on major data-model proposals, including anything Campfire suggests schema-wise. Thin Jira presence (works above ticket level) — engage in `#foundation-pod` or group DMs `C0B849UFBPC` (Ken + Mike), `C0BAPCDFH1B` (Campfire).

### Design / UX

**Fred Leung — UX Designer** (design leadership; 1:1s with Yang). Design system (FP-1973/FP-2005 color+typography), platform-wide copy consistency. Fast same-day turnaround on UX review asks. Notably piloting Claude Code + Storybook MCP himself (Mike is his setup buddy). Surfaces: DM `D0A7FL9691S`, parcel-copy group DM `C0BKD5JMJSJ` (with Sarah Xu), design-system group DM `C0B98AJA3GX`. Snapshot 2026-07-23: approved/tightened the shipping-insurance disclosure copy for home-portal !2320 within the hour.

**Sarah Xu — PM (3MP parcel, seller/migrations; likely the closest thing Foundations has to a pod PM — unconfirmed).** Owns product copy sign-off and vendor decisions (passed on Shippo 2026-07-23); sets migration cutover dates; LOE-vs-scope calls. Surfaces: group DM `C0BKD5JMJSJ` (with Fred). Snapshot 2026-07-23: closed the last open parcel-insurance copy item.

**Others:** Anushka Jain (Sr UX Designer — Seller designs with Fred), Helen Holyk (UX Designer, Amsterdam — UXD project), Alyssa Shum (marketing/design — design-system launch messaging), Neil Zhu (UX — CS-portal filters, Oct 2025), Vajira Nissanka (Figma access).

### External

**Tim Foster — Campfire Analytics** (`tfoster@campfireanalytics.com`, Slack Connect via `#bstock-campfire` `C09V4EF0F3J` and group DM `C0BAPCDFH1B`). Owns the GA4 offline-events spec. Mike is the engineering liaison; **Aziz Vahora** (`U0B6WG6BK9A`) is the internal program owner coordinating access and stories. ⚠️ Snapshot 2026-07-24: Tim has followed up twice (07-14, 07-22) awaiting Mike's reply on the GA4 offline-events thread.

### Departed but still referenced

**Ryan Jenkins** (`U01N2L2LS0Z`, left ~Jan 2026) — previous owner of GTM, Google Analytics, the SEO-agency relationship, and the Deck Shuffle seat Mike inherited. Made Mike GTM admin on the way out; the GA-admin gap was closed by Mary 2026-07-24. His name still appears on onboarding docs (FE Onboarding page) and old GTM/SEO group DMs.

## Extended roster — FE guild & pod channels

`#fe-guild` (`C04225G5QCS`, 61 members) and `#foundation-pod` (`C09G5BQDEJD`, 52 members) overlap heavily. Beyond the people above, the review-network regulars in `#fe-guild`: Patrick Fisher (`U06LENC7SE6`), Jorge Castillo (Sr FE), Bryan Lopez (Sr SWE), Cole Allan (SWE), Michael Feldman (Buyer pod SWE), Andrii Prasolov (FE), Shivam Bandral (FE), Yury Herlovich (Sr SWE), Michael Ilchuk, Mike Talimonchuk, Ashish Tulsankar, Ary Baldioceda (SWE), Acker Apple (`U01DMD45AKV`), Igor Shkulipa, Josh Mozley, Sriram Sridhar, Tim Tate (SWE), Alexandra Ash, Kai DiRamio, Calvin La, Sachin Jagtap, Amit Negi, Eric Chu, Gavin Grooms, Geethika Kilaru. Non-engineering members of `#foundation-pod` worth knowing: Gary Fewkes (Sr. Director, Customer Service), Jay Hormes (Analytics), Stanley Ho (Product Analyst), Jesseca Frazier (Operations). A `bug-fix-loop` bot posts review requests and stale-approval nags to both channels (since 2026-07-23). Emails follow `first.last@bstock.com` or `first@bstock.com`; resolve Slack UIDs on demand with `slack_search_users`.

## Access requests & IT support — processes

- **IT support tickets**: [service desk portal 15](https://bstock.atlassian.net/servicedesk/customer/portal/15) (facilities = portal 22). Owner: Jon Paul Hutchins. Use for hardware, Cylance, SaaS provisioning, account requests (e.g. Zoom).
- **GitLab account/repos**: manager emails `devops@bstock.com`.
- **Datadog**: automatic via the `dev@bstock.com` distribution list.
- **CAS / DSK / Teleport (prod SSH)**: `techsupport@bstock.com` or `devops@bstock.com`.
- **LaunchDarkly**: ask in `#feature-flags-launchdarkly`; flag lifecycle docs: "Feature Flag Process (Buyer Pod)" + "Feature Flag How-To's" (Alexandra Ash).
- **Figma**: Vajira Nissanka. **Qase**: email the QA team.
- **App-level roles / Jira permissions / prod service accounts**: DM David Chan.
- **GTM / GA / Sentry**: no documented process — GTM is Mike's own admin domain; GA goes through Mary; Sentry ask DevOps/`#tech-general`.
- Key Confluence anchors: [Engineering roster](https://bstock.atlassian.net/wiki/spaces/EN/overview) (stale Jun-2025, legacy team names), [Buyer Pod Tech Support Procedures](https://bstock.atlassian.net/wiki/spaces/EN/pages/3908403201) (current pod boundaries), [FE Onboarding](https://bstock.atlassian.net/wiki/spaces/EN/pages/2663972959), [DevOps Escalation Matrix](https://bstock.atlassian.net/wiki/spaces/TO/pages/2729246813), [IT Help Desk space](https://bstock.atlassian.net/wiki/spaces/it/overview).

## Known unknowns / open questions

- **Foundations pod PM**: unconfirmed. Sarah Xu is the best circumstantial candidate; no Confluence page names one (Buyer and Seller each have a "Pod Designs" page naming theirs).
- **Justin James email discrepancy**: `justinjames@` (Slack/GitLab) vs `justin.james@` (Jira) — same person, two formats on file.
- **Sohil's exact position in the QA hierarchy** vs Anthony, and who performs ticket QA audits day-to-day, is still fuzzy (Mike's own note).
- **Official titles/reporting lines**: pending a Pingboard (Workleap) export from Mike.
- Missing IDs marked `?` in the identity table — fill opportunistically.
