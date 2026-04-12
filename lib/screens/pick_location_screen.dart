import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';

class PickLocationScreen extends StatefulWidget {
  final LatLng? initial;

  const PickLocationScreen({super.key, this.initial});

  @override
  State<PickLocationScreen> createState() => _PickLocationScreenState();
}

class _PickLocationScreenState extends State<PickLocationScreen> {
  late LatLng _selected;
  bool _loading = false;
  String _address = 'Manzil tanlanmagan';

  @override
  void initState() {
    super.initState();
    _selected = widget.initial ?? const LatLng(41.2995, 69.2401); // Tashkent
    _reverseGeocode(_selected);
  }

  Future<void> _useMyLocation() async {
    setState(() => _loading = true);
    try {
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        setState(() => _loading = false);
        return;
      }
      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        setState(() => _loading = false);
        return;
      }
      final pos = await Geolocator.getCurrentPosition();
      setState(() {
        _selected = LatLng(pos.latitude, pos.longitude);
        _loading = false;
      });
      _reverseGeocode(_selected);
    } catch (_) {
      setState(() => _loading = false);
    }
  }

  Future<void> _reverseGeocode(LatLng p) async {
    try {
      final placemarks = await placemarkFromCoordinates(p.latitude, p.longitude);
      if (placemarks.isEmpty) return;
      final m = placemarks.first;
      final parts = <String>[
        if ((m.street ?? '').isNotEmpty) m.street!,
        if ((m.subLocality ?? '').isNotEmpty) m.subLocality!,
        if ((m.locality ?? '').isNotEmpty) m.locality!,
        if ((m.administrativeArea ?? '').isNotEmpty) m.administrativeArea!,
      ];
      if (parts.isEmpty) return;
      setState(() {
        _address = parts.join(', ');
      });
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    const primaryGreen = Color(0xFF0F2F2B);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Manzilni tanlang'),
        backgroundColor: Colors.white,
        foregroundColor: primaryGreen,
        elevation: 0,
      ),
      body: Column(
        children: [
          Expanded(
            child: FlutterMap(
              options: MapOptions(
                initialCenter: _selected,
                initialZoom: 13,
                onTap: (_, point) {
                  setState(() => _selected = point);
                  _reverseGeocode(point);
                },
              ),
              children: [
                TileLayer(
                  urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                  userAgentPackageName: 'hello_flutter_app',
                ),
                MarkerLayer(
                  markers: [
                    Marker(
                      point: _selected,
                      width: 48,
                      height: 48,
                      child: const Icon(
                        Icons.location_on,
                        color: Colors.red,
                        size: 36,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
            color: Colors.white,
            child: Row(
              children: [
                ElevatedButton.icon(
                  onPressed: _loading ? null : _useMyLocation,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryGreen,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  icon: const Icon(Icons.my_location, size: 18),
                  label: Text(_loading ? 'Yuklanmoqda...' : 'Mening joyim'),
                ),
                const Spacer(),
                ElevatedButton(
                  onPressed: () => Navigator.pop(
                    context,
                    _PickResult(point: _selected, address: _address),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryGreen,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text('Saqlash'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _PickResult {
  final LatLng point;
  final String address;

  const _PickResult({required this.point, required this.address});
}
