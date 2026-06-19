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
