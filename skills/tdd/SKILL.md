---
name: tdd
description: >
  Outside-in discovery testing workflow for backend/Node/TypeScript code. Drives
  implementation through collaboration tests at system boundaries, collaborator
  identification, and archetype-appropriate testing. Use when implementing any new
  backend unit, service, function, or module with tests — especially when invoked
  with /tdd, or when user says "implement with TDD", "use discovery testing",
  "write tests first", or "test-drive" any backend feature. Also loads when
  reviewing backend tests or evaluating test design quality.
user-invocable: true
---

# Discovery Testing Workflow

Outside-in TDD for backend/Node/TypeScript. Run autonomously through the full tree — don't pause for approval at each step. Log each design decision inline. Produce a topology summary at the end.

**Run the tests at every step — red before green.** "Autonomous" means no approval gates, not skipping test runs. This is TDD: after writing a test, run it and confirm it fails *for the expected reason* (asserts, not import/syntax errors) before writing any implementation. After implementing, run it again and confirm it passes. Never write test + implementation together and run once at the end — a test you never watched fail proves nothing. Move to the next unit only once the current one is green.

**Testing mental model.** Three modes, and only two of them are valid:

- **No mocks** (pure logic) — fails when logic rules change; survives implementation refactors
- **All mocked** (collaboration) — fails when contracts change; survives dependency internals changing
- **Mixed real + fake** — fails for any reason, so a failure tells you nothing. Never do this.

By archetype: pure → no mocks · collaborator → all mocked · wrapper → no unit test (E2E covers it) · value → no test. Tests are either pure unit or full E2E — almost nothing in between.

Prefer return value assertions over call verification; only verify fire-and-forget side effects that have no return value. "If X fails, Y shouldn't happen" tests are a design smell — data dependency should enforce ordering structurally, not a test.

Test antipatterns are in the `/review-style` skill. See `references/vitest-when.md` for stub/mock patterns.

## Philosophy

**Mocked tests are design tools, not correctness tools.** A collaboration test exists to iterate on internal APIs and contracts between units — not to verify correct outputs. Goal: drive collaborators toward simple, data-passing structures where each unit receives inputs from the previous and passes outputs to the next, like a pipeline. Failure propagation should be structural: if a unit fails, the next unit *cannot* be called because its input only comes from the failed unit — no conditional logic required.

**Necessary & Sufficient.** Tests should be exactly what's needed — no more, no less.
- *Necessary*: only test behaviors actually needed. Don't test edge cases handled upstream — unnecessary guard clauses restrict implementation freedom and mislead readers.
- *Sufficient*: each test must fully specify observable behavior. Asserting only that something returned is not enough. Stubs must be conditional on specific arguments.

**NOOOPE zone.** Don't write mid-stack integration tests that couple to framework internals (e.g. NestJS controllers, mounted component trees). They're simultaneously too coupled to implementation details *and* too divorced from reality — they break on refactors without catching real bugs. When the urge hits: can the seam move to make this a unit test? If not, make it a full SAFE (Smoke/Acceptance/Full-stack/End-to-end) test — use the `/e2e` skill.

## Phase 1: Collaboration Test

Write a failing collaboration test at the system entry point before any implementation.

- Write the test as if the ideal API already exists
- All dependencies are mocked — fully, never partially. A pure/functional dependency is still mocked — letting it run real because it "looks harmless" is the mixed real+fake antipattern
- The test specifies relationships (what the entry point calls and with what), not logic

Immediately name every collaborator the entry point needs. For each, declare its archetype:

- **functional** — pure logic, input → output, no side effects
- **collaborator** — delegates work to other units. If its only state is dependency references, it's just a module — make it stateless functions and push real state down into the wrapper that owns the third-party handle.
- **wrapper** — thin encapsulation of a third-party dependency
- **value** — plain data; no methods, no behavior. Units that operate on values (persistence, transformation) are separate and accept the value as input.

**Stub newly discovered units so the test can run.** A collaboration test that imports a not-yet-existing collaborator fails on an import error, which specifies nothing. For each new unit you named, create its file now with the real export and signature but a `throw new Error('not implemented')` body. The collaboration test mocks these collaborators, so the throwing body never executes — it's a placeholder that satisfies the import and the type checker until Phase 4 implements it for real. Stub the entry point itself the same way (throwing) so the suite resolves but the assertion is what fails.

Run the test. Confirm it fails on the assertion or on the entry point's own `not implemented` throw — not on a missing import or type error, which means a unit's signature is still absent. Then log: `[entry-point]: collaboration test written, failing as expected. Collaborators: [name: archetype, ...]`

## Phase 2: Pain Check

Before implementing, evaluate the test against these signals (thresholds are guides, not hard rules):

| Signal | Diagnosis |
|---|---|
| Mock setup > ~5 lines | Collaborator interface too broad |
| Subject has > ~3–4 dependencies | Unit doing too much — split |
| Arrange phase longer than act + assert | Too many preconditions on subject |
| Deep mock chain (mock returns object with mock method) | Law of Demeter violation |
| Test specifies both logic and relationships | Mixed archetypes — separate do from delegate |
| Branching/conditional logic in a collaborator | Dependency's API is wrong — fix the dep API, don't branch |
| Urge to verify "if X fails, Y shouldn't happen" | Structural wiring problem — data dependency should enforce this |
| Many test cases to cover one unit | Too many code paths — split by responsibility |
| Same dependency across many unrelated tests | Abstraction at wrong level |
| Value object requires complex graph to construct | Fix the value, not the test |
| Test requires knowing another unit's internals to set up | Abstraction boundary leaking |
| Same setup repeated identically across multiple test files | Shared logic not extracted into its own unit |

