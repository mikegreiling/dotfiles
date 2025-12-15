# Fix Patterns for noUncheckedIndexedAccess Violations

This document provides detailed examples of fix patterns for common `noUncheckedIndexedAccess` violations.

## Pattern 1: Object Index Signature Access

### Problem

```typescript
const types: { [key: string]: string } = {
  'audio/x-mpeg': 'mpega',
  'video/mp4': 'mp4'
}

// ❌ Error: Type 'string | undefined' is not assignable to type 'string'
export const getExtensionByMimeType = (type: string): string => types[type]
```

### Fix Options

#### Option A: Update return type (Preferred for functions)

```typescript
// ✅ Best: Be explicit about undefined possibility
export const getExtensionByMimeType = (type: string): string | undefined => types[type]

// Caller must handle undefined:
const ext = getExtensionByMimeType(mimeType)
if (!ext) {
  throw new Error(`Unknown mime type: ${mimeType}`)
}
```

#### Option B: Provide fallback (Good for known defaults)

```typescript
// ✅ Good: Provide sensible default
export const getExtensionByMimeType = (type: string): string => types[type] ?? 'bin'
```

#### Option C: Throw if undefined (Good for required values)

```typescript
// ✅ Good: Throw if type not found
export const getExtensionByMimeType = (type: string): string => {
  const extension = types[type]
  if (extension === undefined) {
    throw new Error(`Unknown mime type: ${type}`)
  }
  return extension
}
```

## Pattern 2: Array Index Access

### Problem

```typescript
const items = ['a', 'b', 'c']
// ❌ Error: Type 'string | undefined' is not assignable to type 'string'
const first: string = items[0]
```

### Fix Options

#### Option A: Check before access (Production code)

```typescript
// ✅ Best for production: Explicit check
if (items.length === 0) {
  throw new Error('Array is empty')
}
// Length check above guarantees first element exists
// eslint-disable-next-line @typescript-eslint/no-non-null-assertion
const first = items[0]!
```

#### Option B: Use at() with nullish coalescing

```typescript
// ✅ Good: at() method with fallback
const first = items.at(0) ?? defaultValue
```

#### Option C: Destructuring with default

```typescript
// ✅ Good: Destructure with default
const [first = defaultValue] = items
```

#### Option D: Non-null assertion in tests

```typescript
// ✅ OK in test files: Mock guarantees value
// Test mock returns exactly 3 items
const first = items[0]!
const second = items[1]!
```

## Pattern 3: Test File Array Access

### Problem

```typescript
// Test file
const inputs = getAllByRole('textbox')
// ❌ Error: HTMLElement | undefined not assignable to HTMLElement
await user.type(inputs[0], 'value1')
```

### Fix Options

#### Option A: Non-null assertion with comment (Preferred for tests)

```typescript
// ✅ Best for tests: Assert with explanatory comment
const inputs = getAllByRole('textbox')
// Test setup creates exactly 2 textbox inputs
await user.type(inputs[0]!, 'value1')
await user.type(inputs[1]!, 'value2')
```

#### Option B: Explicit assertion before use

```typescript
// ✅ Good: Explicit test assertion
const inputs = getAllByRole('textbox')
expect(inputs).toHaveLength(2)
// expect().toHaveLength(2) assertion guarantees 2 elements
await user.type(inputs[0]!, 'value1')
await user.type(inputs[1]!, 'value2')
```

#### Option C: Array destructuring

```typescript
// ✅ Good: Destructure to named variables
const [input1, input2] = getAllByRole('textbox')
// Test setup guarantees 2 inputs exist
if (!input1 || !input2) throw new Error('Expected 2 inputs')
await user.type(input1, 'value1')
await user.type(input2, 'value2')
```

## Pattern 4: RegExp Named Groups

### Problem

```typescript
const match = regex.exec(text)
if (!match.groups) {
  throw new Error('Named capture groups not supported')
}
// ❌ Error: Type 'string | undefined' not assignable to type 'string'
const key = match.groups.key
const value = match.groups.value
```

### Fix Options

#### Option A: Runtime validation (Best)

