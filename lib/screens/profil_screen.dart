import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../helpers/database_helper.dart';
import '../models/user_model.dart';
import '../utils/constants.dart';

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

class _ProfilScreenState extends State<ProfilScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _namaCtrl;
  late TextEditingController _emailCtrl;
  String? _fotoPath;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _namaCtrl = TextEditingController(text: widget.user?.nama ?? '');
    _emailCtrl = TextEditingController(text: widget.user?.email ?? '');
    _fotoPath = widget.user?.foto;
  }

  @override
  void dispose() {
    _namaCtrl.dispose();
    _emailCtrl.dispose();
    super.dispose();
  }

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

  void _showSnackBar(String msg, bool isError) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: isError ? Colors.red.shade700 : Colors.green.shade700,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF0F4FF),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
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
              const SizedBox(height: 32),

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
      ),
    );
  }

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

  InputDecoration _inputDeco(IconData icon, String hint) {
    return InputDecoration(
      hintText: hint,
      prefixIcon: Icon(icon, color: Colors.grey.shade400),
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
