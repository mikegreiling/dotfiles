# Setup / teardown — resource seeding (FUTURE EXTENSION POINT, not yet built)

Status: **stub.** `assets/demo-template/setup.ts` throws; `teardown.ts` is a no-op.
This file records the intent so a future session can fill it in (and is encouraged
to — see SKILL.md "self-revise").

## The problem
Some demos need a record in a specific shape that doesn't already exist:
- an **order** in a particular status (to demo order details / shipping / returns),
- a **dispute** (create listing → finalize → order → open dispute),
- a refund, a paid invoice, a multi-item cart, etc.

Today the workflow handles this by: seed the record **manually** (or via existing
`fe-scripts` commands), drop its ID into `demo.config.records`, and flag the gap.
That's fine for one-offs but not deterministic/replayable.

## Intended design (when built)
- `setup.ts` exposes an async `setup()` that **deterministically creates** the
  required resources and returns their IDs, so `demo.config.records` can be
  populated programmatically and a scenario can declare a dependency on it.
- Drive it via **`fe-scripts`** (the team's test-data CLI: `init-state`,
  `create-listing`, auction/contract/order/dispute flows) or direct API calls with
  the minted token. Reuse `fe-scripts` rather than reinventing seeding.
- `teardown.ts` cleans up disposable records (cancel order, close dispute, delete
  listing) so repeated runs stay clean.
- Wire `setup`/`teardown` into `demo.config` (currently `setup:null, teardown:null`)
  and call them from `global-setup`/a fixture.

## Known limitations to design around
- `fe-scripts` currently creates only **LTL** listings (transportMode hardcoded) —
  it cannot make Parcel listings. Order/dispute flows exist; verify the exact
  shape each demo needs.
- Seeding is environment- and account-specific (buyer-group visibility, etc.).

## When you build any of this
Codify it back into this skill (template `setup.ts` + this doc), then commit to
chezmoi. That's the whole point of the WIP ethos.
