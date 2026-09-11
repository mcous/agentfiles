---
name: review-style
description: >
  Code review workflow: review philosophy, criteria, antipatterns, communication
  tone, and Conventional Comments format. Use when reviewing a pull request or diff,
  when replying to review feedback from a human or bot reviewer, when evaluating
  test design quality, or when invoked with /review-style.
user-invocable: true
---

# Code Review

## Philosophy

**Question existence before quality.** Before critiquing how something is done, ask whether it needs to exist. Deleted function has no bugs.

**Keep PRs focused.** Migrations migrate. Refactors refactor. Bug fixes fix the bug. Flag out-of-scope changes and suggest a follow-up.

**Review against the relevant skill.** When a project skill governs the code under review (e.g. the `solidjs` data-flow skill), load it and review the diff against it as the reference. Claims about framework behavior must be checked against the installed source or canonical repo — never asserted from memory.

## Review Criteria

### Test value

Flag tests that mirror implementation rather than verify behavior — they provide no safety net when code changes.

**Pain signals and what they diagnose:**

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

**Antipatterns to flag:**

- **Insufficient assertions** — testing only that something returned, not what. Related: "fantasy tests" — pass despite the code not working, usually from over-mocked subjects that don't reflect real interactions
- **Test-specific mocks in global setup** — mocks in `jest.setup.ts` apply to every test regardless of relevance; co-locate with the tests that need them
- **Hard-coded expected values re-implement the code** — an assertion that re-derives the calculation will pass even when the calculation is wrong; derive from requirements, not implementation
- **Realistic-looking test data** — `18`, `"test@example.com"`, `"John Smith"` implies significance; use obviously meaningless values (`1337`, `"x@x.x"`, `"a b"`) so readers know the value doesn't matter
- **Unconditional stubs** — `mockFn.mockReturnValue(x)` passes even with wrong arguments; use argument-conditional stubs (`vitest-when` `.calledWith()`)
- **`any`-typed mocks** — silently drift from real type when the type changes; use `Mocked<ActualType>` (imported from `vitest`)
- **Partial mocks** — mocking some methods on a real object while leaving others real; the unmocked methods can change independently. Replace the whole module.
- **Mixed real + fake dependencies** — no experimental control; fails for any reason. Either all mocked or none.
- **Mocking value objects** — mocking args passed to/from the subject rather than collaborators the subject delegates to; values should be cheap to construct
- **Mocking at intermediate stack layers** — only two valid positions: direct dependency (isolated unit test) or external system boundary (integration test). Arbitrary middle-layer mocks produce failures that don't correspond to anything meaningful.
- **Mocking third-party libs directly** — wrap first, mock the wrapper; mocking library internals couples tests to implementation details you don't control
- **Teardown inlined in test bodies** — won't run if the test fails; put in `afterEach`
- **Redundant stub + verify** — if you stubbed with specific args and asserted the return value, call verification is redundant; reserve for fire-and-forget side effects with no return value

### Export hygiene

Question exports with no apparent external consumers. A common cause: exporting internals solely to make them unit-testable signals mixed archetypes — extract the logic into a pure function instead.

### Error handling

Expected failures should be return values, not thrown exceptions. Flag `try/catch` scopes wider than the single operation that can throw. Flag `Promise.allSettled` when all operations must succeed (use `Promise.all`). Flag a user-facing `throw` for a "can't happen if used correctly" condition — that's an invariant, not an `Error` for the caller. Flag `!` or `as` papering over a genuinely maybe-absent value — the honest type is `T | undefined`, handled with a `Show`/guard, not an assertion.

### UI / a11y (when relevant)

- Async/in-flight state: verify UI accounts for all phases — idle, pending, success, error
- Prefer semantic HTML (`<footer>`, `<header>`, `<nav>`, `<section>`, `<aside>`) over `<div>`; collapsible sections need `aria-expanded`/`aria-controls` on the trigger and a `region` role on the controlled element
- `aria-label` on icon-only buttons; explicit `type="button"` on all `<button>` elements
- Live region containers (`role="status"`, `role="alert"`) must pre-exist in DOM before content appears

### CI failures

A red check is not a finding. The author already sees it; restating it adds nothing.

Comment only when all three hold:

