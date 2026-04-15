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

class _PickLocationScreenState extends State<PickLocationScreen>
    with SingleTickerProviderStateMixin {
  late LatLng _selected;
  bool _loading = false;
  String _address = 'Manzil tanlanmagan';
  final MapController _mapController = MapController();
  late final AnimationController _animController;
  bool _mapReady = false;
  LatLng? _pendingTarget;
  double? _pendingZoom;
  VoidCallback? _animListener;

  @override
  void initState() {
    super.initState();
    _selected = widget.initial ?? const LatLng(41.2995, 69.2401); // Tashkent
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    _reverseGeocode(_selected);
    // Try to auto-select current location on open
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _useMyLocation();
    });
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  Future<void> _useMyLocation() async {
    setState(() => _loading = true);
    try {
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        if (mounted) {
          _showLocationDialog(
            title: 'Location o‘chiq',
            message: 'Location yoqing va qayta urinib ko‘ring.',
            openSettings: Geolocator.openLocationSettings,
          );
        }
        setState(() => _loading = false);
        return;
      }
      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        if (mounted) {
          _showLocationDialog(
            title: 'Location ruxsati yo‘q',
            message: 'Ruxsat berish uchun sozlamalarga kiring.',
            openSettings: Geolocator.openAppSettings,
          );
        }
        setState(() => _loading = false);
        return;
      }
      Position? pos;
      try {
        pos = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high,
          timeLimit: const Duration(seconds: 10),
        );
      } catch (_) {
        pos = await Geolocator.getLastKnownPosition();
      }
      if (pos == null) {
        if (mounted) {
          _showLocationDialog(
            title: 'Joy aniqlanmadi',
            message:
                'Location topilmadi. GPS yoqilganini tekshiring va qayta urinib ko‘ring.',
            openSettings: Geolocator.openLocationSettings,
          );
        }
        setState(() => _loading = false);
        return;
      }
      setState(() {
        _selected = LatLng(pos!.latitude, pos.longitude);
        _loading = false;
      });
      _animateTo(_selected, 16);
      _reverseGeocode(_selected);
    } catch (_) {
      setState(() => _loading = false);
    }
  }

  void _animateTo(LatLng target, double zoom) {
    if (!_mapReady) {
      _pendingTarget = target;
      _pendingZoom = zoom;
      return;
    }
    final startCenter = _mapController.camera.center;
    final startZoom = _mapController.camera.zoom;
    final tween = _LatLngTween(begin: startCenter, end: target);
    final zoomTween = Tween<double>(begin: startZoom, end: zoom);
    final animation = CurvedAnimation(
      parent: _animController,
      curve: Curves.easeOutCubic,
    );
    if (_animListener != null) {
      _animController.removeListener(_animListener!);
    }
    _animListener = () {
      final c = tween.lerp(animation.value);
      final z = zoomTween.lerp(animation.value)!;
      _mapController.move(c, z);
    };
    _animController
      ..reset()
      ..addListener(_animListener!)
      ..forward();
  }

  void _showLocationDialog({
    required String title,
    required String message,
    required Future<bool> Function() openSettings,
  }) {
    _showFastDialog(
      builder: (ctx) {
        return AlertDialog(
          title: Text(title),
          content: Text(message),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Bekor'),
            ),
            TextButton(
              onPressed: () async {
                Navigator.pop(ctx);
                await openSettings();
              },
              child: const Text('Sozlamalar'),
            ),
          ],
        );
      },
    );
  }

  Future<T?> _showFastDialog<T>({
    required WidgetBuilder builder,
    bool barrierDismissible = true,
  }) {
    return showGeneralDialog<T>(
      context: context,
      barrierDismissible: barrierDismissible,
      barrierLabel:
          MaterialLocalizations.of(context).modalBarrierDismissLabel,
      barrierColor: Colors.black54,
      transitionDuration: const Duration(milliseconds: 150),
      pageBuilder: (ctx, _, __) {
        return SafeArea(
          child: Builder(builder: builder),
        );
      },
      transitionBuilder: (ctx, anim, __, child) {
        final curved =
            CurvedAnimation(parent: anim, curve: Curves.easeOutCubic);
        return FadeTransition(
          opacity: curved,
          child: ScaleTransition(
            scale: Tween<double>(begin: 0.98, end: 1.0).animate(curved),
            child: child,
          ),
        );
      },
    );
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
              mapController: _mapController,
              options: MapOptions(
                initialCenter: _selected,
                initialZoom: 13,
                onMapReady: () {
                  _mapReady = true;
                  if (_pendingTarget != null && _pendingZoom != null) {
                    final t = _pendingTarget!;
                    final z = _pendingZoom!;
                    _pendingTarget = null;
                    _pendingZoom = null;
                    _animateTo(t, z);
                  }
                },
                onTap: (_, point) {
                  setState(() => _selected = point);
                  _animateTo(point, _mapController.camera.zoom);
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
                    PickResult(point: _selected, address: _address),
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

class PickResult {
  final LatLng point;
  final String address;

  const PickResult({required this.point, required this.address});
}

class _LatLngTween {
  final LatLng begin;
  final LatLng end;

  const _LatLngTween({required this.begin, required this.end});

  LatLng lerp(double t) {
    return LatLng(
      begin.latitude + (end.latitude - begin.latitude) * t,
      begin.longitude + (end.longitude - begin.longitude) * t,
    );
  }
}
