# B-Stock three-mp MR Approval Rules (cached 2026-05-26)

Who must approve a merge request, per project, for the active `b-stock/code/three-mp` estate.

## How to read this

- **Any-member (N)**: the "All Members" `any_approver` rule — needs N approvals from *any* project member with Developer+ role. Not enumerated (it's the whole project membership).
- **Named rules** (SMEs, Code Review, Lead, Default approvers, etc.): need approval from a specific list. **Only rules with required > 0 block the merge.** Rules marked *(optional)* require 0 and are just a suggested reviewer pool.
- **Code owners**: file/directory-specific approvers from the repo's `CODEOWNERS` file.
- The **`ai-code-reviewer`** bot auto-approves and fills one any-member slot on most repos. That's live state, not a rule — ignore it when reasoning about who *can* approve.
- **Blocked/inactive users** appear in some lists but can't approve: `ryan.jenkins` (155, blocked), `mgreiling` (420, inactive — Mike's old account; use `mike.greiling`/421).

## Limitations / freshness

- There is **no project-level approval-rules API**; each project's rules were read from one recent MR's snapshot on 2026-05-26. Re-verify with `GITLAB_HOST=gitlab.bstock.io glab api "projects/:id/merge_requests/:iid/approval_state"` on any MR if rules may have changed.
- `fe/dsk` and `fe/sunrise` were sampled from MRs with `approval_rules_overwritten: true`, so their listed rules may be MR-level overrides rather than the project default.
- `common/ci-libs`, `common/ci-pipelines`, `common/ci-tools` have **zero MRs**, so their rules can't be observed yet — recheck once they get a first MR.

## Handy shortcuts

- **Al Veitas (`@al`, 184)** is in nearly every named rule across three-mp — the safest single ping when a project has an SME/Lead/Code-Review gate.
- The recurring **"SMEs"** rule (account, auction, docserv, saved-search, search, watchlist, location, skeleton-nestjs) almost always contains the core **`@alexandra`, `@michael.ilchuk`, `@yury`, `@al`** (usually `@mary` too) — one of those clears the SME slot on those projects.

## Required approvers by project

Legend: ✓ = checked out under `bstock-projects/`. "req" = approvals required.

### svc/

| Project | ID | ✓ | Required to merge |
|---------|----|----|-------------------|
| svc/account | 522 | ✓ | any-member (2) + SMEs (1 of: mary, alexandra, michael.ilchuk, yury, al, cole, michael) |
| svc/api-client-generator | 614 | ✓ | any-member (1) + SMEs (1 of: alvarobstock, alexandra, michael.ilchuk, yury, al, justinjames, joshua.mozley, joseph.spandrusyszyn) |
| svc/auction | 582 | ✓ | any-member (2) + SMEs (1 of: mary, alexandra, michael.ilchuk, yury, al). *Default approvers optional.* |
| svc/bridge | 607 | ✓ | any-member (2) |
| svc/contract | 759 | ✓ | any-member (1) |
| svc/crosslisting | 887 | ✓ | any-member (1) + Lead (1 of: damien, al, joseph.spandrusyszyn, mike.greiling, serhii.ovcharenko) |
| svc/dead-letter | 831 | ✓ | any-member (2). Code-owners: `*` → @three-mp team *(optional)* |
| svc/dispute | 504 | ✓ | Code Review (2 of: mary, alvarobstock, alex.garcia, david.chan, acker, ary, igor, volodymyr, al, justinjames, umesh, joshua.mozley, parvinder, kai, ashiash, anthony.lombardo, paul). *No any-member req.* |
| svc/docserv | 565 | ✓ | any-member (2) + SMEs (1 of: mary, alexandra, michael.ilchuk, yury, al, cole, michael, kai). *Default approvers optional.* |
| svc/erp | 605 | ✓ | Code Review (2 of: alvarobstock, joe.ellis, alex.garcia, david.chan, acker, igor, volodymyr, al, justinjames, umesh, joshua.mozley, parvinder, kai, ashiash, paul). *No any-member req.* |
| svc/ingestion-nestjs | 661 | ✓ | any-member (2) + Team TBD Minimal Approvers (1 of: michael.ruth, al, justinjames, umesh, calvin, joseph.spandrusyszyn, waldemar) |
| svc/integration | 770 | ✓ | any-member (1) |
| svc/listing | 628 | ✓ | any-member (2) + Team TBD Minimal Approvers (1 of: michael.ruth, al, justinjames, umesh, calvin, amit, joseph.spandrusyszyn) |
| svc/location | 546 | ✓ | any-member (2) + SMEs (1 of: mary, alvarobstock, alexandra, michael.ilchuk, yury, al, umesh, cole, michael). Code-owners: `*` → @three-mp team *(optional)* |
| svc/notification | 576 | ✓ | Default approvers (2 of ≈ entire three-mp team). *No any-member req.* |
| svc/offering | 735 | ✓ | any-member (2) |
| svc/order | 515 | ✓ | any-member (2) + code review (2 of: mary, alvarobstock, alexandra, joe.ellis, alex.garcia, david.chan, acker, ary, igor, volodymyr, al, justinjames, umesh, joshua.mozley, parvinder, kai, ashiash, anthony.lombardo, paul). *Has a code_owner `*`→three-mp rule but no CODEOWNERS file at standard paths.* |
| svc/order-process | 722 | ✓ | code review (2 of: mary, alvarobstock, joe.ellis, alex.garcia, david.chan, acker, ary, igor, volodymyr, al, umesh, joshua.mozley, kai, ashiash, paul, waldemar). *No any-member req.* |
| svc/payments/methods | 520 | ✓ | any-member (1) + SME (1 of: acker, ary, igor) |
| svc/payments/payments-shared | 563 | ✓ | any-member (0) — **no required approval** |
| svc/payments/transactions | 519 | ✓ | any-member (2) |
| svc/pdf-gen | 626 | ✓ | any-member (2). *Default approvers optional.* |
| svc/risk | 802 | ✓ | any-member (2) |
| svc/saved-search | 798 | ✓ | any-member (2) + SMEs (1 of: mary, alexandra, michael.ilchuk, yury, al, cole, michael) |
| svc/search | 603 | ✓ | any-member (2) + SMEs (1 of: yury, joshua.mozley, kai, Cy-Kong, andrii.prasolov, michael.ilchuk, alexandra, cole, mary, al, calvin, michael, david.chan) |
| svc/shipment | 524 | ✓ | Default approvers (2 of: mary, alvarobstock, joe.ellis, alex.garcia, yury, volodymyr, al, justinjames). *No any-member req.* |
| svc/tms | 516 | ✓ | any-member (2) |
| svc/3mp-att-aomp-orders | 892 | ✗ | no approval rules defined (sampled MR had none) |
| svc/review | 583 | ✗ | any-member (2). *Default approvers optional.* |
| svc/seller-migration | 625 | ✗ | any-member (2) |
| svc/subscription | 577 | ✗ | Code Review (2 of: acker, ary, al, justinjames, umesh, joshua.mozley, parvinder, anmol, nihit). *No any-member req.* |
| svc/tax | 923 | ✗ | Default approvers (2 of: mary, alexandra, Cy-Kong, michael.ilchuk, david.chan, andrii.prasolov, orest, acker, yury, ary, al, joshua.mozley, calvin, cole, michael, parvinder, anmol, nihit, kai). *No any-member req.* |
| svc/watchlist | 561 | ✗ | any-member (2) + SMEs (1 of: mary, alexandra, michael.ilchuk, yury, al, justinjames, michael, joseph.spandrusyszyn) |

