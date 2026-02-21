# Contributing to Kaiwa

## Architecture

Kaiwa is a bilingual conversation app with three layers:

1. **iOS app** (SwiftUI) — Split-screen UI showing Japanese and English in real-time
2. **Convex backend** — User auth (Clerk), session management, translation (OpenAI)
3. **Soniox** — Real-time speech-to-text via WebSocket

```
┌─────────────┐    WebSocket     ┌──────────┐
│  iOS Client │ ───────────────▶ │  Soniox  │
│  (SwiftUI)  │                  │  STT RT  │
└──────┬──────┘                  └──────────┘
       │ Convex SDK
       ▼
┌─────────────┐
│   Convex    │
│  Backend    │
│ (auth, API  │
│  translate) │
└─────────────┘
```

## Setup

### Backend (Convex)

```bash
npm install
npx convex dev
```

Set environment variables in your Convex dashboard:
- `SONIOX_API_KEY` — from [soniox.com](https://soniox.com)
- `OPENAI_API_KEY` — for translation
- `CLERK_JWT_ISSUER_DOMAIN` — from [clerk.com](https://clerk.com)

### iOS

1. Open `ios/Kaiwa.xcodeproj` in Xcode
2. Add `Config.plist` with `ClerkPublishableKey`
3. Build and run on a physical device (mic required)

## Project Structure

```
ios/Kaiwa/
├── Views/
│   ├── ContentView.swift       # Auth gate + navigation
│   ├── SetupView.swift         # Language layout picker
│   ├── SessionView.swift       # Main session UI (split-screen)
│   └── TranscriptView.swift    # Scrollable transcript
├── ViewModels/
│   └── SessionViewModel.swift  # Session lifecycle + state
├── Services/
│   ├── SonioxService.swift     # WebSocket STT client
│   ├── ConvexService.swift     # Backend API client
│   ├── AudioCaptureService.swift  # Mic → PCM audio
│   └── ConfigService.swift     # App config (plist)
└── Models/
    ├── ConversationEntry.swift # Transcript entry
    └── SessionAuth.swift       # Auth response model

convex/
├── auth.config.ts    # Clerk auth
├── session.ts        # Key delivery + rate limiting
├── translate.ts      # OpenAI translation
├── users.ts          # User management
└── schema.ts         # Database schema
```

## Code Style

- Swift: standard Xcode formatting
- TypeScript: default Convex conventions
- Commits: conventional commits (`feat:`, `fix:`, `chore:`)
