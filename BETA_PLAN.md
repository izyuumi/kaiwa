# Kaiwa TestFlight Beta Program Plan

_Pre-launch planning document. Execution begins once the first TestFlight build uploads._
_Last updated: 2026-03-05_

---

## Overview

- **Target tester count:** 10–20 external testers, first round
- **Primary profile:** Japanese/English bilingual speakers who regularly navigate real language-barrier moments — not just learners, but people who actually need this in daily life
- **Goal of beta:** Verify the two-sided layout feels natural in a real hand-off scenario, confirm translation quality is usable, and surface any crashes/flow confusion before App Store submission

---

## 1. Tester Recruitment

### Who to target

**Primary:**
- Expats in Japan who regularly communicate with Japanese family members, landlords, doctors, or colleagues
- Non-Japanese spouses or partners in mixed-language families (common in the r/japanlife community)
- Japanese people with English-speaking friends, family, or coworkers they regularly bridge for

**Secondary:**
- Japanese learners at N3/N2+ level who are actively using Japanese in real-life situations and will notice translation quality issues
- Healthcare interpreters or bilingual individuals working in clinical or service contexts

**Explicitly not targeting:**
- Pure language learners who haven't used the language in real contexts yet — they can't reliably assess whether the translation output is accurate enough to matter
- People who only want to test it as a novelty — we need edge-case reports, not hype

### Where to post

| Community | Platform | Notes |
|---|---|---|
| r/japanlife | Reddit | High density of expats in Japan; very honest reviewers |
| r/LearnJapanese | Reddit | Hit N3/N2+ learners specifically; post in Weekly Discussion |
| Japan Life Discord (official) | Discord | ~60K members; multiple channels for daily life |
| Tofugu community / forums | Web | Engaged JP/EN bilingual learner audience |
| HelloTalk app community groups | In-app | Language exchange users — direct overlap |
| r/japan | Reddit | Broader reach, filter comments for actual residents |

### Paste-ready recruitment post (Reddit / Discord)

> **Early access: Kaiwa — real-time JP/EN conversation translator for iOS**
>
> I'm looking for 10–15 people to beta test Kaiwa before it goes to the App Store. It's an iPhone app built for situations where you need to actually talk to someone who doesn't share your language — put the phone between you, tap Start, and it transcribes and translates both sides in real time. The screen splits: your text at the top, theirs at the bottom, each facing the right person.
>
> It's early access and will have rough edges. What I need from testers: try it in at least one real conversation (or simulate one with a bilingual friend), fill out a short survey afterward, and tell me honestly what didn't work. This is specifically Japanese ↔ English.
>
> To get an invite: **reply here with your email or DM me.** I'll send a TestFlight link within 24 hours. Account approval is required to start sessions — I'll approve all beta testers immediately.
>
> Useful background: you live or work in Japan, you regularly communicate across a language gap, or you're at a level where you can judge whether a Japanese translation is actually correct.

### How to collect tester emails

1. **Manual DM/reply collection (first 10–20):** Given the small target count, collect emails via Reddit DM or Discord DM from people who respond to the post. Log them in a plain text file (`beta-testers.txt`, gitignored) or a private note.
2. **TestFlight invite flow:** In App Store Connect → TestFlight → External Testing → Add Testers. Each email gets a TestFlight invite email with a redemption link. No App Store account required to redeem (they'll be prompted to create one if they don't have one).
3. **Do not use a public Google Form** for the first round — manual collection keeps quality high and avoids bots. If tester count needs to scale to 50+, revisit.

---

## 2. Structured Test Scenarios

Each scenario should be tested with two people, or simulated with a bilingual person playing both roles. Testers should run through the setup screen each time to test the layout selection, not just the session itself.

---

### Scenario A: The Doctor's Office Visit _(Core use case — priority)_

**Setup:** One person plays the role of a Japanese-speaking doctor or pharmacist; the other plays an English-speaking patient. Find a quiet room. Use the JP-top / EN-bottom layout. Set the phone flat on a table between you.

**Script to follow:**
- Doctor: 「どこが痛いですか？」("Where does it hurt?")
- Patient: "My stomach has been hurting for two days. I feel nauseous."
- Doctor: 「いつから始まりましたか？昨日から？一昨日から？」("When did it start?")
- Patient: "Two days ago, in the morning."
- End the session and check the transcript.

