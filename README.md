# Moments Remembered

A private, local-first occasion reminder and message companion for Android, iPhone, and the web.

## Product promise

Remember important people, prepare something thoughtful, and follow through on time.

The app deliberately does **not** send messages automatically. It prepares an editable draft and opens SMS, WhatsApp, or the system share sheet. The user reviews and presses Send.

## What the personal MVP includes

1. Add birthdays, anniversaries, New Year, holidays, or custom occasions.
2. See the next occurrence and a human-friendly countdown.
3. Receive local reminders 7 days, 1 day, and the morning of the occasion—even when the app is closed.
4. Start from warm, playful, short, or formal message templates.
5. Edit every word and open a messaging app for approval.
6. Mark the occasion handled to prevent accidental duplicate follow-up.
7. Keep all personal data on the phone. There is no account, server, advertising SDK, analytics SDK, or contact upload.
8. Export a recurring `.ics` calendar containing reminders for Apple Calendar, Google Calendar, or Outlook.

## Use it without installing an app

Open [web-lite/index.html](web-lite/index.html) in a browser or deploy that folder as a static website. It stores occasions only in that browser and can download a recurring calendar file. Importing the file into the phone's calendar provides closed-browser reminders without an App Store download or notification server.

## Stage-by-stage plan

### Stage 1 — validate personally (implemented)

Use manual entry for several real occasions. Validate reminder reliability, message quality, and whether the workflow saves time.

### Stage 2 — small private test

Invite 5–10 trusted Android users through a closed Play test. Improve onboarding, accessibility, notification recovery, editing, and deletion. Add optional contact import only if testers request it.

### Stage 3 — first store release

Prepare the privacy policy, screenshots, icon, Play data-safety form, signed Android App Bundle, and store description. Keep the app free and ad-free while measuring whether users return and complete occasion actions.

### Stage 4 — sustainable monetization

If retention exists, consider a one-time Pro upgrade for advanced reminder schedules, more templates, encrypted backup/export, and optional AI drafts. Affiliate links for cards, flowers, or cakes can be tested later. Avoid advertising in private message flows.

### Stage 5 — iPhone

Open this same repository on macOS, install Xcode and Flutter, run `flutter create .` if platform files need refreshing, configure signing, test notification behavior on a physical iPhone, and distribute with TestFlight. App Store publication requires an Apple Developer Program membership.

## Development setup on Windows

Flutter source code is present. Generate or refresh platform projects after Flutter and Android Studio are ready:

```text
flutter create --org com.arpithamurthy --project-name moments_remembered --platforms android,ios .
flutter pub get
flutter analyze
flutter test
flutter run
```

The first `flutter create` command preserves the `lib`, `test`, and project documentation while adding standard Android and iOS host projects.

## Android configuration

After platform generation, verify these permissions in the Android manifest:

- `POST_NOTIFICATIONS`
- `RECEIVE_BOOT_COMPLETED`
- `SCHEDULE_EXACT_ALARM` is not required because reminders use inexact scheduling.

Follow the current `flutter_local_notifications` setup guide for Gradle desugaring and notification receivers. Test on a physical device with battery optimization both enabled and disabled.

## iOS configuration

After platform generation on macOS:

- Add notification usage messaging where required.
- Test permission denial and later enabling in Settings.
- Test SMS/iMessage composition on a physical iPhone.
- Messages remain user-approved; iOS does not permit silent iMessage sending through public APIs.

## Privacy

See [docs/PRIVACY.md](docs/PRIVACY.md). Occasion details and message drafts remain local. Store listing privacy declarations must be reviewed whenever a contact, analytics, advertising, AI, backup, or commerce feature is added.
