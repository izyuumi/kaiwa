# Kaiwa Privacy Policy

_Last updated: 2026-03-05_

Kaiwa ("the app", "we") is a real-time conversation translation app. This policy describes what data the app collects, how it is used, and which third-party services process it.

---

## What we collect

| Data | How it is used |
|---|---|
| **Microphone audio** | Captured during an active session and streamed to Soniox for real-time speech-to-text transcription. Audio is not stored by Kaiwa or Soniox after transcription. |
| **Transcribed text** | The text output from speech recognition is sent to OpenAI for translation (see below) and displayed in the app. Text is not stored server-side after the session ends. |
| **Session history** | Conversation entries are stored locally on your device only. They are not synced or uploaded. |
| **Account information (email, name)** | Collected by Clerk for authentication. Used only to identify your account and gate subscription access. |
| **Subscription status** | Managed by RevenueCat / Apple In-App Purchase. Used to control access to session features. |
| **Crash and usage data** | Anonymous crash reports collected by Expo. Used to identify and fix bugs. |

---

## Third-party services and sub-processors

### Soniox (speech-to-text)
Microphone audio is streamed to [Soniox](https://soniox.com) during active sessions for real-time transcription. Audio is not retained by Soniox beyond the transcription request. See [Soniox Privacy Policy](https://soniox.com/privacy).

### OpenAI (translation)
Transcribed text — the text output from speech recognition — is sent to OpenAI's API (GPT-4o-mini) for translation. **Raw audio is never sent to OpenAI.** OpenAI processes text in transit to produce translations; under their standard API data usage policy, API inputs are not used to train OpenAI models by default. See [OpenAI's data usage policy](https://platform.openai.com/docs/models/how-we-use-your-data) for details on retention and processing.

### Convex (backend infrastructure)
Translation requests and session coordination are routed through a Convex backend. Convex processes data in transit but does not persist conversation content after the session ends. See [Convex Privacy Policy](https://www.convex.dev/privacy).

### Clerk (authentication)
Account creation and sign-in are handled by [Clerk](https://clerk.com). Clerk stores your email address and account identifiers. See [Clerk Privacy Policy](https://clerk.com/privacy).

---

## Data retention

- **Audio:** Not retained. Processed in real time, discarded after transcription.
- **Transcribed text sent to OpenAI:** Subject to [OpenAI's API data retention policy](https://platform.openai.com/docs/models/how-we-use-your-data). As of this writing, API inputs are retained for up to 30 days for trust and safety purposes, then deleted, and are not used for model training.
- **Session history:** Stored locally on your device. Deleted when you clear history or uninstall the app.
- **Account data:** Retained by Clerk for the life of your account.

---

## Your rights

You can delete your account and associated data by contacting us at the support URL below. Local session history can be cleared from within the app.

---

## Contact

Privacy questions: open an issue at [github.com/izyuumi/kaiwa](https://github.com/izyuumi/kaiwa).
