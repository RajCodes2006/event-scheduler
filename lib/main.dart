import 'dart:io' show Platform;

import 'package:flutter/material.dart';
import 'package:sqflite/sqflite.dart' as sqflite;
import 'package:sqflite_common_ffi/sqflite_ffi.dart' as sqflite_ffi;
import 'package:provider/provider.dart';

import 'screens/app_shell.dart';
import 'state/event_controller.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // On Windows, use the SQLite FFI implementation instead of the mobile plugin.
  if (Platform.isWindows) {
    sqflite_ffi.sqfliteFfiInit();
    sqflite.databaseFactory = sqflite_ffi.databaseFactoryFfi;
  }
  runApp(
    ChangeNotifierProvider(
      create: (_) => EventController()..loadEvents(),
      child: const EventSchedulerApp(),
    ),
  );
}

class EventSchedulerApp extends StatelessWidget {
  const EventSchedulerApp({super.key});

  static const Color brandColor = Color(0xFF5B5CE2);

  @override
  Widget build(BuildContext context) {
    final colorScheme = ColorScheme.fromSeed(
      seedColor: brandColor,
      brightness: Brightness.light,
    );

    return MaterialApp(
      title: 'Daymark',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: colorScheme,
        scaffoldBackgroundColor: const Color(0xFFF7F8FC),
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFFF7F8FC),
          surfaceTintColor: Colors.transparent,
          elevation: 0,
        ),
        cardTheme: const CardThemeData(
          color: Colors.white,
          elevation: 0,
          margin: EdgeInsets.zero,
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: Colors.white,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: Color(0xFFE4E6EF)),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: Color(0xFFE4E6EF)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: EventSchedulerApp.brandColor, width: 1.5),
          ),
        ),
      ),
      home: const AppShell(),
    );
  }
}
