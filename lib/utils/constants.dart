// Konstanta aplikasi GeoPresence
class AppConstants {
  // Informasi Kantor / Lokasi Presensi
  static const double officeLatitude = -8.158300;
  static const double officeLongitude = 113.723400;
  static const String officeName = 'Lokasi Kantor';
  static const double maxDistance = 100.0; // meter

  // Batas Jam Presensi
  static const int jamMasukBatas = 7;   // 07:00
  static const int menitMasukBatas = 30; // 07:30

  // Warna Tema
  static const int primaryColorValue = 0xFF1565C0;
  static const int secondaryColorValue = 0xFF0288D1;

  // Nama Database
  static const String dbName = 'geo_presence.db';
  static const int dbVersion = 1;

  // Nama Tabel
  static const String tableUser = 'user';
  static const String tablePresensi = 'presensi';

  // Shared Preferences Keys
  static const String prefUserId = 'user_id';
  static const String prefUserNama = 'user_nama';
  static const String prefIsLogin = 'is_login';
}
