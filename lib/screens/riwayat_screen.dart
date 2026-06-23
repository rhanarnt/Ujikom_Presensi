import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:intl/intl.dart';
import '../helpers/database_helper.dart';
import '../models/presensi_model.dart';

/// Widget Halaman Riwayat untuk menampilkan daftar riwayat presensi pengguna.
class RiwayatScreen extends StatefulWidget {
  final int userId;

  const RiwayatScreen({super.key, required this.userId});

  @override
  State<RiwayatScreen> createState() => _RiwayatScreenState();
}

/// State untuk mengelola daftar data riwayat kehadiran yang dimuat dari database SQLite.
class _RiwayatScreenState extends State<RiwayatScreen> {
  List<PresensiModel> _riwayat = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadRiwayat();
  }

  @override
  void didUpdateWidget(covariant RiwayatScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Memuat ulang riwayat jika ID User berubah dari inisialisasi awal (dari 0 ke ID asli)
    if (oldWidget.userId != widget.userId) {
      _loadRiwayat();
    }
  }

  /// Memuat riwayat data presensi pengguna dari database SQLite.
  Future<void> _loadRiwayat() async {
    setState(() => _isLoading = true);
    try {
      final db = DatabaseHelper();
      final data = await db.getRiwayatPresensi(widget.userId);
      if (mounted) setState(() => _riwayat = data);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  /// Menampilkan lembar detail presensi (bottom sheet) yang memuat foto masuk/keluar serta mini peta lokasi.
  void _showDetailDialog(PresensiModel p) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => DraggableScrollableSheet(
        initialChildSize: 0.65,
        maxChildSize: 0.92,
        minChildSize: 0.4,
        expand: false,
        builder: (_, controller) => SingleChildScrollView(
          controller: controller,
          padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Detail Presensi',
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF1A237E),
                    ),
                  ),
                  _buildStatusBadge(p.status),
                ],
              ),
              const SizedBox(height: 20),

              // Tanggal
              _buildDetailRow(Icons.calendar_today, 'Tanggal', p.tanggal),
              _buildDetailRow(Icons.login_rounded, 'Jam Masuk', p.jamMasuk ?? '-'),
              _buildDetailRow(Icons.logout_rounded, 'Jam Keluar', p.jamKeluar ?? '-'),
              _buildDetailRow(
                Icons.location_on_outlined,
                'Koordinat',
                p.latitude != null
                    ? '${p.latitude!.toStringAsFixed(6)}, ${p.longitude!.toStringAsFixed(6)}'
                    : '-',
              ),
              const SizedBox(height: 16),

              // Foto Masuk
              if (p.fotoMasuk != null) ...[
                const Text(
                  'Foto Masuk',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF1A237E),
                  ),
                ),
                const SizedBox(height: 8),
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.file(
                    File(p.fotoMasuk!),
                    height: 160,
                    width: double.infinity,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => Container(
                      height: 80,
                      color: Colors.grey.shade200,
                      child: const Center(child: Text('Foto tidak tersedia')),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
              ],

              // Foto Keluar
              if (p.fotoKeluar != null) ...[
                const Text(
                  'Foto Keluar',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF1A237E),
                  ),
                ),
                const SizedBox(height: 8),
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.file(
                    File(p.fotoKeluar!),
                    height: 160,
                    width: double.infinity,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => Container(
                      height: 80,
                      color: Colors.grey.shade200,
                      child: const Center(child: Text('Foto tidak tersedia')),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
              ],

              // Mini Map
              if (p.latitude != null && p.longitude != null) ...[
                const Text(
                  'Lokasi Presensi',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF1A237E),
                  ),
                ),
                const SizedBox(height: 8),
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: SizedBox(
                    height: 200,
                    child: FlutterMap(
                      options: MapOptions(
                        initialCenter: LatLng(p.latitude!, p.longitude!),
                        initialZoom: 16.0,
                        interactionOptions: const InteractionOptions(
                          flags: InteractiveFlag.none,
                        ),
                      ),
                      children: [
                        TileLayer(
                          urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                          userAgentPackageName: 'com.ujikom.geo_presence',
                        ),
                        MarkerLayer(
                          markers: [
                            Marker(
                              point: LatLng(p.latitude!, p.longitude!),
                              width: 40,
                              height: 40,
                              child: const Icon(
                                Icons.location_on,
                                color: Colors.red,
                                size: 40,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  /// Membuat baris ubin detail data presensi (seperti tanggal atau waktu masuk).
  Widget _buildDetailRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: const Color(0xFFE3F2FD),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, size: 16, color: const Color(0xFF1565C0)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF1A237E),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Membuat penanda (badge) status kehadiran (Tepat Waktu atau Terlambat) dengan warna yang sesuai.
  Widget _buildStatusBadge(String? status) {
    Color color;
    Color bgColor;
    if (status == 'Tepat Waktu') {
      color = Colors.green.shade700;
      bgColor = Colors.green.shade50;
    } else if (status == 'Terlambat') {
      color = Colors.red.shade700;
      bgColor = Colors.red.shade50;
    } else {
      color = Colors.grey.shade700;
      bgColor = Colors.grey.shade100;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.4)),
      ),
      child: Text(
        status ?? 'N/A',
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w700,
          color: color,
        ),
      ),
    );
  }

  /// Mengatur pembangunan UI utama layar riwayat, menampilkan indikator loading, pesan kosong, atau daftar kartu riwayat.
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF0F4FF),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _riwayat.isEmpty
              ? _buildEmpty()
              : RefreshIndicator(
                  onRefresh: _loadRiwayat,
                  child: ListView.builder(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 20),
                    itemCount: _riwayat.length + 1,
                    itemBuilder: (ctx, index) {
                      if (index == 0) return _buildHeader();
                      final p = _riwayat[index - 1];
                      return _buildRiwayatCard(p);
                    },
                  ),
                ),
    );
  }

  /// Membuat header bagian atas riwayat yang menampilkan judul halaman dan total data presensi.
  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Riwayat Presensi',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF1A237E),
                ),
              ),
              Text(
                '${_riwayat.length} data ditemukan',
                style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
              ),
            ],
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: const Color(0xFF1565C0).withOpacity(0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              children: [
                const Icon(Icons.history, size: 16, color: Color(0xFF1565C0)),
                const SizedBox(width: 4),
                Text(
                  'Total: ${_riwayat.length}',
                  style: const TextStyle(
                    color: Color(0xFF1565C0),
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Membuat kartu (card) daftar riwayat absen individu untuk satu tanggal tertentu.
  Widget _buildRiwayatCard(PresensiModel p) {
    return GestureDetector(
      onTap: () => _showDetailDialog(p),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.07),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            // Date Badge
            Container(
              width: 52,
              padding: const EdgeInsets.symmetric(vertical: 8),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF1565C0), Color(0xFF0288D1)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                children: [
                  Text(
                    _getDayNum(p.tanggal),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  Text(
                    _getMonth(p.tanggal),
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.8),
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 14),

            // Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        _formatTanggal(p.tanggal),
                        style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 14,
                          color: Color(0xFF1A237E),
                        ),
                      ),
                      _buildStatusBadge(p.status),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      _buildTimeChip(
                        icon: Icons.login_rounded,
                        label: p.jamMasuk ?? '--:--',
                        color: Colors.green.shade600,
                      ),
                      const SizedBox(width: 8),
                      const Icon(
                        Icons.arrow_forward,
                        size: 14,
                        color: Colors.grey,
                      ),
                      const SizedBox(width: 8),
                      _buildTimeChip(
                        icon: Icons.logout_rounded,
                        label: p.jamKeluar ?? '--:--',
                        color: Colors.orange.shade600,
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(width: 8),
            Icon(
              Icons.chevron_right_rounded,
              color: Colors.grey.shade400,
            ),
          ],
        ),
      ),
    );
  }

  /// Membuat chip waktu mini yang menunjukkan jam masuk atau keluar dengan warna dan ikon.
  Widget _buildTimeChip({
    required IconData icon,
    required String label,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Icon(icon, size: 12, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  /// Membuat tampilan UI ketika belum ada data riwayat presensi yang terekam.
  Widget _buildEmpty() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.history_toggle_off_outlined,
            size: 80,
            color: Colors.grey.shade300,
          ),
          const SizedBox(height: 16),
          Text(
            'Belum Ada Riwayat',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: Colors.grey.shade500,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Data presensi Anda akan muncul di sini',
            style: TextStyle(fontSize: 14, color: Colors.grey.shade400),
          ),
        ],
      ),
    );
  }

  /// Mengurai nomor hari dari string tanggal berformat (dd-MM-yyyy).
  String _getDayNum(String tanggal) {
    try {
      final parts = tanggal.split('-');
      return parts[0];
    } catch (_) {
      return '--';
    }
  }

  /// Mengurai dan memformat nama bulan singkat (misal: Jan, Feb) dari string tanggal berformat (dd-MM-yyyy).
  String _getMonth(String tanggal) {
    try {
      final parts = tanggal.split('-');
      final date = DateTime(int.parse(parts[2]), int.parse(parts[1]));
      return DateFormat('MMM').format(date);
    } catch (_) {
      return '--';
    }
  }

  /// Memformat string tanggal (dd-MM-yyyy) menjadi format lengkap lokalisasi Indonesia (Hari, Tanggal Bulan Tahun).
  String _formatTanggal(String tanggal) {
    try {
      final parts = tanggal.split('-');
      final date = DateTime(
        int.parse(parts[2]),
        int.parse(parts[1]),
        int.parse(parts[0]),
      );
      return DateFormat('EEEE, dd MMM yyyy', 'id_ID').format(date);
    } catch (_) {
      return tanggal;
    }
  }
}
