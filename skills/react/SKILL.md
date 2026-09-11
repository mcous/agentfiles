---
name: react
description: >
  React/UI antipatterns and review criteria — hooks, effects, accessibility,
  semantic HTML, component logic, and React Testing Library. Use when writing or
  reviewing React components, or when invoked with /react.
user-invocable: true
---

# React

## Hooks & effects

- **No `exhaustive-deps` disables.** `// eslint-disable-next-line react-hooks/exhaustive-deps` almost always signals a wrong dependency list and a stale-closure bug. Fix the deps or restructure the hook.
- **Narrow effect deps.** Depending on a whole object fires the effect more than intended. Destructure to the exact values needed.
- **`useRef` is not state.** A ref change won't re-render, so derived values reading it go stale. Correctness bug, not a style choice.
- **No unnecessary `async`.** `async` without `await` silently wraps the return in a `Promise` and changes the inferred type. Remove it, or there's a missing `await`.

## Component structure

- **Logic out of component bodies.** Filtering, sorting, calculation belong in pure functions with their own unit tests. A component that both renders and computes mixes archetypes.
- **Async/in-flight state.** UI must reflect every phase — idle, pending, success, error. Flag a button that stays enabled while a request is in flight.

## Accessibility

- **Icon-only buttons** need `aria-label` (`title` is not reliably announced). All `<button>`s need explicit `type="button"` — the default is contextual and can trigger form submits.
- **Live-region containers** (`role="status"`, `role="alert"`) must already be in the DOM before the message appears. Render the container always; conditionally render content inside it.
- **`React.useId()` for linked IDs** (label+input, button+controlled-region). Hard-coded strings break on re-render/reuse; incrementing counters are fragile.

## Semantic HTML

- Prefer `<header>`, `<footer>`, `<nav>`, `<section>`, `<aside>`, heading elements over generic `<div>`s.
- Collapsible sections: `aria-expanded` + `aria-controls` on the trigger; `role="region"` (e.g. `<section aria-labelledby="...">`) on the controlled element.

## React Testing Library

Full FE testing workflow is in `/tdd-fe`. Two rules that bite most:

- **Query priority**: prefer `getByRole` over `getByText`/`getByTestId`. A component unreachable by role is an a11y bug, not just a test smell.
- **`userEvent`, not `fireEvent`.** `fireEvent` dispatches synthetic events that bypass real focus/keyboard/pointer behavior.
