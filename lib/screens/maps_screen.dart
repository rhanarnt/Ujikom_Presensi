import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../utils/constants.dart';

class MapsScreen extends StatefulWidget {
  const MapsScreen({super.key});

  @override
  State<MapsScreen> createState() => _MapsScreenState();
}

class _MapsScreenState extends State<MapsScreen> {
  final MapController _mapController = MapController();
  Position? _userPosition;
  bool _isLoading = true;
  double? _jarak;

  LatLng _officeLocation = const LatLng(
    AppConstants.officeLatitude,
    AppConstants.officeLongitude,
  );
  double _maxDistance = AppConstants.maxDistance;

  @override
  void initState() {
    super.initState();
    _loadOfficeLocation().then((_) {
      _loadMap();
    });
  }

  // Memuat data koordinat kantor dan radius dinamis dari SharedPreferences.
  Future<void> _loadOfficeLocation() async {
    final prefs = await SharedPreferences.getInstance();
    final lat = prefs.getDouble(AppConstants.prefOfficeLat);
    final lng = prefs.getDouble(AppConstants.prefOfficeLng);
    final rad = prefs.getDouble(AppConstants.prefOfficeRadius);
    if (lat != null && lng != null) {
      setState(() {
        _officeLocation = LatLng(lat, lng);
      });
    }
    if (rad != null) {
      setState(() {
        _maxDistance = rad;
      });
    }
  }

  Future<void> _loadMap() async {
    setState(() => _isLoading = true);
    await _getUserLocation();
    setState(() => _isLoading = false);
  }