If signals triggered: propose redesign, log rationale, do not proceed until the design is clean. More setup is never the fix.

If clean: proceed.

## Phase 3: Implement Entry Point

Write the minimum implementation to pass the collaboration test, then run it and confirm green before recursing. The entry point should only delegate — no logic. If logic appears during implementation, extract it to a functional collaborator and return to Phase 1 for that unit.

## Phase 4: Recurse into Collaborators

Implement collaborator children before the functional units and wrappers beneath them. Don't design the leaf APIs up front — the friction of writing a collaborator's test is what reveals the right dependency API (this is how a wrapper's `update(id, changes)` method, or collapsing a parse + read into one `loadSave(slug)`, gets discovered). Among sibling collaborators the order is free; the depth order is not.

For each collaborator:

> If a collaborator is a frontend component, switch to the `/tdd-fe` skill for that subtree. Note: reactive units (hooks, stores, signals) that interface with the framework are not tested in isolation — they're covered by the component integration test or E2E. Backend discovery continues in parallel.

**Functional unit:**

- Write pure function tests — no mocks
- Tests specify logic rules: given inputs → expected outputs
- Run them red, implement to pass, run them green — one rule at a time
- If logic is complex, test each rule separately

**Collaborator unit:**

- Return to Phase 1 for this unit — full discovery testing, recursively

**Wrapper unit:**

- Implement thin adapter — no unit test needed (trust the library)
- Document which library features are actually used
- Callers mock this wrapper, never the underlying library directly
- Why: pushing third-party interactions to boundaries gives you a seam you own. Pain of mocking a library you don't control is useless — you can't fix it by redesigning code you don't own.

**Value type:**

- Implement as a typed interface or plain object — no unit test needed
- Values have no behavior; all operations on them belong in functional or wrapper units

## Phase 5: Topology Summary

Output at end:

```
## Topology

entry-point [collaborator]
├── unitA [functional] — split: logic found in entry point
├── unitB [collaborator]
│   ├── unitC [functional]
│   └── awesomeLibWrapper [wrapper] — wraps: AwesomeLib.optimize()
└── unitD [functional]
```

One-line rationale for each split.

## Practices

**Arrange-Act-Assert.** Three visually separated phases. Prefer spies over mocks: mock expectations set before the act phase invert AAA order. `vitest-when` uses spy-style — configure stubs before act, verify after.

**Meaningless test data.** Inputs should be obviously insignificant — values that can't be mistaken for boundary cases, magic numbers, or real data:

```typescript
// Bad — `18` looks like an age boundary; `"test@example.com"` looks like a real fixture
const fixture = { id: 1, age: 18, email: 'test@example.com' } satisfies User;

// Good — obviously meaningless; any deviation from this shape signals intent
const fixture = { id: 1, age: 1337, email: 'x@x.x' } satisfies User;
```

Use `satisfies` for strict typing without widening. For variations, use a builder:

```typescript
const createUser = (overrides: Partial<User> = {}) => ({ ...fixture, ...overrides });
```

**Never export solely for tests.** A unit exported and imported only by its test file signals mixed archetypes — the logic should live in a pure function that's independently testable without being exported from the collaborator.

**Minimise redundant coverage.** In a well-designed suite, each unit is exercised exactly twice: its own unit test, and one SAFE test. Coverage beyond that creates cascading failures when a single logic change happens — multiple tests break for one reason.

**Vitest config.** Set `mockReset: true` to automatically reset mocks between tests. One test file per unit under test.

## Standing Rules

- All mocked or none mocked. Never partial.
- Enumerate every import in a collaborator's test file. Everything that isn't the subject under test or a plain value type must have a `vi.mock`. If the test goes green without a stub configured for a dependency, that dependency ran for real — a leak, not a convenience.
- Inject dependencies as module imports mocked with `vi.mock` — not through an options object. Pushing `id`/`clock`/persistence out to dependency *modules* is right; threading them through a `createX({ ... })` options bag is the mistake.
- Design a wrapper's write methods to return the resource (`put`/`update` return the written value) so the collaborator's behavior is observable through its return value rather than call verification.
- Mock wrappers, never third-party libs directly.
- Never use `any`-typed mocks — use `Mocked<ActualType>` (imported from `vitest`) so the type system enforces mock shape.
- Prefer return values over call verification. Only verify fire-and-forget side effects (log writes, job enqueues) where there is no return value to assert.
- If you stub a call with specific args and assert its return value, call verification is redundant — omit it.
- Each test must fully specify observable behavior — asserting only that something returned is not sufficient.
- Values should be cheap to construct — if a value requires a deep graph to instantiate, fix the value.
- Use `vitest-when` with `.calledWith()` for all stubs. If not present in the project, recommend adding it (`npm install --save-dev vitest-when`) before proceeding — the workflow depends on conditional stubs. See `references/vitest-when.md`.
- Mock antipatterns (wrong layer, unconditional stubs, too many deps) are design signals about the subject, not the test. Trace to root before suggesting a fix — patching the stub without fixing the subject leaves the design unchanged.
