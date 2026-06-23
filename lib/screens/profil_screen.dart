import 'dart:convert';
import 'dart:io';
import 'package:crypto/crypto.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../helpers/database_helper.dart';
import '../models/user_model.dart';
import '../utils/constants.dart';

/// Widget Halaman Profil untuk menampilkan data pengguna,
/// merubah biodata diri, mengunggah foto profil baru, dan merubah kata sandi.
class ProfilScreen extends StatefulWidget {
  final UserModel? user;
  final VoidCallback onProfileUpdated;

  const ProfilScreen({
    super.key,
    required this.user,
    required this.onProfileUpdated,
  });

  @override
  State<ProfilScreen> createState() => _ProfilScreenState();
}

/// State untuk mengelola input formulir edit profil, interaksi galeri foto, dan pembaruan password.
class _ProfilScreenState extends State<ProfilScreen> {
  final _formKey = GlobalKey<FormState>();
  final _formPasswordKey = GlobalKey<FormState>();

  late TextEditingController _namaCtrl;
  late TextEditingController _emailCtrl;
  late TextEditingController _nisnCtrl;
  late TextEditingController _kelasCtrl;

  final _oldPasswordCtrl = TextEditingController();
  final _newPasswordCtrl = TextEditingController();
  final _confirmNewPasswordCtrl = TextEditingController();

  String? _fotoPath;
  bool _isLoading = false;

  bool _obscureOldPassword = true;
  bool _obscureNewPassword = true;
  bool _obscureConfirmNewPassword = true;

  @override
  void initState() {
    super.initState();
    _namaCtrl = TextEditingController(text: widget.user?.nama ?? '');
    _emailCtrl = TextEditingController(text: widget.user?.email ?? '');
    _nisnCtrl = TextEditingController(text: widget.user?.nisn ?? '');
    _kelasCtrl = TextEditingController(text: widget.user?.kelas ?? '');
    _fotoPath = widget.user?.foto;
  }

  @override
  void dispose() {
    _namaCtrl.dispose();
    _emailCtrl.dispose();
    _nisnCtrl.dispose();
    _kelasCtrl.dispose();
    _oldPasswordCtrl.dispose();
    _newPasswordCtrl.dispose();
    _confirmNewPasswordCtrl.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(covariant ProfilScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Menyinkronkan ulang data form ketika data pengguna berhasil dimuat di Dashboard
    if (oldWidget.user != widget.user) {
      _namaCtrl.text = widget.user?.nama ?? '';
      _emailCtrl.text = widget.user?.email ?? '';
      _nisnCtrl.text = widget.user?.nisn ?? '';
      _kelasCtrl.text = widget.user?.kelas ?? '';
      setState(() {
        _fotoPath = widget.user?.foto;
      });
    }
  }

  /// Membuka galeri foto perangkat untuk memilih gambar baru sebagai foto profil.
  Future<void> _pilihFoto() async {
    try {
      final picker = ImagePicker();
      final XFile? foto = await picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 70,
      );
      if (foto != null) {
        setState(() => _fotoPath = foto.path);
      }
    } catch (e) {
      _showSnackBar('Gagal memilih foto: ${e.toString()}', true);
    }
  }

