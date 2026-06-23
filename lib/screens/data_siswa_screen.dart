import 'dart:io';
import 'package:flutter/material.dart';
import '../helpers/database_helper.dart';
import '../models/user_model.dart';
import '../models/presensi_model.dart';

/// Widget Halaman Data Siswa yang menyajikan daftar seluruh siswa terdaftar.
/// Mendukung pencarian dinamis (berdasarkan Nama, NISN, atau Kelas)
/// dan menampilkan rincian kehadiran detail masing-masing siswa.
class DataSiswaScreen extends StatefulWidget {
  const DataSiswaScreen({super.key});

  @override
  State<DataSiswaScreen> createState() => _DataSiswaScreenState();
}

class _DataSiswaScreenState extends State<DataSiswaScreen> {
  final _dbHelper = DatabaseHelper();
  final _searchController = TextEditingController();

  List<UserModel> _allSiswa = [];
  List<UserModel> _filteredSiswa = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadSiswa();
    _searchController.addListener(_filterSiswa);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  // Mengambil daftar seluruh siswa dari database SQLite
  Future<void> _loadSiswa() async {
    setState(() => _isLoading = true);
    try {
      final siswa = await _dbHelper.getAllSiswa();
      setState(() {
        _allSiswa = siswa;
        _filteredSiswa = siswa;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      _showSnackBar('Gagal memuat data siswa: ${e.toString()}', isError: true);
    }
  }

  // Melakukan penyaringan (filter) data siswa berdasarkan input kolom pencarian (search bar)
  void _filterSiswa() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      if (query.isEmpty) {
        _filteredSiswa = _allSiswa;
      } else {
        _filteredSiswa = _allSiswa.where((siswa) {
          final matchNama = siswa.nama.toLowerCase().contains(query);
          final matchNisn = (siswa.nisn ?? '').toLowerCase().contains(query);
          final matchKelas = (siswa.kelas ?? '').toLowerCase().contains(query);
          return matchNama || matchNisn || matchKelas;
        }).toList();
      }
    });
  }

  // Menampilkan detail lengkap siswa di dalam BottomSheet secara interaktif
  Future<void> _showSiswaDetail(UserModel siswa) async {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _SiswaDetailBottomSheet(siswa: siswa),
    );
  }

  void _showSnackBar(String msg, {bool isError = false}) {
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
      appBar: AppBar(
        title: const Text(
          'Daftar Siswa',
          style: TextStyle(fontWeight: FontWeight.w700),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: _loadSiswa,
            tooltip: 'Refresh Data',
          ),
        ],
      ),
      body: Column(
        children: [
          // Search Bar Panel
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withOpacity(0.06),
                    blurRadius: 10,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: TextFormField(
                controller: _searchController,
                decoration: InputDecoration(
                  hintText: 'Cari nama, NISN, atau kelas...',
                  hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 14),
                  prefixIcon: const Icon(Icons.search, color: Color(0xFF1565C0)),
                  suffixIcon: _searchController.text.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear, color: Colors.grey),
                          onPressed: () => _searchController.clear(),
                        )
                      : null,
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
                ),
              ),
            ),
          ),

          // Siswa List View
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _filteredSiswa.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.people_outline, size: 64, color: Colors.grey.shade400),
                            const SizedBox(height: 12),
                            Text(
                              'Siswa tidak ditemukan',
                              style: TextStyle(color: Colors.grey.shade600, fontSize: 16),
                            ),
                          ],
                        ),
                      )
                    : RefreshIndicator(
                        onRefresh: _loadSiswa,
                        child: ListView.builder(
                          physics: const AlwaysScrollableScrollPhysics(),
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          itemCount: _filteredSiswa.length,
                          itemBuilder: (context, index) {
                            final siswa = _filteredSiswa[index];
                            return _buildSiswaCard(siswa);
                          },
                        ),
                      ),
          ),
        ],
      ),
    );
  }

  // Membuat item kartu (Card) data siswa
  Widget _buildSiswaCard(UserModel siswa) {
    final hasFoto = siswa.foto != null && File(siswa.foto!).existsSync();
    final initials = siswa.nama.isNotEmpty
        ? siswa.nama.trim().split(' ').map((l) => l[0]).take(2).join().toUpperCase()
        : 'S';

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade100),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: CircleAvatar(
          radius: 26,
          backgroundColor: const Color(0xFF1565C0).withOpacity(0.1),
          backgroundImage: hasFoto ? FileImage(File(siswa.foto!)) : null,
          child: !hasFoto
              ? Text(
                  initials,
                  style: const TextStyle(
                    color: Color(0xFF1565C0),
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                )
              : null,
        ),
        title: Text(
          siswa.nama,
          style: const TextStyle(
            fontWeight: FontWeight.w700,
            fontSize: 15,
            color: Color(0xFF1A237E),
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Row(
              children: [
                Icon(Icons.badge_outlined, size: 14, color: Colors.grey.shade500),
                const SizedBox(width: 4),
                Text(
                  siswa.nisn ?? '-',
                  style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
                ),
                const SizedBox(width: 12),
                Icon(Icons.class_outlined, size: 14, color: Colors.grey.shade500),
                const SizedBox(width: 4),
                Text(
                  siswa.kelas ?? '-',
                  style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
                ),
              ],
            ),
          ],
        ),
        trailing: const Icon(Icons.chevron_right_rounded, color: Colors.grey),
        onTap: () => _showSiswaDetail(siswa),
      ),
    );
  }
}

/// Widget Kustom BottomSheet untuk memaparkan statistik kehadiran & profil detail siswa.
class _SiswaDetailBottomSheet extends StatefulWidget {
  final UserModel siswa;

