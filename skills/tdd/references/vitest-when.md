# vitest-when Patterns

## Basic setup

```typescript
import { when } from 'vitest-when';
import { vi, expect } from 'vitest';

// Automock the module
vi.mock('./some-dependency');
import { someFunction } from './some-dependency';
```

## `when()` does not need `vi.mocked()`

`when` is typed to accept mocked functions directly — no `vi.mocked()` wrapper needed. Passing a non-mock will error at runtime.

```typescript
// Good: pass the import directly
when(someFunction).calledWith('x').thenResolve(result);

// Unnecessary: vi.mocked() wrapper adds noise with no benefit
when(vi.mocked(someFunction)).calledWith('x').thenResolve(result);
```

## Conditional stubs (.calledWith is required)

Always use `.calledWith()` — unconditional stubs pass even with wrong arguments.

```typescript
// Good: only resolves when called with exactly this argument
when(mockRepository.findById).calledWith(123).thenResolve({ id: 123, name: 'a b' });

// Bad: passes regardless of what argument is passed
mockFn.mockReturnValue(x);
```

## Common patterns

```typescript
// Sync return
when(mockFn).calledWith('input').thenReturn('output');

// Async resolve
when(mockFn).calledWith('input').thenResolve({ data: 'x' });

// Throw
when(mockFn).calledWith('bad').thenThrow(new SomeError('msg'));

// Asymmetric matchers
when(mockFn).calledWith(expect.any(Number)).thenResolve(null);
when(mockFn)
  .calledWith(expect.objectContaining({ id: 1 }))
  .thenReturn(result);

// Multiple sequential returns
when(mockFn).calledWith('key').thenReturn('first', 'second');

// Limit to N calls
when(mockFn, { times: 1 }).calledWith('key').thenReturn('value');
```

## Verification

Only verify fire-and-forget calls (logging, job queues) — where there's no return value to assert.

```typescript
// Good: verifying a side effect with no observable return
expect(mockLogger.warn).toHaveBeenCalledWith('something bad happened');

// Redundant: stub + assert return value already proves the call happened correctly
when(mockFn).calledWith(x).thenReturn(y);
const result = subject.run(x);
expect(result).toBe(y);
expect(mockFn).toHaveBeenCalledWith(x); // ← delete this
```

## Typed mocks

```typescript
import { type Mocked } from 'vitest';

// Use Mocked to keep TypeScript honest
const mockRepo: Mocked<Repository> = {
  save: vi.fn(),
  findById: vi.fn(),
};
```

## Vitest config

```typescript
// vitest.config.ts: reset mocks between tests automatically
export default {
  test: {
    mockReset: true,
  },
};
```
