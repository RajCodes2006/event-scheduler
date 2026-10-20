import 'dart:io' show Platform;

import 'package:flutter/material.dart';
import 'package:sqflite/sqflite.dart' as sqflite;
import 'package:sqflite_common_ffi/sqflite_ffi.dart' as sqflite_ffi;
import 'package:provider/provider.dart';

import 'screens/app_shell.dart';
import 'state/event_controller.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
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

  static const Color brandColor = Color(0xFF685CF0);

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<EventController>();
    return MaterialApp(
      title: 'Daymark',
      debugShowCheckedModeBanner: false,
      themeMode: controller.isDarkMode ? ThemeMode.dark : ThemeMode.light,
      theme: _buildTheme(Brightness.light),
      darkTheme: _buildTheme(Brightness.dark),
      home: const AppShell(),
    );
  }

  ThemeData _buildTheme(Brightness brightness) {
    final isDark = brightness == Brightness.dark;
    final scheme = ColorScheme.fromSeed(
      seedColor: brandColor,
      brightness: brightness,
      surface: isDark ? const Color(0xFF171925) : const Color(0xFFFFFFFF),
    );
    final background = isDark ? const Color(0xFF10111A) : const Color(0xFFF6F6FB);
    final border = isDark ? const Color(0xFF303345) : const Color(0xFFE6E7F0);

    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: scheme,
      scaffoldBackgroundColor: background,
      appBarTheme: AppBarTheme(
        backgroundColor: background,
        foregroundColor: scheme.onSurface,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
      ),
      cardTheme: CardThemeData(color: scheme.surface, elevation: 0, margin: EdgeInsets.zero),
      dividerTheme: DividerThemeData(color: border, thickness: 1, space: 1),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: scheme.surface,
        indicatorColor: scheme.secondaryContainer,
        labelTextStyle: WidgetStateProperty.resolveWith(
          (states) => TextStyle(
            fontSize: 12,
            fontWeight: states.contains(WidgetState.selected)
                ? FontWeight.w700
                : FontWeight.w500,
          ),
        ),
      ),
      navigationRailTheme: NavigationRailThemeData(
        backgroundColor: background,
        indicatorColor: scheme.secondaryContainer,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: isDark ? const Color(0xFF202333) : const Color(0xFFFFFFFF),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: scheme.primary, width: 1.6),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
    );
  }
}
