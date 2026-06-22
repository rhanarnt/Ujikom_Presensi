class PresensiModel {
  int? idPresensi;
  int idUser;
  String tanggal;
  String? jamMasuk;
  String? jamKeluar;
  double? latitude;
  double? longitude;
  String? status; // Tepat Waktu / Terlambat
  String? fotoMasuk;
  String? fotoKeluar;

  /// Konstruktor untuk membuat instance [PresensiModel].
  /// [idPresensi] bersifat opsional karena diisi otomatis oleh database.
  /// [idUser] dan [tanggal] wajib diisi.
  /// Atribut lainnya seperti jam masuk, jam keluar, lokasi (latitude/longitude), status, serta foto bersifat opsional.
  PresensiModel({
    this.idPresensi,
    required this.idUser,
    required this.tanggal,
    this.jamMasuk,
    this.jamKeluar,
    this.latitude,
    this.longitude,
    this.status,
    this.fotoMasuk,
    this.fotoKeluar,
  });

  /// Mengonversi instance [PresensiModel] menjadi [Map] dengan format key-value.
  /// Digunakan untuk menyimpan data presensi ke database SQLite atau mengirimkannya ke API.
  Map<String, dynamic> toMap() {
    return {
      'id_presensi': idPresensi,
      'id_user': idUser,
      'tanggal': tanggal,
      'jam_masuk': jamMasuk,
      'jam_keluar': jamKeluar,
      'latitude': latitude,
      'longitude': longitude,
      'status': status,
      'foto_masuk': fotoMasuk,
      'foto_keluar': fotoKeluar,
    };
  }

  /// Membuat instance [PresensiModel] baru dari data [Map] (biasanya didapatkan dari database SQLite atau respon API).
  factory PresensiModel.fromMap(Map<String, dynamic> map) {
    return PresensiModel(
      idPresensi: map['id_presensi'],
      idUser: map['id_user'],
      tanggal: map['tanggal'],
      jamMasuk: map['jam_masuk'],
      jamKeluar: map['jam_keluar'],
      latitude: map['latitude'],
      longitude: map['longitude'],
      status: map['status'],
      fotoMasuk: map['foto_masuk'],
      fotoKeluar: map['foto_keluar'],
    );
  }
}
