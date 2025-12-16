---
name: noUncheckedIndexedAccess
description: Conservative, low-risk fixes for TypeScript errors introduced by enabling noUncheckedIndexedAccess, with different policies for test vs production code and a bias toward non-cascading changes.
---

# noUncheckedIndexedAccess Violation Resolver

Enable `noUncheckedIndexedAccess` while keeping changes **safe**, **local**, and **reviewable**.

`noUncheckedIndexedAccess` changes indexed access from `T` to `T | undefined` (arrays, objects with index signatures, `Record<...>`, etc.). This skill focuses on fixing the resulting type errors without turning the migration into a signature-changing domino chain.

## When to Use

Use this skill when you see TypeScript errors that appear after enabling `noUncheckedIndexedAccess`, commonly:

- TS2532: Object is possibly 'undefined'
- TS18048: 'x' is possibly 'undefined'
- TS2345: Type 'T | undefined' is not assignable to type 'T'
- TS2538: Type 'undefined' cannot be used as an index type

## Mode Detection: Tests vs Production

**Test files** (lower risk):
- Paths matching `**/*.test.*`, `**/*.spec.*`, `**/__tests__/**`, `**/test/**`
- Or files that clearly use test frameworks (`jest`, `vitest`) / Testing Library (`@testing-library/*`)

**Production code** (higher risk):
- Everything else, especially shared libraries and app runtime code

## Core Principles

1. **Local fixes beat cascading API changes**  
   Prefer local guards, defaults, and boundary validation over changing return types or parameter types.

2. **Production code: avoid unsafe assertions**  
   Do **not** use `as any`, `as unknown`, `as never`, or blanket `@ts-ignore` as a quick escape hatch.

3. **Tests have different ergonomics**  
   In tests, it’s acceptable to use:
   - non-null assertions (`!`) for ergonomics, especially after runtime expectations
   - test-only assertion helpers that narrow types (preferred over `!` for “type narrowing”)

4. **Suppressions must be deliberate**  
   - Prefer `@ts-expect-error` over `@ts-ignore` (because it self-invalidates once fixed)
   - In production code, `@ts-expect-error` must include a ticket + expiry date (or equivalent)

## Fix Policy

### Test Code Policy (preferred order)

1. **Use test helpers that narrow types**  
   See `references/test-helpers.md` for `expectString`, `expectDefined`, `at()`, etc.

2. **Use `!` for indexing after an explicit runtime assertion**  
   Example: `expect(rows).toHaveLength(2)` then `rows[0]!`.

3. **Use `@ts-expect-error` only for intentionally invalid test cases**  
   Avoid it for normal indexing/narrowing.

4. **Avoid `@ts-ignore`**  
   It disables type checking too broadly.

### Production Code Policy (preferred order)

1. **Defaulting** (`??`) when a sensible fallback exists  
2. **Guard/early return** when undefined is acceptable and local handling is correct  
3. **Throw with a clear error** when undefined is a programmer/configuration error  
4. **Tighten types** (e.g., restrict key unions, `as const` objects) when keys are known  
5. **Non-null assertion (`!`) only for true invariants** (and comment if non-obvious)  
6. **`@ts-expect-error`** only when the correct fix is genuinely structural and must be deferred (ticket + expiry required)

## Avoiding the “Spiral”

Before changing a function signature (e.g., returning `T | undefined` where it previously returned `T`), ask:

- Can we handle `undefined` locally at the call site?
- Is this value coming from a boundary (URL params, env/config, JSON parsing)? Validate once at the boundary.
- Would a signature change force many callers to change? If yes, prefer local handling or upstream validation.

Signature changes can be correct, but they must be *deliberate* and usually handled in a focused PR.

## Recommended Lint Guardrails

To prevent “`!` creep” in production code:

- Enable `@typescript-eslint/no-non-null-assertion` in production code (error or warn)
- Enable `@typescript-eslint/no-unnecessary-type-assertion` (type-aware) to catch some unnecessary assertions

Tests can override `no-non-null-assertion` to allow ergonomic `!`.

> Note: `no-unnecessary-type-assertion` requires type-aware ESLint (`parserOptions.project`, often via `tsconfig.eslint.json`).

## Workflow

1. **Confirm scope**: test vs production
2. **Classify the violation**:
   - array indexing
   - object index signature / `Record`
   - map/dictionary lookup
   - boundary data (config/env/user input)
   - falsy vs undefined confusion
3. **Apply the lowest-risk fix** using the policies above
4. **Run typecheck/tests** (or describe what should be run in the repo)
5. **Record the fix** in `logs/{project-name}-resolution-log.md` where `{project-name}` is derived from the current working directory basename (e.g., `cops-portal`, `seller-portal`, `fe-core`). Record what changed and why – UNLESS it is a _trivial_ application of a non-null assertion in a test file, we do not need to log these. If we have already created a code comment documenting our justifications, these log entries ought to be as concise as possible. Simply append to this log file, do NOT read the whole thing or it will fill up the context window quickly

## References

- `references/fix-patterns.md` — common motifs and the recommended fix for each
- `references/test-helpers.md` — assertion helpers that narrow types in tests
- `references/known-issues.md` — edge cases / novel patterns worth remembering

## Success Criteria

- Errors resolved with minimal runtime behavior changes
- Production code avoids unsafe type assertions and broad suppressions
- Test code fixes are ergonomic and maintainable
- Fixes are logged for review and repeatability
