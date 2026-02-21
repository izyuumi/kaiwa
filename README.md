# 会話 Kaiwa

[![License: MIT](https://img.shields.io/badge/License-MIT-blue.svg)](LICENSE)

Real-time bilingual conversation translator for iOS. Place your phone between two speakers — one sees Japanese, the other sees English — both in real-time.

## How It Works

1. **Choose layout** — pick which language goes on top (for the person sitting across from you)
2. **Start session** — audio is streamed to [Soniox](https://soniox.com) for speech-to-text
3. **Live translation** — transcribed text is translated via OpenAI and displayed on both halves of the screen

The top half is rotated 180° so the person across the table can read their language naturally.

## Stack

- **iOS** — SwiftUI, AVFoundation for audio capture
- **Backend** — [Convex](https://convex.dev) for auth, user management, and translation
- **STT** — [Soniox](https://soniox.com) real-time speech-to-text via WebSocket
- **Translation** — OpenAI GPT for Japanese ↔ English
- **Auth** — [Clerk](https://clerk.com) for user authentication

## Requirements

- iOS 17+
- Physical device (microphone required)
- Approved account (invite-only during beta)

## Development

See [CONTRIBUTING.md](CONTRIBUTING.md) for setup instructions.

## License

MIT