### common/

| Project | ID | ✓ | Required to merge |
|---------|----|----|-------------------|
| common/agent-skills | 840 | ✓ | any-member (1) + SME Approvers (1 of: mary, alvarobstock, alex.garcia, al, justinjames, paul, mike.greiling). Code-owners (path-specific, see below) |
| common/authorization | 528 | ✓ | any-member (2) + SMEs (1 of: mary, alexandra, michael.ilchuk, yury, al, justinjames, michael, joseph.spandrusyszyn) |
| common/ci | 685 | ✓ | any-member (2) |
| common/code-quality | 525 | ✓ | any-member (2). *(Formerly cached as `bstock-eslint-config`.)* |
| common/i18n-shared | 838 | ✓ | any-member (0) — **no required approval** |
| common/logging | 529 | ✓ | Code Review (2 of: mary, alexandra, mykhailo.talimonchuk, michael.ilchuk, acker, yury, al, justinjames, umesh, joshua.mozley, calvin, cole, michael, kai). *No any-member req.* |
| common/skeleton-nestjs | 514 | ✓ | any-member (2) + SMEs (1 of: mary, alvarobstock, alexandra, michael.ilchuk, yury, ~~ryan.jenkins~~ blocked, cole, michael) |
| common/dev-deps | 569 | ✗ | code review (1 of ≈ entire three-mp team). *No any-member req.* |
| common/nestjs-utils | 532 | ✗ | Required Approval Rule (1 of: mary, alvarobstock, mykhailo.talimonchuk, david.chan, acker, al, justinjames, parvinder, olga, anthony.lombardo, gavin.grooms, daria.kazhybay + common group). *No any-member req.* |
| common/qa-assistant | 897 | ✗ | any-member (2). *"current release?" rule optional.* |
| common/ci-libs | 820 | ✗ | undetermined (no MRs yet) |
| common/ci-pipelines | 819 | ✗ | undetermined (no MRs yet) |
| common/ci-tools | 821 | ✗ | undetermined (no MRs yet) |

### fe/

| Project | ID | ✓ | Required to merge |
|---------|----|----|-------------------|
| fe/accounts-portal | 400 | ✓ | any-member (2) |
| fe/cms-portal | 891 | ✓ | any-member (2) |
| fe/crosslister | 888 | ✓ | any-member (1) + Lead (1 of: damien, al, joseph.spandrusyszyn, serhii.ovcharenko) |
| fe/cs-portal | 721 | ✓ | any-member (2) |
| fe/fe-core | 506 | ✓ | any-member (2) |
| fe/fe-scripts | 544 | ✓ | any-member (1) |
| fe/home-portal | 768 | ✓ | any-member (2) |
| fe/seller-portal | 508 | ✓ | any-member (2) |
| fe/dsk | 41 | ✗ | any-member (0) *(MR-level override sampled; project default may differ)* |
| fe/sunrise | 61 | ✗ | any-member (1) *(MR-level override sampled; project default may differ)* |

