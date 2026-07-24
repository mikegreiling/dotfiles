# People & Organization

Who's who at B-Stock: the org structure, cross-system identities, domain experts, service gatekeepers, and recurring meetings. Use this to answer questions like "who should I ask about X", "which team is Y on", "who gates access to Z", and to seed cross-platform catch-ups ("summarize my recent collaboration with Mary" → grab her IDs here, then sweep Slack/Jira/GitLab with them).

**This is a living document.** Amend it freely: when you learn a new stable ID, a person's role, who owns a service, or who the expert on a domain is — add it here. When reality contradicts this file, verify against the source system and correct the file. Two kinds of content coexist, treat them differently:

- **Stable caches** (Slack/GitLab/Jira IDs, emails, DM channel IDs): safe to rely on; verify only on visible failure.
- **Snapshots** (titles, team membership, current projects, "recent interaction" notes): dated where possible; presume drift after a few months. Refresh via live lookup when a decision hinges on one.

Verification recipes: `slack_search_users` (returns title + email + timezone), `GITLAB_HOST=gitlab.bstock.io glab api "users?search=<term>"`, Atlassian MCP `lookupJiraAccountId`. **Email is the reliable join key across systems.** For "recent interactions with person X", use the sync-since-cursor recipe in `slack-workflow.md` (`with:<@UID>` scoped to `im,mpim`, plus `from:<@UID>`), Jira JQL on their accountId, and `glab` MR activity on their GitLab username.

Bulk research for this file was done 2026-07-24 (Slack + Jira + Confluence sweeps); undated claims below are as of then.

**Org-chart snapshot & refresh directive:** formal reporting lines and official titles below come from a Pingboard (now "Workleap Pingboard") org-chart PDF **exported 2026-07-24**. There is no live API access, so this data rots as people join/leave/get promoted. **If that snapshot is more than ~a quarter old, ask Mike to re-export** (`b-stock.pingboard.com/org_chart` → Download & Print → PDF with reporting chains) and reconcile this file against it. A quarterly repeating reminder also lives in Mike's Things (B-Stock area).

## Quick routing — who to ask / who gates what

| Service / decision | Go to | Notes |
|---|---|---|
| Google Analytics (admin, access) | **Mary Gutierrez** | granted Mike GA admin 2026-07-24; previous owner Ryan Jenkins (departed) |
| Google Tag Manager | **Mike himself** (admin) | inherited from Ryan Jenkins; no Confluence-documented process |
| LaunchDarkly — flag flips (buyer product) | **Jeremy Walton** (PM) | gives the product go-ahead ("you've got my okay") |
| LaunchDarkly — flag hygiene/retirement | **Mary Gutierrez**; buyer-pod flag process owned by Alexandra Ash | questions → `#feature-flags-launchdarkly` |
| LaunchDarkly — access | `#feature-flags-launchdarkly` channel | no formal ticket process documented; Evizi QA credentials went through Justin James |
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
| Data model / service boundaries / schema changes | **Damien Jones** (Enterprise Architect) | get his sign-off on major data-model proposals (e.g. Campfire schema asks). Canonical position: `listing_id`, not `auction_id` |
| Contracts service | **Waldemar "Waldek" Dziubek** | per Justin James: "he's the guy" |
| FE architecture / DX direction | **Joe Spandrusyszyn** (Principal SWE, senior-most FE) | Mike and Paul Robertson sit directly under him in seniority |
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

## Official org chart (Pingboard snapshot 2026-07-24)

Company-wide: **239 people**, everything stems from **Marcus Shen — CEO**. His 10 direct reports: Eric Moriarty (VP Account Expansion), Ryan Norton (Director Account Expansion), Kate Francis (Mgr Sales), Robert Iaria (VP Client Solutions & Logistics), Sean Cleland (VP Mobile), Kenny Fung (VP Strategy & Biz Ops), John Dokoza (VP Finance), **Kenneth "Ken" Shum (VP Engineering)**, Michelle Vazquez (VP Client Operations), Kylee Hall (VP Marketing — Customer Service sits under her via Gary Fewkes). Full company transcription available on request (Mike keeps the PDF at `~/Downloads/org-chart.pdf`).

**Engineering department (62 people) — Ken Shum's 13 direct reports and their subtrees:**

- **Parvinder Bhasin — Director, DevOps** → David Chan (Senior Site Reliability Engineer), Jon Hutchins (Solutions Engineer), Orest Stetsiak (Senior DevOps Engineer)
- **Damien Jones — Enterprise Architect** (group "3MP - Architects Engineering", no reports)
- **Algirdas "Al" Veitas — Senior Director, Engineering** (Seller Pod) → Waldemar Dziubek (Senior React Engineer), Mike Ruth (Backend Engineering Lead, "3MP - Inventory Engineering"), **Joseph Spandrusyszyn (Principal Software Engineer)**, Connor Finley (Software Engineering Lead)
- **Yang Luan — Senior Group Product Manager** (heads ALL of Product & UX Design) → Sarah Xu (Senior PM), Fred Leung (Senior UX Designer), Alyssa Shum (Associate Product Designer), Anushka Jain (Senior Product Designer), Amara Mir (UX Researcher), **Austin Jones (Senior Product Manager, Payments)**
- **Jeremy Walton — Director, Product Buyer Experience & Growth** → Geethika Kilaru (Senior PM — a PM, not an engineer)
- **Azizahmed "Aziz" Vahora — Senior Director, Data Engineering** → Justin Spracklen† (Senior Data Engineer), **Jeroen "Jay" Hormes (Director, Analytics)** → Kyle Magner, Stanley Ho, Sriram Sridhar (Senior Data Analysts), Arran Wass-Little, Swara Gandhi, Malachy McGovern (Data Analysts)
- **Data Analytics group reporting straight to Ken**: Louies Tam (Data Scientist II), Gavin Lang (Jr SWE Data), Mark Ma (Staff Data Engineer), Harish Deepak Verlekar (Senior Data Scientist II)
- **Mary Gutierrez — Director, Engineering** → Alexandra Ash (Senior SWE, "3MP - Shipments Engineering"), Cole Allan, Michael Feldman (Senior SWE), Yury Herlovich (Senior SWE), Helen Foutch, Eric Chu (Senior SWE React), Bryan Lopez (Senior SWE React)
- **Alvaro Ferreira — Director, Engineering** → Joseph "Joe" Ellis (Senior SWE), Javier Garcia Godinez† (Software Engineering Lead — almost certainly "Alex Garcia"), **James Han (Senior Engineering Manager)** → Timothy Tate (Backend Engineering Lead), Jorge Castillo (Senior SWE React), Patrick Fisher (Senior SWE React); Cy Kong (React Engineer), **Michael "Mike" Greiling (Staff Software Engineer)**, **Sohil Sethi (Manager, QA Engineering)** → Olga Chmikhun, Gavin Grooms, Sviatlana "Lana" Kukharchyk (QA Engineers), Daria Kazhybay (SWE, QA)
- **Justin James — Senior Director, Engineering** → Acker Apple (SWE, "3MP - Payments Engineering"), Kai DiRamio (SWE), **Homer "Paul" Robertson (Staff Software Engineer)**, one unnamed card† ("3MP - Orders Engineering", SWE Node.js Microservices), Ary Baldioceda (SWE), **Susan Oakes (Technical Project Manager)**