- The failure is a **test failure** (not lint, typecheck, flake, infra, or a timeout)
- You have a **specific fix** — the line to change and what to change it to, not "this test needs updating"
- **No existing review or comment already says it** — check before writing, per Before Posting

Otherwise stay silent on CI — a test failure whose fix you can't name is the author's to diagnose.

### Validation

Prefer validation functions that return validated data over ones that throw or mutate as side effects.

## Communication Tone

- Curious, not declarative — "Could this live in X?" not "This should be in X"
- "We" not "you" — shared problems, not personal failures
- Every comment actionable; if uncertain about the solution, say so explicitly
- Batch related issues — combine similar findings into one comment rather than filing several near-identical ones
- Flag untested assumptions: "I haven't tested this, but I'd expect..."

## Comment Format

Conventional Comments apply to **one** kind of comment: the first comment in a
thread you are opening, in a review you are driving. Nothing else. Every reply —
to a human reviewer, to a bot reviewer, to your own earlier comment, on your PR
or someone else's — is plain prose. See Replies below.

```
**<label> [(non-blocking)]:** <subject>

[discussion]

<link>
```

Link to the PR diff line: `https://github.com/{owner}/{repo}/pull/{number}/files#diff-{sha256(path)}R{line}`
- `{sha256(path)}` — SHA-256 of the file path: `printf '%s' "{path}" | shasum -a 256`
- `R{line}` targets the right side (added/context lines); `L{line}` the left side (removed lines). The anchor targets a single line — ranges aren't supported.
Get the PR number: `gh pr view --json number -q .number`

**Labels:**
- `issue` — bugs or anti-patterns
- `suggestion` — improvements to consider
- `todo` — small necessary changes
- `chore` — follow-up tasks, cleanup
- `note` — informational
- `question` — genuine uncertainty
- `thought` — observations not requiring action
- `praise` — something genuinely done well; specific and understated; skip for small or routine changes
- `polish` — cleanliness that doesn't affect correctness
- `quibble` — trivial style/preference; minimize these

`issue`, `suggestion`, and `todo` are **blocking by default** — add `(non-blocking)` to explicitly opt out. All other labels are always non-blocking.

## Replies

A reply is a normal message to a person. Open with the substance — agreement,
disagreement, the correction, what changed — in ordinary sentences.

No label header, and no label smuggled in as decoration: `**praise:**`,
`**praise (with a correction):**`, `**issue (non-blocking, disagree):**`, or a
bolded lead-in standing in for one are all the same mistake. A label is the
reviewer's classification of a finding, so it has no meaning coming from the
person answering the finding — and applied to a reviewer's own work it reads as
grading them.

Say the thing the label was reaching for instead:

| Instead of | Write |
|---|---|
| `**praise:**` | "Confirmed — good catch." / "Agreed, and worth noting…" |
| `**praise (with a correction):**` | "Real bug, wrong mechanism: …" |
| `**issue (non-blocking, disagree):**` | "I don't think this holds here — …" |
| `**note:**` on a self-correction | "Correcting one detail above: …" |

Structure a reply as: the verdict, then what changed and where (commit, PR, test
coverage), then anything still open. Concede plainly when the reviewer is right;
disagree plainly when they aren't, with the evidence and a stated resolution
("resolving as not-a-bug — happy to reopen if…"). Keep the ~80-word budget.

## Before Posting

The review is drafted, not posted. Pull down what is already on the PR and prune the draft against it.

```sh
gh pr view <n> --json reviews --jq '.reviews[] | {author: .author.login, state, body}'
gh api repos/{owner}/{repo}/pulls/<n>/comments --paginate \
  --jq '.[] | {path, line, author: .user.login, body: .body[0:280]}'
```

Resolved and outdated threads count as already said.

Drop a drafted comment when an existing one:

- Makes the same point on the same line, whoever wrote it — including a bot
- Makes the same point elsewhere in the diff and yours adds no new instance
- Was already answered by the author, unless the answer is wrong; then it is a plain-prose reply in that thread, not a new comment

Keep it when yours adds a mechanism, a failure case, or a fix the existing comment lacks; name what is new in one sentence.

Then re-run the batching rule: what remains may collapse into fewer comments than the draft had.

## LLM Attribution

Comments destined for GitHub carry the LLM-attribution footer — see CLAUDE.md. One per posted comment, not per finding. Include it in drafts shown for approval; a conversational summary of findings isn't a post.

