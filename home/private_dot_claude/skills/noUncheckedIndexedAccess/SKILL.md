---
name: noUncheckedIndexedAccess
description: Systematically resolves TypeScript noUncheckedIndexedAccess violations by applying conservative fix patterns, logging all changes with justifications, and improving over time through pattern recognition.
---

# noUncheckedIndexedAccess Violation Resolver

This skill provides systematic, conservative fixes for TypeScript `noUncheckedIndexedAccess` violations across B-Stock frontend portal projects.

## When to Use This Skill

Use this skill when:
- Resolving type errors caused by enabling `noUncheckedIndexedAccess` in tsconfig
- Fixing `TS2532` (Object is possibly 'undefined') errors
- Fixing `TS2345` (Type 'X | undefined' is not assignable) errors
- Fixing `TS2538` (Type 'undefined' cannot be used as an index type) errors
- Fixing `TS18048` (X is possibly 'undefined') errors

## Core Principles

1. **Conservative approach**: Prefer proper null checks over ignoring problems
2. **No reckless assertions**: NEVER use type assertions to any, unknown, or never without explicit user approval
3. **Justification required**: Production code assertions require explanatory comments. Test assertions do NOT require comments when self-evident.
4. **Learn and improve**: Log novel situations and suggest skill improvements
5. **Verify changes**: Run type-check after fixes to confirm resolution

## Fix Hierarchy

### For Production Code (Conservative)

1. **Proper null checks with early return/throw**
   ```typescript
   // BEST: Explicit null check
   if (value === undefined) {
     throw new Error('Value is required')
   }
   // Now value is narrowed to non-undefined
   ```

2. **Nullish coalescing with sensible defaults**
   ```typescript
   const extension = mimeTypes[type] ?? 'bin'
   ```

3. **Type guards/narrowing**
   ```typescript
   if (accountRole !== undefined) {
     // Use accountRole here
   }
   ```

4. **Destructuring with defaults**
   ```typescript
   const [first = defaultValue] = array
   ```

5. **Non-null assertion (the ! operator)** - ONLY when immediately preceded by a check that guarantees existence
   ```typescript
   if (array.length > 0) {
     // Length check above guarantees first element exists
     // eslint-disable-next-line @typescript-eslint/no-non-null-assertion
     const first = array[0]!
   }
   ```

### For Test Files (More Permissive)

Test files can use non-null assertions more liberally since test setup guarantees values exist. **Straightforward test file assertions do NOT require explanatory comments.**

```typescript
// Simple test file - no comment needed
const inputs = getAllByRole('textbox')
await user.type(inputs[0]!, 'value1')
await user.type(inputs[1]!, 'value2')
```

## Assertion Comment Requirements

**Production Code**: ALL non-null assertion or type assertion usage MUST include:
1. An explanatory comment describing why it's safe
2. An ESLint/TypeScript suppression comment (`eslint-disable-next-line` or `@ts-expect-error`)

**Test Files**: Comments and suppressions are NOT required for straightforward assertions where test setup clearly guarantees values.

```typescript
// Production code - comment + suppression REQUIRED
if (array.length > 0) {
  // Length check above guarantees element exists
  // eslint-disable-next-line @typescript-eslint/no-non-null-assertion
  const first = array[0]!
}

// Production code - alternative with @ts-expect-error
// accountRoles[accountId] guaranteed by JWT validation middleware
// @ts-expect-error TS2532 - see comment above
const role = accountRoles[accountId]

// Test file - No comment or suppression needed (obvious)
const button = getByRole('button')
fireEvent.click(button!)

// Test file - Comment for non-obvious case (suppression optional)
// Custom mock factory always includes userId in response
const userId = mockResponse.userId!
```

## Agent Workflow

When invoked, this skill uses the `nounchecked-fixer` sub-agent to:

1. **Read the file** and understand context
2. **Identify violations** from type-check output
3. **Apply fixes** following the hierarchy above
4. **Add explanatory comments** for production code assertions or non-obvious situations
5. **Verify fixes** by running type-check on the file
6. **Log changes** with justifications to `~/.claude/skills/noUncheckedIndexedAccess/logs/resolution-log.md`
7. **Flag novel situations** for user review if encountering new patterns
8. **Suggest improvements** to skill reference documentation

## References

- **Fix patterns**: See `references/fix-patterns.md` for detailed examples
- **Known issues**: See `references/known-issues.md` for edge cases and novel patterns

## Logging

All changes are logged to `logs/resolution-log.md` with:
- Violations fixed per file
- Fix method used for each violation
- Justification for the approach
- Verification results
- Novel situations encountered
- Suggested skill improvements

## Success Criteria

- Type errors resolved without breaking runtime behavior
- No type assertions to any, unknown, or never without explicit approval
- Production code assertions include explanatory comments
- Test file assertions are straightforward and self-explanatory
- Verification passes after fixes
- Comprehensive change log for review
