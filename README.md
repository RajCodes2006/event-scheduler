# Daymark — Flutter Event Scheduler

A minimal personal event scheduler starter built with Flutter, Provider, `table_calendar`, and SQLite. It is designed for an offline-first Android/iOS app; cloud sync and reminders are intentionally left for the next development phase.

## Included in this starter

- Home dashboard with today's and upcoming events
- Month calendar with markers for scheduled dates
- Create and edit events
- Delete events with a confirmation prompt
- Event title, category, notes, location, date, start time, and end time
- SQLite persistence on Android/iOS (events survive app restarts)
- Material 3 layout with a minimal indigo theme

## 1. Check Flutter on your computer

Open PowerShell or the VS Code terminal:

```powershell
flutter doctor
```

Resolve any Android toolchain errors reported by Flutter Doctor before running the app.

## 2. Generate the platform project

Do this in the folder where you keep your projects:

```powershell
flutter create event_scheduler
cd event_scheduler
```

This creates the Android/iOS platform folders that are not included in this source archive.

## 3. Copy the starter files

Extract this archive. Copy its `lib` folder into the generated `event_scheduler` folder, replacing the generated `lib` folder. Then replace the generated `pubspec.yaml` with the one from this archive.

Keep the `android`, `ios`, and other platform folders created by `flutter create`.

## 4. Install dependencies

From the root of `event_scheduler`:

```powershell
flutter pub get
```

## 5. Run it

Start an Android emulator or connect an Android phone with USB debugging enabled, then run:

```powershell
flutter devices
flutter run
```

If Flutter offers multiple devices, select your Android emulator or phone.

## Project structure

```text
lib/
  main.dart
  data/event_database.dart
  models/schedule_event.dart
  screens/app_shell.dart
  screens/home_screen.dart
  screens/calendar_screen.dart
  screens/event_form_screen.dart
  state/event_controller.dart
  widgets/event_card.dart
```

## Current limits

- SQLite storage is local to the device. It does not sync across phones yet.
- Notifications/reminders are not included in this first milestone.
- The calendar currently shows events on their start date. Overnight events can be created, but are listed under their start date.
- `sqflite` targets Android/iOS in this starter; desktop and web require a different database setup.

## Next milestones

1. Run and validate the core CRUD flow on your device.
2. Add local notifications and reminder times.
3. Add optional cloud sync and sign-in when the offline version is stable.
