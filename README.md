# Kaiwa (会話)

Real-time conversation translator for iOS. Set the phone between you and someone who speaks a different language — Kaiwa transcribes and translates both sides simultaneously, each person reading text that faces them.

## Setup

### Prerequisites

- Node.js 18+
- Xcode 16+
- A [Clerk](https://clerk.com) account for authentication
- A [Convex](https://convex.dev) deployment for the backend

### iOS config

The iOS app reads API keys from `ios/Kaiwa/Config.plist`. This file is **not committed to git** — create it from the example:

```bash
cp ios/Kaiwa/Config.plist.example ios/Kaiwa/Config.plist
```

Then edit `Config.plist` and fill in your values:

- **ConvexURL** — your Convex deployment URL, found in the Convex dashboard under Settings → URL & Deploy Key. This value is intentionally non-secret (it is embedded in the app binary and used for client-side API calls).
- **ClerkPublishableKey** — your Clerk publishable key (`pk_live_*` or `pk_test_*`), found in the Clerk dashboard under API Keys. Publishable keys are client-facing and will appear in the app binary, but should not be committed to version control so they can be rotated without a public git history trail.

### Install dependencies

```bash
npm install
```

### Run

```bash
npx expo start
```

## Architecture

- React Native / Expo (frontend)
- Convex (backend / realtime)
- Clerk (authentication)
- Soniox (speech-to-text)