  const _SiswaDetailBottomSheet({required this.siswa});

  @override
  State<_SiswaDetailBottomSheet> createState() => _SiswaDetailBottomSheetState();
}

class _SiswaDetailBottomSheetState extends State<_SiswaDetailBottomSheet> {
  final _dbHelper = DatabaseHelper();
  Map<String, int> _stats = {};
  List<PresensiModel> _riwayat = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadStatsAndHistory();
  }

  // Memuat ringkasan data statistik dan kueri riwayat kehadiran siswa
  Future<void> _loadStatsAndHistory() async {
    try {
      final userId = widget.siswa.idUser ?? 0;
      final stats = await _dbHelper.getStatistikPresensi(userId);
      final riwayat = await _dbHelper.getRiwayatPresensi(userId);
      if (mounted) {
        setState(() {
          _stats = stats;
          _riwayat = riwayat;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final siswa = widget.siswa;
    final hasFoto = siswa.foto != null && File(siswa.foto!).existsSync();
    final initials = siswa.nama.isNotEmpty
        ? siswa.nama.trim().split(' ').map((l) => l[0]).take(2).join().toUpperCase()
        : 'S';

    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(28),
          topRight: Radius.circular(28),
        ),
      ),
      padding: EdgeInsets.only(
        top: 20,
        left: 20,
        right: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 20,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Handle Bar
            Center(
              child: Container(
                width: 40,
                height: 5,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Profil Siswa Header
            Row(
              children: [
                CircleAvatar(
                  radius: 36,
                  backgroundColor: const Color(0xFF1565C0).withOpacity(0.1),
                  backgroundImage: hasFoto ? FileImage(File(siswa.foto!)) : null,
                  child: !hasFoto
                      ? Text(
                          initials,
                          style: const TextStyle(
                            color: Color(0xFF1565C0),
                            fontWeight: FontWeight.bold,
                            fontSize: 22,
                          ),
                        )
                      : null,
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        siswa.nama,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1A237E),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        siswa.email,
                        style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            const Divider(),
            const SizedBox(height: 12),

            // Detail Atribut Siswa
            const Text(
              'Detail Identitas',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Color(0xFF1A237E)),
            ),
            const SizedBox(height: 10),
            _buildDetailRow(Icons.badge_outlined, 'NISN (No Induk)', siswa.nisn ?? '-'),
            _buildDetailRow(Icons.class_outlined, 'Kelas', siswa.kelas ?? '-'),
            const SizedBox(height: 20),

            // Statistik Kehadiran Siswa
            const Text(
              'Statistik Kehadiran',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Color(0xFF1A237E)),
            ),
            const SizedBox(height: 12),
            _isLoading
                ? const Center(child: CircularProgressIndicator())
                : Row(
                    children: [
                      _buildStatItem('Total Hadir', _stats['total_hadir'].toString(), const Color(0xFF1565C0)),
                      const SizedBox(width: 8),
                      _buildStatItem('Tepat Waktu', _stats['tepat_waktu'].toString(), Colors.green.shade600),
                      const SizedBox(width: 8),
                      _buildStatItem('Terlambat', _stats['terlambat'].toString(), Colors.red.shade600),
                    ],
                  ),
            const SizedBox(height: 24),

            // Riwayat Presensi Terbaru Siswa
            const Text(
              'Riwayat Presensi Terbaru',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Color(0xFF1A237E)),
            ),
            const SizedBox(height: 10),
            _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _riwayat.isEmpty
                    ? Padding(
                        padding: const EdgeInsets.symmetric(vertical: 20),
                        child: Center(
                          child: Text(
                            'Belum ada riwayat kehadiran',
                            style: TextStyle(color: Colors.grey.shade500, fontSize: 13),
                          ),
                        ),
                      )
                    : ListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: _riwayat.length > 5 ? 5 : _riwayat.length,
                        itemBuilder: (context, index) {
                          final log = _riwayat[index];
                          return _buildRiwayatItem(log);
                        },
                      ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: OutlinedButton(
                onPressed: () => Navigator.pop(context),
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: Color(0xFF1565C0)),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: const Text(
                  'Tutup',
                  style: TextStyle(color: Color(0xFF1565C0), fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(IconData icon, String key, String val) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Icon(icon, color: Colors.grey.shade500, size: 18),
          const SizedBox(width: 8),
          Text(key, style: TextStyle(color: Colors.grey.shade600, fontSize: 13)),
          const Spacer(),
          Text(val, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
        ],
      ),
    );
  }

  Widget _buildStatItem(String label, String count, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
        decoration: BoxDecoration(
          color: color.withOpacity(0.08),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withOpacity(0.2)),
        ),
        child: Column(
          children: [
            Text(
              count,
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: color),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(fontSize: 10, color: Colors.grey.shade600, fontWeight: FontWeight.w500),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRiwayatItem(PresensiModel log) {
    final isTepat = log.status == 'Tepat Waktu';
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                log.tanggal,
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
              ),
              const SizedBox(height: 2),
              Text(
                'Masuk: ${log.jamMasuk ?? "--:--"} | Pulang: ${log.jamKeluar ?? "--:--"}',
                style: TextStyle(color: Colors.grey.shade600, fontSize: 11),
              ),
            ],
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: isTepat ? Colors.green.shade50 : Colors.red.shade50,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: isTepat ? Colors.green.shade200 : Colors.red.shade200),
            ),
            child: Text(
              log.status ?? 'Hadir',
              style: TextStyle(
                color: isTepat ? Colors.green.shade700 : Colors.red.shade700,
                fontSize: 10,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
