---
name: e2e
description: >
  End-to-end testing workflow using Playwright. Covers when to write E2E tests,
  the page object model pattern, fixture setup, and test structure. Use when
  writing or reviewing Playwright tests, when invoked with /e2e, or when user
  asks about E2E testing strategy, full-app tests, or behavior that spans
  multiple components or routes.
user-invocable: true
---

# E2E Testing with Playwright

E2E tests verify real user flows through the running application. They're the right layer for behavior that spans routes, depends on reactive state wiring, or exercises the full stack. Keep the suite small — each test should cover something a component integration test can't.

## When to write an E2E test

- Behavior spans multiple components or routes
- Reactive state wiring (stores, signals, URL state) is the thing being verified
- The test must cross a real network, auth, or database boundary
- You've pushed reactive unit testing out of isolation and need coverage somewhere

Don't write E2E tests for behavior adequately covered by component integration tests — they're slower and more fragile.

## Page Object Model

Structure each page or feature as a typed page object: separate `Locators` and `Actions` interfaces, combined into a `PageName` type, created by a `createPageName({ page })` factory.

```typescript
// e2e/pages/home.ts
import type { Page, Locator } from '@playwright/test'

export interface HomePageLocators {
  mainHeading: Locator
  initialCallToAction: Locator
  getStartedButton: Locator
}

export interface HomePageActions {
  goto: () => Promise<void>
  getStarted: () => Promise<void>
}

export type HomePage = HomePageLocators & HomePageActions

export const createHomePage = ({ page }: { page: Page }): HomePage => {
  const locators: HomePageLocators = {
    mainHeading: page.getByRole('heading', { level: 1 }),
    initialCallToAction: page.getByText(/start planning/iu),
    getStartedButton: page.getByRole('button', { name: /get started/iu }),
  }

  const actions: HomePageActions = {
    async goto() {
      await page.goto('/')
    },
    async getStarted() {
      await locators.getStartedButton.click()
    },
  }

  return { ...locators, ...actions }
}
```

Locators go on the object directly (not behind a method) so tests can assert against them without calling functions.

## Fixture setup

Use `test.extend()` to attach page objects as fixtures. The fixture **constructs the page object only — no side effects, no navigation**. Each test navigates explicitly, so the URL a test starts at reads in the test body, not hidden in a fixture:

```typescript
// e2e/home.test.ts
import { test as baseTest, expect } from '@playwright/test'
import { createHomePage, type HomePage } from './pages/home.ts'

const test = baseTest.extend<{ home: HomePage }>({
  home: async ({ page }, use) => {
    await use(createHomePage({ page }))
  },
})
```

## Test structure

Name tests as user-observable behaviors, not implementation steps:

```typescript
test('is titled Satisfactorizer and has a call to action', async ({ page, home }) => {
  await home.goto()

  await expect(page).toHaveTitle('Satisfactorizer')
  await expect(home.mainHeading).toHaveAccessibleName('Satisfactorizer')
  await expect(home.initialCallToAction).toBeVisible()
})

test('creates a new save', async ({ page, home }) => {
  await home.goto()
  await home.getStarted()

  await expect(page).toHaveTitle('New Save | Satisfactorizer')
  await expect(home.mainHeading).toHaveAccessibleName('New Save')
  await expect(home.initialCallToAction).not.toBeVisible()
})
```

## Hydration races (SSR + client frameworks)

Playwright clicks the instant an element is *actionable* — before SSR-rendered handlers hydrate — so a click can land on a not-yet-interactive control and be silently dropped. **Fix the app, not the test:** disable interactive controls until hydrated (gate `disabled` on a client-mount signal such as `createIsHydrated()` — see the `solidjs` skill). Playwright's enabled-state actionability auto-wait then bridges the gap with zero test-side waiting.

The test is not a representative user — it clicks faster than any human, so it over-represents the hydration gap; that's a reason to fix the app honestly, not to work around it. Rejected non-fixes: a `globalSetup` browser warm-up, `vite` `server.warmup` config, and bumping the `expect` timeout — a longer timeout can't fix a *dropped* (no-op) click, only a slow one.

## Diagnosing flakes

Read the failure artifact before theorising. Playwright's `error-context.md` ARIA snapshot shows the actual page state at the moment of failure (e.g. "still on the home page" → the click was dropped, or the URL was read before async navigation settled). Diagnose from the snapshot, not by guessing and retrying.

## Config notes

Standard Playwright config for a SolidStart/Vite project:

```typescript
// playwright.config.ts
export default defineConfig({
  testDir: './e2e',
  fullyParallel: true,
  forbidOnly: isCi,
  retries: isCi ? 2 : 0,
  workers: isCi ? 1 : '50%',

  use: {
    baseURL: process.env.PLAYWRIGHT_BASE_URL || 'http://localhost:3000',
    trace: isCi ? 'retain-on-failure-and-retries' : 'on-first-retry',
  },

  webServer: {
    command: 'pnpm dev',
    url: 'http://localhost:3000',
    reuseExistingServer: true,
  },
})
```

`PLAYWRIGHT_BASE_URL` lets the same tests run against a deployed environment (e.g. a preview URL) without changes.

## Standing Rules

- One page object per page/route; one test file per page object
- Locators live on the page object, not inlined in tests — tests read as user actions
- Actions encapsulate interaction sequences; tests assert against named locators
- `getByRole` first — `getByText`, `getByLabel` next — `getByTestId` only as last resort
- Tests should be independent — no shared state between tests; fixtures construct page objects only, each test navigates explicitly (no `goto` in a fixture)
- Keep the suite small; if you're writing many E2E tests for the same component, the component test layer is probably missing coverage