**What to watch for:**
- Does the layout feel stable when the phone is set on a table? (No accidental taps on the control button)
- How quickly does each person's speech appear on their half of the screen?
- Is the Japanese medical terminology ("吐き気", "胃") transcribed correctly?
- Does the translation convey medically meaningful information, or does it lose nuance?
- Is it clear which side to read when it's your turn?

---

### Scenario B: The Family Dinner _(Social / informal register)_

**Setup:** Two people — one speaks Japanese naturally (including informal/casual register), one speaks English. No script — have a natural conversation about anything. Try to keep it going for at least 3–4 exchanges each.

**Suggested topic:** What you had for lunch, weekend plans, something funny that happened recently — anything conversational.

**What to watch for:**
- Does casual/informal Japanese (using だ/よ/ね endings, contractions, filler words like 「えーと」) transcribe cleanly?
- Does the translation preserve conversational tone, or does it sound formal/awkward?
- What happens when someone speaks quickly or mumbles?
- Does the session feel like a conversation, or does it feel like waiting for a machine?
- At what point (if any) does the flow break down enough that you'd give up and switch to typing?

---

### Scenario C: The Pharmacy Counter _(Short, high-stakes exchanges)_

**Setup:** One person plays a pharmacy staff member speaking Japanese; the other plays an English-speaking customer picking up a prescription. Keep exchanges short — 1–2 sentences each.

**Script to follow:**
- Staff: 「こちらのお薬は食後に飲んでください。一日三回です。」("Please take this medication after meals, three times a day.")
- Customer: "Is it okay to take with alcohol?"
- Staff: 「アルコールとの併用は避けてください。」("Please avoid combining with alcohol.")
- Customer: "What if I miss a dose?"
- Staff: 「飲み忘れた場合は、次の服用時間まで待ってください。」("If you miss a dose, wait until the next scheduled time.")

**What to watch for:**
- Does the transcription correctly handle pharmaceutical terms (服用, 一日三回, アルコール)?
- Is there a delay between speech and translation that would feel awkward at a real counter?
- Does the staff side (top of screen) feel usable in portrait when the phone is handed across a counter vs. laid flat?
- Any dropped words or incomplete sentences?

---

### Scenario D: Edge Case — Background Noise + Fast Speech _(Stress test)_

**Setup:** Find a location with background noise — a café, kitchen with appliances running, or simulate with music playing softly (TV works too). One person speaks Japanese at a natural/slightly fast pace; the other speaks English.

**What to do:** Have the same doctor/patient conversation from Scenario A, but in the noisy environment. One person should intentionally speak faster than comfortable for about 30 seconds.

**What to watch for:**
- Does transcription degrade significantly vs. quiet? At what noise level does it break?
- Does fast speech get truncated — are words cut off or run together?
- If the transcription produces garbled text, does the translation still make sense, or does it amplify the error?
- How does the app behave if a word is misheard — does the wrong text persist, or does it self-correct?
- Any crashes under audio stress?

---

### Scenario E: Mid-Session Speaker Switch _(UX edge case)_

**Setup:** Two people start a session with the JP-top / EN-bottom layout. Midway through, they want to swap — the Japanese speaker now wants to read from the bottom. They should NOT end the session; instead, one of them physically rotates the phone 180°.