† = see "chart anomalies" below.

**Reporting lines vs. pods are cross-cutting — don't conflate them.** Examples: Joe Spandrusyszyn and Waldek report to Al and are **Seller pod, NOT Foundations** (Mike confirmed 2026-07-24 — they never attend Foundations meetings), even though Joe S operates as the org-wide FE authority and Waldek is the contracts-service SME whom Foundations folks consult; James Han reports to Alvaro (Foundations) but he and his reports (Jorge, Patrick Fisher) do Buyer-pod work; QA (Sohil's team) reports through Alvaro but serves all pods; all PMs and designers report through Yang or Jeremy, not through the pod EMs. Use the chart for "who is someone's manager"; use the pod table below for "who works on what".

**Aliases — printed/legal name vs. colloquial** (note new ones here whenever spotted):

| Goes by | Printed in Pingboard | Notes |
|---|---|---|
| Paul Robertson | **Homer Robertson** | news to Mike (2026-07-24); per the card-vs-bio pattern below, Homer is presumably his legal first name — never call him Homer |
| Al Veitas | Algirdas Veitas | |
| Ken Shum | Kenneth Shum | |
| Aziz Vahora | Azizahmed Vahora | |
| Joe Ellis / Joe Spandrusyszyn | Joseph … | |
| Jay Hormes | Jeroen Hormes | Slack `jay@bstock.com`, title "Analytics" — Director, Analytics under Aziz (high confidence, same surname) |
| Lana Kukharchyk | Sviatlana Kukharchyk | goes by Lana/Svetlana; bio panel says "Lana" |
| Alex Garcia | Javier Garcia Godinez | **confirmed by Mike 2026-07-24** |
| Patrick Spracklen | **Justin Spracklen** | **confirmed same person** (Mike 2026-07-24): the card prints "Justin" but his profile bio says Patrick |
| Tim Tate | Timothy Tate | |
| Mike Talimonchuk | Mykhailo Talimonchuk | contractor; NOT in Pingboard |

Pattern (verified on Patrick and Lana, 2026-07-24): **Pingboard org-chart cards print the legal name; clicking through to the profile bio shows the preferred/go-by name.** When a chart name looks unfamiliar, assume legal-vs-preferred before assuming a different person.

