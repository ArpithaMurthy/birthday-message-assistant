# Setup, migration, and verification

This guide is the recovery checklist for a new Windows laptop and the test plan for confirming that Moments Remembered works as intended.

## Important distinction: source code versus personal data

Git stores the application source code. It does **not** store occasions entered into the app.

- Flutter app data is stored locally on the phone by `SharedPreferences`.
- Web Lite data is stored in that browser's `localStorage`.
- Deleting the app, clearing browser/site data, or replacing a phone can remove that data.
- Calendar export creates a portable `.ics` snapshot. Import it into Apple Calendar, Google Calendar, or Outlook before changing devices.
- A later encrypted backup/import feature is still needed for complete app-data migration.

Never commit personal occasion data, phone numbers, signing keys, or exported calendars containing private information.

## Restore the source on another Windows laptop

### 1. Install prerequisites

Install:

1. Git
2. VS Code with the Flutter and Dart extensions
3. Flutter stable
4. Android Studio
5. Android SDK Platform, Build-Tools, Platform-Tools, and Command-line Tools

Recommended locations:

- Flutter: `C:\Users\<you>\flutter`
- Android SDK: `C:\Users\<you>\AppData\Local\Android\Sdk`
- Android Studio JDK: use Android Studio's embedded JDK

Add Flutter's `bin` directory to the user `PATH`.

### 2. Clone and validate

Clone the private GitHub repository while signed in as its owner:

```text
git clone https://github.com/ArpithaMurthy/birthday-message-assistant.git
cd birthday-message-assistant
```

Open that folder, then run:

```text
flutter doctor -v
flutter pub get
flutter analyze
flutter test
flutter build apk --debug
```

The debug APK is generated at:

```text
build\app\outputs\flutter-apk\app-debug.apk
```

The repository already contains Android and iOS host projects. Do not run `flutter create .` during a normal restore. Use it only when intentionally regenerating missing platform files, then review every resulting change before committing.

### 3. Android license recovery

If Flutter reports unaccepted licenses:

```text
flutter doctor --android-licenses
```

If it reports missing command-line tools, install **Android SDK Command-line Tools (latest)** from Android Studio's SDK Manager, then rerun the command.

Visual Studio is not required for Android, iOS, or Web Lite. Its warning can be ignored unless a Windows desktop build is wanted.

## Verify on an Android phone

A real Android phone is preferable because an emulator cannot fully validate SMS and WhatsApp handoff.

### Install

1. Enable Developer options and USB debugging on the phone.
2. Connect it with USB and approve the computer.
3. Confirm it appears with `flutter devices`.
4. Run `flutter run`, or copy and install the debug APK.

Do not distribute the debug APK publicly. A Play release needs a private release signing key and an Android App Bundle.

### Functional checks

1. Add a birthday, anniversary, holiday, New Year, and custom occasion.
2. Close and reopen the app; confirm all occasions remain.
3. Confirm sorting and countdowns, including an occasion today.
4. Prepare each message tone and edit its text.
5. Verify SMS, WhatsApp, and the share sheet open with the draft, but do not send automatically.
6. Mark an occasion handled and confirm the status survives an app restart.
7. Remove an occasion and confirm it stays removed.
8. Export the calendar and import it into a calendar application.
9. Confirm the imported event repeats yearly and contains advance reminders.

### Closed-app notification test

The production schedule is 7 days, 1 day, and the occasion morning at approximately 09:00 local time. Inexact Android scheduling may be delayed by the operating system.

For a practical test:

1. Add an occasion that is tomorrow and enable reminders.
2. Force-close the UI by swiping the app away; do not use **Force stop** in Android Settings.
3. Leave the phone powered on and verify the reminder appears around 09:00.
4. Restart the phone and verify future reminders still appear.
5. Repeat once with battery optimization enabled and once with it disabled for the app.

Android **Force stop** intentionally blocks alarms and notifications until the user launches the app again. Some manufacturers also impose aggressive battery restrictions; document the phone model when a reminder is delayed.

Keep a normal calendar reminder as a control until notification delivery has been observed on the target phone.

## Verify on iPhone without a Mac

Use Web Lite and calendar export:

1. Serve or deploy `web-lite/` over HTTPS.
2. Open it in Safari on the iPhone.
3. Add occasions and select **Export calendar**.
4. Import the `.ics` file into Apple Calendar.
5. Confirm yearly recurrence and alerts in Calendar.

Browser data remains only in that Safari profile. Calendar notifications continue independently after import, even when the browser is closed.

A native iPhone build requires macOS, Xcode, signing, and physical-device notification testing.

## Verify Web Lite locally

Opening the HTML file directly works in ordinary browsers, but using a local server better matches deployment:

```text
npx --yes http-server web-lite -p 8080 -c-1
```

Open `http://localhost:8080`, add an occasion, refresh the page, prepare a message, and export the calendar. Delete the test browser data after testing if it contains real personal details.

## Docker: useful but optional

Docker is useful only for serving and checking the static Web Lite experience consistently. It does not:

- build or emulate the Flutter mobile app,
- provide native Android/iOS notifications,
- preserve Web Lite browser data,
- synchronize personal occasions, or
- remove the need for Android Studio/Xcode.

With Docker Desktop's Linux engine running:

```text
docker compose up --build
```

Open `http://localhost:8080`. Stop it with:

```text
docker compose down
```

For public hosting, a static host such as GitHub Pages is simpler and cheaper than maintaining a container server. HTTPS is recommended for mobile sharing and browser capabilities.

## Before switching laptops

1. Ensure `git status` is clean.
2. Push every source commit to a private or public GitHub repository.
3. Confirm the remote commit is visible on GitHub.
4. Export personal occasions to a calendar or another safe personal backup.
5. Back up any future Android release keystore separately in a password manager or secure drive; never commit it.
6. Record the application ID: `com.arpithamurthy.moments_remembered`.
