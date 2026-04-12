import 'package:flutter/material.dart';
import 'package:hello_flutter_app/screens/pick_location_screen.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';

class CartScreen extends StatefulWidget {
  const CartScreen({super.key});

  @override
  State<CartScreen> createState() => _CartScreenState();
}

class _CartScreenState extends State<CartScreen> {
  final List<_CartItem> _items = [
    _CartItem(
      id: 1,
      name: 'Smart Blender',
      price: 1250000,
      qty: 1,
      selected: true,
      imagePath: 'assets/corusel1.png',
    ),
    _CartItem(
      id: 2,
      name: 'Quloqchin Pro',
      price: 499000,
      qty: 2,
      selected: true,
      imagePath: 'assets/corusel2.png',
    ),
  ];
  String _payMethod = 'Click';
  final List<_Receiver> _receivers = [];
  int _selectedReceiver = -1;
  String _deliveryPlace = 'Manzil tanlanmagan';
  LatLng? _deliveryPoint;
  
  void _removeReceiver(int index) {
    setState(() {
      if (index < 0 || index >= _receivers.length) return;
      _receivers.removeAt(index);
      if (_receivers.isEmpty) {
        _selectedReceiver = -1;
      } else {
        _selectedReceiver = 0;
      }
    });
  }

  int _total() {
    int sum = 0;
    for (final i in _items) {
      if (i.selected) {
        sum += i.price * i.qty;
      }
    }
    return sum;
  }

  String _format(int v) {
    final s = v.toString();
    final b = StringBuffer();
    for (int i = 0; i < s.length; i++) {
      final idx = s.length - i;
      b.write(s[i]);
      if (idx > 1 && idx % 3 == 1) b.write(' ');
    }
    return b.toString();
  }

  void _changeQty(int id, int delta) {
    setState(() {
      final idx = _items.indexWhere((e) => e.id == id);
      if (idx == -1) return;
      final next = _items[idx].qty + delta;
      _items[idx] = _items[idx].copyWith(qty: next < 1 ? 1 : next);
    });
  }

  void _removeItem(int id) {
    setState(() {
      _items.removeWhere((e) => e.id == id);
    });
  }

  void _toggleSelected(int id) {
    setState(() {
      final idx = _items.indexWhere((e) => e.id == id);
      if (idx == -1) return;
      _items[idx] =
          _items[idx].copyWith(selected: !_items[idx].selected);
    });
  }

  void _selectPay(String method) {
    setState(() => _payMethod = method);
  }

