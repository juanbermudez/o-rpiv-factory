# Mobile App Deployment (`apps/mobile`)

Expo React Native app (SDK 54, React Native 0.81). Uses EAS (Expo Application Services) for builds and submissions.

> **Configure before use**: Replace `{PROJECT_ROOT}` with your monorepo root path, `{EXPO_ACCOUNT}` with your EAS account slug, and `{EXPO_PROJECT}` with your EAS project slug.

## Prerequisites

- EAS CLI installed: `npm install -g eas-cli`
- Logged in: `eas login`
- App Store Connect / Google Play credentials configured in EAS dashboard

## Build

### iOS

```bash
cd {PROJECT_ROOT}/apps/mobile
eas build --platform ios
```

### Android

```bash
cd {PROJECT_ROOT}/apps/mobile
eas build --platform android
```

### Both platforms

```bash
cd {PROJECT_ROOT}/apps/mobile
eas build --platform all
```

Builds run in the EAS cloud. Monitor at `https://expo.dev/accounts/{EXPO_ACCOUNT}/projects/{EXPO_PROJECT}/builds`.

## Submit to App Stores

After a successful build:

### iOS (App Store)

```bash
eas submit --platform ios
```

### Android (Google Play)

```bash
eas submit --platform android
```

EAS prompts for the build to submit — select the most recent production build.

## OTA Updates (Over-the-Air)

For JS-only changes that don't require a native rebuild:

```bash
cd {PROJECT_ROOT}/apps/mobile
eas update --branch production --message "Description of changes"
```

OTA updates are available to users without going through the app store review process. Use for bug fixes and UI changes. **Do NOT use OTA for native module changes, SDK upgrades, or new permissions** — these require a full build + submission.

## When to Build vs OTA Update

| Change Type | Action |
|-------------|--------|
| JS/TypeScript changes | OTA update |
| New npm package (JS only) | OTA update |
| Native module added | Full build + submit |
| SDK version bump | Full build + submit |
| New app permissions | Full build + submit |
| App icon / splash changes | Full build + submit |

## Verify

1. Install the build on a test device via TestFlight (iOS) or internal track (Android)
2. Smoke test: login, navigate to main screen, test core features
3. For OTA updates: force close and reopen the app to pull the update

## Rollback

OTA updates can be rolled back by publishing a previous branch:

```bash
eas update --branch production --message "Rollback to stable" # from a known-good commit
```

For store builds, rollback requires submitting the previous build artifact through EAS.
