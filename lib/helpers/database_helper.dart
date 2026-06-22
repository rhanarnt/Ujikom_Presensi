import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:crypto/crypto.dart';
import 'dart:convert';
import '../models/user_model.dart';
import '../models/presensi_model.dart';
import '../utils/constants.dart';

class DatabaseHelper {
  // Singleton instance untuk memastikan hanya ada satu instance DatabaseHelper yang berjalan di aplikasi.
  static final DatabaseHelper _instance = DatabaseHelper._internal();
  
  // Factory constructor untuk mengembalikan instance singleton yang sama setiap kali dipanggil.
  factory DatabaseHelper() => _instance;
  
  // Named constructor internal untuk inisialisasi awal database helper.
  DatabaseHelper._internal();

  static Database? _database;

  // Getter asinkronus untuk mengambil instance database SQLite.
  // Jika database belum dibuat/dibuka, akan melakukan inisialisasi terlebih dahulu.
  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  // Menginisialisasi koneksi database SQLite dengan mengatur path penyimpanan dan versi database.
  Future<Database> _initDatabase() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, AppConstants.dbName);

    return await openDatabase(
      path,
      version: AppConstants.dbVersion,
      onCreate: _onCreate,
    );
  }

  // Callback yang dijalankan saat database pertama kali dibuat.
  // Di sini tabel 'User' dan 'Presensi' dibuat menggunakan query DDL (Data Definition Language).
  Future<void> _onCreate(Database db, int version) async {
    // Membuat Tabel User untuk menyimpan informasi akun pengguna/karyawan.
    await db.execute('''
      CREATE TABLE ${AppConstants.tableUser} (
        id_user INTEGER PRIMARY KEY AUTOINCREMENT,
        nama TEXT NOT NULL,
        email TEXT NOT NULL UNIQUE,
        password TEXT NOT NULL,
        foto TEXT
      )
    ''');

    // Membuat Tabel Presensi untuk mencatat data absen harian (masuk & keluar).
    // Memiliki relasi Foreign Key ke tabel User (id_user).
    await db.execute('''
      CREATE TABLE ${AppConstants.tablePresensi} (
        id_presensi INTEGER PRIMARY KEY AUTOINCREMENT,
        id_user INTEGER NOT NULL,
        tanggal TEXT NOT NULL,
        jam_masuk TEXT,
        jam_keluar TEXT,
        latitude REAL,
        longitude REAL,
        status TEXT,
        foto_masuk TEXT,
        foto_keluar TEXT,
        FOREIGN KEY (id_user) REFERENCES ${AppConstants.tableUser}(id_user)
      )
    ''');

    // Memasukkan (insert) user demo bawaan untuk login pertama kali saat aplikasi diuji.
    final passwordHash = _hashPassword('admin123');
    await db.insert(AppConstants.tableUser, {
      'nama': 'Ahmad Roihan',
      'email': 'admin@geopresence.com',
      'password': passwordHash,
      'foto': null,
    });
  }

  // Melakukan hashing password menggunakan algoritma SHA-256 demi keamanan data.
  // Password tidak disimpan dalam bentuk teks biasa (plain text) di database.
  String _hashPassword(String password) {
    final bytes = utf8.encode(password);
    final digest = sha256.convert(bytes);
    return digest.toString();
  }

  // ===================== USER OPERATIONS (OPERASI USER) =====================

  // Melakukan validasi login pengguna dengan mencocokkan email dan password yang telah di-hash.
  // Mengembalikan objek UserModel jika login berhasil, atau null jika gagal.
  Future<UserModel?> login(String email, String password) async {
    final db = await database;
    final hashedPassword = _hashPassword(password);
    final result = await db.query(
      AppConstants.tableUser,
      where: 'email = ? AND password = ?',
      whereArgs: [email, hashedPassword],
    );
    if (result.isNotEmpty) {
      return UserModel.fromMap(result.first);
    }
    return null;
  }

  // Mendaftarkan (registrasi) pengguna baru ke database SQLite.
  // Password pengguna akan di-hash terlebih dahulu sebelum disimpan ke tabel User.
  Future<int> registerUser(UserModel user) async {
    final db = await database;
    final userMap = user.toMap();
    userMap['password'] = _hashPassword(user.password);
    userMap.remove('id_user');
    return await db.insert(AppConstants.tableUser, userMap);
  }

  // Mengambil informasi data pengguna berdasarkan ID User.
  // Berguna untuk memperbarui session atau menampilkan profil pengguna.
  Future<UserModel?> getUserById(int id) async {
    final db = await database;
    final result = await db.query(
      AppConstants.tableUser,
      where: 'id_user = ?',
      whereArgs: [id],
    );
    if (result.isNotEmpty) return UserModel.fromMap(result.first);
    return null;
  }

  // Memperbarui data profil pengguna (Nama, Email, dan Foto Profil) di database SQLite.
  Future<int> updateUser(UserModel user) async {
    final db = await database;
    final userMap = {
      'nama': user.nama,
      'email': user.email,
      'foto': user.foto,
    };
    return await db.update(
      AppConstants.tableUser,
      userMap,
      where: 'id_user = ?',
      whereArgs: [user.idUser],
    );
  }

  // Memperbarui password pengguna dengan password baru yang di-hash menggunakan SHA-256.
  Future<int> updatePassword(int userId, String newPassword) async {
    final db = await database;
    return await db.update(
      AppConstants.tableUser,
      {'password': _hashPassword(newPassword)},
      where: 'id_user = ?',
      whereArgs: [userId],
    );
  }

  // ===================== PRESENSI OPERATIONS (OPERASI ABSENSI) =====================

  // Mengambil data presensi pengguna pada tanggal tertentu (biasanya hari ini).
  // Digunakan untuk mengecek apakah user sudah melakukan absen masuk atau absen keluar hari ini.
  Future<PresensiModel?> getPresensiHariIni(int userId, String tanggal) async {
    final db = await database;
    final result = await db.query(
      AppConstants.tablePresensi,
      where: 'id_user = ? AND tanggal = ?',
      whereArgs: [userId, tanggal],
    );
    if (result.isNotEmpty) return PresensiModel.fromMap(result.first);
    return null;
  }

  // Memasukkan data absen masuk pengguna baru ke tabel Presensi.
  // Menyimpan data waktu masuk, tanggal, lokasi GPS, foto selfie masuk, dan status (tepat waktu/terlambat).
  Future<int> insertPresensiMasuk(PresensiModel presensi) async {
    final db = await database;
    final map = presensi.toMap();
    map.remove('id_presensi');
    return await db.insert(AppConstants.tablePresensi, map);
  }

  // Memperbarui data presensi dengan menambahkan jam keluar dan foto selfie keluar saat pengguna melakukan absen pulang.
  Future<int> updatePresensiKeluar(
    int idPresensi,
    String jamKeluar,
    String? fotoKeluar,
  ) async {
    final db = await database;
    return await db.update(
      AppConstants.tablePresensi,
      {'jam_keluar': jamKeluar, 'foto_keluar': fotoKeluar},
      where: 'id_presensi = ?',
      whereArgs: [idPresensi],
    );
  }

  // Mengambil seluruh riwayat presensi milik pengguna tertentu.
  // Data diurutkan berdasarkan tanggal terbaru dan jam masuk terbaru.
  Future<List<PresensiModel>> getRiwayatPresensi(int userId) async {
    final db = await database;
    final result = await db.query(
      AppConstants.tablePresensi,
      where: 'id_user = ?',
      whereArgs: [userId],
      orderBy: 'tanggal DESC, jam_masuk DESC',
    );
    return result.map((e) => PresensiModel.fromMap(e)).toList();
  }

  // Menghitung statistik presensi pengguna untuk ditampilkan di dashboard.
  // Menghasilkan total hadir, jumlah terlambat, dan jumlah tepat waktu.
  Future<Map<String, int>> getStatistikPresensi(int userId) async {
    final db = await database;
    final all = await db.query(
      AppConstants.tablePresensi,
      where: 'id_user = ?',
      whereArgs: [userId],
    );

    int totalHadir = all.where((e) => e['jam_masuk'] != null).length;
    int terlambat = all.where((e) => e['status'] == 'Terlambat').length;
    int tepat = all.where((e) => e['status'] == 'Tepat Waktu').length;

    return {
      'total_hadir': totalHadir,
      'terlambat': terlambat,
      'tepat_waktu': tepat,
    };
  }

  // Menutup koneksi database SQLite saat tidak digunakan lagi untuk menghindari kebocoran memori (memory leak).
  Future<void> closeDatabase() async {
    if (_database != null) {
      await _database!.close();
      _database = null;
    }
  }
}
