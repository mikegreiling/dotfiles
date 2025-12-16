# Test Helpers for Type Narrowing

Jest/Vitest `expect(...)` calls are runtime assertions and generally do **not** narrow TypeScript types.
These helpers provide runtime checks **and** compile-time narrowing.

Place these in a test-only utility module (e.g. `test/assert.ts`) and import where needed.

---

## `expectString` — narrow `unknown` to `string`

```ts
export function expectString(value: unknown): asserts value is string {
  expect(typeof value).toBe("string")
}
```

Usage:

```ts
expectString(value)
expect(value.startsWith(".")).toBe(true)
```

---

## `expectDefined` — narrow `T | undefined | null` to `T`

```ts
export function expectDefined<T>(
  value: T,
  message = "Expected value to be defined"
): asserts value is NonNullable<T> {
  expect(value).toBeDefined()
}
```

Usage (array indexing):

```ts
expect(rows).toHaveLength(2)
expectDefined(rows[0])
within(rows[0])
```

---

## `at()` — safe array indexing with a better failure mode

```ts
export function at<T>(arr: readonly T[], i: number): T {
  const v = arr[i]
  if (v === undefined) throw new Error(`Expected element at index ${i}`)
  return v
}
```

Usage:

```ts
expect(rows).toHaveLength(2)
within(at(rows, 0))
```

---

## `expectNonEmptyArray` — narrow to `[T, ...T[]]`

```ts
export function expectNonEmptyArray<T>(arr: readonly T[]): asserts arr is readonly [T, ...T[]] {
  expect(arr.length).toBeGreaterThan(0)
}
```

Usage:

```ts
expectNonEmptyArray(rows)
within(rows[0]) // now OK because rows is known non-empty
```

---

## Notes

- Prefer helpers like `expectString` when your intent is **type narrowing**.
- Prefer `at()` or `expectDefined(rows[0])` when the pattern repeats frequently.
- For simple cases, `rows[0]!` is acceptable in test code when a prior expectation guarantees it.
