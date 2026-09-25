---
name: tdd-fe
description: >
  Discovery testing workflow for frontend/UI code across component frameworks
  (Preact, Svelte, Solid, React, Astro islands, etc.). Extracts logic to pure
  functions, applies vitest browser mode integration tests to stateful components,
  and pushes reactive/framework-coupled units to E2E rather than isolated tests.
  Use when implementing UI components with tests, when invoked with /tdd-fe, or
  when user says "implement a component with tests", "test-drive a component", or
  asks for frontend testing strategy. Also loads when reviewing component tests or
  evaluating frontend test design quality.
user-invocable: true
---

# Frontend Discovery Testing Workflow

Collaboration tests don't translate to the component boundary — components can't be isolated from their runtime, and mocking framework internals produces fragile tests divorced from real behavior. The strategy:

- **Pure functions** extracted from components → `/tdd` workflow, full unit tests
- **Reactive units that don't need framework setup** (e.g. Solid derived signals, simple computed values) → test directly as functions
- **Reactive units with framework coupling** → `renderHook` (or framework equivalent) is acceptable in moderation; mocking inside it is a signal to extract logic or push to E2E instead
- **Logic components** → vitest browser mode (Playwright provider) integration test
- **Collaborator/layout components** → no test; TypeScript + E2E own verification

**Testing mental model.** All mocked or none mocked, never partial — a mixed real+fake test fails for any reason, so a failure tells you nothing. Extracted pure logic → no mocks. Component integration tests → stub external wrapper units at the boundary and nothing else. Full version in `/tdd`; test antipatterns in `/review-style`.

**Run the tests at every step — red before green.** This is TDD: after writing a test (extracted pure function or component integration), run it and confirm it fails *for the expected reason* (the assertion, not a missing import or render error) before writing the implementation. After implementing, run it again and confirm green. Never write test + implementation together and run once at the end — a test you never watched fail proves nothing. Move on only once the current unit is green.

## Phase 1: Logic Extraction

**Start from the consumer.** Begin at the user's entry point — the E2E flow or the component that renders this one — not a leaf unit built in isolation before there's a consumer.

Before writing any component, identify what can leave it:

- Data transformation, filtering, sorting, calculations → **pure functions** → test with `/tdd`
- API/external calls → **wrapper units** → no unit test; stub at the boundary in component tests
- Reactive units → ask: does it need framework setup to run? If no, test it directly. If yes, `renderHook` is acceptable in moderation — but if mocking is required to make it work, that's a signal to extract the interesting logic as pure functions and leave the wireup to E2E

Components receive their logic as props or reactive primitives — they shouldn't compute anything themselves.

Log: `Extracted: [unit: type, ...]` or `Nothing to extract — component is pure rendering`

## Phase 2: Component Classification

**Logic component** — has local state, user interactions, conditional rendering, async behavior, or error states. Needs an integration test.

**Collaborator/layout component** — pure composition: routes, layouts, feature containers whose only job is rendering children or wiring components together. No unit test.

Log: `[ComponentName]: [logic | collaborator]`

## Phase 3: Logic Component — Vitest Browser Mode Integration Test

Use **vitest browser mode** (Playwright provider). Rendering goes through a framework-specific setup file (e.g. `tests/vitest-browser-solid.ts`) that extends `page.render()` using the framework's testing library (`@solidjs/testing-library`, `@preact/testing-library`, etc.) and exposes a `screen` Locator scoped to the rendered element via `page.elementLocator(baseElement)`.

```typescript
import { page } from 'vitest/browser'

const onSubmit = vi.fn()
const renderSubject = () => page.render(() => <LoginForm onSubmit={onSubmit} />)

it('starts with submit disabled', async () => {
  const { screen } = renderSubject()
  await expect.element(screen.getByRole('button', { name: /submit/i })).toBeDisabled()
})

it('calls onSubmit when submitted', async () => {
  const { screen } = renderSubject()
  await screen.getByRole('button', { name: /submit/i }).click()
  expect(onSubmit).toHaveBeenCalledWith(expectedArgs)
})
```

Two assertion APIs — don't mix them:
- `await expect.element(locator).toX()` — DOM/Playwright assertions (async)
- `expect(spy).toHaveBeenCalledWith(...)` — vitest spy assertions (sync, no `await`)

`getByRole` first — an element unreachable by role is an accessibility bug.

**On external calls:** stub wrapper units (API, storage) at the boundary using `vitest-when` conditional stubs (`.calledWith()`, same convention as `/tdd`) — not child components. "Don't mock children" means component internals; external boundaries should still be stubbed.

Don't mock child components or framework context. If test setup requires knowing how a child renders, the boundary is wrong.

## When to use E2E instead

Push to SAFE tests when:

- Behavior spans multiple components or routes
- Reactive state (stores, signals, derived state) is the primary thing being verified
- Framework lifecycle (mounting, cleanup, reactivity chains) needs to be exercised

Reactive wireup is not tested in isolation — the interesting logic should have been extracted as pure functions in Phase 1. What remains is just binding, which E2E covers.

## FE Pain Signals

| Signal | Diagnosis |
|---|---|
| Logic in component body (calculation, filtering, sorting) | Extract to pure function |
| Component consuming many reactive units | Too many responsibilities — split |
| Props covering unrelated concerns | Component mixing archetypes |
| Stateful component also composing layout | Split into logic + collaborator |
| Test needs `getByTestId`/`locator('[data-testid]')` to find key elements | Missing semantic HTML — use roles |
| Reactive state is the main thing being tested | Push to E2E |
| Test setup requires knowing a child's internals | Wrong boundary |
| Collaborator component accumulating state | Extract stateful child |

## Topology Summary

```
## Topology

LoginPage [collaborator, no test]
├── validateCredentials [functional] → unit test (/tdd)
├── authApiWrapper [wrapper] → no unit test
└── LoginForm [logic component] → vitest browser mode
    └── (useLoginForm reactive unit: covered by LoginForm test, not tested separately)
```

## Standing Rules

- vitest browser mode (Playwright provider) for all component integration tests
- Render via `page.render()` (framework setup extends this); query via `screen` Locators; interact via `.click()`, `.fill()` on locators
- DOM assertions: `await expect.element(locator).toX()` — spy assertions: `expect(spy).toHaveBeenCalled()` (sync, no await)
- `getByRole` first, always — inaccessible element is a bug
- All `<button>` elements need explicit `type="button"`
- Logic in component body is always a smell — extract before writing the test
- Don't mock children or framework context in component tests
- Stub external wrapper units at the boundary with `vitest-when` `.calledWith()` — never unconditional stubs
- Reactive units: test directly if no framework setup needed; `renderHook` acceptable in moderation otherwise; mocking inside renderHook is a smell — extract logic or push to E2E
- Live region containers (`role="status"`, `role="alert"`) must pre-exist in DOM before content appears
