import 'dart:async';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';
import '../helpers/database_helper.dart';
import '../models/user_model.dart';
import '../models/presensi_model.dart';
import '../utils/constants.dart';
import 'presensi_screen.dart';
import 'riwayat_screen.dart';
import 'profil_screen.dart';
import 'maps_screen.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  int _selectedIndex = 0;
  UserModel? _user;
  PresensiModel? _presensiHariIni;
  Map<String, int> _statistik = {};
  Timer? _clockTimer;
  String _jamSekarang = '';
  String _tanggalSekarang = '';
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
    _startClock();
  }

  void _startClock() {
    _updateClock();
    _clockTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) _updateClock();
    });
  }

  void _updateClock() {
    final now = DateTime.now();
    setState(() {
      _jamSekarang = DateFormat('HH:mm:ss').format(now);
      _tanggalSekarang = DateFormat('EEEE, dd MMMM yyyy', 'id_ID').format(now);
    });
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final prefs = await SharedPreferences.getInstance();
      final userId = prefs.getInt(AppConstants.prefUserId);
      if (userId == null) {
        Navigator.pushReplacementNamed(context, '/login');
        return;
      }

      final db = DatabaseHelper();
      final user = await db.getUserById(userId);
      final tanggal = DateFormat('dd-MM-yyyy').format(DateTime.now());
      final presensi = await db.getPresensiHariIni(userId, tanggal);
      final statistik = await db.getStatistikPresensi(userId);

      if (mounted) {
        setState(() {
          _user = user;
          _presensiHariIni = presensi;
          _statistik = statistik;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _logout() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Konfirmasi Logout'),
        content: const Text('Apakah Anda yakin ingin keluar?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red.shade600,
              foregroundColor: Colors.white,
            ),
            child: const Text('Logout'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.clear();
      if (mounted) Navigator.pushReplacementNamed(context, '/login');
    }
  }

  Widget _buildHomeTab() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    return RefreshIndicator(
      onRefresh: _loadData,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Greeting Header Card
            _buildGreetingCard(),
            const SizedBox(height: 20),

            // Clock & Date Card
            _buildClockCard(),
            const SizedBox(height: 20),

            // Status Presensi Hari Ini
            _buildPresensiStatusCard(),
            const SizedBox(height: 20),

            // Tombol Presensi
            _buildPresensiButtons(),
            const SizedBox(height: 20),

            // Statistik
            _buildStatistikCard(),
            const SizedBox(height: 20),

            // Quick Actions
            _buildQuickActions(),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildGreetingCard() {
    final jam = DateTime.now().hour;
    String greeting;
    IconData greetIcon;
    if (jam < 12) {
      greeting = 'Selamat Pagi';
      greetIcon = Icons.wb_sunny_outlined;
    } else if (jam < 15) {
      greeting = 'Selamat Siang';
      greetIcon = Icons.wb_sunny;
    } else if (jam < 18) {
      greeting = 'Selamat Sore';
      greetIcon = Icons.wb_twilight;
    } else {
      greeting = 'Selamat Malam';
      greetIcon = Icons.nights_stay_outlined;
    }

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF1565C0), Color(0xFF0288D1)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF1565C0).withOpacity(0.3),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(greetIcon, color: Colors.amber.shade300, size: 18),
                    const SizedBox(width: 6),
                    Text(
                      greeting,
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.85),
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  _user?.nama ?? 'Pengguna',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _user?.email ?? '',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.7),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          CircleAvatar(
            radius: 28,
            backgroundColor: Colors.white.withOpacity(0.2),
            backgroundImage: _user?.foto != null
                ? NetworkImage(_user!.foto!)
                : null,
            child: _user?.foto == null
                ? Text(
                    _user?.nama.substring(0, 1).toUpperCase() ?? 'U',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  )
                : null,
          ),
        ],
      ),
    );
  }

  Widget _buildClockCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.grey.shade100, width: 1.5),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.08),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Text(
            _jamSekarang,
            style: const TextStyle(
              fontSize: 48,
              fontWeight: FontWeight.w700,
              color: Color(0xFF1565C0),
              letterSpacing: 2,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            _tanggalSekarang,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey.shade600,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPresensiStatusCard() {
    final hasMasuk = _presensiHariIni?.jamMasuk != null;
    final hasKeluar = _presensiHariIni?.jamKeluar != null;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.grey.shade100),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.07),
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
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFFE3F2FD),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.calendar_today_outlined,
                  color: Color(0xFF1565C0),
                  size: 18,
                ),
              ),
              const SizedBox(width: 10),
              const Text(
                'Status Presensi Hari Ini',
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 15,
                  color: Color(0xFF1A237E),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildStatusItem(
                  label: 'Masuk',
                  value: _presensiHariIni?.jamMasuk ?? '--:--',
                  color: hasMasuk ? Colors.green.shade600 : Colors.grey.shade400,
                  icon: Icons.login_rounded,
                  isActive: hasMasuk,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildStatusItem(
                  label: 'Keluar',
                  value: _presensiHariIni?.jamKeluar ?? '--:--',
                  color: hasKeluar ? Colors.orange.shade600 : Colors.grey.shade400,
                  icon: Icons.logout_rounded,
                  isActive: hasKeluar,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildStatusItem(
                  label: 'Status',
                  value: _presensiHariIni?.status ?? 'Belum',
                  color: _presensiHariIni?.status == 'Tepat Waktu'
                      ? Colors.green.shade600
                      : _presensiHariIni?.status == 'Terlambat'
                          ? Colors.red.shade600
                          : Colors.grey.shade400,
                  icon: Icons.verified_outlined,
                  isActive: _presensiHariIni?.status != null,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatusItem({
    required String label,
    required String value,
    required Color color,
    required IconData icon,
    required bool isActive,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 10),
      decoration: BoxDecoration(
        color: isActive ? color.withOpacity(0.08) : Colors.grey.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isActive ? color.withOpacity(0.3) : Colors.grey.shade200,
        ),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(height: 6),
          Text(
            value,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: isActive ? color : Colors.grey.shade500,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: TextStyle(fontSize: 11, color: Colors.grey.shade500),
          ),
        ],
      ),
    );
  }

  Widget _buildPresensiButtons() {
    final hasMasuk = _presensiHariIni?.jamMasuk != null;
    final hasKeluar = _presensiHariIni?.jamKeluar != null;

    return Row(
      children: [
        Expanded(
          child: _buildActionButton(
            label: 'Presensi Masuk',
            icon: Icons.login_rounded,
            gradient: hasMasuk
                ? [Colors.grey.shade400, Colors.grey.shade500]
                : [const Color(0xFF1565C0), const Color(0xFF0288D1)],
            onTap: hasMasuk
                ? null
                : () async {
                    await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => PresensiScreen(
                          userId: _user!.idUser!,
                          jenisPresentasi: 'masuk',
                          presensiHariIni: _presensiHariIni,
                        ),
                      ),
                    );
                    _loadData();
                  },
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildActionButton(
            label: 'Presensi Keluar',
            icon: Icons.logout_rounded,
            gradient: !hasMasuk || hasKeluar
                ? [Colors.grey.shade400, Colors.grey.shade500]
                : [const Color(0xFFE65100), const Color(0xFFF57C00)],
            onTap: !hasMasuk || hasKeluar
                ? null
                : () async {
                    await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => PresensiScreen(
                          userId: _user!.idUser!,
                          jenisPresentasi: 'keluar',
                          presensiHariIni: _presensiHariIni,
                        ),
                      ),
                    );
                    _loadData();
                  },
          ),
        ),
      ],
    );
  }

  Widget _buildActionButton({
    required String label,
    required IconData icon,
    required List<Color> gradient,
    VoidCallback? onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 64,
        decoration: BoxDecoration(
          gradient: LinearGradient(colors: gradient),
          borderRadius: BorderRadius.circular(16),
          boxShadow: onTap != null
              ? [
                  BoxShadow(
                    color: gradient[0].withOpacity(0.4),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ]
              : null,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: Colors.white, size: 22),
            const SizedBox(width: 8),
            Text(
              label,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w700,
                fontSize: 13,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatistikCard() {
    final total = _statistik['total_hadir'] ?? 0;
    final terlambat = _statistik['terlambat'] ?? 0;
    final tepat = _statistik['tepat_waktu'] ?? 0;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.grey.shade100),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.07),
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
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFFE8F5E9),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.bar_chart_rounded,
                  color: Color(0xFF2E7D32),
                  size: 18,
                ),
              ),
              const SizedBox(width: 10),
              const Text(
                'Statistik Kehadiran',
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 15,
                  color: Color(0xFF1A237E),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              _buildStatItem('Total Hadir', total.toString(), const Color(0xFF1565C0), Icons.people_outline),
              const SizedBox(width: 10),
              _buildStatItem('Tepat Waktu', tepat.toString(), Colors.green.shade600, Icons.check_circle_outline),
              const SizedBox(width: 10),
              _buildStatItem('Terlambat', terlambat.toString(), Colors.red.shade600, Icons.watch_later_outlined),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(String label, String value, Color color, IconData icon) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 10),
        decoration: BoxDecoration(
          color: color.withOpacity(0.08),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withOpacity(0.2)),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 22),
            const SizedBox(height: 6),
            Text(
              value,
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w800,
                color: color,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickActions() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Menu Cepat',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: Color(0xFF1A237E),
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            _buildQuickAction(
              icon: Icons.map_outlined,
              label: 'Lihat Maps',
              color: const Color(0xFF1565C0),
              onTap: () => setState(() => _selectedIndex = 1),
            ),
            const SizedBox(width: 12),
            _buildQuickAction(
              icon: Icons.history_rounded,
              label: 'Riwayat',
              color: const Color(0xFF00897B),
              onTap: () => setState(() => _selectedIndex = 2),
            ),
            const SizedBox(width: 12),
            _buildQuickAction(
              icon: Icons.person_outline,
              label: 'Profil',
              color: const Color(0xFF7B1FA2),
              onTap: () => setState(() => _selectedIndex = 3),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildQuickAction({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 16),
          decoration: BoxDecoration(
            color: color.withOpacity(0.08),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: color.withOpacity(0.2)),
          ),
          child: Column(
            children: [
              Icon(icon, color: color, size: 26),
              const SizedBox(height: 8),
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  color: color,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _clockTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final List<Widget> pages = [
      _buildHomeTab(),
      const MapsScreen(),
      RiwayatScreen(userId: _user?.idUser ?? 0),
      ProfilScreen(
        user: _user,
        onProfileUpdated: _loadData,
      ),
    ];

    return Scaffold(
      backgroundColor: const Color(0xFFF0F4FF),
      appBar: AppBar(
        title: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.location_on, color: Colors.white, size: 20),
            const SizedBox(width: 6),
            const Text(
              'GeoPresence',
              style: TextStyle(
                fontWeight: FontWeight.w800,
                fontSize: 20,
                letterSpacing: 0.5,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout_rounded),
            tooltip: 'Logout',
            onPressed: _logout,
          ),
        ],
      ),
      body: IndexedStack(
        index: _selectedIndex,
        children: pages,
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.08),
              blurRadius: 20,
              offset: const Offset(0, -4),
            ),
          ],
        ),
        child: NavigationBar(
          selectedIndex: _selectedIndex,
          onDestinationSelected: (idx) => setState(() => _selectedIndex = idx),
          backgroundColor: Colors.white,
          indicatorColor: const Color(0xFF1565C0).withOpacity(0.12),
          destinations: const [
            NavigationDestination(
              icon: Icon(Icons.home_outlined),
              selectedIcon: Icon(Icons.home_rounded, color: Color(0xFF1565C0)),
              label: 'Dashboard',
            ),
            NavigationDestination(
              icon: Icon(Icons.map_outlined),
              selectedIcon: Icon(Icons.map_rounded, color: Color(0xFF1565C0)),
              label: 'Maps',
            ),
            NavigationDestination(
              icon: Icon(Icons.history_outlined),
              selectedIcon: Icon(Icons.history_rounded, color: Color(0xFF1565C0)),
              label: 'Riwayat',
            ),
            NavigationDestination(
              icon: Icon(Icons.person_outline),
              selectedIcon: Icon(Icons.person_rounded, color: Color(0xFF1565C0)),
              label: 'Profil',
            ),
          ],
        ),
      ),
    );
  }
}
