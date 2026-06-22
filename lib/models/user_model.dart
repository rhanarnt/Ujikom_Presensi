class UserModel {
  int? idUser;
  String nama;
  String email;
  String password;
  String? foto;

  /// Konstruktor untuk membuat instance [UserModel].
  /// [idUser] bersifat opsional karena diisi otomatis oleh database.
  /// [nama], [email], dan [password] wajib diisi.
  /// [foto] bersifat opsional untuk menyimpan path atau URL foto profil pengguna.
  UserModel({
    this.idUser,
    required this.nama,
    required this.email,
    required this.password,
    this.foto,
  });

  /// Mengonversi instance [UserModel] menjadi [Map] dengan format key-value.
  /// Digunakan untuk menyimpan data pengguna ke database SQLite atau mengirimkannya ke API.
  Map<String, dynamic> toMap() {
    return {
      'id_user': idUser,
      'nama': nama,
      'email': email,
      'password': password,
      'foto': foto,
    };
  }

  /// Membuat instance [UserModel] baru dari data [Map] (biasanya didapatkan dari database SQLite atau respon API).
  factory UserModel.fromMap(Map<String, dynamic> map) {
    return UserModel(
      idUser: map['id_user'],
      nama: map['nama'],
      email: map['email'],
      password: map['password'],
      foto: map['foto'],
    );
  }

  /// Membuat salinan objek [UserModel] baru dengan beberapa atribut yang diubah nilainya.
  /// Jika suatu parameter tidak diberikan, nilai atribut dari objek saat ini akan dipertahankan.
  UserModel copyWith({
    int? idUser,
    String? nama,
    String? email,
    String? password,
    String? foto,
  }) {
    return UserModel(
      idUser: idUser ?? this.idUser,
      nama: nama ?? this.nama,
      email: email ?? this.email,
      password: password ?? this.password,
      foto: foto ?? this.foto,
    );
  }
}
