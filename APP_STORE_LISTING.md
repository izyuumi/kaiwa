# Kaiwa — App Store Listing

_All fields ready for App Store Connect submission. Apply changes in order below._
_Last updated: 2026-03-05 | Keywords updated from ASO audit (research-analyst)_

---

## App Identity

| Field | Value |
|---|---|
| **App Name** | Kaiwa - Conversation Translator |
| **Bundle ID** | to.yumi.kaiwa |
| **SKU** | kaiwa-1-0-0 |
| **Apple Team ID** | AN5KM8QGEF |
| **Version** | 1.0.0 |
| **Build** | 5 |
| **Primary Category** | Travel |
| **Secondary Category** | Utilities |
| **Age Rating** | 4+ |
| **Privacy Policy URL** | https://github.com/izyuumi/kaiwa/blob/main/PRIVACY_POLICY.md |
| **Support URL** | https://github.com/izyuumi/kaiwa |

---

## English (en-US) Listing

### App Name
```
Kaiwa - Conversation Translator
```

### Subtitle (30 chars max)
```
Real-time Japanese–English Talk
```
(31 chars — trim to:)
```
Real-time JP–EN Conversation
```
(28 chars ✅)

### Promotional Text (170 chars max)
```
Set the phone between you. Talk. Kaiwa transcribes and translates both sides in real time — each person reads text that faces them. Session history saved automatically.
```
(168 chars ✅)

### Description
```
You know the moment: you're at the doctor's office, the pharmacy, or your partner's family dinner, trying to talk to someone who doesn't share your language. You reach for Google Translate and start typing back and forth — it works, but it's not a conversation.

Kaiwa is built for that moment.

Start a session, set the phone between you, and talk. It transcribes what each person says and translates in real time — Japanese and English, side by side, each line facing the person who said it.

No typing. No switching modes. No copying text between apps.

The screen stays on and locks to portrait so it doesn't rotate when you set the phone down. A live session timer shows how long you've been talking. After the session, the full conversation is saved in your history so you can review what was said, or copy specific lines.

WHERE KAIWA WORKS
• Doctor's office and clinic visits
• Pharmacy counter
• Family gatherings with Japanese-speaking relatives
• Hotels and check-ins
• Any moment where typing back and forth isn't enough

WHAT MAKES IT DIFFERENT
• Two-sided layout: each person reads text that faces them
• Session history: no other conversation translator saves the full exchange
• Screen-on during sessions: won't lock mid-conversation
• Haptic feedback: feel when a translation lands
• Japanese and English, done well

HONEST NOTE
Kaiwa uses your microphone and an internet connection for real-time speech recognition. It works best in reasonably quiet environments. Japanese and English are the supported languages — we focused on doing one language pair well rather than many poorly.
```

### Keywords (en-US, 100 chars max)
```
japanese,interpreter,bilingual,real-time,face to face,travel,live translation,two-sided,expat,japan
```
(99 chars ✅)

---

## Japanese (ja) Localization

### Subtitle (ja, 30 chars max)
```
日本語・英語のリアルタイム会話翻訳
```
(17 chars ✅)

### Keywords (ja, 100 chars max)
```
リアルタイム翻訳,会話翻訳,通訳,日英翻訳,音声翻訳,対面会話,旅行翻訳,翻訳機,病院通訳,外国語,英語会話,在日,向かい合わせ,会話履歴,薬局,インバウンド,外国人,旅行者,観光,英日,医療
```
(96 chars ✅)

_Note: Japanese description localization is optional for v1.0 — English description acceptable for initial submission. Add ja description in v1.1 update._

---

## Screenshot Captions (iPhone 6.9" — 1320×2868px)

4 screenshots required. Captions appear below each screenshot on the App Store product page.

| # | Caption |
|---|---|
| 1 | Set the phone between you. Each person reads what faces them. |
| 2 | Live session timer. Screen stays on. Won't lock mid-conversation. |
| 3 | Session history. Review what was said after the conversation ends. |
| 4 | Real-time transcription + translation. No typing required. |

---

## App Privacy Declaration

### Data Collected

| Data type | Collected? | Purpose | Linked to user? | Tracking? |
|---|---|---|---|---|
| Audio (microphone) | Yes (processed, not stored) | App functionality — speech transcription via Soniox | No | No |
| User Content (transcribed text) | Yes (sent to OpenAI for translation) | App functionality — real-time translation | No | No |
| Usage data | Yes (crash reports via Expo) | App debugging | No | No |
| Name, email (Clerk) | Yes | Account authentication | Yes | No |
| Purchase history | Yes (subscription status) | Subscription gating | Yes | No |

### Privacy Nutrition Label (App Store Connect selections)

**Data Used to Track You:** None

**Data Linked to You:**
- Identifiers → User ID (required for account)
- Purchases → Purchase history (subscription gating)

**Data Not Linked to You:**
- User Content → Transcribed speech text sent to OpenAI for translation
- Usage Data (crash analytics)

### Notes for Apple Reviewer
- Audio is processed by Soniox (third-party STT service) in real time; no audio is stored by Kaiwa or Soniox beyond the transcription request
- Transcribed text (not audio) is sent to OpenAI GPT-4o-mini for translation; raw audio never reaches OpenAI
- OpenAI API data usage policy: https://platform.openai.com/docs/models/how-we-use-your-data (API inputs not used for model training; retained up to 30 days for trust and safety)
- Translation routing is via the Convex backend; conversation text is not persisted server-side beyond the session
- Privacy policy URL: https://github.com/izyuumi/kaiwa/blob/main/PRIVACY_POLICY.md

---

## App Review Notes

```
Kaiwa requires:
1. Sign in with Apple or email (Clerk authentication)
2. An active subscription to start conversation sessions

Demo account for review:
  Email: [CREATE BEFORE SUBMISSION — see BETA_PLAN.md for plan]
  Password: [ADD BEFORE SUBMISSION]
  Subscription: Active (reviewer account should have subscription enabled)

To test:
1. Sign in with the demo account
2. Tap "Start Session"
3. Speak in English — you will see your speech transcribed and translated to Japanese
4. Tap the microphone button on the other side to switch speaker
5. Speak in Japanese — translation appears on the English side
6. End the session — verify conversation history is saved
7. Tap any history entry — verify copy-to-clipboard works

Note: The app requires an internet connection and microphone permission. Speech recognition uses Soniox's API (cloud-based); translation uses Convex. Both require network access.
```

---

## Submission Checklist

- [ ] All code merged to main (`to.yumi.kaiwa`, build 5, version 1.0.0)
- [ ] App icon confirmed (1024×1024px, committed to main)
- [ ] 4× iPhone 6.9" screenshots ready (1320×2868px)
- [ ] Privacy policy live at public URL
- [ ] TestFlight build uploaded (requires GitHub Actions secrets)
- [ ] App Store Connect app entry created
- [ ] All listing fields entered (en-US + ja keywords)
- [ ] Privacy nutrition label completed
- [ ] Demo reviewer account created with active subscription
- [ ] Review notes filled in with demo credentials
- [ ] Version 1.0.0 selected as submission build
- [ ] Submit for review

---

## Post-Approval Actions

1. Fire Kaiwa launch posts (see ~/projects/launch/ANNOUNCEMENTS.md):
   - r/japanlife, r/LearnJapanese, r/travel
   - Product Hunt draft (stage day before approval)
   - Tweet variants (3 options)
2. Monitor TestFlight crash reports for first 48 hours
3. Respond to first App Store reviews within 24 hours
4. After 60 days: review App Store Connect Analytics → Search Terms → swap `英日` keyword if a higher-performing term appears
