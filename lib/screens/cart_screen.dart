import 'package:flutter/material.dart';
import 'package:hello_flutter_app/models/product.dart';
import 'package:hello_flutter_app/screens/orders_screen.dart';
import 'package:hello_flutter_app/screens/pick_location_screen.dart';
import 'package:hello_flutter_app/services/auth_api_service.dart';
import 'package:hello_flutter_app/services/order_api_service.dart';
import 'package:hello_flutter_app/services/product_api_service.dart';
import 'package:hello_flutter_app/widgets/product_image.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';

class CartScreen extends StatefulWidget {
  final VoidCallback? onSummaryChanged;

  const CartScreen({super.key, this.onSummaryChanged});

  @override
  State<CartScreen> createState() => _CartScreenState();
}

class _CartScreenState extends State<CartScreen> {
  final ProductApiService _productApi = ProductApiService();
  final OrderApiService _orderApi = OrderApiService();
  final List<_CartItem> _items = [];
  bool _isLoadingCart = true;
  String? _cartError;
  String _payMethod = 'Click';
  bool _isPlacingOrder = false;
  final List<_Receiver> _receivers = [];
  int _selectedReceiver = -1;
  String _deliveryPlace = 'Manzil tanlanmagan';
  LatLng? _deliveryPoint;

  @override
  void initState() {
    super.initState();
    _loadCart();
  }

  Future<void> _loadCart() async {
    setState(() {
      _isLoadingCart = true;
      _cartError = null;
    });
    try {
      final products = await _productApi.getCartProducts();
      if (!mounted) return;
      setState(() {
        _items
          ..clear()
          ..addAll(products.map(_CartItem.fromProduct));
        _isLoadingCart = false;
      });
    } on AuthApiException catch (error) {
      if (!mounted) return;
      setState(() {
        _cartError = error.message;
        _isLoadingCart = false;
      });
    } on Object {
      if (!mounted) return;
      setState(() {
        _cartError = 'Savatchani yuklab bo‘lmadi';
        _isLoadingCart = false;
      });
    }
  }

  Future<T?> _showFastBottomSheet<T>({
    required WidgetBuilder builder,
    bool isScrollControlled = false,
    bool showDragHandle = true,
    bool isDismissible = true,
    bool enableDrag = true,
    bool useRootNavigator = false,
    Color? backgroundColor,
    ShapeBorder? shape,
  }) {
    return showModalBottomSheet<T>(
      context: context,
      isScrollControlled: isScrollControlled,
      showDragHandle: showDragHandle,
      isDismissible: isDismissible,
      enableDrag: enableDrag,
      useRootNavigator: useRootNavigator,
      backgroundColor: backgroundColor,
      shape: shape,
      builder: builder,
    );
  }