**What to watch for:**
- Does the layout respond correctly when the phone is physically flipped? (iOS auto-rotate lock behavior — Kaiwa locks to portrait, so physically rotating doesn't rotate the OS UI, but it does flip which half is "up" relative to each person)
- Is there any confusion about which speaker's text is which after the physical rotation?
- Do both testers agree on what the "right" UX is here, or is it confusing?
- **Expected behavior:** The layout doesn't change; the person who wanted to read from the other side just reads upside-down. If testers find this confusing, that's a valid bug report — note it.

---

## 3. Feedback Collection

### Survey questions (post-session, 5 questions)

Send these via a simple Google Form after each tester completes at least one scenario. Keep it short — completion rate drops fast after question 5.

---

**Q1 — Core experience (required)**
_On a scale of 1–5, how natural did the conversation feel compared to having an interpreter present?_
> 1 = Completely unnatural, we had to stop and type instead
> 3 = Workable but noticeable delays/errors
> 5 = Felt close to a real interpreted conversation

**Q2 — Translation quality (required)**
_Did the translations convey the intended meaning accurately?_
> Options: Always / Usually / Sometimes / Rarely / Not at all
> Follow-up (text box): If not always, describe a specific translation that was wrong or misleading.

**Q3 — Layout and UX (required)**
_Was it clear at all times which half of the screen to read?_
> Options: Yes, immediately obvious / Yes, after a moment of orientation / Somewhat confusing / No, I kept reading the wrong side
> Follow-up (text box): What would have made it clearer?

**Q4 — Bugs and breakage (required)**
_Did anything stop working or crash during your session?_
> Options: No issues / Minor issue (describe below) / Major issue, had to restart / App crashed
> Follow-up (text box): What happened? When in the session?

**Q5 — Would you use this (open response, required)**
_In one or two sentences: what's the one thing you'd fix before recommending this to someone who actually needs it in a real situation?_
> (Free text — this is the highest-signal question)

---

### Beta duration recommendation

**Run beta for 2 weeks (14 days) before App Store submission.**

Rationale:
- **Week 1:** Most testers complete their first session and submit the survey. Crash reports and major UX bugs surface.
- **Week 2:** Address P0 issues found in Week 1 and re-upload a build (TestFlight supports multiple builds per external group; existing testers auto-update). Collect second-pass feedback confirming fixes didn't break anything else.
- **Total:** 14 days gives two full feedback cycles with a meaningful tester pool (10–20 people) without delaying the App Store submission significantly.

**Don't run longer than 3 weeks.** Tester engagement drops fast after the first session. A second or third nudge rarely produces better signal — it just produces resentful feedback.

**Trigger for early submission (skip to Week 2 end):** If by Day 7, Q1 average ≥ 3.5 and Q4 shows zero crash reports from a pool of ≥10 completed surveys, submission can begin. The long tail of polish doesn't warrant holding.

---

## 4. Apple Reviewer Demo Account Plan

### Why this matters

App Store Review Guidelines require that apps with authentication or accounts must provide a working demo account for reviewers to access the app's core features. Without this, Apple will reject the submission with:

> _"Your app requires users to log in to access features, but we were unable to log in with the demo account credentials provided."_

Kaiwa has Clerk-based auth with account approval gating — both need to be handled for the reviewer.

### Account plan

**Email to create:** `kaiwa-reviewer@yumi.to`
(Uses the yumi.to domain so it's clearly owned by the developer. Avoid Gmail to prevent reviewer confusion with personal accounts.)

**Account setup (to execute before App Store submission):**
1. Create a Clerk account with email `kaiwa-reviewer@yumi.to` in the Kaiwa production environment
2. In Convex backend, manually set `isApproved: true` for this user (bypassing the normal approval queue)
3. Assign an active subscription tier to the account (required to start sessions; Apple reviewers must see the full app, not a paywall)
4. Verify the account can start a session end-to-end before submission

**Credential storage:**
Do not commit credentials to the repo. Record them in:
- **App Store Connect → App → Review Information → Demo Account** (the designated field for this purpose)
- Specifically, in the **Review Notes** field of the App Store submission form (not the binary notes) — this field is private to Apple reviewers and not published

Format for the Review Notes entry:
```
Demo account for review:
Email: kaiwa-reviewer@yumi.to
Password: [set at submission time]
Note: Account is pre-approved and has an active subscription. Start a session from the home screen and use the two-sided layout to see the core experience.
```

**Create a companion document:** `~/projects/kaiwa/APP_STORE_SUBMIT.md`

This file (gitignored or private) should track:
- Reviewer account email
- Password (or note that it's stored in App Store Connect)
- Date the account was created and approved in Convex
- Subscription expiry date (check this before re-submitting updates — reviewer account subscriptions can lapse)
- Link to the App Store Connect Review Information page for quick access

**Important:** The reviewer account password should be something memorably secure but not a reused password — since it will be typed into App Store Connect's plaintext Review Notes field. Use a dedicated password for this account.

---

## Execution Checklist (when TestFlight build is live)

- [ ] Upload at least one complete TestFlight build to App Store Connect
- [ ] Add internal testers (yumi + any direct collaborators) — Week -1
- [ ] Post recruitment copy to r/japanlife and LearnJapanese Discord
- [ ] Collect emails via DM/reply, add to TestFlight external tester group
- [ ] Send testers the Google Form survey link with their TestFlight invite
- [ ] Day 7: Review crash reports in App Store Connect, triage survey Q4/Q5 responses
- [ ] Day 7: Upload updated build if P0 bugs found
- [ ] Day 14: Close beta, review all survey responses, make final pre-submission fixes
- [ ] Create `kaiwa-reviewer@yumi.to` account in Clerk + approve in Convex + add subscription
- [ ] Fill in App Store Connect Review Information fields
- [ ] Create `APP_STORE_SUBMIT.md` with credential plan documented
- [ ] Submit to App Store Review
