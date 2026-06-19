class UserModel {
  int? idUser;
  String nama;
  String email;
  String password;
  String? foto;

  UserModel({
    this.idUser,
    required this.nama,
    required this.email,
    required this.password,
    this.foto,
  });

  Map<String, dynamic> toMap() {
    return {
      'id_user': idUser,
      'nama': nama,
      'email': email,
      'password': password,
      'foto': foto,
    };
  }

  factory UserModel.fromMap(Map<String, dynamic> map) {
    return UserModel(
      idUser: map['id_user'],
      nama: map['nama'],
      email: map['email'],
      password: map['password'],
      foto: map['foto'],
    );
  }

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