  void _openReceiverModal() {
    final firstCtrl = TextEditingController();
    final lastCtrl = TextEditingController();
    final phoneCtrl = TextEditingController();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Padding(
            padding: EdgeInsets.fromLTRB(
              16,
              8,
              16,
              MediaQuery.of(ctx).viewInsets.bottom + 16,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Yangi buyurtma oluvchi',
                  style: TextStyle(
                    color: Color(0xFF0F2F2B),
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: firstCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Ism',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: lastCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Familiya',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: phoneCtrl,
                  keyboardType: TextInputType.phone,
                  decoration: const InputDecoration(
                    labelText: 'Telefon raqami',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  height: 44,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF0F2F2B),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    onPressed: () {
                      if (firstCtrl.text.trim().isEmpty ||
                          lastCtrl.text.trim().isEmpty ||
                          phoneCtrl.text.trim().isEmpty) {
                        return;
                      }
                      setState(() {
                        _receivers.add(_Receiver(
                          firstName: firstCtrl.text.trim(),
                          lastName: lastCtrl.text.trim(),
                          phone: phoneCtrl.text.trim(),
                        ));
                        _selectedReceiver = _receivers.length - 1;
                      });
                      Navigator.pop(ctx);
                    },
                    child: const Text(
                      'Saqlash',
                      style:
                          TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _openDeliveryModal() {
    showModalBottomSheet(
      context: context,
      showDragHandle: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Yetkazib berish joyi',
                  style: TextStyle(
                    color: Color(0xFF0F2F2B),
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 12),
                _PayOption(
                  title: 'Xarita orqali tanlash',
                  onTap: () {
                    Navigator.pop(ctx);
                    _openMapPicker();
                  },
                ),
                const SizedBox(height: 8),
                _PayOption(
                  title: 'Hozirgi joyim (GPS)',
                  onTap: () {
                    Navigator.pop(ctx);
                    _useCurrentLocation();
                  },
                ),
                const SizedBox(height: 8),
                _PayOption(
                  title: "Manzilni qo'lda yozish",
                  onTap: () {
                    Navigator.pop(ctx);
                    _openManualAddress();
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _openMapPicker() {
    Navigator.of(context)
        .push<PickResult>(
      MaterialPageRoute(
        builder: (_) => PickLocationScreen(initial: _deliveryPoint),
      ),
    )
        .then((result) {
      if (result == null) return;
      setState(() {
        _deliveryPoint = result.point;
        _deliveryPlace = result.address.isEmpty
            ? 'Lat: ${result.point.latitude.toStringAsFixed(5)}, Lng: ${result.point.longitude.toStringAsFixed(5)}'
            : result.address;
      });
    });
  }

  Future<void> _useCurrentLocation() async {
    try {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Joy aniqlanmoqda...')),
        );
      }
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        _showLocationDialog(
          title: 'Location o‘chiq',
          message: 'Location yoqing va qayta urinib ko‘ring.',
          openSettings: Geolocator.openLocationSettings,
        );
        return;
      }
      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        _showLocationDialog(
          title: 'Location ruxsati yo‘q',
          message: 'Ruxsat berish uchun sozlamalarga kiring.',
          openSettings: Geolocator.openAppSettings,
        );
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
        _showLocationDialog(
          title: 'Joy aniqlanmadi',
          message:
              'Location topilmadi. GPS yoqilganini tekshiring va qayta urinib ko‘ring.',
          openSettings: Geolocator.openLocationSettings,
        );
        return;
      }
      final point = LatLng(pos.latitude, pos.longitude);
      String address = '';
      try {
        final placemarks =
            await placemarkFromCoordinates(point.latitude, point.longitude);
        if (placemarks.isNotEmpty) {
          final m = placemarks.first;
          final parts = <String>[
            if ((m.street ?? '').isNotEmpty) m.street!,
            if ((m.locality ?? '').isNotEmpty) m.locality!,
            if ((m.administrativeArea ?? '').isNotEmpty) m.administrativeArea!,
          ];
          address = parts.join(', ');
        }
      } catch (_) {}
      setState(() {
        _deliveryPoint = point;
        _deliveryPlace = address.isEmpty
            ? 'Lat: ${point.latitude.toStringAsFixed(5)}, Lng: ${point.longitude.toStringAsFixed(5)}'
            : address;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Joy tanlandi')),
        );
      }
    } catch (_) {}
  }

  void _openManualAddress() {
    final cityCtrl = TextEditingController();
    final streetCtrl = TextEditingController();
    final homeCtrl = TextEditingController();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Padding(
            padding: EdgeInsets.fromLTRB(
              16,
              8,
              16,
              MediaQuery.of(ctx).viewInsets.bottom + 16,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    "Manzilni qo'lda yozish",
                    style: TextStyle(
                      color: Color(0xFF0F2F2B),
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: cityCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Shahar',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: streetCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Ko‘cha',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: homeCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Uy / kvartira',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  height: 44,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF0F2F2B),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    onPressed: () {
                      final city = cityCtrl.text.trim();
                      final street = streetCtrl.text.trim();
                      final home = homeCtrl.text.trim();
                      final parts = [city, street, home]
                          .where((e) => e.isNotEmpty)
                          .toList();
                      if (parts.isEmpty) return;
                      setState(() {
                        _deliveryPlace = parts.join(', ');
                      });
                      Navigator.pop(ctx);
                    },
                    child: const Text(
                      'Saqlash',
                      style:
                          TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showLocationDialog({
    required String title,
    required String message,
    required Future<bool> Function() openSettings,
  }) {
    showDialog(
      context: context,
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

  void _openPaySummary() {
    showModalBottomSheet(
      context: context,
      showDragHandle: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'To‘lov: $_payMethod',
                  style: const TextStyle(
                    color: Color(0xFF0F2F2B),
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 10),
                _RowItem(
                  label: 'Jami summa',
                  value: '${_format(_total())} so‘m',
                  bold: true,
                ),
                const SizedBox(height: 12),
                SizedBox(
                  height: 44,
                  width: double.infinity,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF0F2F2B),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    onPressed: () {},
                    child: Text(
                      _payMethod == "Mahsulotni olgandan so'ng"
                          ? "Buyurtmani tasdiqlash"
                          : "To'lash",
                      style: const TextStyle(
                          fontSize: 14, fontWeight: FontWeight.w700),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showOrderSuccess() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) {
        return Dialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 24, 20, 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.check_circle,
                    color: Colors.green, size: 64),
                const SizedBox(height: 12),
                const Text(
                  'Buyurtmangiz qabul qilindi',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Color(0xFF0F2F2B),
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  "Buyurtma uchun rahmat. Uni tez orada yetkazib berishadi.",
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Color(0xFF3D4B48),
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  height: 40,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF0F2F2B),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    onPressed: () => Navigator.pop(ctx),
                    child: const Text(
                      'Tushunarli',
                      style:
                          TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    const primaryGreen = Color(0xFF0F2F2B);
    final currentReceiver =
        _selectedReceiver >= 0 ? _receivers[_selectedReceiver] : null;
    final canOrder = _items.any((e) => e.selected) &&
        (currentReceiver?.fullName.trim().isNotEmpty ?? false) &&
        (currentReceiver?.phone.trim().length ?? 0) > 3 &&
        _deliveryPlace != 'Manzil tanlanmagan' &&
        _payMethod.trim().isNotEmpty;

    String? _missingField() {
      if (!_items.any((e) => e.selected)) return 'Mahsulot tanlanmagan';
      if (currentReceiver == null ||
          currentReceiver.fullName.trim().isEmpty ||
          currentReceiver.phone.trim().length <= 3) {
        return 'Buyurtma oluvchi yo‘q';
      }
      if (_deliveryPlace == 'Manzil tanlanmagan') {
        return 'Yetkazib berish manzili yo‘q';
      }
      if (_payMethod.trim().isEmpty) return 'To‘lov usuli tanlanmagan';
      return null;
    }

    if (_items.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        child: Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(18),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.12),
                blurRadius: 22,
                offset: const Offset(0, 10),
              ),
            ],
            border: Border.all(color: primaryGreen.withOpacity(0.18)),
          ),
          child: Column(
            children: const [
              Icon(Icons.shopping_cart_outlined,
                  size: 52, color: primaryGreen),
              SizedBox(height: 12),
              Text(
                'Savat bo‘sh',
                style: TextStyle(
                  color: primaryGreen,
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
              ),
              SizedBox(height: 6),
              Text(
                'Mahsulot qo‘shing va buyurtma bering.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Color(0xFF8A9A97),
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        children: [
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _items.length,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final item = _items[index];
              return _CartCard(
                item: item,
                onToggle: () => _toggleSelected(item.id),
                onAdd: () => _changeQty(item.id, 1),
                onRemove: () => _changeQty(item.id, -1),
                onDelete: () => _removeItem(item.id),
              );
            },
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.08),
                  blurRadius: 16,
                  offset: const Offset(0, 8),
                ),
              ],
              border: Border.all(color: primaryGreen.withOpacity(0.12)),
            ),
            child: Column(
              children: [
                SizedBox(
                  height: 46,
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: _openReceiverModal,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: primaryGreen,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    icon: const Icon(Icons.person_add, size: 20),
                    label: const Text(
                      'Buyurtmani oluvchi',
                      style:
                          TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Column(
                  children: List.generate(_receivers.length, (i) {
                    final r = _receivers[i];
                    final selected = i == _selectedReceiver;
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: _PayOption(
                        title: '${r.fullName} • ${r.phone}',
                        selected: selected,
                        onTap: () => setState(() => _selectedReceiver = i),
                      ),
                    );
                  }),
                ),
                const SizedBox(height: 4),
                _SectionCard(
                  title: 'Yetkazib berish joyi',
                  value: _deliveryPlace,
                  onTap: _openDeliveryModal,
                  showChevron: false,
                ),
                const SizedBox(height: 12),
                const Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    "To'lov shaklini tanlang",
                    style: TextStyle(
                      color: Color(0xFF0F2F2B),
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                _PayOption(
                  title: 'Click',
                  leading: Image.asset('assets/click.png', width: 40, height: 40),
                  selected: _payMethod == 'Click',
                  onTap: () => _selectPay('Click'),
                ),
                const SizedBox(height: 8),
                _PayOption(
                  title: 'Payme',
                  leading: Image.asset('assets/payme.png', width: 40, height: 40),
                  selected: _payMethod == 'Payme',
                  onTap: () => _selectPay('Payme'),
                ),
                const SizedBox(height: 8),
                _PayOption(
                  title: "Mahsulotni olgandan so'ng",
                  selected: _payMethod == "Mahsulotni olgandan so'ng",
                  onTap: () => _selectPay("Mahsulotni olgandan so'ng"),
                ),
                const SizedBox(height: 12),
                _RowItem(
                  label: 'Jami',
                  value: '${_format(_total())} so‘m',
                  bold: true,
                ),
                const SizedBox(height: 12),
                SizedBox(
                  height: 44,
                  width: double.infinity,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: primaryGreen,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    onPressed: () {
                      final missing = _missingField();
                      if (missing != null) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(missing),
                            duration: Duration(seconds: 2),
                          ),
                        );
                        return;
                      }
                      _showOrderSuccess();
                    },
                    child: const Text(
                      'Buyurtma berish',
                      style:
                          TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}

class _CartItem {
  final int id;
  final String name;
  final int price;
  final int qty;
  final bool selected;
  final String imagePath;

  const _CartItem({
    required this.id,
    required this.name,
    required this.price,
    required this.qty,
    required this.selected,
    required this.imagePath,
  });

  _CartItem copyWith({int? qty, bool? selected}) {
    return _CartItem(
      id: id,
      name: name,
      price: price,
      qty: qty ?? this.qty,
      selected: selected ?? this.selected,
      imagePath: imagePath,
    );
  }
}

class _CartCard extends StatelessWidget {
  final _CartItem item;
  final VoidCallback onToggle;
  final VoidCallback onAdd;
  final VoidCallback onRemove;
  final VoidCallback onDelete;

  const _CartCard({
    required this.item,
    required this.onToggle,
    required this.onAdd,
    required this.onRemove,
    required this.onDelete,
  });

  String _format(int v) {
    final s = v.toString();
    final b = StringBuffer();
    for (int i = 0; i < s.length; i++) {
      final idx = s.length - i;
      b.write(s[i]);
      if (idx > 1 && idx % 3 == 1) b.write(' ');
    }
    return b.toString();
  }

  @override
  Widget build(BuildContext context) {
    const primaryGreen = Color(0xFF0F2F2B);
    const softGray = Color(0xFFF6F7F8);

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
        border: Border.all(color: primaryGreen.withOpacity(0.12)),
      ),
      child: Column(
        children: [
          Row(
            children: [
              GestureDetector(
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      fullscreenDialog: true,
                      builder: (_) => _ImagePreview(imagePath: item.imagePath),
                    ),
                  );
                },
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.asset(
                    item.imagePath,
                    width: 72,
                    height: 72,
                    fit: BoxFit.cover,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: primaryGreen,
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${_format(item.price)} so‘m',
                      style: TextStyle(
                        color: primaryGreen.withOpacity(0.7),
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        _QtyButton(icon: Icons.remove, onTap: onRemove),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: softGray,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            '${item.qty}',
                            style: const TextStyle(
                              color: primaryGreen,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        _QtyButton(icon: Icons.add, onTap: onAdd),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Column(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    width: 32,
                    height: 32,
                    padding: const EdgeInsets.all(2),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: primaryGreen.withOpacity(0.12)),
                    ),
                    child: Checkbox(
                      value: item.selected,
                      onChanged: (_) => onToggle(),
                      activeColor: primaryGreen,
                      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      visualDensity: VisualDensity.compact,
                    ),
                  ),
                  const SizedBox(height: 12),
                  IconButton(
                    onPressed: onDelete,
                    icon: const Icon(Icons.close, color: Colors.red, size: 18),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _QtyButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;

  const _QtyButton({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    const primaryGreen = Color(0xFF0F2F2B);
    const softGray = Color(0xFFF6F7F8);

    return Container(
      width: 28,
      height: 28,
      decoration: BoxDecoration(
        color: softGray,
        borderRadius: BorderRadius.circular(8),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(8),
        onTap: onTap,
        child: Icon(icon, size: 16, color: primaryGreen),
      ),
    );
  }
}

class _RowItem extends StatelessWidget {
  final String label;
  final String value;
  final bool bold;

  const _RowItem({
    required this.label,
    required this.value,
    this.bold = false,
  });

  @override
  Widget build(BuildContext context) {
    const primaryGreen = Color(0xFF0F2F2B);
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            color: primaryGreen.withOpacity(bold ? 1 : 0.7),
            fontSize: bold ? 14 : 12,
            fontWeight: bold ? FontWeight.w700 : FontWeight.w500,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            color: primaryGreen,
            fontSize: bold ? 14 : 12,
            fontWeight: bold ? FontWeight.w700 : FontWeight.w600,
          ),
        ),
      ],
    );
  }
}

class _PayOption extends StatelessWidget {
  final String title;
  final Widget? leading;
  final VoidCallback? onTap;
  final bool selected;

  const _PayOption({
    required this.title,
    this.leading,
    this.onTap,
    this.selected = false,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(14),
      onTap: onTap ?? () => Navigator.pop(context),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        decoration: BoxDecoration(
          color: selected
              ? const Color(0xFFE6F4EF)
              : const Color(0xFFF6F7F8),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: selected
                ? const Color(0xFF0F2F2B)
                : const Color(0xFF0F2F2B).withOpacity(0.1),
          ),
        ),
        child: Row(
          children: [
            if (leading != null) ...[
              leading!,
              const SizedBox(width: 10),
            ],
            Text(
              title,
              style: const TextStyle(
                color: Color(0xFF0F2F2B),
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
            const Spacer(),
            if (selected)
              const Icon(Icons.check_circle,
                  color: Color(0xFF0F2F2B), size: 18),
          ],
        ),
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  final String title;
  final String value;
  final VoidCallback onTap;
  final bool showChevron;
  final Widget? trailing;

  const _SectionCard({
    required this.title,
    required this.value,
    required this.onTap,
    this.showChevron = true,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        decoration: BoxDecoration(
          color: const Color(0xFFF6F7F8),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: const Color(0xFF0F2F2B).withOpacity(0.1)),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      color: Color(0xFF0F2F2B),
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    value,
                    style: const TextStyle(
                      color: Color(0xFF0F2F2B),
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                    ),
                    softWrap: true,
                    overflow: TextOverflow.visible,
                  ),
                ],
              ),
            ),
            if (trailing != null)
              trailing!
            else if (showChevron)
              const Icon(Icons.chevron_right, color: Color(0xFF0F2F2B)),
          ],
        ),
      ),
    );
  }
}

class _Receiver {
  final String firstName;
  final String lastName;
  final String phone;

  const _Receiver({
    required this.firstName,
    required this.lastName,
    required this.phone,
  });

  String get fullName => '$firstName $lastName';
}

class _ImagePreview extends StatelessWidget {
  final String imagePath;

  const _ImagePreview({required this.imagePath});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Stack(
          children: [
            Center(
              child: InteractiveViewer(
                child: Image.asset(imagePath),
              ),
            ),
            Positioned(
              top: 12,
              right: 12,
              child: IconButton(
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.close, color: Colors.white),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
