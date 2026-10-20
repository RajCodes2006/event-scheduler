# Daymark — Event Scheduler

Daymark is a minimal personal event scheduler built with Flutter. It is designed for **Android and Windows** with an offline-first SQLite database.

## Features

- Home dashboard with today's and upcoming events
- Monthly calendar with markers for scheduled dates
- Create, edit, and delete events
- Daily, weekly, and monthly repeating event series with individual or whole-series deletion
- Event title, category, notes, location, date, start time, and end time
- On-device event reminders (5, 10, 15, 30, or 60 minutes before, or off)
- Local SQLite persistence
- Search by event title, notes, location, or category with date and category filters
- Persistent light and dark themes
- Refined Material 3 interface with indigo gradients and category-aware event cards
- Custom Daymark calendar-and-reminder launcher icon on Android and Windows
- Download page for Android and Windows builds

## Download

Visit the Daymark website to find the latest app builds:

**https://daymark-download.vercel.app/**

Releases and release notes are also available here:

**https://github.com/RajCodes2006/event-scheduler/releases**

### Android

1. Download `app-release.apk` from a GitHub Release.
2. Open the APK on your Android device.
3. Approve installation from your browser or file manager if Android asks.

### Windows

1. Download `daymark-windows-x64.zip` from a GitHub Release.
2. Extract the ZIP to a folder.
3. Run `event_scheduler.exe` from the extracted folder. Keep the included DLL and `data` files beside the executable.

Windows downloads target **64-bit Windows**. The ZIP is a portable app package, not an installer.

## Development setup

Install Flutter and the Android SDK for Android builds. To build Windows locally, use Windows with Visual Studio's **Desktop development with C++** workload installed.

From the project root:

```powershell
flutter pub get
```

If the Windows platform folder is not present yet, generate it:

```powershell
flutter create --platforms=windows --project-name event_scheduler .
```

Run on a connected Android phone or emulator:

```powershell
flutter devices
flutter run
```

Run the Windows desktop app on a properly configured Windows development machine:

```powershell
flutter run -d windows
```

## Project structure

```text
lib/
  main.dart
  data/event_database.dart
  models/schedule_event.dart
  services/notification_service.dart
  screens/
    app_shell.dart
    home_screen.dart
    calendar_screen.dart
    event_form_screen.dart
  state/event_controller.dart
  widgets/event_card.dart
website/
  index.html
.github/workflows/
  flutter-checks.yml
  release-apk.yml
tools/
  create_windows_icon.py
```

## Publishing new builds

1. Configure the repository secrets `ANDROID_KEYSTORE_BASE64`, `ANDROID_KEYSTORE_PASSWORD`, `ANDROID_KEY_ALIAS`, and `ANDROID_KEY_PASSWORD` with a persistent signing key.
2. Open **Actions → Build and publish Android + Windows downloads** in GitHub.
3. Select **Run workflow** and enter a new version tag such as `v1.0.4` (each release should use a new tag).
4. Wait for Android and Windows builds to finish. The workflow publishes the APK and Windows ZIP together.
5. The website checks the latest GitHub Release and updates both download buttons automatically. The matching app version is maintained in `pubspec.yaml`.

Never commit the keystore or its passwords to the repository.

The website is a static HTML page, deployed from the `website` directory. The Windows release workflow generates and applies the custom ICO before building the desktop package.

## Storage and platform notes

- Event data is stored locally on each device; it does not sync between devices yet.
- Android uses the native sqflite plugin.
- Windows uses `sqflite_common_ffi` and saves its database under the application's support directory.
- Android local reminders are scheduled on-device and can alert while Daymark is closed; notification permission is requested when saving an event with a reminder.
- Choose no reminder, 5, 10, 15, or 30 minutes, or 1 hour before the event.
- Reminder times are stored with events in SQLite. Existing events migrate to a 15-minute default.
- Recurring events are stored as separate occurrence rows with a shared series identifier so each occurrence can have its own reminder and can be deleted independently.
- Dark-mode preference is stored locally and survives app restarts.
- Reminders are currently supported on Android only; Windows reminder scheduling is not yet supported.
- Events appear on their start date in the calendar. Overnight events can be created but are listed under their start date.
