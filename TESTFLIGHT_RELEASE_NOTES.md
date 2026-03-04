# Kaiwa TestFlight Release Notes

## Version 0.1.0 (Build 5) — Initial TestFlight Build

Thanks for testing Kaiwa! This is the first TestFlight build for external testers.

---

### What is Kaiwa?

Kaiwa is a real-time conversation translator for iOS. Set the phone between you and someone who speaks a different language, and talk naturally — Kaiwa transcribes and translates Japanese and English in real time, with each side facing the right person.

---

### What to test

**1. Core session flow**
- Tap "Start Session" and begin speaking
- Verify your speech is transcribed and translated correctly
- Make sure the other person's speech appears on their side (rotated 180°)
- End the session and confirm you return to the home screen cleanly

**2. Screen wake lock**
- Start a session and put the phone down — the screen should stay on
- Leave the session — normal auto-lock should resume

**3. Portrait lock**
- Try rotating the device during a session — it should stay in portrait
- After ending the session, verify rotation works again

**4. Session timer**
- While listening, you should see a `MM:SS` timer above the controls
- Timer should count up while active and disappear when idle

**5. Haptic feedback** (on a real device)
- When a translation completes, you should feel a light tap
- When a translation fails (e.g., network error), you should feel a distinct error haptic

**6. Conversation history**
- Scroll through earlier messages in the transcript
- Verify the original text appears above the translation for each entry

---

### Known limitations in this build

- Language pair is fixed to Japanese ↔ English
- Accounts require approval — if your account shows as pending, contact us
- This is an early build; rough edges are expected

---

### How to give feedback

Use the TestFlight feedback button (shake the device or tap "Send Beta Feedback" in the TestFlight app). You can also email directly.

---

*Kaiwa (会話) means "conversation" in Japanese.*
