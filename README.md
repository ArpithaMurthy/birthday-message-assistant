# TinyTools Life Admin

A private, local-first life-admin reminder companion for Android, iPhone, and the web.

## Product promise

Remember important people, renewals, bills, gifts, home tasks, and admin deadlines so you follow through on time.

The app deliberately does **not** send messages automatically. It prepares an editable draft or action note and opens SMS, WhatsApp, LINE, a saved action link, or the system share sheet. The user reviews and presses Send or completes the action.

The main add flow stays intentionally small: choose a quick preset, pick a date, add a title, optionally add a person/item and note, then save. Module, repeat, channel, phone, action link, and default message are available under **Advanced details** when needed.

## What the personal MVP includes

1. Add birthdays, anniversaries, renewals, visa/admin deadlines, home maintenance, bills, gifts, job-search follow-ups, family-care tasks, or custom reminders from quick presets.
2. See the next occurrence and a human-friendly countdown.
3. Receive local reminders 7 days, 1 day, and the morning of the occasion—even when the app is closed.
4. Start from warm, playful, short, formal, or saved default message/action templates.
5. Edit every word and open WhatsApp, LINE, SMS/iMessage, an action link, or the share sheet for approval.
6. Mark the occasion handled to prevent accidental duplicate follow-up.
7. Keep all personal data on the phone. There is no account, server, advertising SDK, analytics SDK, or contact upload.
8. Export a recurring `.ics` calendar containing reminders for Apple Calendar, Google Calendar, or Outlook.

## Use it without installing an app

Open [web-lite/index.html](web-lite/index.html) in a browser or deploy that folder as a static website. It stores occasions only in that browser and can download a recurring calendar file. Importing the file into the phone's calendar provides closed-browser reminders without an App Store download or notification server.

## Deploy Web Lite for anyone to use

The repository includes a GitHub Pages workflow at `.github/workflows/deploy-web-lite.yml` that publishes only the static `web-lite/` folder. The deployed app stores each user's reminders in that user's browser `localStorage`; there is no server account, database, analytics SDK, or contact upload.

Adding or importing occasions in Web Lite does **not** automatically add them to a calendar. The user must click **Export calendar** and import the downloaded `.ics` file into Apple Calendar, Google Calendar, or Outlook. Reminder delivery then depends on that calendar app and the user's device notification settings. If calendar notifications are disabled, the browser app cannot force a reminder.

To deploy:

1. Push the repository to GitHub.
2. In GitHub, open **Settings > Pages**.
3. Set **Build and deployment > Source** to **GitHub Actions**.
4. Run the **Deploy Web Lite** workflow manually, or push a change under `web-lite/`.

For a public repository, the app URL is:

```text
https://ArpithaMurthy.github.io/tinytools/
```

If the repository stays private, confirm your GitHub plan and Pages visibility settings support public access. If you need a guaranteed public URL while keeping the repo private, deploy `web-lite/` to a static host such as Azure Static Web Apps, Netlify, Vercel, or Cloudflare Pages.

## Add your people, reminders, and default messages

Web Lite is login-free by design. Use **Import data** to load a local JSON or CSV file; the file is read in the browser and is not uploaded to a server. Use **Export data** to back up or move the same browser-local list to another device.

JSON format:

```json
{
  "schemaVersion": 1,
  "occasions": [
    {
      "module": "Occasions",
      "type": "Birthday",
      "title": "Birthday",
      "date": "2026-09-20",
      "person": "Maya",
      "relationship": "Friend",
      "channel": "WhatsApp",
      "phone": "+886912345678",
      "repeat": "yearly",
      "actionUrl": "",
      "notes": "Mention the hiking trip.",
      "defaultMessage": "Happy birthday, Maya! Hope your day is full of joy."
    }
  ]
}
```

CSV format:

```csv
module,type,title,date,person,relationship,channel,phone,repeat,action_url,notes,default_message
Occasions,Birthday,Birthday,2026-09-20,Maya,Friend,WhatsApp,+886912345678,yearly,,Mention the hiking trip.,Happy birthday Maya!
Documents & renewals,Renewal,Passport renewal,Oct 12,,Passport,Share,,none,https://example.com/passport,Check required documents.,
Subscriptions & bills,Bill,Phone bill,1/9,,Bills,Share,,monthly,,Pay before due date.,
```

