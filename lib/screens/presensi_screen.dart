import 'dart:io';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import '../helpers/database_helper.dart';
import '../models/presensi_model.dart';
import '../utils/constants.dart';

class PresensiScreen extends StatefulWidget {
  final int userId;
  final String jenisPresentasi; // 'masuk' atau 'keluar'
  final PresensiModel? presensiHariIni;

  const PresensiScreen({
    super.key,
    required this.userId,
    required this.jenisPresentasi,
    this.presensiHariIni,
  });

  @override
  State<PresensiScreen> createState() => _PresensiScreenState();
}

class _PresensiScreenState extends State<PresensiScreen>
    with SingleTickerProviderStateMixin {
  bool _isLoading = false;
  bool _isGettingLocation = false;
  Position? _currentPosition;
  double? _jarak;
  String _statusLokasi = 'Belum dideteksi';
  String? _fotoPath;
  late AnimationController _pulseController;
  late Animation<double> _pulseAnim;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);
    _pulseAnim = Tween<double>(begin: 0.95, end: 1.05).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
    _detectLocation();
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  Future<void> _detectLocation() async {
    setState(() {
      _isGettingLocation = true;
      _statusLokasi = 'Mendeteksi lokasi...';
    });

    try {
      // Cek permission
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        setState(() => _statusLokasi = 'GPS tidak aktif, harap aktifkan GPS');
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          setState(() => _statusLokasi = 'Izin lokasi ditolak');
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        setState(() => _statusLokasi = 'Izin lokasi ditolak permanen');
        return;
      }

      // Dapatkan posisi
      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 15),
        ),
      );

      // Hitung jarak ke kantor
      final jarak = Geolocator.distanceBetween(
        position.latitude,
        position.longitude,
        AppConstants.officeLatitude,
        AppConstants.officeLongitude,
      );

      if (mounted) {
        setState(() {
          _currentPosition = position;
          _jarak = jarak;
          if (jarak <= AppConstants.maxDistance) {
            _statusLokasi = '✓ Dalam area presensi (${jarak.toStringAsFixed(0)} m)';
          } else {
            _statusLokasi = '✗ Di luar area presensi (${jarak.toStringAsFixed(0)} m)';
          }
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _statusLokasi = 'Gagal mendapatkan lokasi: ${e.toString()}');
      }
    } finally {
      if (mounted) setState(() => _isGettingLocation = false);
    }
  }

  Future<void> _ambilFoto() async {
    try {
      final picker = ImagePicker();
      final XFile? foto = await picker.pickImage(
        source: ImageSource.camera,
        imageQuality: 70,
        preferredCameraDevice: CameraDevice.front,
      );
      if (foto != null) {
        setState(() => _fotoPath = foto.path);
      }
    } catch (e) {
      _showSnackBar('Gagal membuka kamera: ${e.toString()}', isError: true);
    }
  }

  Future<void> _simpanPresensi() async {
    if (_currentPosition == null) {
      _showSnackBar('Harap deteksi lokasi terlebih dahulu', isError: true);
      return;
    }

    if (_jarak == null || _jarak! > AppConstants.maxDistance) {
      _showSnackBar(
        'Anda berada di luar area presensi (${_jarak?.toStringAsFixed(0)} m dari kantor)',
        isError: true,
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final db = DatabaseHelper();
      final now = DateTime.now();
      final tanggal = DateFormat('dd-MM-yyyy').format(now);
      final jam = DateFormat('HH:mm').format(now);

      if (widget.jenisPresentasi == 'masuk') {
        // Tentukan status (Tepat Waktu / Terlambat)
        String status;
        if (now.hour < AppConstants.jamMasukBatas ||
            (now.hour == AppConstants.jamMasukBatas &&
                now.minute <= AppConstants.menitMasukBatas)) {
          status = 'Tepat Waktu';
        } else {
          status = 'Terlambat';
        }

        final presensi = PresensiModel(
          idUser: widget.userId,
          tanggal: tanggal,
          jamMasuk: jam,
          latitude: _currentPosition!.latitude,
          longitude: _currentPosition!.longitude,
          status: status,
          fotoMasuk: _fotoPath,
        );

        await db.insertPresensiMasuk(presensi);

        if (mounted) {
          _showSuccessDialog(
            title: 'Presensi Masuk Berhasil!',
            jam: jam,
            status: status,
          );
        }
      } else {
        // Presensi Keluar
        await db.updatePresensiKeluar(
          widget.presensiHariIni!.idPresensi!,
          jam,
          _fotoPath,
        );

        if (mounted) {
          _showSuccessDialog(
            title: 'Presensi Keluar Berhasil!',
            jam: jam,
            status: 'Selesai',
          );
        }
      }
    } catch (e) {
      _showSnackBar('Gagal menyimpan presensi: ${e.toString()}', isError: true);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showSuccessDialog({
    required String title,
    required String jam,
    required String status,
  }) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: Colors.green.shade50,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.check_circle_rounded,
                color: Colors.green.shade600,
                size: 48,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              title,
              style: const TextStyle(
                fontWeight: FontWeight.w800,
                fontSize: 18,
                color: Color(0xFF1A237E),
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            _buildInfoRow('Jam', jam),
            _buildInfoRow('Status', status),
            _buildInfoRow(
              'Koordinat',
              '${_currentPosition!.latitude.toStringAsFixed(6)}, ${_currentPosition!.longitude.toStringAsFixed(6)}',
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.pop(ctx);
                  Navigator.pop(context);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1565C0),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                child: const Text(
                  'Selesai',
                  style: TextStyle(fontWeight: FontWeight.w700),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(color: Colors.grey.shade600, fontSize: 13)),
          Flexible(
            child: Text(
              value,
              style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
              textAlign: TextAlign.right,
            ),
          ),
        ],
      ),
    );
  }

  void _showSnackBar(String msg, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: isError ? Colors.red.shade700 : Colors.green.shade700,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  bool get _dalamArea =>
      _jarak != null && _jarak! <= AppConstants.maxDistance;

  @override
  Widget build(BuildContext context) {
    final isMasuk = widget.jenisPresentasi == 'masuk';
    final primaryColor = isMasuk ? const Color(0xFF1565C0) : const Color(0xFFE65100);

    return Scaffold(
      backgroundColor: const Color(0xFFF0F4FF),
      appBar: AppBar(
        title: Text(
          isMasuk ? 'Presensi Masuk' : 'Presensi Keluar',
          style: const TextStyle(fontWeight: FontWeight.w700),
        ),
        backgroundColor: primaryColor,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            // Animasi GPS Status
            ScaleTransition(
              scale: _pulseAnim,
              child: Container(
                width: 150,
                height: 150,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: _isGettingLocation
                      ? Colors.orange.withOpacity(0.1)
                      : _dalamArea
                          ? Colors.green.withOpacity(0.1)
                          : _currentPosition != null
                              ? Colors.red.withOpacity(0.1)
                              : Colors.grey.withOpacity(0.1),
                  border: Border.all(
                    color: _isGettingLocation
                        ? Colors.orange
                        : _dalamArea
                            ? Colors.green
                            : _currentPosition != null
                                ? Colors.red
                                : Colors.grey,
                    width: 3,
                  ),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      _isGettingLocation
                          ? Icons.gps_fixed
                          : _dalamArea
                              ? Icons.location_on
                              : Icons.location_off,
                      size: 48,
                      color: _isGettingLocation
                          ? Colors.orange
                          : _dalamArea
                              ? Colors.green
                              : _currentPosition != null
                                  ? Colors.red
                                  : Colors.grey,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _isGettingLocation
                          ? 'Mendeteksi...'
                          : _dalamArea
                              ? 'Dalam Area'
                              : _currentPosition != null
                                  ? 'Luar Area'
                                  : 'GPS',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: _isGettingLocation
                            ? Colors.orange
                            : _dalamArea
                                ? Colors.green
                                : _currentPosition != null
                                    ? Colors.red
                                    : Colors.grey,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Info Lokasi Card
            _buildInfoCard(),
            const SizedBox(height: 20),

            // Refresh Location Button
            OutlinedButton.icon(
              onPressed: _isGettingLocation ? null : _detectLocation,
              icon: Icon(
                Icons.refresh_rounded,
                color: _isGettingLocation ? Colors.grey : primaryColor,
              ),
              label: Text(
                'Refresh Lokasi',
                style: TextStyle(
                  color: _isGettingLocation ? Colors.grey : primaryColor,
                ),
              ),
              style: OutlinedButton.styleFrom(
                side: BorderSide(
                  color: _isGettingLocation ? Colors.grey.shade300 : primaryColor,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              ),
            ),
            const SizedBox(height: 20),

            // Foto Selfie Section
            _buildFotoSection(),
            const SizedBox(height: 32),

            // Tombol Presensi
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton.icon(
                onPressed: (_isLoading || _isGettingLocation || !_dalamArea)
                    ? null
                    : _simpanPresensi,
                icon: _isLoading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : Icon(isMasuk ? Icons.login_rounded : Icons.logout_rounded),
                label: Text(
                  _isLoading
                      ? 'Menyimpan...'
                      : isMasuk
                          ? 'Lakukan Presensi Masuk'
                          : 'Lakukan Presensi Keluar',
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 16,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryColor,
                  foregroundColor: Colors.white,
                  elevation: 4,
                  shadowColor: primaryColor.withOpacity(0.4),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
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
            'Informasi Lokasi',
            style: TextStyle(
              fontWeight: FontWeight.w700,
              fontSize: 15,
              color: Color(0xFF1A237E),
            ),
          ),
          const Divider(height: 20),
          _buildInfoRow('Lokasi Kantor',
              '${AppConstants.officeLatitude}, ${AppConstants.officeLongitude}'),
          const SizedBox(height: 8),
          _buildInfoRow(
            'Lokasi Anda',
            _currentPosition != null
                ? '${_currentPosition!.latitude.toStringAsFixed(6)}, ${_currentPosition!.longitude.toStringAsFixed(6)}'
                : 'Belum dideteksi',
          ),
          const SizedBox(height: 8),
          _buildInfoRow(
            'Jarak ke Kantor',
            _jarak != null ? '${_jarak!.toStringAsFixed(1)} meter' : '-',
          ),
          const SizedBox(height: 8),
          _buildInfoRow('Batas Jarak', '${AppConstants.maxDistance.toInt()} meter'),
          const Divider(height: 20),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 14),
            decoration: BoxDecoration(
              color: _dalamArea
                  ? Colors.green.shade50
                  : _currentPosition != null
                      ? Colors.red.shade50
                      : Colors.grey.shade50,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: _dalamArea
                    ? Colors.green.shade200
                    : _currentPosition != null
                        ? Colors.red.shade200
                        : Colors.grey.shade200,
              ),
            ),
            child: Text(
              _statusLokasi,
              style: TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 13,
                color: _dalamArea
                    ? Colors.green.shade700
                    : _currentPosition != null
                        ? Colors.red.shade700
                        : Colors.grey.shade600,
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFotoSection() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
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
          Row(
            children: [
              const Text(
                'Foto Selfie',
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 15,
                  color: Color(0xFF1A237E),
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: Colors.orange.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.orange.shade200),
                ),
                child: Text(
                  'Opsional',
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.orange.shade700,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          GestureDetector(
            onTap: _ambilFoto,
            child: Container(
              height: 160,
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: _fotoPath != null
                      ? Colors.green.shade400
                      : Colors.grey.shade300,
                  width: 2,
                  style: _fotoPath != null
                      ? BorderStyle.solid
                      : BorderStyle.solid,
                ),
              ),
              child: _fotoPath != null
                  ? ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Image.file(
                        File(_fotoPath!),
                        fit: BoxFit.cover,
                        width: double.infinity,
                      ),
                    )
                  : Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.camera_alt_outlined,
                          size: 40,
                          color: Colors.grey.shade400,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Tap untuk ambil selfie',
                          style: TextStyle(
                            color: Colors.grey.shade500,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
            ),
          ),
          if (_fotoPath != null)
            Padding(
              padding: const EdgeInsets.only(top: 10),
              child: TextButton.icon(
                onPressed: () => setState(() => _fotoPath = null),
                icon: const Icon(Icons.delete_outline, size: 16),
                label: const Text('Hapus foto'),
                style: TextButton.styleFrom(foregroundColor: Colors.red.shade600),
              ),
            ),
        ],
      ),
    );
  }
}