  /// Memvalidasi data form dan menyimpan perubahan biodata pengguna (Nama, Email, Foto) ke database SQLite.
  Future<void> _simpanProfil() async {
    if (!_formKey.currentState!.validate()) return;
    if (widget.user == null) return;

    setState(() => _isLoading = true);
    try {
      final db = DatabaseHelper();
      final updatedUser = widget.user!.copyWith(
        nama: _namaCtrl.text.trim(),
        email: _emailCtrl.text.trim(),
        foto: _fotoPath,
        nisn: _nisnCtrl.text.trim(),
        kelas: _kelasCtrl.text.trim(),
      );

      await db.updateUser(updatedUser);

      // Update session nama
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(AppConstants.prefUserNama, updatedUser.nama);

      widget.onProfileUpdated();
      if (mounted) _showSnackBar('Profil berhasil diperbarui', false);
    } catch (e) {
      if (mounted) _showSnackBar('Gagal menyimpan profil: ${e.toString()}', true);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  /// Menampilkan pesan pemberitahuan di bagian bawah layar menggunakan SnackBar.
  void _showSnackBar(String msg, bool isError) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: isError ? Colors.red.shade700 : Colors.green.shade700,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  // Melakukan hashing password dengan algoritma SHA-256 untuk dicocokkan dengan database
  String _hashPassword(String password) {
    final bytes = utf8.encode(password);
    final digest = sha256.convert(bytes);
    return digest.toString();
  }

  // Menangani perubahan kata sandi (password) pengguna.
  // Memvalidasi kesesuaian password lama, lalu mengupdate password baru ke database SQLite.
  Future<void> _ubahPassword() async {
    if (!_formPasswordKey.currentState!.validate()) return;
    if (widget.user == null) return;

    // 1. Memvalidasi kecocokan password lama
    final hashedOld = _hashPassword(_oldPasswordCtrl.text);
    if (hashedOld != widget.user!.password) {
      _showSnackBar('Password lama tidak sesuai', true);
      return;
    }

    setState(() => _isLoading = true);
    try {
      final db = DatabaseHelper();
      
      // 2. Memperbarui password baru di SQLite
      await db.updatePassword(widget.user!.idUser!, _newPasswordCtrl.text);

      // 3. Mengosongkan form input setelah berhasil
      _oldPasswordCtrl.clear();
      _newPasswordCtrl.clear();
      _confirmNewPasswordCtrl.clear();

      if (mounted) _showSnackBar('Password berhasil diperbarui', false);
    } catch (e) {
      if (mounted) _showSnackBar('Gagal memperbarui password: ${e.toString()}', true);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  /// Menampilkan dialog konfirmasi untuk memastikan pengguna benar-benar ingin menghapus akun.
  Future<void> _konfirmasiHapusAkun() async {
    if (widget.user == null) return;

    final konfirmasi = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Row(
            children: [
              Icon(Icons.warning_amber_rounded, color: Colors.red.shade700),
              const SizedBox(width: 8),
              const Text('Hapus Akun?'),
            ],
          ),
          content: const Text(
            'Apakah Anda yakin ingin menghapus akun ini secara permanen? '
            'Semua riwayat presensi Anda juga akan terhapus dan tindakan ini tidak dapat dibatalkan.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: Text(
                'Batal',
                style: TextStyle(color: Colors.grey.shade600),
              ),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(true),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red.shade600,
                foregroundColor: Colors.white,
              ),
              child: const Text('Ya, Hapus'),
            ),
          ],
        );
      },
    );

    if (konfirmasi == true) {
      await _hapusAkun();
    }
  }

  /// Menangani proses penghapusan akun dari SQLite dan membersihkan sesi lokal.
  Future<void> _hapusAkun() async {
    setState(() => _isLoading = true);
    try {
      final db = DatabaseHelper();
      
      // 1. Hapus user & data presensinya dari database
      await db.deleteUser(widget.user!.idUser!);

      // 2. Bersihkan sesi SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      await prefs.clear();

      if (mounted) {
        _showSnackBar('Akun Anda berhasil dihapus secara permanen', false);
        // 3. Arahkan pengguna kembali ke halaman Login dan hapus seluruh stack navigasi
        Navigator.of(context).pushNamedAndRemoveUntil('/login', (route) => false);
      }
    } catch (e) {
      if (mounted) {
        _showSnackBar('Gagal menghapus akun: ${e.toString()}', true);
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  /// Mengatur pembangunan UI utama layar Profil, termasuk form biodata, form ubah password, dan tombol simpan.
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF0F4FF),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            // FORM 1: Biodata Profil
            Form(
              key: _formKey,
              child: Column(
                children: [
                  // Foto Profil Card
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.grey.withOpacity(0.08),
                          blurRadius: 10,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        Stack(
                          children: [
                            CircleAvatar(
                              radius: 50,
                              backgroundColor: Colors.grey.shade200,
                              backgroundImage: _fotoPath != null
                                  ? FileImage(File(_fotoPath!))
                                  : null,
                              child: _fotoPath == null
                                  ? const Icon(Icons.person, size: 50, color: Colors.grey)
                                  : null,
                            ),
                            Positioned(
                              bottom: 0,
                              right: 0,
                              child: GestureDetector(
                                onTap: _pilihFoto,
                                child: Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: const BoxDecoration(
                                    color: Color(0xFF1565C0),
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(
                                    Icons.camera_alt,
                                    color: Colors.white,
                                    size: 20,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        const Text(
                          'Ubah Foto Profil',
                          style: TextStyle(
                            fontSize: 14,
                            color: Color(0xFF1565C0),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Form Biodata Card
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.grey.withOpacity(0.08),
                          blurRadius: 10,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Informasi Personal',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF1A237E),
                          ),
                        ),
                        const SizedBox(height: 20),

                        // Input Nama
                        _buildLabel('Nama Lengkap'),
                        const SizedBox(height: 8),
                        TextFormField(
                          controller: _namaCtrl,
                          decoration: _inputDeco(Icons.person_outline, 'Masukkan nama'),
                          validator: (v) => v!.isEmpty ? 'Nama tidak boleh kosong' : null,
                        ),
                        const SizedBox(height: 16),

                        // Input NISN
                        _buildLabel('NISN'),
                        const SizedBox(height: 8),
                        TextFormField(
                          controller: _nisnCtrl,
                          decoration: _inputDeco(Icons.badge_outlined, 'Masukkan NISN'),
                          validator: (v) => v!.isEmpty ? 'NISN tidak boleh kosong' : null,
                        ),
                        const SizedBox(height: 16),

                        // Input Kelas
                        _buildLabel('Kelas'),
                        const SizedBox(height: 8),
                        TextFormField(
                          controller: _kelasCtrl,
                          decoration: _inputDeco(Icons.class_outlined, 'Masukkan kelas'),
                          validator: (v) => v!.isEmpty ? 'Kelas tidak boleh kosong' : null,
                        ),
                        const SizedBox(height: 16),

                        // Input Email
                        _buildLabel('Email'),
                        const SizedBox(height: 8),
                        TextFormField(
                          controller: _emailCtrl,
                          keyboardType: TextInputType.emailAddress,
                          decoration: _inputDeco(Icons.email_outlined, 'Masukkan email'),
                          validator: (v) => v!.isEmpty ? 'Email tidak boleh kosong' : null,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Tombol Simpan
                  SizedBox(
                    width: double.infinity,
                    height: 54,
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _simpanProfil,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF1565C0),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      child: _isLoading
                          ? const CircularProgressIndicator(color: Colors.white)
                          : const Text(
                              'Simpan Perubahan',
                              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                            ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // FORM 2: Ubah Kata Sandi
            Form(
              key: _formPasswordKey,
              child: Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey.withOpacity(0.08),
                      blurRadius: 10,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Ubah Kata Sandi',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF1A237E),
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Input Password Lama
                    _buildLabel('Password Lama'),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _oldPasswordCtrl,
                      obscureText: _obscureOldPassword,
                      decoration: _inputDeco(
                        Icons.lock_outline,
                        'Masukkan password lama',
                        suffix: IconButton(
                          icon: Icon(
                            _obscureOldPassword
                                ? Icons.visibility_off_outlined
                                : Icons.visibility_outlined,
                            color: Colors.grey.shade500,
                            size: 20,
                          ),
                          onPressed: () => setState(
                              () => _obscureOldPassword = !_obscureOldPassword),
                        ),
                      ),
                      validator: (v) {
                        if (v == null || v.isEmpty) return 'Password lama wajib diisi';
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),

                    // Input Password Baru
                    _buildLabel('Password Baru'),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _newPasswordCtrl,
                      obscureText: _obscureNewPassword,
                      decoration: _inputDeco(
                        Icons.lock_outline,
                        'Masukkan password baru',
                        suffix: IconButton(
                          icon: Icon(
                            _obscureNewPassword
                                ? Icons.visibility_off_outlined
                                : Icons.visibility_outlined,
                            color: Colors.grey.shade500,
                            size: 20,
                          ),
                          onPressed: () => setState(
                              () => _obscureNewPassword = !_obscureNewPassword),
                        ),
                      ),
                      validator: (v) {
                        if (v == null || v.isEmpty) return 'Password baru wajib diisi';
                        if (v.length < 6) return 'Password minimal 6 karakter';
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),

                    // Input Konfirmasi Password Baru
                    _buildLabel('Konfirmasi Password Baru'),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _confirmNewPasswordCtrl,
                      obscureText: _obscureConfirmNewPassword,
                      decoration: _inputDeco(
                        Icons.lock_clock_outlined,
                        'Ulangi password baru',
                        suffix: IconButton(
                          icon: Icon(
                            _obscureConfirmNewPassword
                                ? Icons.visibility_off_outlined
                                : Icons.visibility_outlined,
                            color: Colors.grey.shade500,
                            size: 20,
                          ),
                          onPressed: () => setState(
                              () => _obscureConfirmNewPassword = !_obscureConfirmNewPassword),
                        ),
                      ),
                      validator: (v) {
                        if (v == null || v.isEmpty) return 'Konfirmasi password wajib diisi';
                        if (v != _newPasswordCtrl.text) return 'Konfirmasi password tidak cocok';
                        return null;
                      },
                    ),
                    const SizedBox(height: 24),

                    // Tombol Perbarui Password
                    SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _ubahPassword,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.orange.shade700,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: _isLoading
                            ? const CircularProgressIndicator(color: Colors.white)
                            : const Text(
                                'Perbarui Password',
                                style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
                              ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // FORM 3: Zona Bahaya (Hapus Akun)
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.red.shade100, width: 1.5),
                boxShadow: [
                  BoxShadow(
                    color: Colors.red.withOpacity(0.02),
                    blurRadius: 10,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.warning_amber_rounded, color: Colors.red.shade700, size: 24),
                      const SizedBox(width: 8),
                      Text(
                        'Zona Bahaya',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: Colors.red.shade800,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Setelah Anda menghapus akun, semua data profil serta seluruh riwayat kehadiran Anda akan dihapus secara permanen dari perangkat ini.',
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.grey.shade600,
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _konfirmasiHapusAkun,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red.shade600,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text(
                        'Hapus Akun Permanen',
                        style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Membuat widget label teks berwarna untuk setiap form input di halaman profil.
  Widget _buildLabel(String text) {
    return Text(
      text,
      style: const TextStyle(
        fontSize: 13,
        fontWeight: FontWeight.w600,
        color: Color(0xFF1565C0),
      ),
    );
  }

  /// Membuat dekorasi input form (InputDecoration) dengan warna, garis tepi, ikon, dan teks petunjuk (hint).
  InputDecoration _inputDeco(IconData icon, String hint, {Widget? suffix}) {
    return InputDecoration(
      hintText: hint,
      prefixIcon: Icon(icon, color: Colors.grey.shade400),
      suffixIcon: suffix,
      filled: true,
      fillColor: Colors.grey.shade50,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.grey.shade200),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFF1565C0)),
      ),
    );
  }
}
