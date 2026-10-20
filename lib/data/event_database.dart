import 'package:path/path.dart' as p;
import 'package:sqflite/sqflite.dart';

import '../models/schedule_event.dart';

class EventDatabase {
  EventDatabase._();

  static final EventDatabase instance = EventDatabase._();
  static Database? _database;

  Future<Database> get database async {
    if (_database != null) return _database!;

    final dbPath = await getDatabasesPath();
    final path = p.join(dbPath, 'daymark_events.db');

    _database = await openDatabase(
      path,
      version: 1,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE events (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            title TEXT NOT NULL,
            description TEXT NOT NULL DEFAULT '',
            location TEXT NOT NULL DEFAULT '',
            category TEXT NOT NULL DEFAULT 'Personal',
            start_at TEXT NOT NULL,
            end_at TEXT NOT NULL
          )
        ''');
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
