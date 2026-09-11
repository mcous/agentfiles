---
name: comment-cleanup
description: >
  Delete pass over the comments and TSDoc a branch or PR added, cutting them back to
  one-line TSDoc on APIs and nothing else. Use when comments or JSDoc are too verbose,
  when asked to "trim the comments", "cut the JSDoc", "clean up the comments on this
  PR", or when invoked with /comment-cleanup. Written for a subagent with no context
  on how the code was written. Not a code review.
user-invocable: true
---

# Cutting comments back

You are reading this code the way its next reader will: with no memory of writing
it, no ticket, no design doc. That is the qualification, not a handicap. A comment
that only makes sense to someone who remembers the implementation session is a
comment to delete, and you are the one person who can tell.

The output is a comment-only diff. You are not reviewing the code — no logic
findings, no naming suggestions in the diff, no tests.

## Scope

Target is a PR number, a branch, or nothing (then it's the current branch).

```bash
gh pr diff <n> --name-only                      # PR given
git diff --name-only $(git merge-base HEAD main)..HEAD   # branch or current
```

Then read each file in full — the diff hunks alone hide which symbols are
exported and whether a doc line is redundant with the code under it.

Three boundaries, all hard:

1. **Only comments the diff added or changed.** A pre-existing comment the branch
   never touched is out of scope even when it's terrible.
2. **Only comment lines change.** No renames, no extractions, no reformatting, no
   import shuffling. If a comment can only be saved by restructuring the code, cut
   the comment and put the site in the report.
3. **Don't add prose.** The one exception: a symbol this branch exported with no
   TSDoc at all gets one line.

## Keep

| Comment | Treatment |
|---|---|
| Machine-read pragmas — `@ts-expect-error`, `eslint-disable*`, `biome-ignore`, `v8 ignore`, codegen markers, license headers | Verbatim. Never touch. |
| `@deprecated`, `@internal`, `@see` on a kept doc | Keep the tag, trim the prose to a clause |
| TSDoc on an exported symbol | One line, imperative mood |
| TSDoc on an internal symbol whose purpose isn't evident from its name and signature | One line |
| `@param`/`@returns` that fits on one line and says something the name and type don't | Keep as is |
| A complete `@param` set — every parameter tagged | Keep as is |
| `TODO`/`FIXME` carrying a ticket ID | Verbatim |

That's the whole list.

## Cut

- **Every comment inside a function body.** No exceptions above the pragma line.
- Restatements of the code — `// increment the counter`, `/** The user's name. */`
  over `name: string`.
- `@param`/`@returns` that wraps past one line, or that only echoes the parameter
  name or its type — `@param userId - The ID of the user`. Trim the wrapping ones to
  a single line where there's a fact in them; delete the echoes.
- **A partial `@param` set.** Tagging some parameters and not others is invalid, not
  terse. Every parameter gets a one-line tag or none of them do — so cutting one echo
  forces the choice: give the rest a line each, or delete the whole block and let the
  summary carry what mattered. One parameter worth a tag means delete the block; two
  or more means tag them all.
- `@example` blocks, section banners (`// ─── helpers ───`), file-header summaries,
  `// eslint-disable` without a rule name.
- Narrative and process — "previously this used X", "added for ABC-123",
  "renamed from", "keeping the old path for now".
- Justification — why nothing breaks, why the cast is safe, what would have
  happened otherwise, what a reviewer might wonder. A doc line records what is
  true, never argues it.
- Bare `TODO`/`FIXME`/`XXX` with no ticket. Cut it; list it in the report.
- Arrange/act/assert narration in tests, and any comment restating a test name.
- The second clause. After `so`, `hence`, `meaning`, `which means`, `therefore`,
  `ensuring`, or an em dash followed by reassurance: if it follows from the first
  clause it's a restatement; if it doesn't it's an unhomed claim. Cut either way.

## Per-comment procedure

1. Machine-read? Keep verbatim, move on.
2. Delete it and read the code again. Could a reader who knows the language but not
   this codebase say what this symbol is for? If yes, it stays deleted.
3. If no, and it's an API worth documenting, write the shortest true sentence —
   first clause only — and stop. Imperative mood — "Resolve", not "Resolves" or
   "This function resolves" — no "Helper that", no restating types.
4. If no and one line genuinely can't carry it, the code is the problem, not the
   doc. Keep the one-line version anyway and add a line to the report.

## Rewrites

```ts
// Before
/**
 * Validates the incoming session token and, if it is still within its TTL,
 * returns the associated user record. We check the TTL here rather than in the
 * middleware so that the refresh path can reuse this function without having to
 * duplicate the expiry logic, which was previously a source of drift.
 *
 * @param token - The session token to validate
 * @param now - The current time, injectable for tests
 * @returns The user record, or null if the token is invalid or expired
 */

// After
/**
 * Resolve an unexpired session token to its user, or `null`.
 *
 * @param token - Opaque token from the `sid` cookie.
 * @param now - Instant the TTL is measured against.
 */
```

One blank `*` line between the summary and the tags, and no other blank line in the
block. `now` earns a tag — which clock the expiry compares against isn't in the
signature — and that obliges `token` to have one too, so it gets the fact its name
doesn't carry instead of the echo it had. "Injectable for tests" went: that's about
the test suite, not the API. Had `token` had nothing to say, both tags would go and
the summary would absorb the clock: "Resolve a session token unexpired as of `now`
to its user, or `null`."

```ts
// Before
export function toCents(amount: number): number {
  // Multiply by 100 to convert dollars to cents, then round to avoid
  // floating-point drift (e.g. 1.005 * 100 === 100.49999999999999).
  return Math.round(amount * 100)
}

// After
export function toCents(amount: number): number {
  return Math.round(amount * 100)
}
```

The rounding fact isn't lost — it's in `Math.round`. If a fact really only lives in
the deleted comment, that's a report line, not a reprieve.

## Verify

Every added line in your own diff must be a comment line:

```bash
git diff -U0 | grep '^+' | grep -vE '^\+\+\+' | grep -vE '^\+\s*(//|/\*|\*|\*/)'
```

Empty output, or you changed code. Then the repo's own gates — **pnpm only**, never
`npx` or `node_modules/.bin`:

```bash
pnpm typecheck && pnpm lint
```

Typecheck catches a pragma you removed by accident; lint catches a repo that
requires JSDoc on exports. Fix what you broke, don't work around it by putting the
prose back.

## Report

Leave the changes uncommitted unless asked to commit. If asked: `fixup: trim
comments` on a branch that already has a commit, and no force-push once a human has
reviewed the PR.

The report is a table and at most a few lines after it:

```
src/session/resolve.ts    4 cut, 1 rewritten
src/billing/cents.ts      3 cut
```

Then, only if there are any:

- Facts with nowhere left to live — one line each, file and what was lost.
- Bare TODOs removed — one line each.
- Sites where a one-line doc needed an extraction to be honest.

Nothing else. No summary of the rules, no count of files read, no note on what you
left alone.
