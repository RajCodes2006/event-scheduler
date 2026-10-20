import 'dart:io' show Directory, Platform;

import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';

import '../models/schedule_event.dart';

class EventDatabase {
  EventDatabase._();

  static final EventDatabase instance = EventDatabase._();
  static Database? _database;

  Future<Database> get database async {
    if (_database != null) return _database!;

    final String path;
    if (Platform.isWindows) {
      final supportDirectory = await getApplicationSupportDirectory();
      final appDirectory = Directory(p.join(supportDirectory.path, 'Daymark'));
      await appDirectory.create(recursive: true);
      path = p.join(appDirectory.path, 'daymark_events.db');
    } else {
      final dbPath = await getDatabasesPath();
      path = p.join(dbPath, 'daymark_events.db');
    }

    _database = await openDatabase(
      path,
      version: 3,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE events (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            title TEXT NOT NULL,
            description TEXT NOT NULL DEFAULT '',
            location TEXT NOT NULL DEFAULT '',
            category TEXT NOT NULL DEFAULT 'Personal',
            start_at TEXT NOT NULL,
            end_at TEXT NOT NULL,
            reminder_minutes_before INTEGER NOT NULL DEFAULT 15,
            recurrence_series_id TEXT,
            recurrence_frequency TEXT NOT NULL DEFAULT 'none',
            recurrence_until TEXT
          )
        ''');
        await db.execute('''
          CREATE TABLE app_settings (
            setting_key TEXT PRIMARY KEY,
            setting_value TEXT NOT NULL
          )
        ''');
      },
      onUpgrade: (db, oldVersion, newVersion) async {
        // Version 2 introduced reminders; do not rebuild or clear existing rows.
        if (oldVersion < 2) {
          await db.execute(
            'ALTER TABLE events ADD COLUMN reminder_minutes_before INTEGER NOT NULL DEFAULT 15',
          );
        }
        // Version 3 adds recurrence metadata and a small settings table.
        // Existing event IDs, rows, and reminder values are retained.
        if (oldVersion < 3) {
          await db.execute(
            'ALTER TABLE events ADD COLUMN recurrence_series_id TEXT',
          );
          await db.execute(
            "ALTER TABLE events ADD COLUMN recurrence_frequency TEXT NOT NULL DEFAULT 'none'",
          );
          await db.execute(
            'ALTER TABLE events ADD COLUMN recurrence_until TEXT',
          );
          await db.execute('''
            CREATE TABLE IF NOT EXISTS app_settings (
              setting_key TEXT PRIMARY KEY,
              setting_value TEXT NOT NULL
            )
          ''');
        }
      },
    );

    return _database!;
  }

  Future<List<ScheduleEvent>> getAllEvents() async {
    final db = await database;
    final rows = await db.query('events', orderBy: 'start_at ASC');
    return rows.map(ScheduleEvent.fromMap).toList();
  }

  Future<int> insertEvent(ScheduleEvent event) async {
    final db = await database;
    final map = event.toMap()..remove('id');
    return db.insert('events', map);
  }

  Future<List<ScheduleEvent>> insertEvents(
    List<ScheduleEvent> events,
  ) async {
    if (events.isEmpty) return const [];
    final db = await database;
    return db.transaction((txn) async {
      final inserted = <ScheduleEvent>[];
      for (final event in events) {
        final map = event.toMap()..remove('id');
        final id = await txn.insert('events', map);
        inserted.add(event.copyWith(id: id));
      }
      return inserted;
    });
  }

  Future<int> updateEvent(ScheduleEvent event) async {
    final db = await database;
    return db.update(
      'events',
      event.toMap()..remove('id'),
      where: 'id = ?',
      whereArgs: [event.id],
    );
  }

  Future<int> deleteEvent(int id) async {
    final db = await database;
    return db.delete('events', where: 'id = ?', whereArgs: [id]);
  }

  Future<List<ScheduleEvent>> getSeriesEvents(String seriesId) async {
    final db = await database;
    final rows = await db.query(
      'events',
      where: 'recurrence_series_id = ?',
      whereArgs: [seriesId],
      orderBy: 'start_at ASC',
    );
    return rows.map(ScheduleEvent.fromMap).toList();
  }

  Future<int> deleteSeries(String seriesId) async {
    final db = await database;
    return db.delete(
      'events',
      where: 'recurrence_series_id = ?',
      whereArgs: [seriesId],
    );
  }

  Future<bool> getDarkModeEnabled() async {
    final db = await database;
    final rows = await db.query(
      'app_settings',
      columns: ['setting_value'],
      where: 'setting_key = ?',
      whereArgs: ['dark_mode'],
      limit: 1,
    );
    if (rows.isEmpty) return false;
    return rows.first['setting_value'] == 'true';
  }

  Future<void> setDarkModeEnabled(bool enabled) async {
    final db = await database;
    await db.insert(
      'app_settings',
      {'setting_key': 'dark_mode', 'setting_value': enabled ? 'true' : 'false'},
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }
}