  Future<T?> _showFastDialog<T>({
    required WidgetBuilder builder,
    bool barrierDismissible = true,
  }) {
    return showGeneralDialog<T>(
      context: context,
      barrierDismissible: barrierDismissible,
      barrierLabel: MaterialLocalizations.of(context).modalBarrierDismissLabel,
      barrierColor: Colors.black54,
      transitionDuration: const Duration(milliseconds: 150),
      pageBuilder: (ctx, _, __) {
        return SafeArea(child: Builder(builder: builder));
      },
      transitionBuilder: (ctx, anim, __, child) {
        final curved = CurvedAnimation(
          parent: anim,
          curve: Curves.easeOutCubic,
        );
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

  _Receiver? _activeReceiver() {
    if (_receivers.isEmpty) return null;
    if (_selectedReceiver >= 0 && _selectedReceiver < _receivers.length) {
      return _receivers[_selectedReceiver];
    }
    return _receivers.first;
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

  Future<void> _changeQty(String id, int delta) async {
    final idx = _items.indexWhere((e) => e.id == id);
    if (idx == -1) return;
    final current = _items[idx];
    final next = current.qty + delta;
    final normalized = next < 1 ? 1 : next;
    setState(() {
      _items[idx] = current.copyWith(qty: normalized);
    });
    try {
      final serverQty = await _productApi.addToCart(id, qty: normalized);
      widget.onSummaryChanged?.call();
      if (!mounted) return;
      setState(() {
        final currentIdx = _items.indexWhere((e) => e.id == id);
        if (currentIdx != -1) {
          _items[currentIdx] = _items[currentIdx].copyWith(qty: serverQty);
        }
      });
    } on Object {
      if (!mounted) return;
      setState(() {
        final currentIdx = _items.indexWhere((e) => e.id == id);
        if (currentIdx != -1) _items[currentIdx] = current;
      });
      _showSnack('Server bilan bog‘lanib bo‘lmadi');
    }
  }

  Future<void> _removeItem(String id) async {
    final idx = _items.indexWhere((e) => e.id == id);
    if (idx == -1) return;
    final removed = _items[idx];
    setState(() {
      _items.removeWhere((e) => e.id == id);
    });
    try {
      await _productApi.removeFromCart(id);
      widget.onSummaryChanged?.call();
    } on Object {
      if (!mounted) return;
      setState(() => _items.insert(idx, removed));
      _showSnack('Server bilan bog‘lanib bo‘lmadi');
    }
  }

  Future<void> _toggleSelected(String id) async {
    setState(() {
      final idx = _items.indexWhere((e) => e.id == id);
      if (idx == -1) return;
      _items[idx] = _items[idx].copyWith(selected: !_items[idx].selected);
    });
    final item = _items.firstWhere((e) => e.id == id);
    try {
      await _productApi.addToCart(id, qty: item.qty, selected: item.selected);
      widget.onSummaryChanged?.call();
    } on Object {
      if (!mounted) return;
      setState(() {
        final idx = _items.indexWhere((e) => e.id == id);
        if (idx != -1) {
          _items[idx] = _items[idx].copyWith(selected: !item.selected);
        }
      });
      _showSnack('Server bilan bog‘lanib bo‘lmadi');
    }
  }

  void _showSnack(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), duration: const Duration(seconds: 2)),
    );
  }

  void _selectPay(String method) {
    setState(() => _payMethod = method);
  }

  String _paymentMethodToApi(String uiValue) {
    final v = uiValue.trim();
    if (v == 'Click') return 'click';
    if (v == 'Payme') return 'payme';
    if (v == "Mahsulotni olgandan so'ng") return 'cod';
    return v.toLowerCase();
  }

  Future<void> _placeOrder() async {
    if (_isPlacingOrder) return;
    final receiver = _activeReceiver();
    if (receiver == null) {
      _showSnack('Buyurtma oluvchi yo‘q');
      return;
    }
    if (_deliveryPlace == 'Manzil tanlanmagan') {
      _showSnack('Yetkazib berish manzili yo‘q');
      return;
    }
    if (!_items.any((e) => e.selected)) {
      _showSnack('Mahsulot tanlanmagan');
      return;
    }

    final selected = _items.where((e) => e.selected).toList();
    final storeIds = selected
        .map((e) => e.storeId.trim())
        .where((e) => e.isNotEmpty)
        .toSet();
    if (storeIds.isEmpty) {
      _showSnack("Do'kon aniqlanmadi");
      return;
    }
    if (storeIds.length != 1) {
      _showSnack("Buyurtma faqat bitta do'kondan bo'lishi kerak");
      return;
    }
    final storeId = storeIds.first;

    setState(() => _isPlacingOrder = true);
    try {
      final order = await _orderApi.createOrder(
        storeId: storeId,
        receiver: {
          'firstName': receiver.firstName,
          'lastName': receiver.lastName,
          'phone': receiver.phone,
        },
        delivery: {
          'addressText': _deliveryPlace,
          'lat': _deliveryPoint?.latitude,
          'lng': _deliveryPoint?.longitude,
        },
        paymentMethod: _paymentMethodToApi(_payMethod),
      );
      await _loadCart();
      widget.onSummaryChanged?.call();
      if (!mounted) return;
      _showOrderSuccess(orderId: order.id);
    } on AuthApiException catch (error) {
      if (!mounted) return;
      _showSnack(error.message);
    } on Object {
      if (!mounted) return;
      _showSnack('Server bilan bog‘lanib bo‘lmadi');
    } finally {
      if (mounted) setState(() => _isPlacingOrder = false);
    }
  }

  InputDecoration _modalInputDecoration(String label) {
    const primaryGreen = Color(0xFF1F5A50);
    const mutedText = Color(0xFF8A9A97);

    OutlineInputBorder border(Color color, {double width = 1}) {
      return OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: color, width: width),
      );
    }

