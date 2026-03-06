# Frontend Engineering Standards

**Version:** 1.0.0
**Last updated:** 2026-03-05
**Domain:** Frontend
**Status:** Approved

---

## 1. Project Structure

- Source code lives in `src/`
- Static assets served directly live in `public/`
- Components in `src/components/`; pages or routes in `src/pages/` or `src/app/` (framework-dependent)
- Keep the top-level `src/` flat — avoid nesting more than 3 levels deep unless the project is very large
- One component per file; filename matches the exported component name

## 2. Component Architecture

- Use functional components with hooks exclusively. No class components in new code.
- Keep components small and focused. If a component is longer than ~150 lines, consider splitting.
- Extract reusable logic into custom hooks (`use<Name>`), not utility functions that return JSX.
- Prefer composition over inheritance. Avoid deeply nested prop drilling — use context or a state manager.
- Distinguish clearly between presentational (dumb) and container (smart) components.

## 3. TypeScript

- TypeScript is the default. JavaScript files are acceptable only in config/tooling contexts.
- Avoid `any`. Use `unknown` when the type is genuinely unknown, then narrow it.
- Define types and interfaces at the top of the file or in a co-located `types.ts`.
- Use strict mode (`"strict": true` in tsconfig).
- Prefer interfaces for object shapes; use type aliases for unions, intersections, and utility types.

## 4. State Management

- Prefer local state (`useState`, `useReducer`) until global state is clearly necessary.
- Use React Context for low-frequency shared state (theme, user session, locale).
- Use a dedicated state manager (Zustand, Redux Toolkit, Jotai) only when Context causes re-render issues.
- Do not fetch data inside components directly — use a data-fetching layer (React Query, SWR, or a custom hook).
- Avoid storing derived values in state — compute them from existing state.

## 5. Accessibility (a11y)

- All interactive elements must be keyboard accessible.
- Use semantic HTML — `<button>`, `<nav>`, `<main>`, `<section>` over generic `<div>`.
- Every image must have an `alt` attribute (empty string if decorative).
- Form inputs must have associated `<label>` elements.
- Do not rely solely on color to convey information.
- Target WCAG 2.1 AA compliance.

## 6. Performance

- Lazy-load routes and large components with `React.lazy` / dynamic imports.
- Memoize expensive computations with `useMemo`; memoize stable callbacks with `useCallback` when passed to child components.
- Do not memoize everything — profile first, optimize second.
- Keep the initial JS bundle under 200 KB (gzipped) for the critical path.
- Prefer CSS transitions over JS-driven animations for simple effects.

## 7. Styling

- Pick one styling approach per project and stay consistent: CSS Modules, Tailwind CSS, or a CSS-in-JS library.
- Do not mix inline styles with class-based styling except for truly dynamic values (e.g., computed widths).
- Use design tokens (CSS custom properties or a theme object) for colors, spacing, and typography — no magic numbers.
- Dark mode should be handled at the token level, not scattered across components.

## 8. Testing

- Unit test individual functions and hooks with Vitest or Jest.
- Component tests with React Testing Library — test behavior, not implementation.
- Integration/e2e tests with Playwright or Cypress for critical user flows.
- Aim for meaningful coverage, not a coverage percentage. Critical paths must be tested.
- Do not snapshot-test large component trees — they become noise.

## 9. Tooling

- Linting: ESLint with a strict config. No committed code should have lint errors.
- Formatting: Prettier. Format on save or pre-commit hook.
- Type-checking: `tsc --noEmit` in CI.
- Package manager: consistent across the project (pick one: npm, pnpm, or yarn).

## 10. Error Handling

- UI must handle loading and error states explicitly — no blank screens on failure.
- Use Error Boundaries at route or major feature boundaries.
- Log errors to a monitoring service (Sentry or equivalent) in production.
- Never swallow errors silently in async handlers.

## 11. Security

- Never store secrets in frontend code or environment variables that ship to the browser.
- Sanitize user input before rendering as HTML.
- Use HTTPS for all API calls.
- Keep dependencies up to date — review `npm audit` output before release.

---

## Changelog

| Version | Date | Change |
|---------|------|--------|
| 1.0.0 | 2026-03-05 | Initial version |
