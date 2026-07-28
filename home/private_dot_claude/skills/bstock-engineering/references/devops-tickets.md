# Filing DEVOPS Tickets (infra & access requests)

How to request infrastructure and access changes from the DevOps team — GCP service accounts, cloud API enablement, BigQuery grants, IAM changes, and similar. Evidence-based as of 2026-07-28; confidence levels marked.

## When a DEVOPS ticket is the right mechanism

Anything touching B-Stock's Google Cloud org or third-party infra access that engineers can't self-serve: service-account creation, enabling cloud APIs on GCP projects, BigQuery dataset/job grants, credentials delivery into the services' secrets path. Verified precedents: DEVOPS-3698 (BigQuery access, 2025), DEVOPS-4287 (BigQuery access for Campfire contractor), DEVOPS-4760 (GCP service account + Data Manager API enablement, filed 2026-07-28).

## Who owns it

**Parvinder Bhasin** — Director of DevOps & Cybersecurity (`parvinder@bstock.com`, Slack `U02PYTURXEH`, Mike's DM channel `D07FLF8NESW`). He personally executes GCP/IAM grants. Historical note: **Daehee Kim (data engineering) used to approve the data-side grants and has left the company** — Parvinder absorbed that function (confirmed in #bstock-campfire, 2026-03-04: "it was Daehee who gave your team BigQuery access… Let me investigate," followed by him executing the grant). If a request is data-warehouse-flavored and old docs name Daehee, route to Parvinder anyway.

## The established two-step pattern

1. **File the ticket** — the ticket is the artifact DevOps acts on and the audit trail. Daehee's own instruction (verified, #team-data 2025-08-07): "Create a ticket with DEVOPS. I'll approve the ticket."
2. **Ping the owner on Slack with the ticket link** — observed grants in practice got unblocked through Slack conversation with the ticket as the anchor (the Campfire BigQuery grants played out in #bstock-campfire threads). A bare ticket with no ping risks sitting unnoticed; a bare Slack ask with no ticket has no artifact to execute against. Do both.

## Mechanics (verified by filing DEVOPS-4760 via acli)

- Project `DEVOPS`; issue type **Task** (type ids as of 2026-07-28: Epic 10000, Story 10010, Task 10006, Bug 10027, Sub-task 10007).
- Plain `acli jira workitem create --project DEVOPS --type Task --summary "…" --description "…" --json` works; no required custom fields surfaced at create time.
- Leave **unassigned** — it lands in their queue; the Slack ping provides the routing. Reporter (you) is the contact.
- No status transitions needed at filing time.

## What a good request body contains

- **The ask as a numbered list** of concrete deliverables (e.g. "1. service account X, 2. enable API Y on the project, 3. deliver credentials to the services' secrets path for dev/qa/staging/prod").
- **What you'll self-serve** — explicitly fence off the parts DevOps doesn't need to do (e.g. GA4 property grants when the requester holds GA4 admin). Shrinks their surface, speeds execution.
- **Precedents by ticket key** — cite the prior ticket(s) with the same shape (DEVOPS-4287, or a service already doing the thing, e.g. Sunrise calls Google APIs with SA credentials). Post-Daehee, context that used to live in someone's head must travel with the request.
- **Deadline context** with the driving reason (contract dates, epic key), not just "urgent."

## Not verified — do not assert

The DEVOPS project's internal status workflow, triage cadence, board setup, and any SLA are **unknown** (never inspected). If a filed ticket needs status tracking beyond "Parvinder replied on Slack," check the ticket's available transitions at that time rather than assuming the FP/GLOB workflow applies.