    return InputDecoration(
      labelText: label,
      labelStyle: const TextStyle(color: mutedText),
      floatingLabelStyle: const TextStyle(
        color: primaryGreen,
        fontWeight: FontWeight.w700,
      ),
      filled: true,
      fillColor: const Color(0xFFF6F7F8),
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      enabledBorder: border(primaryGreen.withValues(alpha: 0.12)),
      focusedBorder: border(primaryGreen, width: 1.4),
      errorBorder: border(Colors.redAccent.withValues(alpha: 0.7)),
      focusedErrorBorder: border(Colors.redAccent, width: 1.4),
    );
  }

  void _openReceiverModal() {
    final firstCtrl = TextEditingController();
    final lastCtrl = TextEditingController();
    final phoneCtrl = TextEditingController();
    _showFastBottomSheet(
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
                    color: Color(0xFF1F5A50),
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: firstCtrl,
                  cursorColor: const Color(0xFF1F5A50),
                  decoration: _modalInputDecoration('Ism'),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: lastCtrl,
                  cursorColor: const Color(0xFF1F5A50),
                  decoration: _modalInputDecoration('Familiya'),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: phoneCtrl,
                  keyboardType: TextInputType.phone,
                  cursorColor: const Color(0xFF1F5A50),
                  decoration: _modalInputDecoration('Telefon raqami'),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  height: 44,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF1F5A50),
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
                        _receivers.add(
                          _Receiver(
                            firstName: firstCtrl.text.trim(),
                            lastName: lastCtrl.text.trim(),
                            phone: phoneCtrl.text.trim(),
                          ),
                        );
                        _selectedReceiver = _receivers.length - 1;
                      });
                      Navigator.pop(ctx);
                    },
                    child: const Text(
                      'Saqlash',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                      ),
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
    _showFastBottomSheet(
      isDismissible: true,
      enableDrag: true,
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
                Row(
                  children: [
                    const Expanded(
                      child: Text(
                        'Yetkazib berish joyi',
                        style: TextStyle(
                          color: Color(0xFF1F5A50),
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.of(ctx).pop(),
                      icon: const Icon(Icons.close, size: 20),
                      color: const Color(0xFF1F5A50),
                      splashRadius: 20,
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                _PayOption(
                  title: 'Xarita orqali tanlash',
                  onTap: () {
                    Navigator.of(ctx).pop();
                    _openMapPicker();
                  },
                ),
                const SizedBox(height: 8),
                _PayOption(
                  title: 'Hozirgi joyim (GPS)',
                  onTap: () {
                    Navigator.of(ctx).pop();
                    _useCurrentLocation();
                  },
                ),
                const SizedBox(height: 8),
                _PayOption(
                  title: "Manzilni qo'lda yozish",
                  onTap: () {
                    Navigator.of(ctx).pop();
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
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Joy aniqlanmoqda...')));
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
        final placemarks = await placemarkFromCoordinates(
          point.latitude,
          point.longitude,
        );
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
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Joy tanlandi')));
      }
    } catch (_) {}
  }

  void _openManualAddress() {
    final cityCtrl = TextEditingController();
    final streetCtrl = TextEditingController();
    final homeCtrl = TextEditingController();
    _showFastBottomSheet(
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
                      color: Color(0xFF1F5A50),
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: cityCtrl,
                  cursorColor: const Color(0xFF1F5A50),
                  decoration: _modalInputDecoration('Shahar'),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: streetCtrl,
                  cursorColor: const Color(0xFF1F5A50),
                  decoration: _modalInputDecoration('Ko‘cha'),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: homeCtrl,
                  cursorColor: const Color(0xFF1F5A50),
                  decoration: _modalInputDecoration('Uy / kvartira'),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  height: 44,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF1F5A50),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    onPressed: () {
                      final city = cityCtrl.text.trim();
                      final street = streetCtrl.text.trim();
                      final home = homeCtrl.text.trim();
                      final parts = [
                        city,
                        street,
                        home,
                      ].where((e) => e.isNotEmpty).toList();
                      if (parts.isEmpty) return;
                      setState(() {
                        _deliveryPlace = parts.join(', ');
                      });
                      Navigator.pop(ctx);
                    },
                    child: const Text(
                      'Saqlash',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                      ),
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

  void _openPaySummary() {
    _showFastBottomSheet(
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
                    color: Color(0xFF1F5A50),
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
                      backgroundColor: const Color(0xFF1F5A50),
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
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                      ),
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

  void _showOrderSuccess({String? orderId}) {
    _showFastDialog(
      barrierDismissible: false,
      builder: (ctx) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 24, 20, 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.check_circle, color: Colors.green, size: 64),
                const SizedBox(height: 12),
                const Text(
                  'Buyurtmangiz qabul qilindi',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Color(0xFF1F5A50),
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                if (orderId != null && orderId.trim().isNotEmpty) ...[
                  const SizedBox(height: 6),
                  Text(
                    'Buyurtma ID: $orderId',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: Color(0xFF8A9A97),
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
                const SizedBox(height: 8),
                const Text(
                  "Buyurtma uchun rahmat. Uni tez orada yetkazib berishadi.",
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Color(0xFF3D4B48), fontSize: 12),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  height: 40,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF1F5A50),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    onPressed: () => Navigator.pop(ctx),
                    child: const Text(
                      'Tushunarli',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                TextButton(
                  onPressed: () {
                    Navigator.pop(ctx);
                    Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const OrdersScreen()),
                    );
                  },
                  child: const Text(
                    "Buyurtmalaringizni Mening buyurtmalarim sahifasida ko'rishingiz mumkin",
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Color(0xFF1F5A50),
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      decoration: TextDecoration.underline,
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
    const primaryGreen = Color(0xFF1F5A50);
    final currentReceiver = _activeReceiver();
    final canOrder =
        _items.any((e) => e.selected) &&
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

    if (_isLoadingCart) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 28),
        child: Center(child: CircularProgressIndicator(color: primaryGreen)),
      );
    }

    if (_cartError != null) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        child: Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: primaryGreen.withOpacity(0.18)),
          ),
          child: Column(
            children: [
              const Icon(
                Icons.shopping_cart_outlined,
                size: 52,
                color: primaryGreen,
              ),
              const SizedBox(height: 12),
              Text(
                _cartError!,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: primaryGreen,
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 12),
              TextButton.icon(
                onPressed: _loadCart,
                icon: const Icon(Icons.refresh_rounded),
                label: const Text('Qayta urinish'),
                style: TextButton.styleFrom(foregroundColor: primaryGreen),
              ),
            ],
          ),
        ),
      );
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
              Icon(Icons.shopping_cart_outlined, size: 52, color: primaryGreen),
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
                style: TextStyle(color: Color(0xFF8A9A97), fontSize: 12),
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
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                      ),
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
                        title: r.fullName,
                        subtitle: r.phone,
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
                      color: Color(0xFF1F5A50),
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                _PayOption(
                  title: 'Click',
                  leading: Image.asset(
                    'assets/click.png',
                    width: 40,
                    height: 40,
                  ),
                  selected: _payMethod == 'Click',
                  onTap: () => _selectPay('Click'),
                ),
                const SizedBox(height: 8),
                _PayOption(
                  title: 'Payme',
                  leading: Image.asset(
                    'assets/payme.png',
                    width: 40,
                    height: 40,
                  ),
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
                    onPressed: !canOrder || _isPlacingOrder
                        ? null
                        : () {
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
                            _placeOrder();
                          },
                    child: _isPlacingOrder
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Text(
                            'Buyurtma berish',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                            ),
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
  final String id;
  final String name;
  final int price;
  final int qty;
  final bool selected;
  final String imagePath;
  final List<String> images;
  final String storeId;

  const _CartItem({
    required this.id,
    required this.name,
    required this.price,
    required this.qty,
    required this.selected,
    required this.imagePath,
    required this.images,
    required this.storeId,
  });

  factory _CartItem.fromProduct(Product product) {
    final resolvedImages = product.resolvedImages;
    final previewImage = resolvedImages.isNotEmpty
        ? resolvedImages.first
        : product.resolvedImagePath;
    return _CartItem(
      id: product.id,
      name: product.name,
      price: product.price,
      qty: product.cartQty > 0 ? product.cartQty : 1,
      selected: product.selected,
      imagePath: previewImage,
      images: resolvedImages.isNotEmpty ? resolvedImages : [previewImage],
      storeId: product.storeId,
    );
  }

  _CartItem copyWith({int? qty, bool? selected}) {
    return _CartItem(
      id: id,
      name: name,
      price: price,
      qty: qty ?? this.qty,
      selected: selected ?? this.selected,
      imagePath: imagePath,
      images: images,
      storeId: storeId,
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
    const primaryGreen = Color(0xFF1F5A50);
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
                      builder: (_) =>
                          _ImagePreview(images: item.images, initialIndex: 0),
                    ),
                  );
                },
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: SizedBox(
                    width: 72,
                    child: ProductImage(path: item.imagePath, height: 72),
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
    const primaryGreen = Color(0xFF1F5A50);
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

  const _RowItem({required this.label, required this.value, this.bold = false});

  @override
  Widget build(BuildContext context) {
    const primaryGreen = Color(0xFF1F5A50);
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
  final String? subtitle;
  final Widget? leading;
  final VoidCallback? onTap;
  final bool selected;

  const _PayOption({
    required this.title,
    this.subtitle,
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
          color: selected ? const Color(0xFFE6F4EF) : const Color(0xFFF6F7F8),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: selected
                ? const Color(0xFF1F5A50)
                : const Color(0xFF1F5A50).withOpacity(0.1),
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (leading != null) ...[leading!, const SizedBox(width: 10)],
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    title,
                    softWrap: true,
                    style: const TextStyle(
                      color: Color(0xFF1F5A50),
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      height: 1.2,
                    ),
                  ),
                  if ((subtitle ?? '').trim().isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      subtitle!,
                      softWrap: true,
                      style: const TextStyle(
                        color: Color(0xFF3D4B48),
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        height: 1.2,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(width: 10),
            if (selected)
              const Padding(
                padding: EdgeInsets.only(top: 2),
                child: Icon(
                  Icons.check_circle,
                  color: Color(0xFF1F5A50),
                  size: 18,
                ),
              ),
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
          border: Border.all(color: const Color(0xFF1F5A50).withOpacity(0.1)),
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
                      color: Color(0xFF1F5A50),
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    value,
                    style: const TextStyle(
                      color: Color(0xFF1F5A50),
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
              const Icon(Icons.chevron_right, color: Color(0xFF1F5A50)),
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

class _ImagePreview extends StatefulWidget {
  final List<String> images;
  final int initialIndex;

  const _ImagePreview({required this.images, this.initialIndex = 0});

  @override
  State<_ImagePreview> createState() => _ImagePreviewState();
}

class _ImagePreviewState extends State<_ImagePreview> {
  late final PageController _controller;
  late final int _safeInitial;

  @override
  void initState() {
    super.initState();
    final count = widget.images.length;
    _safeInitial = widget.initialIndex < 0
        ? 0
        : widget.initialIndex >= count
        ? (count == 0 ? 0 : count - 1)
        : widget.initialIndex;
    _controller = PageController(initialPage: _safeInitial);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Stack(
          children: [
            if (widget.images.isEmpty)
              const Center(
                child: Text(
                  'Rasm topilmadi',
                  style: TextStyle(color: Colors.white),
                ),
              )
            else
              PageView.builder(
                controller: _controller,
                itemCount: widget.images.length,
                itemBuilder: (context, index) {
                  final path = widget.images[index];
                  return Center(
                    child: InteractiveViewer(
                      child:
                          path.startsWith('http://') ||
                              path.startsWith('https://')
                          ? Image.network(path)
                          : Image.asset(path),
                    ),
                  );
                },
              ),
            Positioned(
              top: 12,
              right: 12,
              child: IconButton(
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.close, color: Colors.white),
              ),
            ),
            if (widget.images.isNotEmpty)
              Positioned(
                bottom: 14,
                left: 0,
                right: 0,
                child: Center(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.45),
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      child: AnimatedBuilder(
                        animation: _controller,
                        builder: (context, _) {
                          final page = _controller.hasClients
                              ? (_controller.page ??
                                    _controller.initialPage.toDouble())
                              : _safeInitial.toDouble();
                          final current = page.round().clamp(
                            0,
                            widget.images.length - 1,
                          );
                          return Text(
                            '${current + 1}/${widget.images.length}',
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w700,
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