  Future<void> _getUserLocation() async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) return;

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) return;
      }
      if (permission == LocationPermission.deniedForever) return;

      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 15),
        ),
      );

      // Menghitung jarak antara lokasi GPS user dengan koordinat kantor dinamis
      final jarak = Geolocator.distanceBetween(
        position.latitude,
        position.longitude,
        _officeLocation.latitude,
        _officeLocation.longitude,
      );

      if (mounted) {
        setState(() {
          _userPosition = position;
          _jarak = jarak;
        });
      }
    } catch (e) {
      debugPrint('Error getting location: $e');
    }
  }

  // Menetapakan koordinat kantor baru berdasarkan GPS saat ini dan menyimpannya secara persisten.
  Future<void> _setOfficeLocation() async {
    if (_userPosition == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Harap tunggu hingga GPS mendeteksi lokasi Anda'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Set Lokasi Kantor'),
        content: const Text(
            'Apakah Anda yakin ingin menetapkan lokasi Anda saat ini sebagai koordinat kantor baru?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue.shade700,
              foregroundColor: Colors.white,
            ),
            child: const Text('Set Lokasi'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setDouble(AppConstants.prefOfficeLat, _userPosition!.latitude);
      await prefs.setDouble(AppConstants.prefOfficeLng, _userPosition!.longitude);
      
      setState(() {
        _officeLocation = LatLng(_userPosition!.latitude, _userPosition!.longitude);
        _jarak = 0.0;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Lokasi kantor berhasil diperbarui ke posisi Anda saat ini!'),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  void _goToOffice() {
    _mapController.move(_officeLocation, 17.0);
  }

  void _goToUser() {
    if (_userPosition == null) return;
    _mapController.move(
      LatLng(_userPosition!.latitude, _userPosition!.longitude),
      17.0,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF0F4FF),
      body: Column(
        children: [
          // Info Bar
          Container(
            margin: const EdgeInsets.fromLTRB(16, 16, 16, 0),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withOpacity(0.1),
                  blurRadius: 10,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: Row(
              children: [
                Expanded(
                  child: _buildInfoTile(
                    icon: Icons.business_outlined,
                    label: 'Lokasi Kantor',
                    value:
                        '${_officeLocation.latitude.toStringAsFixed(6)}, ${_officeLocation.longitude.toStringAsFixed(6)}',
                    color: Colors.blue.shade700,
                  ),
                ),
                Container(
                  width: 1,
                  height: 40,
                  color: Colors.grey.shade200,
                  margin: const EdgeInsets.symmetric(horizontal: 12),
                ),
                Expanded(
                  child: _buildInfoTile(
                    icon: Icons.person_pin_circle_outlined,
                    label: 'Jarak Anda',
                    value: _jarak != null
                        ? '${_jarak!.toStringAsFixed(1)} m'
                        : 'Mendeteksi...',
                    color: _jarak != null && _jarak! <= _maxDistance
                        ? Colors.green.shade700
                        : Colors.red.shade700,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),

          // Status Banner
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 10),
              decoration: BoxDecoration(
                color: _jarak != null && _jarak! <= _maxDistance
                    ? Colors.green.shade50
                    : _jarak != null
                        ? Colors.red.shade50
                        : Colors.grey.shade50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: _jarak != null && _jarak! <= _maxDistance
                      ? Colors.green.shade200
                      : _jarak != null
                          ? Colors.red.shade200
                          : Colors.grey.shade200,
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    _jarak != null && _jarak! <= _maxDistance
                        ? Icons.check_circle_outline
                        : Icons.cancel_outlined,
                    size: 16,
                    color: _jarak != null && _jarak! <= _maxDistance
                        ? Colors.green.shade700
                        : _jarak != null
                            ? Colors.red.shade700
                            : Colors.grey.shade600,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    _jarak != null && _jarak! <= _maxDistance
                        ? '✓ Anda berada dalam area presensi'
                        : _jarak != null
                            ? '✗ Anda berada di luar area presensi'
                            : 'Mendeteksi lokasi...',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: _jarak != null && _jarak! <= _maxDistance
                          ? Colors.green.shade700
                          : _jarak != null
                              ? Colors.red.shade700
                              : Colors.grey.shade600,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),

          // Map
          Expanded(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: _isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : FlutterMap(
                        mapController: _mapController,
                        options: MapOptions(
                          initialCenter: _userPosition != null
                              ? LatLng(
                                  _userPosition!.latitude,
                                  _userPosition!.longitude,
                                )
                              : _officeLocation,
                          initialZoom: 16.0,
                        ),
                        children: [
                          TileLayer(
                            urlTemplate:
                                'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                            userAgentPackageName: 'com.ujikom.geo_presence',
                          ),
                          CircleLayer(
                            circles: [
                              CircleMarker(
                                point: _officeLocation,
                                radius: _maxDistance,
                                useRadiusInMeter: true,
                                color: Colors.blue.withOpacity(0.15),
                                borderColor: Colors.blue.shade600,
                                borderStrokeWidth: 2,
                              ),
                            ],
                          ),
                          MarkerLayer(
                            markers: [
                              Marker(
                                point: _officeLocation,
                                width: 40,
                                height: 40,
                                child: const Icon(
                                  Icons.location_on,
                                  color: Colors.blue,
                                  size: 40,
                                ),
                              ),
                              if (_userPosition != null)
                                Marker(
                                  point: LatLng(
                                    _userPosition!.latitude,
                                    _userPosition!.longitude,
                                  ),
                                  width: 40,
                                  height: 40,
                                  child: const Icon(
                                    Icons.person_pin_circle,
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
          ),
        ],
      ),
      floatingActionButton: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          FloatingActionButton.small(
            heroTag: 'set_office',
            onPressed: _setOfficeLocation,
            backgroundColor: Colors.orange.shade700,
            tooltip: 'Set Lokasi Kantor Sekarang',
            child: const Icon(Icons.add_location_alt_rounded, color: Colors.white),
          ),
          const SizedBox(height: 8),
          FloatingActionButton.small(
            heroTag: 'office',
            onPressed: _goToOffice,
            backgroundColor: Colors.blue.shade700,
            child: const Icon(Icons.business, color: Colors.white),
          ),
          const SizedBox(height: 8),
          FloatingActionButton.small(
            heroTag: 'user',
            onPressed: _goToUser,
            backgroundColor: Colors.red.shade600,
            child: const Icon(Icons.my_location, color: Colors.white),
          ),
          const SizedBox(height: 8),
          FloatingActionButton.small(
            heroTag: 'refresh',
            onPressed: _loadMap,
            backgroundColor: Colors.green.shade600,
            child: const Icon(Icons.refresh, color: Colors.white),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoTile({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 14, color: color),
            const SizedBox(width: 4),
            Text(
              label,
              style: TextStyle(fontSize: 11, color: Colors.grey.shade500),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: color,
          ),
        ),
      ],
    );
  }
}
