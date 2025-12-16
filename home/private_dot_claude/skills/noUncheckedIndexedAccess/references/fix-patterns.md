# Fix Patterns for noUncheckedIndexedAccess Violations

This document catalogs high-frequency motifs caused by enabling `noUncheckedIndexedAccess`, with conservative fixes that avoid cascading type changes.

> Quick rule: **tests optimize for ergonomics**, **production optimizes for correctness + stability**.

---

## Pattern 1: Array indexing after a runtime assertion (tests)

### Symptom

```ts
expect(rows).toHaveLength(2)
within(rows[0]) // TS: rows[0] is possibly undefined
```

### Recommended fixes

**Option A (simple): non-null assertion**

```ts
expect(rows).toHaveLength(2)
within(rows[0]!)
```

**Option B (cleaner): use `at()` helper (recommended when repeated often)**

```ts
expect(rows).toHaveLength(2)
within(at(rows, 0))
```

See `references/test-helpers.md`.

---

## Pattern 2: “typeof” checks that don’t narrow types (tests)

### Symptom

```ts
expect(typeof value).toBe('string')
expect(value.startsWith('.')).toBe(true) // TS: value might not be string
```

### Recommended fix: assertion helper that narrows

```ts
expectString(value)
expect(value.startsWith('.')).toBe(true)
```

See `references/test-helpers.md`.

---

## Pattern 3: Object index signature access (`Record` / `{[k: string]: T}`) in production

### Symptom

```ts
const types: Record<string, string> = {
  "audio/x-mpeg": "mpega",
  "video/mp4": "mp4",
}

export const extFor = (type: string): string => types[type] // TS: string | undefined
```

### Fix options (choose based on semantics)

**Option A: Provide a sensible default**

```ts
export const extFor = (type: string): string => types[type] ?? "bin"
```

**Option B: Guard and throw (programmer/config error)**

```ts
export const extFor = (type: string): string => {
  const ext = types[type]
  if (ext === undefined) throw new Error(`Unknown mime type: ${type}`)
  return ext
}
```

**Option C: Tighten the key type (when keys are known)**

```ts
const types = {
  "audio/x-mpeg": "mpega",
  "video/mp4": "mp4",
} as const

type Mime = keyof typeof types

export const extFor = (type: Mime): string => types[type]
```

This avoids `undefined` entirely by making the key space explicit.

---

## Pattern 4: Index access + property access chain (production)

### Symptom

```ts
const label = labels[key].text // TS: labels[key] possibly undefined
```

### Fix options

**Option A: Optional chaining + default**

```ts
const label = labels[key]?.text ?? "Unknown"
```

**Option B: Guard**

```ts
const entry = labels[key]
if (!entry) return "Unknown"
return entry.text
```

Prefer `=== undefined` checks if falsy values are valid:

```ts
const entry = labels[key]
if (entry === undefined) return "Unknown"
```

---

## Pattern 5: `undefined` as an index type (production)

### Symptom

```ts
const key = maybeKey // string | undefined
const v = obj[key]   // TS2538: undefined cannot be used as an index type
```

### Fix options

**Option A: Guard key**

```ts
if (!key) return
const v = obj[key]
```

**Option B: Default key (only if appropriate)**

```ts
const v = obj[key ?? "defaultKey"]
```

---

## Pattern 6: Boundary validation (config/env/URL params/user input)

When the value originates from a boundary, validate once and keep internal code clean.

### Symptom

```ts
const env = process.env.APP_ENV // string | undefined
const config = configs[env]     // TS: env possibly undefined; config possibly undefined
```

### Recommended fix (validate once)

```ts
const env = process.env.APP_ENV
if (!env) throw new Error("APP_ENV is required")

const config = configs[env]
if (!config) throw new Error(`Unknown APP_ENV: ${env}`)
```

This prevents the “spray `| undefined` everywhere” cascade.

---

## Pattern 7: “Falsy” narrowing bugs (production + tests)

### Symptom

```ts
const v = map[key] // string | undefined
if (!v) return     // BUG if empty string is valid
```

### Recommended fix

```ts
const v = map[key]
if (v === undefined) return
```

Use falsy checks only when falsy values are truly impossible or undesired.

---

## Pattern 8: When `!` is acceptable in production

Use `!` only when the invariant is **truly guaranteed** and **locally obvious**, e.g.:

- indexing into a tuple with a known index
- accessing a property that was just checked in the same scope
- values enforced by schema/validation in the same module

Prefer a comment if the invariant isn’t self-evident.

```ts
// Invariant: `activeId` always exists after `loadState()` succeeds.
const active = entities[activeId]!
```

If the invariant is not real, do not use `!`—validate or guard instead.

---

## Summary Decision Tree

```
Is this a test file?
├─ YES
│  ├─ Can we narrow with a test helper? → use expectString/expectDefined/at()
│  └─ Otherwise, use `!` for ergonomic indexing after runtime expects
└─ NO (production)
   ├─ Is there a sensible default? → `value ?? default`
   ├─ Can we handle locally with a guard? → early return / fallback UI
   ├─ Is undefined a programmer/config error? → throw with a good message
   ├─ Are keys known? → tighten the key type (`as const`, `keyof`)
   └─ Only then: `!` (true invariant) or `@ts-expect-error` (ticket + expiry)
```