```typescript
// ✅ Best: Validate after checking groups exists
if (!match.groups) {
  throw new Error('Named capture groups not supported')
}
const key = match.groups.key
const value = match.groups.value
if (!key || !value) {
  throw new Error('Expected key and value in regex match')
}
// Now key and value are validated as strings
```

#### Option B: Non-null assertion with explanatory comment

```typescript
// ✅ OK if regex pattern guarantees groups
if (!match.groups) {
  throw new Error('Named capture groups not supported')
}
// Regex pattern /(?<key>\w+)=(?<value>\w+)/ guarantees key and value groups
// eslint-disable-next-line @typescript-eslint/no-non-null-assertion
const key = match.groups.key!
// eslint-disable-next-line @typescript-eslint/no-non-null-assertion
const value = match.groups.value!
```

## Pattern 5: Cascading Undefined

### Problem

```typescript
const accountRole = roles[accountId]  // accountRole is Role | undefined
// ❌ Error: Object is possibly 'undefined'
if (accountRole.buyer === RoleStatus.INTENDED) {
  // ...
}
```

### Fix Options

#### Option A: Check before use (Best)

```typescript
// ✅ Best: Check undefined before accessing properties
const accountRole = roles[accountId]
if (!accountRole) {
  throw new Error('Account role not found')
}
// Now accountRole is narrowed to Role
if (accountRole.buyer === RoleStatus.INTENDED) {
  // ...
}
```

#### Option B: Optional chaining

```typescript
// ✅ Good: Use optional chaining
const accountRole = roles[accountId]
if (accountRole?.buyer === RoleStatus.INTENDED) {
  // ...
}
```

## Pattern 6: Object Property from Object.entries()

### Problem

```typescript
const obj = { a: 1, b: 2, c: 3 }
for (const [key, value] of Object.entries(obj)) {
  // ❌ Error: Type 'number | undefined' not assignable to type 'number'
  const doubled: number = obj[key]
}
```

### Fix Options

#### Option A: Use the value from entries

```typescript
// ✅ Best: Use value directly from entries
for (const [key, value] of Object.entries(obj)) {
  const doubled = value * 2  // value is already the correct type
}
```

#### Option B: Type assertion with comment (if obj access needed)

```typescript
// ✅ OK: Assert that key is valid (it comes from Object.entries)
for (const [key, value] of Object.entries(obj)) {
  // key comes from Object.entries(obj) so obj[key] is guaranteed to exist
  // eslint-disable-next-line @typescript-eslint/no-non-null-assertion
  const num = obj[key]!
  const doubled = num * 2
}
```

## Pattern 7: Testing Library Queries

### Problem

```typescript
// Test file
const button = container.querySelector('.submit-button')
// ❌ Error: Element | null not assignable to Element
fireEvent.click(button)
```

### Fix Options

#### Option A: Use getBy* queries (Best for tests)

```typescript
// ✅ Best: getBy* throws if element not found
const button = getByRole('button', { name: 'Submit' })
fireEvent.click(button)  // button is guaranteed to exist
```

#### Option B: Assert + non-null assertion

```typescript
// ✅ Good: Explicit assertion
const button = container.querySelector('.submit-button')
// Test DOM setup includes .submit-button element
expect(button).toBeInTheDocument()
fireEvent.click(button!)
```

## Anti-Patterns (AVOID)

### ❌ Type assertion to any

```typescript
// ❌ NEVER: Defeats type safety completely
const value = obj[key] as any
```

### ❌ Type assertion to unknown then to target

```typescript
// ❌ NEVER: Circumvents type checking
const value = obj[key] as unknown as string
```

### ❌ Non-null assertion without justification

```typescript
// ❌ BAD: No comment explaining why this is safe
const value = obj[key]!
```

### ❌ Ignoring undefined in production code

```typescript
// ❌ BAD: Silently using undefined as fallback in production
const config = configs[env]!  // Will crash at runtime if env not in configs
```

## Summary Decision Tree

```
Is it a test file?
├─ YES → Use `!` with SAFETY comment explaining test setup
└─ NO (production code) → Is there a sensible default?
   ├─ YES → Use nullish coalescing: `value ?? default`
   └─ NO → Can you check before use?
      ├─ YES → Use if guard: `if (!value) throw new Error(...)`
      └─ NO → Consult with user for guidance
```