Dates may use `YYYY-MM-DD`, `Jan 9`, `9 Jan`, `Dec 11th`, or `7/12`. Optional fields include `module`, `channel` (`Share`, `WhatsApp`, `LINE`, or `SMS`), `phone`, `repeat` (`yearly`, `monthly`, or `none`), and `action_url`. If `defaultMessage` or `default_message` is present, **Prepare** starts from that exact text; otherwise the app generates a simple draft from the reminder type, person, and notes.

The easiest user flow is:

1. Import or add occasions once.
2. Export and import the calendar so the phone reminds them.
3. When reminded, open Web Lite, tap **Prepare message**, then tap **WhatsApp**, **LINE**, **SMS**, or **Share**.
4. The selected app opens with the draft. The user reviews and presses Send.

WhatsApp and SMS can use a saved phone number. LINE web sharing opens LINE with the message text, but the user still chooses the recipient; LINE does not provide a safe public web API for silently selecting a friend and sending.

## Moving to another laptop

Follow [docs/SETUP_AND_VERIFICATION.md](docs/SETUP_AND_VERIFICATION.md) for the complete clone, Android SDK, build, phone-testing, iPhone/Web Lite, and Docker workflow.

Git preserves source code, not personal reminders. Mobile data stays on the phone and Web Lite data stays in that browser. Exporting a calendar provides a portable reminder snapshot; encrypted app backup/import remains future work.

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

After cloning the repository and installing Flutter and Android Studio:

```text
flutter pub get
flutter analyze
flutter test
flutter build apk --debug
flutter run
```

Android and iOS host projects are already versioned. Do not regenerate them during a normal laptop migration.

## Native mobile app UX

The Flutter app is the best no-hosting path because it keeps data on the phone and uses native local notifications. The main flow is intentionally short:

1. Open the app and tap **Import list** or **Add one occasion**.
2. Enable reminders once.
3. When a reminder arrives, tap the occasion.
4. Review the draft and tap **Open WhatsApp**, **Open LINE**, **Open SMS / iMessage**, or **Open Share**.
5. The messaging app opens with the draft; the user still presses Send.

The app supports local CSV/JSON import by pasting data into **Import list**, plus JSON backup export from the home menu. Supported import fields match Web Lite: `type`, `title`, `date`, `person`, `relationship`, `channel`, `phone`, `notes`, and `default_message`. Friendly dates such as `Jan 9`, `9 Jan`, `Dec 11th`, `7/12`, and `2026-01-09` are accepted.

There is still no server account, hosting, analytics SDK, contact upload, or automatic message sending.

GitHub Actions runs **Mobile CI** on mobile changes: `flutter analyze`, `flutter test`, and `flutter build apk --debug`. The debug APK is uploaded as an artifact named `tinytools-debug-apk`, which is useful for private friend testing before spending money on store publication.

## TinyTools launch workflow

Use `scripts/launch_agent.py` to prepare validation posts without storing social-media credentials or auto-posting blindly.

```powershell
python scripts\launch_agent.py --channel all
python scripts\launch_agent.py --channel x --open
python scripts\launch_agent.py --channel reddit_sideproject --open
python scripts\launch_agent.py --mark-posted x
```

The helper writes drafts to `launch_outbox/` and can open X/Reddit/Indie Hackers composer pages. You still review and press Post manually. `launch_outbox/` is gitignored because it is working state, not product code.

You can also prepare launch drafts from any laptop or mobile browser without cloning the repo:

1. Open the GitHub repository.
2. Go to **Actions > Prepare Launch Posts**.
3. Tap **Run workflow** and choose `all` or one channel.
4. Open the generated GitHub issue.
5. Use the composer links and copy blocks from that issue to post manually from whichever device is logged in.

This workflow does not need or store X, Reddit, or Indie Hackers credentials. Keep those accounts logged in only in your own browser/app.

Recommended channels for first validation:

1. X from your existing account if it already has relevant followers.
2. Reddit with a separate TinyTools account; follow each subreddit self-promotion rules.
3. Indie Hackers with a TinyTools/your-name profile.

Instagram is secondary: useful later for a short visual demo or carousel, but weaker for early product feedback than X, Reddit, and Indie Hackers.

## Optional Web Lite container

Docker provides a repeatable local server for `web-lite/`, but is not needed for Flutter development and cannot provide native mobile notifications:

```text
docker compose up --build
```

Then open `http://localhost:8080`. Static hosting is preferable for a public deployment.

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
