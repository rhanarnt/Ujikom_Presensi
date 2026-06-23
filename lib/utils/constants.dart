// Konstanta aplikasi GeoPresence
/// Kelas yang menampung seluruh konstanta global aplikasi GeoPresence.
/// Berisi konfigurasi koordinat kantor, batas waktu masuk, skema warna tema,
/// konfigurasi database SQLite, dan kunci untuk penyimpanan SharedPreferences.
class AppConstants {
  // ===================== INFORMASI KANTOR / LOKASI PRESENSI =====================
  
  /// Koordinat garis lintang (Latitude) default untuk lokasi kantor.
  static const double officeLatitude = -8.158300;
  
  /// Koordinat garis bujur (Longitude) default untuk lokasi kantor.
  static const double officeLongitude = 113.723400;
  
  /// Nama default penanda lokasi kantor.
  static const String officeName = 'Lokasi Kantor';
  
  /// Radius batas jarak maksimal (dalam meter) bagi pengguna agar dapat melakukan presensi.
  static const double maxDistance = 100.0;

  // ===================== BATAS JAM PRESENSI MASUK =====================
  
  /// Jam batas maksimal absensi masuk tepat waktu (misal: 7 = pukul 07:00).
  static const int jamMasukBatas = 7;
  
  /// Menit batas maksimal absensi masuk tepat waktu (misal: 30 = pukul 07:30).
  static const int menitMasukBatas = 30;

  // ===================== WARNA TEMA UTAMA APLIKASI =====================
  
  /// Nilai warna primer (Biru gelap).
  static const int primaryColorValue = 0xFF1565C0;
  
  /// Nilai warna sekunder (Biru terang).
  static const int secondaryColorValue = 0xFF0288D1;

  // ===================== KONFIGURASI DATABASE SQLITE =====================
  
  /// Nama file database SQLite.
  static const String dbName = 'geo_presence.db';
  
  /// Versi database SQLite yang sedang digunakan.
  static const int dbVersion = 2;

  // ===================== NAMA TABEL DATABASE =====================
  
  /// Nama tabel untuk data pengguna/karyawan.
  static const String tableUser = 'user';
  
  /// Nama tabel untuk data kehadiran/presensi harian.
  static const String tablePresensi = 'presensi';

  // ===================== KUNCI SHAREDPREFERENCES (SESI & KACHE) =====================
  
  /// Kunci penyimpanan ID Pengguna yang sedang masuk.
  static const String prefUserId = 'user_id';
  
  /// Kunci penyimpanan Nama Pengguna yang sedang masuk.
  static const String prefUserNama = 'user_nama';
  
  /// Kunci penanda apakah status pengguna sedang dalam kondisi login.
  static const String prefIsLogin = 'is_login';
  
  /// Kunci penyimpanan koordinat Latitude kantor dinamis.
  static const String prefOfficeLat = 'office_lat';
  
  /// Kunci penyimpanan koordinat Longitude kantor dinamis.
  static const String prefOfficeLng = 'office_lng';
  
  /// Kunci penyimpanan radius toleransi absen dinamis.
  static const String prefOfficeRadius = 'office_radius';
}
