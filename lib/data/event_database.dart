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
      // Windows needs a stable writable app-data folder; getDatabasesPath()
      // is not a suitable default for the FFI implementation on desktop.
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
      version: 2,
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
            reminder_minutes_before INTEGER NOT NULL DEFAULT 15
          )
        ''');
      },
      onUpgrade: (db, oldVersion, newVersion) async {
        if (oldVersion < 2) {
          await db.execute(
            'ALTER TABLE events ADD COLUMN reminder_minutes_before INTEGER NOT NULL DEFAULT 15',
          );
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
}