**Chart anomalies / people missing from Pingboard:** the export appears to cover **employees only — contractors and vendor staff are absent**. Missing despite being active in Slack/GitLab: Anthony Lombardo (QA automation — either a contractor or the one blank/unrendered card under Justin James's "3MP - Orders Engineering"), Volodymyr Kelembet, Igor Shkulipa, Michael Ilchuk, Mykhailo Talimonchuk, Andrii Prasolov, Josh Mozley, Umesh Balasubramaniam, Shivam Bandral, Ashish Tulsankar, Amit Negi, Sachin Jagtap, Calvin La, Nihit Jain, Anmol Anand, all Evizi QA (below). The Jun-2025 Confluence roster explicitly tags several of these "Contractor" (Talimonchuk, Ilchuk, Andrii, Josh Mozley, Umesh, Shivam, Nihit, Anmol). Daehee Kim (Director Data Engineering on the 2025 roster) is also absent from the chart — possibly departed, with Aziz now holding that org (unconfirmed).

## Org structure — pods (working teams)

**VP of Engineering: Ken Shum.** With **Yang Luan**, drives the AI-automation-workflow and velocity push of recent quarters. Velocity = closed story points over time; there are quarterly team and individual targets, and (per Mike's read — hedged, not official policy) it is likely the high-level metric many engineers are judged on.

Product work is divided into three **pods** (the Jira `GLOB` Pod field has exactly these three values) that cut across the reporting lines above:

| Pod (Jira Pod value) | Eng leadership | PM | Domain boundaries (per Buyer Pod Tech Support Procedures, Confluence) |
|---|---|---|---|
| **Buyer** | **Mary Gutierrez** (Director); **James Han** (Sr. EM / team lead) | **Jeremy Walton** | accounts incl. registration, auction/bidding, documents, locations, notifications, search + saved search, some permissions |
| **Seller** | **Al Veitas** (Senior Director) | **Yang Luan** | Client Ops Portal (COPS), Seller Portal, Listings, Ingestion |
| **Payment and Foundations** (Mike's pod) | **Justin James** (Sr Director) + **Alvaro Ferreira** (Director — Mike's manager) | unconfirmed — **Sarah Xu** (top epic reporter) and **Austin Jones** (Senior PM, *Payments* — title fits the pod) are the candidates | shipment, payment, orders, disputes, bridge, CS Portal, contracts |

### Legacy teams → pods (the pre-pod org)

Old team names still appear in Slack history, Confluence, and muscle memory. Full rosters from the Confluence Engineering page (snapshot Jun 30 2025; roles as listed then):

- **Sprinters** (lead **Alvaro Ferreira**) → **Foundation pod** (confirmed: `#team-sprinters` topic says "Relocated to #foundation-pod"). Members: James Han (Sr. EM), Alex Garcia (Sr SWE BE), Cy Kong (SWE FE), Joe Ellis (Sr SWE BE), Volodymyr Kelembet (Sr SWE BE), Mike Greiling (Staff SWE FE), Connor Finley (Lead Integration Engineer). SME: bridge, data migration, DSK, FusionAuth/SSO, Magento, shipment/logistics, ENT microservices, finance, registration, search/Algolia. **James Han's sub-team within Sprinters**: Connor Finley, Tim Tate (BE Lead), Mike Talimonchuk (contractor) — SME: ENT integrations, Sunrise, ENT Magento, 3MP contracts. The "Sprinters standup" name survives for Alvaro's directs' Tuesday standup.
- **Mula** (aka "Moolah", lead **Justin James**) → **Foundation pod** (confirmed: `#team-mulax` topic redirect). Members: Josh Mozley (contractor), Elias Amador, Acker Apple, Paul Robertson (Staff SWE), Patrick Fisher, Kai DiRamio, Ary Baldioceda. SME: Accounts Portal, disputes, GitLab pipelines, Datadog, feature flags, payments-*, pdfgen, shared `@bstock/*` libs.
- **Zero** (lead **Mary Gutierrez**) → **Buyer pod** (inferred — no explicit redirect; weaker evidence). Members: Alexandra Ash, Andrii Prasolov (FE contractor), Cole Allan, Helen Foutch, Michael Ilchuk (BE contractor), Mike Feldman, Eric Chu, **Ryan Jenkins (Principal SWE FE — departed)**, Yury Herlovich. SME: Account Portal, auth/logging libs, buyer migration, docserv, freight-forwarding UI, notification, onboarding, search, Strapi, shipment, tax exemption, TMS.
- **TBD** (lead **Al Veitas**) → **Seller pod** (inferred). Members: Mike Ruth (BE Lead), Santosh (FE contractor), Umesh Balasubramaniam (BE contractor), Waldek Dziubek, Joe Spandrusyszyn (Sr Staff SWE FE), Shivam (FE contractor), Calvin La. SME: ingestion, inventory-lotting, listings, orders, seller migration.
- Non-pod teams unchanged through the transition: **Architecture** (Damien), **Data Engineering** (then Daehee Kim), **DevOps** (Parvinder), **PjM** (Susan).

Timeline markers: pod channels `#foundation-pod` created 2025-09-17 (by Yang Luan); Sprinters dissolved early Oct 2025; an org-wide channel-renaming wave hit 2026-06-03 (Orest archived all `#team-*-prod-errors` channels in one hour). Note `#team-buyer-pod`/`#team-seller-pod` date to 2022 and have near-org-wide membership — channel membership is NOT a reliable pod roster; use the tables above.

### Platform / non-pod functions

- **DevOps** — Parvinder Bhasin; David Chan, Orest Stetsiak, Terry Zhang (Solutions Eng, Platform Support), Jon Paul Hutchins (IT), contractors Nihit Jain + Anmol Anand (India hours). PoC for GitLab/Datadog/GCP/MongoDB/Cloudflare/prod support.
- **Data Engineering & Analytics** — Aziz Vahora (Sr Director) with Patrick Spracklen and the Analytics org under Jay (Jeroen) Hormes: Kyle Magner (the data-export person Yang pulls in), Stanley Ho, Sriram Sridhar, Arran Wass-Little, Swara Gandhi, Malachy McGovern. Plus Ken's direct Data Analytics group: Mark Ma, Louies Tam, Gavin Lang, Harish Verlekar.
- **Architecture** — Damien Jones, Enterprise Architect.
- **Release/Program Management** — Susan Oakes, Technical Project Manager (official) / "Senior Release Manager & PM" (Slack).
- **QA** — see next section.

### QA org & timezones (async by default)

QA reports through **Sohil Sethi (Manager, QA Engineering — Asia/Kolkata, IST)** under Alvaro, and splits into internal staff + an external Vietnam-based vendor, **Evizi**. Expect asynchronous turnaround and plan handoffs accordingly:

| Person | Slack ID | Timezone | Notes |
|---|---|---|---|
| Sohil Sethi | `U01M2C9DRS4` | Asia/Kolkata (IST) | QA manager; coordinates Evizi; relays their Vietnamese-holiday leave schedules |
| Anthony Lombardo | `U05QBEQGE0N` | America/New_York | QA automation (not in Pingboard — possibly contractor) |
| Lana (Sviatlana) Kukharchyk | `U080N3NKSFJ` | America/New_York (NY) | internal QA; loudest P0/P1 escalation voice in `#foundation-pod`; relays to Evizi. Started 2024-11-12; birthday Dec 18 |
| Olga Chmikhun | `U03LQFXEVGQ` | (unset/US-hours observed) | internal QA |
| Gavin Grooms | — (resolve on demand) | — | QA Engineer (per Pingboard, under Sohil) |
| Daria Kazhybay | — (resolve on demand) | — | SWE, QA (per Pingboard) |
| Anh Nguyen | `U01CAR3T074` | Asia/Bangkok (UTC+7) | **Evizi** vendor QA |
| Vinh Tran (Cong) | `U01DM5L1S69` | Asia/Bangkok | **Evizi** — "QA PM from Evizi" |
| Lam Nguyen (Tung) | `U01DY74KLNA` | Asia/Bangkok | **Evizi** vendor QA |
| Thanh Nguyen | `U01H5RNNKT5` | Asia/Bangkok | **Evizi** vendor QA (named "Evizi" by Justin re: LD creds) |

Evizi (Vietnam) runs much of the hands-on regression/story QA; internal QA (Lana, Olga, Anthony/automation) coordinates *with* them. Vietnamese national holidays (Hung Kings Day, Reunification Day, Labor Day, Tet…) take the whole vendor offline — Sohil announces these.

**Other notable non-US timezones** (for async expectations): Parvinder — Asia/Kolkata; Shivam Bandral, Ashish Tulsankar, Amit Negi, Sachin Jagtap — Asia/Kolkata (contractors); Volodymyr Kelembet (`U01P9BBHKBN`), Michael Ilchuk (`U010CB1S533`) — Europe/Helsinki; Igor Shkulipa (`U01MQ6BVA7L`), Mykhailo Talimonchuk (`URFLQKZ6V`), Andrii Prasolov (`U01DWA7ES3W`) — Asia/Jerusalem (Israel-based, despite Slavic names); Yury Herlovich (`U01EMLYNK5Z`) — America/Denver (US-based despite the name); Helen Holyk, Joe Dube — Europe/Amsterdam.

## Meetings & rituals

- **Weekly Deck Shuffle + Optimization Cabal** — Tuesdays 1:30–2:00pm CT. Informal tech-leads huddle: Al Veitas (de-facto chair), Alvaro, Justin James, Mary, James Han, Mike (seat inherited from Ryan Jenkins, who departed early 2026), Yang Luan sometimes. Channel: `#3mp-tactical-planning` (`C0873VC4FU2`). Content: goings-on across teams, migration timelines (AT&T AOMP, mobile), infra flare-ups, Jira workflow friction, upgrade coordination — plus nominally fielding Optimization Cabal tech-debt/perf/DX tickets to teams with bandwidth. Cancelled ~40–50% of the time (conflicts or empty agenda). Note: the **Optimization Cabal itself is a Jira board, not the meeting** — GLOB-1987, the tech-debt backlog, curated day-to-day by Joe Spandrusyszyn and Paul Robertson; Mike pulls from it when between priority assignments. See the `/optimization-cabal-prep` command for meeting prep.
- **Scrum of Scrums (SoS)** — weekly Fridays, headed by **Susan Oakes** with **Sohil Sethi**. Cross-team blockers and release coordination; Joe S uses it as the escalation lever ("so I could bring it up in Scrum of Scrums if I need to poke anybody"). Slack channel `#3mp-scrum_of_scrums` (release-timeline updates, Evizi leave notices). To surface something there: tag Susan and Sohil.
- **Sprinters standup** — Tuesdays; the former-Sprinters crew (Alvaro's direct reports: Mike, Cy Kong, Joe Ellis, Alex Garcia, et al.). Survives the team's Oct-2025 dissolution into Foundations.
- **FE Guild meeting** — see `references/fe-guild-meeting.md` (agenda automation, Confluence notes). Channel `#fe-guild`.
- **ai-guild meeting** — co-run by Paul Robertson; Mike is the fallback host (hosted 2026-06-26). Channels `#ai-engineering`, `#mr-ai-agent-tiger-team`.
- **3MP Weekly Defect Triage** — rotating owner among the leads (Al usually), run out of `#3mp-tactical-planning`.
- **Monday cadence**: "Maker Day" + Mini-Pods on Mondays (introduced ~Jun 2026, the reason Deck Shuffle moved off Mondays); leadership `#monday-am-huddle` where Ken assigns work to directors.
- **Buyer-pod flag standup** — weekly Tuesdays, reviews/closes LaunchDarkly experiments (buyer pod process).

## Identity map — core collaborators

Stable cross-system IDs. GitLab = `gitlab.bstock.io` usernames. "—" = verified not found / n/a; `?` = not yet cached — resolve and fill in when needed. Official (Pingboard) titles where they differ from Slack are in the dossiers.

| Person | Role (snapshot) | Slack ID | Email | TZ | GitLab (id) | Jira accountId |
|---|---|---|---|---|---|---|
| Mike Greiling | Staff Software Engineer (FE), Foundations | `U065SDTU138` | mike.greiling@bstock.com | America/Chicago | `mike.greiling` (421) | `712020:102e13ca-76c4-4a0c-89e1-c9fc45369c5d` |
| Alvaro Ferreira | Director, Engineering — Mike's manager | `UPMJC0VFH` | alvaro@bstock.com | America/Los_Angeles | `alvarobstock` (15) | `5acbb67101a2012a6c31de20` |
| Justin James | Sr Director of Engineering, Foundations | `U026ZL0E858` | justinjames@bstock.com (Slack) / justin.james@bstock.com (Jira) | America/Los_Angeles | `justinjames` (185) | `60df961fee648800689e976e` |
| Al Veitas (Algirdas) | Senior Director, Engineering — Seller pod | `U026WKB3KCM` | al@bstock.com | America/New_York | `al` (184) | `60df961f70941d006928808c` |
| Mary Gutierrez (she/her) | Director of Engineering, Buyer pod | `U0K2Y8D89` | mary@bstock.com | America/Chicago | `mary` (11) | `5acbf7ff780b8e2b9bc0a04b` |
| James Han | Sr. EM (reports to Alvaro; leads Buyer-pod work) | `U06REB92S` | james@bstock.com | America/Los_Angeles | `james` (19) | `5ade1691bda65b2df516f220` |
| Ken Shum (Kenneth) | VP of Engineering | `U02AHHMLYBH` | ken.shum@bstock.com | America/Los_Angeles | `ken.shum` (205) | `611473c4eb7aef0069620dbc` |
| Yang Luan | Senior Group Product Manager (Seller-pod PM) | `UFX01LDS4` | yang@bstock.com | America/Los_Angeles | `yang` (70) | `5c48dbed98c1ac41b4326ec7` |
| Jeremy Walton | Director, Product Buyer Experience & Growth | `U0477MYGY` | jeremy@bstock.com | America/Los_Angeles | `jeremy` (253) | `5b47d1a41f33802cd1c7f518` |
| Sarah Xu | Senior PM — 3MP parcel, seller/migrations | `U04QHRG8Q8G` | sarah@bstock.com | America/Los_Angeles | `sarah` (361) | `63ed4f0f07df05aa82766c7e` |
| Joe Spandrusyszyn | Principal Software Engineer (FE) | `U049J4ALL69` | joseph.spandrusyszyn@bstock.com | America/New_York | `joseph.spandrusyszyn` (332) | `63659c17b7b39379d722512a` |
| Paul Robertson ("Homer") | Staff Software Engineer (FE), AI tooling lead | `U065LP1M6UX` | paul@bstock.com | America/Chicago | `paul` (419) | `712020:b9d94b10-920e-4d35-915b-9994724c9934` |
| Joe Ellis (Joseph) | Senior Software Engineer (BE), Foundations | `UDQ1PD1H6` | joe.ellis@bstock.com | America/New_York | `joe.ellis` (43) | `70121:46cb1856-1239-4833-b2b8-599729de54e8` |
| Cy Kong (Cyrus) | React Engineer / epic lead, Foundations | `UJBMM6K4N` | cyrus@bstock.com | America/Chicago | `Cy-Kong` (48) | `5cb8e545b01aec0e591d6c55` |
| Alex Garcia (Pingboard: Javier Garcia Godinez) | Software Engineering Lead, Logistics & Finance | `U013Y1Y4G5C` | alex.garcia@bstock.com | America/Chicago | `alex.garcia` (100) | `5ec7f4036c50620c1cb0fc61` |
| Helen Foutch | Software Engineer (FE/full-stack), Buyer pod | `U99JLJBDZ` | helen@bstock.com | America/Chicago | `helen` (16) | `5afb0999d1d9445cd3a60343` |
| Waldemar "Waldek" Dziubek | Senior React Engineer, Seller pod — contracts-service expert | `U075L0TF7PS` | waldemar.dziubek@bstock.com | ? | ? | ? |
| Patrick Spracklen (legal "Justin") | Senior Data Engineer — AI Code Reviewer owner | `U06LH6G34DS` | patrick.spracklen@bstock.com | America/Los_Angeles (WA) | ? | ? |
| Aziz Vahora (Azizahmed) | Senior Director, Data Engineering (Campfire GA4 program) | `U0B6WG6BK9A` | ? | ? | ? | ? |
| Damien Jones (he/him) | Enterprise Architect | `U017YNCAP5G` | damien@bstock.com | America/New_York | `damien` (118) | `5f21dc81c9c094001c65cbd5` |
| Parvinder Bhasin | Director, DevOps (& Cybersecurity per Slack) | `U02PYTURXEH` | parvinder@bstock.com | Asia/Kolkata | `parvinder` (248) | `61b13eeed2e64c0071d5f478` |
| Orest Stetsiak | Senior DevOps Engineer | `U01DR3HGCF5` | orest@bstock.com | America/Los_Angeles | `orest` (123) | `5f9c7417c9b15a0078c56736` |
| David Chan | Senior Site Reliability Engineer (access grants) | `U016YQB317Y` | david.chan@bstock.com | America/Los_Angeles | `david.chan` (117) | `5f0f485d9d9a120029526368` |
| Susan Oakes | Technical Project Manager (releases) | `UHBPZ9SUB` | susan@bstock.com | America/Los_Angeles | `skoakes` (55) | `5ca524d1bb353819f2b5ebac` |
| Sohil Sethi | Manager, QA Engineering | `U01M2C9DRS4` | sohil@bstock.com | Asia/Kolkata | `sohil` (152) | `60144967e3a14d0071f45c3b` |
| Anthony Lombardo | QA automation engineer | `U05QBEQGE0N` | anthony.lombardo@bstock.com | America/New_York | `anthony.lombardo` (402) | `712020:aa4eb023-2612-4f9b-bfd5-37675c2f7dbf` |
| Jon Paul Hutchins | Solutions Engineer \| Resident IT Admin | `U01SWFMS1JA` | jonpaul@bstock.com | America/Los_Angeles | — (no GitLab) | `606600c2aee24000688b510c` |
| Fred Leung | Senior UX Designer (design system, parcel) | `U0A0Y5MRHSL` | frederick.leung@bstock.com | America/Los_Angeles | `frederick.leung` (626) | `712020:0accc665-be14-4f4c-9914-796fffa4d0ca` |
| Lana Kukharchyk (Sviatlana) | QA Engineer — P0/P1 escalation voice | `U080N3NKSFJ` | lana.kukharchyk@bstock.com | America/New_York | ? | ? |
| Volodymyr "Vova" Kelembet | Sr SWE (BE — order-process, ETL), Foundations | `U01P9BBHKBN` | volodymyr@bstock.com | Europe/Helsinki | ? | ? |
| Tim Foster | **EXTERNAL** — Campfire Analytics (GA4 spec) | `U4W4M341X` | tfoster@campfireanalytics.com | ? | — | — |

**Name disambiguation** (verify before acting on a bare first name):

- "Paul" → Paul Robertson (`U065LP1M6UX`; legal/Pingboard name **Homer Robertson**), not Paul Angeles (`U075W4W0VDX`, Asia/Chongqing tz, not in Pingboard, no GitLab/Jira activity).
- "Joe" → Joe Spandrusyszyn ("Joe S.") or Joe Ellis depending on context (FE/tooling vs BE/parcel). Joseph Dube (`U9B885U90`, Amsterdam) is **Director, Account Management** (Logistics org — not engineering; GitLab deactivated).
- "Sarah" → Sarah Xu (PM). Sarah Robinson (`U08MNCH285Q`, Denver) is an **Operations Specialist** in Client Operations.
- "Helen" → Helen Foutch (engineer, Buyer pod). Helen Holyk (`U02DM3XAWQ6`, UX Designer, Europe/Amsterdam, UXD project) is a different person.
- "Anthony" → Anthony Lombardo (QA automation). Anthony Campetti (`U05MCB9H34Y`) is an **Account Manager** under Don Anderson.
- "Alex" → Alex Garcia (engineer; probably "Javier Garcia Godinez" in Pingboard). `alex@bstock.com` (Slack `UCF85FWRW`) is **Alexander Cadalso — Lead Product Manager** under Kenny Fung (Strategy & Biz Ops), who does product/business-rules work on SP/XLTR. Alex Vasylyk (`alex@startupsoft.com`) is an external contractor account.
- "Ken" → Ken Shum (VP Eng). **Kenny Fung** is VP Strategy & Business Operation (a different executive). Searching Slack for "Cy" false-positives on Parvinder (matches "Cybersecurity").
- "Jay" → Jay (Jeroen) Hormes, Director of Analytics.
- "Mike"/"Michael" is heavily overloaded: Mike Greiling, Mike Feldman (Buyer pod SWE), Mike Ruth (Backend Engineering Lead, Seller/Inventory), Mike Talimonchuk (contractor), Michael Ilchuk (contractor).
- "Susan"/"Sohil" pair on releases: Susan = release manifests/PjM; Sohil = QA cycles.

## Dossiers

Format: what they do → when to reach out → surfaces (DM channel IDs are stable caches) → dated snapshot of recent collaboration.

### Leadership

**Ken Shum — VP of Engineering** (reports to CEO Marcus Shen; 13 direct reports). Drives the AI-automation and velocity agenda; administers AI tooling spend (OpenAI org billing, Claude MAX/Team right-sizing with Mary + Patrick Spracklen); hands-on in Data Engineering (DET project: BigQuery, agentic-QA infra). Assigns work to directors in `#monday-am-huddle`. Reach out for: AI subscription/licensing needs, escalations above director level. Surfaces: DM `D096EB8KT46`; group DM with Damien + Mike `C0B849UFBPC` (GA-events backend workstream). Snapshot 2026-06-03: chased the backend GA-event meeting outcome; 2026-07-10 asked the guild for token-usage data to right-size subscriptions.

**Yang Luan — Senior Group Product Manager** — heads the entire Product & UX Design org (Sarah Xu, Fred Leung, Alyssa Shum, Anushka Jain, Amara Mir, Austin Jones report to Yang) and acts as Seller-pod PM; 3MP product leadership (Fred: "our fearless leaders", of Yang + Ken). Seller-facing data/migration escalations, marketplace-integration roadmap. Escalation pattern to anticipate: `@here` screenshot spot-checks in `#foundation-pod` ("Did we work on this?"). Rarely DMs — engage in `#3mp-migrations`, `#foundation-pod`, or group DMs. Snapshot: last direct thread with Mike Nov 2025 (disputes CSV export).

**Mary Gutierrez (she/her) — Director of Engineering, Buyer pod** (7 reports: Alexandra Ash, Cole Allan, Mike Feldman, Yury Herlovich, Helen Foutch, Eric Chu, Bryan Lopez). Gatekeeper for Google Analytics admin, LD flag retirement, Bug Triage Agent; co-manages AI budget lists with Ken. Reach out for: GA/analytics access, buyer-pod coordination, flag-removal blessings. Surfaces: DM `D06AV0BMD1U` (active), `#team-buyer-pod`, `#ai-engineering`. Snapshot 2026-07-24: granted Mike GA admin; 2026-07-21 blessed removing the Zoom-chat-widget LD flag.

**Justin James — Senior Director of Engineering, Foundations pod** (reports: Acker Apple, Kai DiRamio, Paul Robertson, Ary Baldioceda, Susan Oakes, + one unnamed Orders-engineering slot). Ex-Mula lead. Deep backend/data-model authority (NetSuite POs, seller-proceeds, order amounts, AlloyDB, Canadian tax). Owns FP board 678 config; triages P0s in `#foundation-pod`; excellent router to the right owner. Reach out for: payments/orders domain questions, board/process issues, "who owns this?" routing. Surfaces: DM `D06QLD6CWBF` (low volume, high value), leads group DM `C0B6J1HQGHY`. Snapshot 2026-06-09: routed Mike — contracts → Waldek, prod service account → David Chan.

**Alvaro Ferreira — Director, Engineering; Mike's manager** (ex-Sprinters lead; reports: Joe Ellis, Alex Garcia, James Han, Cy Kong, Mike, Sohil Sethi). Owns Mike's priority stack and sprint ceremony (retros, demo rotation); arbitrates priority conflicts; watches prod infra; enforces LD-flag discipline. Weekly 1:1. Reach out for: prioritization, PTO, anything blocking. Surfaces: 1:1 DM `D0664RHDF9D` (primary, terse, directive); group DM with Joe Ellis `C079FD6GZEH` (parcel/epic handoffs). When he's on PTO, Sohil is his designated contact. Snapshot 2026-06-30: rescheduling the 1:1 around Mike's PTO; BUGS-5341 merge reported; Mike pitched the Claude bug-repro-video workflow.

**Al Veitas (Algirdas) — Senior Director, Engineering, Seller pod** (Boston; reports: Waldek Dziubek, Mike Ruth, Joe Spandrusyszyn, Connor Finley). Ex-"TBD" team lead. Seller integrations/migrations (AT&T AOMP cutover, T-Mobile/Samsung/GameStop mobile migration, COPS, Sunrise/Magento). De-facto chair of Deck Shuffle; drives 3MP Weekly Defect Triage rotation. Runs Claude himself — posts agent-authored RCAs to `#team-seller-pod`. Reach out for: seller-pod scope, migration timelines, defect-triage. Surfaces: DM `D06DAKAMZC2`, leads group DM `C0B6J1HQGHY`, `#3mp-tactical-planning`. Snapshot 2026-05-28: seller-portal ship-to-address P0 → BUGS-5202.

**James Han — Senior Engineering Manager** (reports to Alvaro; his own reports: Tim Tate, Jorge Castillo, Patrick Fisher — who do Buyer-pod work; ex-Sprinters sub-lead for ENT integrations/Sunrise/contracts). Release-blocking bug triage and incident comms (ran the 2026-05-04 outage war room); drove the React+Next upgrade merge decision. Makes "does this block the release" calls with Susan + Sohil. Reach out for: buyer-pod release risk, incident coordination. Surfaces: DM `D0773H3LTA5` (sparse), leads group DM `C0B6J1HQGHY`, `#3mp-bug-triage-team`.

### Mike's day-to-day peers (Foundations pod + org-wide FE)

**Joe Spandrusyszyn — Principal Software Engineer; senior-most FE; Mike's closest senior peer.** Reports to Al Veitas — **Seller pod, not Foundations** (never in Foundations meetings) — but operates org-wide on FE platform concerns. FE platform & tooling: Vitest migration, Node/React/Next upgrades, dependency hygiene, CI consolidation, Datadog log cleanup, CSP triage. Co-curates Optimization Cabal; one of two `common/ci` approvers (the other is Mike). Go-to for important FE-architectural decisions and DX changes. Surfaces: DM `D066H7SSFK9` (frequent, informal), group DM with Paul R `C066XPKEAEN` (FE tech-debt strategy), group DM with Parvinder + Orest `C0BERD4144D` (GitLab/CI governance). Snapshot 2026-07-15: asked Mike to take the Cylance remote session; on vacation until ~2026-07-27.

**Paul Robertson (legal name Homer Robertson) — Staff Software Engineer; the org's AI-tooling thought leader.** Reports to Justin James (ex-Mula). Owns `common/agent-skills` repo structure; co-runs ai-guild (Mike is backup host); AI code-reviewer rollout; Jest-transform perf. Heavy in `#ai-engineering`, `#mr-ai-agent-tiger-team`. Also looped in by Parvinder/Ken for Cloudflare/Turnstile bypass validation. Surfaces: DM `D0692M1E77E` (light), group DMs `C066XPKEAEN` (Joe S), `C09LDUNP1EH` (Alex Garcia, agent-skills). Snapshot 2026-06-26: agent-skills MR !79 debate; handed ai-guild hosting to Mike.

**Joe Ellis — Senior Software Engineer (BE), Boston.** Reports to Alvaro; ex-Sprinters. Mike's highest-volume backend counterpart: order-process, shipment/Shippo parcel rates, listings-summary, NetSuite item provisioning, shipping-insurance backend (GLOB-4613). Feeds Mike the FE side of parcel epics. Runs Claude for backend spelunking. Surfaces: group DMs `C079FD6GZEH` (with Alvaro), `C0BAVNNQ2GP` (with Alex Garcia + Volodymyr, parcel/Shippo), `C09JKAFSW8G` (with Cy). Snapshot 2026-06-30: flagged GLOB-4613 insurance epic entering technical review.

**Cy Kong (Cyrus) — React Engineer, ex-Sprinters.** cs-portal, home-portal, CSP config, quotes endpoints; epic-level owner of the Enterprise-systems decommission (GLOB-4017/4922). Mike's mutual MR-approval pact partner. Surfaces: DM `D066KTSBF7C` (daily-ish), `#fe-guild`. Snapshot 2026-07-24: raised (unanswered) rising post-merge CI failures across cs-portal/home-portal in `#fe-guild`.

**Alex Garcia — Software Engineering Lead, Logistics & Finance** (Pingboard prints "Javier Garcia Godinez" — probable same person). Ex-Sprinters BE. Disputes service, ERP/NetSuite billing reliability (GLOB-4942), stuck-loads autofix, risk service. Active AI-tooling contributor (agent-skills). Surfaces: group DMs `C09LDUNP1EH` (agent-skills, with Paul R), `C0BAVNNQ2GP` (parcel), `C09R0QDRMPU` (disputes). Snapshot 2026-06-26: conceded to Mike's blocking feedback on agent-skills MR !79.

**Waldemar "Waldek" Dziubek — Senior React Engineer; contracts-service expert** ("he's the guy" — Justin). **Seller pod** (under Al Veitas, not Foundations), even though the contracts service falls inside Foundations' documented domain boundary — cross-pod consultation is normal here. Also in an AI/process group DM with Joe S + Paul + Mike. Reach out for anything touching the contracts service.

**Volodymyr "Vova" Kelembet — Sr SWE BE** (Europe/Helsinki — async). Order-process + ETL; CI validation for Orest. Ex-Sprinters; not in Pingboard (possible contractor).

**Others in the pod orbit:** Acker Apple (SWE Payments, ex-Mula), Kai DiRamio (SWE, ex-Mula), Ary Baldioceda (SWE, ex-Mula), Patrick Fisher + Jorge Castillo (Senior SWE React, under James Han — Buyer-pod work), Tim Tate (Backend Engineering Lead, under James Han), Mike Talimonchuk (contractor, Asia/Jerusalem), Connor Finley (Software Engineering Lead, now under Al/Seller), Mike Ruth (Backend Engineering Lead — Inventory, under Al).

### Buyer pod

**Jeremy Walton — Director, Product Buyer Experience & Growth** (Geethika Kilaru, Senior PM, reports to him). Buyer product: First Dibs (GLOB-4598), Hot Deal/FMV badging, LDP redesign, watchlist, marketing-tracking features. Gives product go-ahead on LD flag flips; trialing LD data-export. Surfaces: `#team-buyer-pod`, group DM `C0A966PKSJ1` (with Mary + Alvaro — OneTrust/chat-widget). Snapshot 2026-07-17: approved re-enabling a flag in soft mode.

**Helen Foutch — Software Engineer (FE/full-stack), high-velocity.** Under Mary; ex-Zero. fe-core + home-portal daily; owns big features end-to-end (Auction Close Schedule "TV Guide", GLOB-4495); design-system implementation with Fred. Alvaro held her and Paul up as the velocity exemplars (>40 pts). Surfaces: DM `D07A1MVM1EZ` (light), design-system group DM `C0B98AJA3GX` (with Fred + Alyssa Shum).

**Alexandra Ash — Senior SWE (Shipments)** — authored the Buyer Pod Tech Support Procedures and the LD flag process; owns flag-removal tickets; buyer-pod support rotation (with Mike Ruth, Yury, Eric Chu, Mike Feldman, Patrick Fisher, Jorge). **Mike Feldman, Yury Herlovich, Eric Chu, Bryan Lopez, Cole Allan** — Mary's engineers (see org chart above).

### DevOps / Data / QA / Release / IT / Architecture

**Parvinder Bhasin — Director, DevOps** ("& Cybersecurity" per Slack; India tz, works odd hours, offers day-or-night phone escalation). Cloudflare WAF/bot rules, GitLab tier/licensing decisions, SAST/dependency-scanning policy, GCP IAM audits. Surfaces: group DM `C0BERD4144D` (with Orest + Joe S + Mike — the standing CI/GitLab governance channel), `#tech-operations`. Snapshot 2026-07-02→10: SARIF/vulnerability-view work with Mike + Joe.

**Orest Stetsiak — Senior DevOps Engineer, hands-on CI operator.** GitLab upgrades, runners/job-token auth, `common/ci` pipeline config (needs Mike's or Joe S's approval on his MRs), FusionAuth updates on dev/qa, Datadog alert triage, Helm/deploy tuning. Ran the 2026-06-03 legacy-channel retirement wave. Surfaces: `C0BERD4144D`, `#tech-operations`, `#3mp-datadog-alerts-prod`. Snapshot 2026-07-10: DOCKER_AUTH_CONFIG removal verified clean.

**David Chan — Senior Site Reliability Engineer.** The access-grant person: app-level roles (granted Mike seller-admin), Jira permissions (fixed Mike's PS-project commenting), prod service accounts; also executes seller-onboarding/warehouse infra scripts (often at Susan's direction), GDPR deletions. Purely transactional DM `D067AGLBRAM` — state the request plainly. Snapshot 2026-06-10: permissions verified working after two rounds.

**Susan Oakes — Technical Project Manager** (official; Slack title "Senior Release Manager & PM"). Reports to Justin James. Compiles the production deployment manifest for approval; schedules patch releases; writes Confluence release notes; heads SoS; runs many Foundations meetings. Coordinate with her so related MRs land in the same manifest. ⚠️ **No GitLab account** — always brief her in Slack prose. Surfaces: DM `D0B1ZAWDACR`, group DMs with Mary `C0ALMA1ND5W` and Sohil `C0AJNCBKGTV`. Snapshot 2026-05-27: walked her through the fe-core→seller-portal→deploy CI chain for a hotfix.

**Sohil Sethi — Manager, QA Engineering** (reports to Alvaro; team: Olga Chmikhun, Gavin Grooms, Lana Kukharchyk, Daria Kazhybay + the Evizi vendor). The ping for QA priority: starts test cycles (wants Jira IDs + service/version pairs), assembles hotfixes, schedules patches with Susan. Alvaro's designated stand-in contact during his PTO. Also personally picks up BUGS fixes. Surfaces: DM `D098W2BV33J`, `#foundation-pod` (constant). Snapshot 2026-03-11: fast-tracked FP-632 re-review.

**Anthony Lombardo — QA automation.** Warm, jokey rapport with Mike; happy to bounce ideas off. Owns `qa/quality-live-portal`, the confidence dashboard (`automation.bstock-qa.com/confidence`), the "Atlas" contract sweeps and Agentic Tester (QA-2054); first-line debugger of the AI Code Reviewer (found the MRs-titled-"drafts" trigger bug). NOT the person for manual QA-review audits — that's Sohil's org. Not present in the Pingboard export (possibly a contractor). Surfaces: DM `D06M3CZMB6W` (frequent, casual), `#mr-ai-agent-tiger-team`. Snapshot 2026-07-21: granted Mike access to quality-live-portal.

**Patrick Spracklen — Senior Data Engineer** (under Aziz Vahora; legal first name "Justin" per Pingboard card — always use Patrick). Washington state (GMT-8); started 2024-02-26; birthday Aug 2. Owns the AI Code Reviewer bot and Claude MAX plan pooling. Ping when the AI reviewer stops firing (Anthony first-line, Patrick owner).

**Aziz Vahora (Azizahmed) — Senior Director, Data Engineering.** Owns the data-engineering + analytics org (Patrick Spracklen; Jay Hormes's analytics team). Internal program owner for the Campfire GA4 offline-events work — coordinates external access, asks Mike to compile spec answers into stories.

**Jon Paul Hutchins — Solutions Engineer / Resident IT Admin** (under Parvinder). IT tickets via service-desk portal 15; Cylance/Arctic Wolf endpoint compliance, hardware, credential management (Delinea), phishing, Zoom account provisioning (Mike's paid Zoom = IT-2236). Self-declared scope limit: does NOT manage app dependencies — those go to `#tech-general`. Escalation-matrix phone: 415-320-7017, 9–5 PST.

**Damien Jones (he/him) — Enterprise Architect.** Final say on data model and service boundaries: listing/order/auction canonical identity (**`listing_id` is canonical, never `auction_id`** — directly relevant to GA4/Campfire work), pricing strategy, relist semantics, FIXED_TERMS/SPOT modeling. Get his sign-off on major data-model proposals, including anything Campfire suggests schema-wise. Thin Jira presence (works above ticket level) — engage in `#foundation-pod` or group DMs `C0B849UFBPC` (Ken + Mike), `C0BAPCDFH1B` (Campfire).

### Design / UX / Product (all under Yang Luan except Jeremy's org)

**Fred Leung — Senior UX Designer** (reports to Yang). Design system (FP-1973/FP-2005 color+typography), platform-wide copy consistency. Fast same-day turnaround on UX review asks. Notably piloting Claude Code + Storybook MCP himself (Mike is his setup buddy). Surfaces: DM `D0A7FL9691S`, parcel-copy group DM `C0BKD5JMJSJ` (with Sarah Xu), design-system group DM `C0B98AJA3GX`. Snapshot 2026-07-23: approved/tightened the shipping-insurance disclosure copy for home-portal !2320 within the hour.

**Sarah Xu — Senior PM (3MP parcel, seller/migrations; candidate Foundations-pod PM).** Owns product copy sign-off and vendor decisions (passed on Shippo 2026-07-23); sets migration cutover dates; LOE-vs-scope calls. Surfaces: group DM `C0BKD5JMJSJ` (with Fred). Snapshot 2026-07-23: closed the last open parcel-insurance copy item.

**Austin Jones — Senior Product Manager, Payments** (under Yang; in `#foundation-pod`). The other candidate for "Foundations pod PM" — title says Payments, which is half the pod's name. Worth confirming with Mike.

**Others:** Anushka Jain (Senior Product Designer — Seller designs with Fred), Alyssa Shum (Associate Product Designer — design-system launch messaging), Amara Mir (UX Researcher — Q3 UXR epic), Helen Holyk (UX Designer, Amsterdam — UXD project), Geethika Kilaru (Senior PM under Jeremy), Neil Zhu (UX — CS-portal filters, Oct 2025), Vajira Nissanka (Figma access).

### External

**Tim Foster — Campfire Analytics** (`tfoster@campfireanalytics.com`, Slack Connect via `#bstock-campfire` `C09V4EF0F3J` and group DM `C0BAPCDFH1B`). Owns the GA4 offline-events spec. Mike is the engineering liaison; **Aziz Vahora** is the internal program owner. ⚠️ Snapshot 2026-07-24: Tim has followed up twice (07-14, 07-22) awaiting Mike's reply on the GA4 offline-events thread.

**Evizi — Vietnam-based QA vendor** (see QA org & timezones above): Anh Nguyen, Vinh Tran (QA PM), Lam Nguyen, Thanh Nguyen. Treated conversationally as a team name ("Evizi runs regression", "Evizi will be on leave").

### Departed but still referenced

Policy (per Mike, 2026-07-24): **keep lingering dossiers on departed employees** — their work keeps surfacing in audit trails, git blame, Confluence authorship, and past decisions. When someone leaves, move their entry here (with their old IDs) rather than deleting it.

**Ryan Jenkins** (`U01N2L2LS0Z`, Principal SWE FE on team Zero; left ~Jan 2026) — previous owner of GTM, Google Analytics, the SEO-agency relationship, and the Deck Shuffle seat Mike inherited. Made Mike GTM admin on the way out; the GA-admin gap was closed by Mary 2026-07-24. His name still appears on onboarding docs and old GTM/SEO group DMs.

**Daehee Kim** — **departed (confirmed: Slack account deactivated)**. Was Director, Data Engineering (led the Data Eng team on the Jun-2025 roster: Mark Ma, Harish Verlekar, Patrick Spracklen, Louies Tam, Gavin Lang). Aziz Vahora now heads Data Engineering & Analytics.

**Elias Amador** (ex-Mula SWE) — on the 2025 roster, absent from the chart and from recent activity.

## Extended roster — FE guild & pod channels

`#fe-guild` (`C04225G5QCS`, 61 members) and `#foundation-pod` (`C09G5BQDEJD`, 52 members) overlap heavily. Beyond the people above, the review-network regulars in `#fe-guild`: Patrick Fisher (`U06LENC7SE6`), Jorge Castillo, Bryan Lopez, Cole Allan, Michael Feldman, Andrii Prasolov (FE contractor, Asia/Jerusalem), Shivam Bandral (FE contractor, Asia/Kolkata), Yury Herlovich, Michael Ilchuk (BE contractor, Europe/Helsinki), Mike Talimonchuk, Ashish Tulsankar (Asia/Kolkata), Ary Baldioceda, Acker Apple (`U01DMD45AKV`), Igor Shkulipa (Asia/Jerusalem), Josh Mozley (contractor), Sriram Sridhar (Data Analyst), Tim Tate, Alexandra Ash, Kai DiRamio, Calvin La, Sachin Jagtap (Asia/Kolkata), Amit Negi (Asia/Kolkata), Eric Chu, Gavin Grooms (QA), Geethika Kilaru (PM). Non-engineering members of `#foundation-pod` worth knowing: Gary Fewkes (Sr. Director Customer Service — under VP Marketing Kylee Hall), Jay Hormes (Director, Analytics), Stanley Ho (Senior Data Analyst), Jesseca Frazier (Operations Specialist, Client Ops). A `bug-fix-loop` bot posts review requests and stale-approval nags to both channels (since 2026-07-23). Emails follow `first.last@bstock.com` or `first@bstock.com`; resolve Slack UIDs on demand with `slack_search_users`.

## Access requests & IT support — processes

- **IT support tickets**: [service desk portal 15](https://bstock.atlassian.net/servicedesk/customer/portal/15) (facilities = portal 22). Owner: Jon Paul Hutchins. Use for hardware, Cylance, SaaS provisioning, account requests (e.g. Zoom).
- **GitLab account/repos**: manager emails `devops@bstock.com`.
- **Datadog**: automatic via the `dev@bstock.com` distribution list.
- **CAS / DSK / Teleport (prod SSH)**: `techsupport@bstock.com` or `devops@bstock.com`.
- **LaunchDarkly**: ask in `#feature-flags-launchdarkly`; flag lifecycle docs: "Feature Flag Process (Buyer Pod)" + "Feature Flag How-To's" (Alexandra Ash).
- **Figma**: Vajira Nissanka. **Qase**: email the QA team.
- **App-level roles / Jira permissions / prod service accounts**: DM David Chan.
- **GTM / GA / Sentry**: no documented process — GTM is Mike's own admin domain; GA goes through Mary; Sentry ask DevOps/`#tech-general`.
- Key Confluence anchors: [Engineering roster](https://bstock.atlassian.net/wiki/spaces/EN/overview) (stale Jun-2025, legacy team names — but the authoritative legacy-team rosters), [Buyer Pod Tech Support Procedures](https://bstock.atlassian.net/wiki/spaces/EN/pages/3908403201) (current pod boundaries), [FE Onboarding](https://bstock.atlassian.net/wiki/spaces/EN/pages/2663972959), [DevOps Escalation Matrix](https://bstock.atlassian.net/wiki/spaces/TO/pages/2729246813), [IT Help Desk space](https://bstock.atlassian.net/wiki/spaces/it/overview).

## Known unknowns / open questions

- **Foundations pod PM**: unconfirmed — Sarah Xu vs Austin Jones (Senior PM, Payments); possibly split. Ask Mike.
- **Anthony Lombardo's employment status** (absent from Pingboard; possibly the blank Orders-engineering card or a contractor).
- **Justin James email discrepancy**: `justinjames@` (Slack/GitLab) vs `justin.james@` (Jira) — same person, two formats on file.
- **Zero→Buyer and TBD→Seller mappings** are inferred (only Sprinters/Mula→Foundation is explicitly documented via channel redirects).
- Missing IDs marked `?` in the identity table — fill opportunistically.

Resolved 2026-07-24 (kept for audit): Spracklen "Justin"=legal/"Patrick"=preferred ✓; Javier Garcia Godinez=Alex Garcia ✓; Daehee Kim departed ✓ (Slack deactivated); Joe S + Waldek are Seller pod, not Foundations ✓.
