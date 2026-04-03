---
name: library-references
description: >
  Reference guides for Supabase (RLS, vault, pgcrypto), shadcn/ui (Tailwind v4, composition),
  and Expo (SDK 54, router) with version-specific gotchas Claude commonly gets wrong.
  These are optional references — customize for your tech stack.
---

# Library Reference Skill

This skill provides quick-reference guides for libraries where Claude frequently makes version-specific mistakes. Read the relevant reference before implementing features that touch these libraries.

> **These references are optional and customizable.** They reflect a specific tech stack (Next.js, Supabase, shadcn/ui, Expo). If your project uses different libraries, replace or extend these references with your own. The value is in having a single place to capture version-specific gotchas for YOUR stack.

## References

| Reference | When to Read |
|-----------|-------------|
| [Supabase](references/supabase.md) | Any database migration, RLS policy, PII encryption, auth, or Supabase client usage |
| [shadcn/ui](references/shadcn-ui.md) | Any UI component work, form implementation, Tailwind styling, or component composition |
| [Expo](references/expo.md) | Any mobile app work, React Native components, Expo Router navigation, or mobile testing |

## General Gotchas

These apply across all libraries and have caused repeated issues:

- **Version assumptions** — Check which versions your project uses (Next.js, Tailwind, Expo SDK, etc.). Do not apply patterns from older docs or tutorials.
- **Deprecated packages** — `@supabase/auth-helpers-nextjs` is deprecated; `tailwind.config.js` is not used in Tailwind v4; `react-native-web` is not used in Expo.
- **Testing framework split** — Mobile typically uses Jest (`jest-expo`), web apps typically use Vitest. Never mix them.
- **Monetary values** — Always store as BIGINT cents (`_cents` suffix). Never use floats.
- **Rates/percentages** — Store as basis points (`_bps` suffix). 599 = 5.99%.
