import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:crypto/crypto.dart';
import 'dart:convert';
import '../models/user_model.dart';
import '../models/presensi_model.dart';
import '../utils/constants.dart';

class DatabaseHelper {
  static final DatabaseHelper _instance = DatabaseHelper._internal();
  factory DatabaseHelper() => _instance;
  DatabaseHelper._internal();

  static Database? _database;

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, AppConstants.dbName);

    return await openDatabase(
      path,
      version: AppConstants.dbVersion,
      onCreate: _onCreate,
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    // Tabel User
    await db.execute('''
      CREATE TABLE ${AppConstants.tableUser} (
        id_user INTEGER PRIMARY KEY AUTOINCREMENT,
        nama TEXT NOT NULL,
        email TEXT NOT NULL UNIQUE,
        password TEXT NOT NULL,
        foto TEXT
      )
    ''');

    // Tabel Presensi
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

    // Insert user demo
    final passwordHash = _hashPassword('admin123');
    await db.insert(AppConstants.tableUser, {
      'nama': 'Ahmad Roihan',
      'email': 'admin@geopresence.com',
      'password': passwordHash,
      'foto': null,
    });
  }

  String _hashPassword(String password) {
    final bytes = utf8.encode(password);
    final digest = sha256.convert(bytes);
    return digest.toString();
  }

  // ===================== USER OPERATIONS =====================

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

  Future<int> registerUser(UserModel user) async {
    final db = await database;
    final userMap = user.toMap();
    userMap['password'] = _hashPassword(user.password);
    userMap.remove('id_user');
    return await db.insert(AppConstants.tableUser, userMap);
  }

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

  Future<int> updatePassword(int userId, String newPassword) async {
    final db = await database;
    return await db.update(
      AppConstants.tableUser,
      {'password': _hashPassword(newPassword)},
      where: 'id_user = ?',
      whereArgs: [userId],
    );
  }

  // ===================== PRESENSI OPERATIONS =====================

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

  Future<int> insertPresensiMasuk(PresensiModel presensi) async {
    final db = await database;
    final map = presensi.toMap();
    map.remove('id_presensi');
    return await db.insert(AppConstants.tablePresensi, map);
  }

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

  Future<void> closeDatabase() async {
    if (_database != null) {
      await _database!.close();
      _database = null;
    }
  }
}