## File/directory-specific code owners

Only these repos have a `CODEOWNERS` file:

- **svc/account**, **svc/dead-letter**, **svc/location** (`.gitlab/CODEOWNERS`, identical):
  - `*` → `@b-stock/teams/three-mp` (whole-team, required 0 / optional)
  - `CHANGELOG.md` → `@b-stock/common-ci-internal`
- **common/agent-skills** (`.gitlab/CODEOWNERS`) — the only repo with meaningful per-path human owners:
  - `/skills/`, `/scripts/`, `/plugins/bstock-common/` → `@@maintainer` (a role token, not a user)
  - `/plugins/paul-robertson/` → `@paul` (Paul Robertson, 419)
  - `/plugins/quality-engineering/` → `@anthony.lombardo` (Anthony Lombardo, 402) — **required 1** as a code_owner rule
- **svc/order** declares a `code_owner *` → `@b-stock/teams/three-mp` rule but no CODEOWNERS file was found at the standard paths (may be on a non-default branch or removed) — flagged for follow-up.

## User directory (username | real name | GitLab ID)

| Username | Real name | ID |
|----------|-----------|----|
| mary | Mary Gutierrez | 11 |
| alvarobstock | Alvaro Ferreira | 15 |
| helen | Helen Foutch | 16 |
| james | James Han | 19 |
| tim.tate | Tim Tate | 23 |
| alexandra | Alexandra Ash | 42 |
| joe.ellis | Joe Ellis | 43 |
| Cy-Kong | Cy Kong | 48 |
| michael.ruth | Michael Ruth | 52 |
| mykhailo.talimonchuk | Mykhailo Talimonchuk | 76 |
| michael.ilchuk | Michael Ilchuk | 78 |
| connor | Connor Finley | 87 |
| nate.patel | Nate Patel | 97 |
| alex.garcia | Alex Garcia | 100 |
| david.chan | David Chan | 117 |
| damien | Damien Jones | 118 |
| anh | Anh Nguyen | 119 |
| andrii.prasolov | Andrii Prasolov | 121 |
| orest | Orest Stetsiak | 123 |
| acker | Acker Apple | 124 |
| vinh.tran.cong | Vinh Tran | 126 |
| lam.nguyen.tung | Lam Nguyen Tung | 129 |
| yury | Yury Herlovich | 130 |
| thanh | Thanh Nguyen | 134 |
| ary | Ary Baldioceda | 154 |
| ryan.jenkins | Ryan Jenkins (blocked) | 155 |
| igor | Igor Shkulipa | 156 |
| volodymyr | Volodymyr Kelembet | 158 |
| joshua.andujar | Joshua Andujar | 170 |
| al | Al Veitas | 184 |
| justinjames | Justin James | 185 |
| umesh | Umesh Balasubramaniam | 193 |
| joshua.mozley | Josh Mozley | 207 |
| calvin | Calvin La | 208 |
| cole | Cole Allan | 210 |
| michael | Michael Feldman | 217 |
| parvinder | Parvinder Bhasin | 248 |
| anmol | Anmol Anand | 270 |
| nihit | Nihit | 281 |
| daehee | Daehee Kim | 292 |
| olga | Olga Chmikhun | 299 |
| amit | Amit Negi | 311 |
| kai | Kai DiRamio | 325 |
| joseph.spandrusyszyn | Joe Spandrusyszyn | 332 |
| ashiash | Ashish Tulsankar | 381 |
| anthony.lombardo | Anthony Lombardo | 402 |
| paul | Paul Robertson | 419 |
| mgreiling | (inactive — old Mike account) | 420 |
| mike.greiling | Mike Greiling | 421 |
| patrick | Patrick Fisher | 434 |
| patrick.spracklen | Patrick Spracklen | 435 |
| echu | Eric Chu | 444 |
| gavin.grooms | Gavin Grooms | 449 |
| waldemar | Waldek Dziubek | 450 |
| shivam.bandral | Shivam Bandral | 472 |
| jorge | Jorge Castillo | 487 |
| lana.kukharchyk | Lana Kukharchyk | 514 |
| gavin.lang | Gavin Lang | 559 |
| serhii.ovcharenko | Serhii Ovcharenko | 637 |
| kyryl.oliinyk | Kyryl Oliinyk | 644 |
| daria.kazhybay | Daria Kazhybay | 651 |
| danylo | Danylo Dzheniuk | 653 |
| bryan.lopez | Bryan Lopez | 656 |
| kateryna.konovalova | Kateryna Konovalova | 672 |
| oleksandr.skibinskyi | Oleksandr Skibinskyi | 677 |
