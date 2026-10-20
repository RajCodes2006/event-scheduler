# Daymark — Event Scheduler

Daymark is a minimal personal event scheduler built with Flutter. It is designed for **Android and Windows** with an offline-first SQLite database.

## Features

- Home dashboard with today's and upcoming events
- Monthly calendar with markers for scheduled dates
- Create, edit, and delete events
- Event title, category, notes, location, date, start time, and end time
- Local SQLite persistence
- Material 3 interface with an indigo theme
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
  deploy-site.yml
  release-apk.yml
```

## Publishing new builds

1. Open **Actions → Build and publish Android + Windows downloads** in GitHub.
2. Select **Run workflow**.
3. Enter a new version tag such as `v1.0.1` (each release should use a new tag).
4. Wait for Android and Windows builds to finish. The workflow publishes the APK and Windows ZIP together.
5. The website checks the latest GitHub Release and updates both download buttons automatically.

The website is a static HTML page, deployed from the `website` directory.

## Storage and platform notes

- Event data is stored locally on each device; it does not sync between devices yet.
- Android uses the native sqflite plugin.
- Windows uses `sqflite_common_ffi` and saves its database under the application's support directory.
- Notifications and cloud sync are not included in the current version.
- Events appear on their start date in the calendar. Overnight events can be created but are listed under their start date.
