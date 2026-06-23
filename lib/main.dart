import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'screens/splash_screen.dart';
import 'screens/login_screen.dart';
import 'screens/dashboard_screen.dart';
import 'screens/register_screen.dart';
import 'utils/constants.dart';

/// Fungsi utama (entry point) aplikasi.
/// Melakukan inisialisasi binding Flutter, lokalisasi tanggal Indonesia,
/// inisialisasi driver database SQLite (untuk platform desktop), dan menjalankan aplikasi.
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Menginisialisasi format tanggal dan waktu untuk locale id_ID (Bahasa Indonesia).
  await initializeDateFormatting('id_ID', null);

  // Menginisialisasi pustaka FFI SQLite jika aplikasi berjalan di platform Windows atau Linux (non-web).
  if (!kIsWeb && (Platform.isWindows || Platform.isLinux)) {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  }

  runApp(const GeoPresenceApp());
}

/// Widget utama kelas aplikasi yang mengatur konfigurasi tema, navigasi rute,
/// dan tampilan awal dari GeoPresence.
class GeoPresenceApp extends StatelessWidget {
  const GeoPresenceApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'GeoPresence',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(AppConstants.primaryColorValue),
          brightness: Brightness.light,
        ),
        useMaterial3: true,
        fontFamily: 'Inter',
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(AppConstants.primaryColorValue),
          foregroundColor: Colors.white,
          elevation: 0,
          centerTitle: true,
        ),
      ),
      darkTheme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(AppConstants.primaryColorValue),
          brightness: Brightness.dark,
        ),
        useMaterial3: true,
      ),
      home: const SplashScreen(),
      routes: {
        '/login': (context) => const LoginScreen(),
        '/dashboard': (context) => const DashboardScreen(),
        '/register': (context) => const RegisterScreen(),
      },
    );
  }
}
