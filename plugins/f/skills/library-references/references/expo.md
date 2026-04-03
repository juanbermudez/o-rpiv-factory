# Expo Reference

Common mistakes Claude makes with Expo and React Native. Read this before writing any mobile code.

---

## SDK 54 / React Native 0.81

This reference targets **Expo SDK 54** with **React Native 0.81**.

Key facts for this version:
- **New Architecture is enabled by default** in RN 0.81. Do not add `newArchEnabled: false` unless you have a specific incompatible dependency.
- **Bridgeless mode** is available but not required.
- `gap` CSS property is fully supported — use it instead of margin hacks.
- Flexbox is the default layout system — no CSS grid.

---

## Navigation with expo-router

Use **expo-router** (file-based routing), not `react-navigation` directly.

**File structure**:
```
app/
  (tabs)/
    _layout.tsx     ← Tab navigator config
    index.tsx       ← Home tab
    orders.tsx      ← Another tab
  _layout.tsx       ← Root layout (providers, auth guard)
  +not-found.tsx    ← 404 screen
```

**Tab navigator**:
```tsx
// app/(tabs)/_layout.tsx
import { Tabs } from 'expo-router'

export default function TabLayout() {
  return (
    <Tabs>
      <Tabs.Screen name="index" options={{ title: 'Home' }} />
      <Tabs.Screen name="orders" options={{ title: 'Orders' }} />
    </Tabs>
  )
}
```

**Linking/navigation**:
```tsx
import { router, Link } from 'expo-router'

// Imperative
router.push('/orders')
router.replace('/(tabs)')

// Declarative
<Link href="/orders">Go to Orders</Link>
```

---

## Import Gotchas

**WRONG** — `react-native-web` is not used in Expo:
```typescript
import { View } from 'react-native-web'  // WRONG: not installed
```

**CORRECT** — Import from `react-native`:
```typescript
import { View, Text, StyleSheet, Pressable, ScrollView } from 'react-native'
```

For platform-specific code, use `Platform.OS`:
```typescript
import { Platform } from 'react-native'

const paddingTop = Platform.OS === 'ios' ? 44 : 24
```

Or use platform-specific file extensions (resolved automatically by Metro):
```
Component.ios.tsx      ← iOS only
Component.android.tsx  ← Android only
Component.tsx          ← Fallback for both
```

---

## Styling

There is no CSS in React Native. All styles use `StyleSheet.create()` or NativeWind.

**StyleSheet.create()**:
```typescript
const styles = StyleSheet.create({
  container: {
    flex: 1,
    flexDirection: 'row',
    gap: 8,           // ✓ supported in RN 0.81
    padding: 16,
  },
  text: {
    fontSize: 16,
    fontWeight: '600',
  },
})
```

**NativeWind** (Tailwind-like classes for React Native) — check if installed before using:
```tsx
<View className="flex-1 flex-row gap-2 p-4">
  <Text className="text-base font-semibold">Hello</Text>
</View>
```

Do NOT use inline objects for repeated styles — use `StyleSheet.create()` for performance.

---

## Testing with Jest

**WRONG** — Mobile does not use Vitest:
```typescript
import { describe, it, expect } from 'vitest'  // WRONG: use Jest for mobile
```

**CORRECT** — Mobile uses Jest with the `jest-expo` preset:
```typescript
import { describe, it, expect } from '@jest/globals'  // or just use globals
```

**jest.config.js** for mobile:
```javascript
module.exports = {
  preset: 'jest-expo',
  setupFilesAfterEach: ['./jest.setup.js'],
}
```

**jest.setup.js** — mock native modules:
```javascript
jest.mock('expo-camera', () => ({ ... }))
jest.mock('@react-native-async-storage/async-storage', () =>
  require('@react-native-async-storage/async-storage/jest/async-storage-mock')
)
```

Test files: `*.test.tsx` or `*.spec.tsx`, colocated with components or in `__tests__/`.

---

## Common Native Modules

| Module | Purpose | Import |
|--------|---------|--------|
| `expo-camera` | Camera access | `import { Camera } from 'expo-camera'` |
| `expo-image-picker` | Photo library | `import * as ImagePicker from 'expo-image-picker'` |
| `expo-secure-store` | Secure key-value | `import * as SecureStore from 'expo-secure-store'` |
| `expo-haptics` | Haptic feedback | `import * as Haptics from 'expo-haptics'` |
| `expo-linking` | Deep links | `import * as Linking from 'expo-linking'` |

Always check `apps/mobile/package.json` before adding a new module — it may already be installed.
