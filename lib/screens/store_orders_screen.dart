import 'package:flutter/material.dart';
import 'package:hello_flutter_app/models/order.dart';
import 'package:hello_flutter_app/services/auth_api_service.dart';
import 'package:hello_flutter_app/services/store_orders_api_service.dart';
import 'package:hello_flutter_app/widgets/product_image.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

class StoreOrdersScreen extends StatefulWidget {
  final String storeId;

  const StoreOrdersScreen({super.key, required this.storeId});

  @override
  State<StoreOrdersScreen> createState() => _StoreOrdersScreenState();
}

class _StoreOrdersScreenState extends State<StoreOrdersScreen> {
  static const primaryGreen = Color(0xFF1F5A50);
  final StoreOrdersApiService _api = StoreOrdersApiService();

  bool _loading = true;
  bool _updating = false;
  String? _error;
  List<OrderModel> _orders = const [];
  final Map<String, String> _deliveryCodes = {};
  final Map<String, TextEditingController> _deliveryCodeCtrls = {};

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    for (final c in _deliveryCodeCtrls.values) {
      c.dispose();
    }
    super.dispose();
  }

  TextEditingController _codeCtrl(String orderId) {
    final existing = _deliveryCodeCtrls[orderId];
    if (existing != null) return existing;
    final created = TextEditingController(text: _deliveryCodes[orderId] ?? '');
    _deliveryCodeCtrls[orderId] = created;
    return created;
  }

  bool _isSixDigits(String v) => RegExp(r'^\d{6}$').hasMatch(v);

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final orders = await _api.getStoreOrders(widget.storeId);
      if (!mounted) return;
      setState(() {
        _orders = orders;
        _loading = false;
      });
    } on AuthApiException catch (error) {
      if (!mounted) return;
      setState(() {
        _error = error.message;
        _loading = false;
      });
    } on Object {
      if (!mounted) return;
      setState(() {
        _error = "Do'konga buyurtmalarni yuklab bo‘lmadi";
        _loading = false;
      });
    }
  }

  String _formatMoney(int v) {
    final s = v.toString();
    final b = StringBuffer();
    for (int i = 0; i < s.length; i++) {
      final idx = s.length - i;
      b.write(s[i]);
      if (idx > 1 && idx % 3 == 1) b.write(' ');
    }
    return b.toString();
  }

  String _dateLabel(DateTime? dt) {
    if (dt == null) return '';
    final local = dt.toLocal();
    final dd = local.day.toString().padLeft(2, '0');
    final mm = local.month.toString().padLeft(2, '0');
    final yy = local.year.toString();
    final hh = local.hour.toString().padLeft(2, '0');
    final min = local.minute.toString().padLeft(2, '0');
    return '$dd.$mm.$yy  $hh:$min';
  }

  String _statusLabel(String status) {
    switch (status.trim().toLowerCase()) {
      case 'pending':
        return 'Kutilmoqda';
      case 'rejected':
        return 'Rad etildi';
      case 'delivering':
      case 'shipped':
        return 'Yetkazilmoqda';
      case 'delivered':
        return 'Yetkazildi';
      case 'canceled':
        return 'Bekor qilindi';
      default:
        return status.trim().isEmpty ? 'Holat noma’lum' : status;
    }
  }

  Color _statusColor(String status) {
    switch (status.trim().toLowerCase()) {
      case 'delivering':
      case 'shipped':
        return const Color(0xFF2E7D6F);
      case 'delivered':
        return const Color(0xFF2DB783);
      case 'rejected':
      case 'canceled':
        return const Color(0xFFE15C5C);
      case 'pending':
      default:
        return primaryGreen;
    }
  }

  Future<void> _accept(OrderModel order) async {
    if (_updating) return;
    setState(() => _updating = true);
    try {
      final updated = await _api.acceptOrder(
        storeId: widget.storeId,
        orderId: order.id,
      );
      if (!mounted) return;
      setState(() {
        _orders = _orders.map((o) => o.id == updated.id ? updated : o).toList();
      });
      _showSnack("Buyurtma qabul qilindi");
    } on AuthApiException catch (error) {
      _showSnack(error.message);
    } on Object {
      _showSnack("Server bilan bog'lanib bo'lmadi");
    } finally {
      if (mounted) setState(() => _updating = false);
    }
  }

  Future<void> _reject(OrderModel order) async {
    if (_updating) return;
    setState(() => _updating = true);
    try {
      final updated = await _api.rejectOrder(
        storeId: widget.storeId,
        orderId: order.id,
      );
      if (!mounted) return;
      setState(() {
        _orders = _orders.map((o) => o.id == updated.id ? updated : o).toList();
      });
      _showSnack("Buyurtma rad etildi");
    } on AuthApiException catch (error) {
      _showSnack(error.message);
    } on Object {
      _showSnack("Server bilan bog'lanib bo'lmadi");
    } finally {
      if (mounted) setState(() => _updating = false);
    }
  }

  Future<void> _markDelivered(OrderModel order, String code) async {
    if (_updating) return;
    setState(() => _updating = true);
    try {
      final updated = await _api.markDelivered(
        storeId: widget.storeId,
        orderId: order.id,
        code: code,
      );
      if (!mounted) return;
      setState(() {
        _orders = _orders.map((o) => o.id == updated.id ? updated : o).toList();
      });
      _showSnack("Yetkazildi deb belgilandi");
    } on AuthApiException catch (error) {
      _showSnack(error.message);
    } on Object {
      _showSnack("Server bilan bog'lanib bo'lmadi");
    } finally {
      if (mounted) setState(() => _updating = false);
    }
  }

  String _extractCodeFromQr(String raw, String orderId) {
    final value = raw.trim();
    if (RegExp(r'^\d{6}$').hasMatch(value)) return value;
    final parts = value.split('|');
    if (parts.length >= 3 &&
        parts.first == 'RELO_ORDER_DELIVERY' &&
        parts[1] == orderId &&
        RegExp(r'^\d{6}$').hasMatch(parts[2])) {
      return parts[2];
    }
    return '';
  }

  Future<void> _scanDeliveryQr(OrderModel order) async {
    final raw = await Navigator.of(context).push<String>(
      MaterialPageRoute(builder: (_) => const _QrCodeScannerScreen()),
    );
    if (!mounted || raw == null) return;
    final code = _extractCodeFromQr(raw, order.id);
    if (code.isEmpty) {
      _showSnack("QR noto'g'ri yoki bu buyurtmaga tegishli emas");
      return;
    }
    setState(() => _deliveryCodes[order.id] = code);
    _codeCtrl(order.id).text = code;
    await _markDelivered(order, code);
  }

  void _showSnack(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), duration: const Duration(seconds: 2)),
    );
  }

  Widget _header(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
      child: Row(
        children: [
          InkWell(
            borderRadius: BorderRadius.circular(12),
            onTap: () => Navigator.of(context).maybePop(),
            child: const Padding(
              padding: EdgeInsets.all(6),
              child: Icon(
                Icons.arrow_back_ios_new_rounded,
                color: primaryGreen,
                size: 28,
              ),
            ),
          ),
          const Expanded(
            child: Text(
              'Buyurtmalar',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: primaryGreen,
                fontSize: 22,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
          const SizedBox(width: 40),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return SafeArea(
        child: Column(
          children: [
            _header(context),
            const Expanded(
              child: Center(
                child: CircularProgressIndicator(color: primaryGreen),
              ),
            ),
          ],
        ),
      );
    }

    if (_error != null) {
      return SafeArea(
        child: Column(
          children: [
            _header(context),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                child: _StateCard(message: _error!, onRetry: _load),
              ),
            ),
          ],
        ),
      );
    }

    if (_orders.isEmpty) {
      return SafeArea(
        child: Column(
          children: [
            _header(context),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                child: _StateCard(
                  message: "Hozircha buyurtmalar yo'q",
                  onRetry: _load,
                ),
              ),
            ),
          ],
        ),
      );
    }

    return SafeArea(
      child: Column(
        children: [
          _header(context),
          Expanded(
            child: RefreshIndicator(
              color: primaryGreen,
              onRefresh: _load,
              child: ListView.separated(
                padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
                itemCount: _orders.length,
                separatorBuilder: (_, i) => const SizedBox(height: 12),
                itemBuilder: (context, index) {
                  final o = _orders[index];
                  final statusColor = _statusColor(o.status);
                  final statusLabel = _statusLabel(o.status);
                  final receiver = o.receiver;
                  final delivery = o.delivery;

                  final status = o.status.trim().toLowerCase();
                  final canAcceptOrReject = status == 'pending';
                  final canMarkDelivered =
                      status == 'delivering' || status == 'shipped';

                  return Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: primaryGreen.withValues(alpha: 0.12),
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.06),
                          blurRadius: 14,
                          offset: const Offset(0, 7),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color: statusColor.withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(
                                  color: statusColor.withValues(alpha: 0.4),
                                ),
                              ),
                              child: Text(
                                statusLabel,
                                style: TextStyle(
                                  color: statusColor,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                            const Spacer(),
                            Text(
                              'Jami: ${_formatMoney(o.total)} so‘m',
                              style: const TextStyle(
                                color: primaryGreen,
                                fontSize: 12.5,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF7FAF9),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: primaryGreen.withValues(alpha: 0.1),
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                receiver?.fullName.trim().isNotEmpty == true
                                    ? receiver!.fullName
                                    : "Qabul qiluvchi ko'rsatilmagan",
                                style: const TextStyle(
                                  color: primaryGreen,
                                  fontSize: 13,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                              if (receiver?.phone.trim().isNotEmpty ==
                                  true) ...[
                                const SizedBox(height: 4),
                                Text(
                                  receiver!.phone,
                                  style: const TextStyle(
                                    color: Color(0xFF3D4B48),
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                              if (delivery?.addressText.trim().isNotEmpty ==
                                  true) ...[
                                const SizedBox(height: 6),
                                Text(
                                  delivery!.addressText,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    color: Color(0xFF3D4B48),
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                              const SizedBox(height: 6),
                              Text(
                                'Sana: ${_dateLabel(o.createdAt)}',
                                style: const TextStyle(
                                  color: Color(0xFF6F7F7B),
                                  fontSize: 11.5,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 10),
                        ...o.items.take(2).map((it) {
                          return Container(
                            margin: const EdgeInsets.only(bottom: 8),
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF8FAF9),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: primaryGreen.withValues(alpha: 0.09),
                              ),
                            ),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(10),
                                  child: SizedBox(
                                    width: 48,
                                    height: 48,
                                    child: ProductImage(
                                      path: it.productImage,
                                      height: 48,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        it.productName,
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                        style: const TextStyle(
                                          color: primaryGreen,
                                          fontSize: 12.5,
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                      const SizedBox(height: 3),
                                      Text(
                                        'Soni: ${it.qty}',
                                        style: const TextStyle(
                                          color: Color(0xFF3D4B48),
                                          fontSize: 11.5,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Text(
                                  '${_formatMoney(it.lineTotal)} so‘m',
                                  style: const TextStyle(
                                    color: primaryGreen,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                              ],
                            ),
                          );
                        }),
                        if (o.items.length > 2)
                          Text(
                            'Yana ${o.items.length - 2} ta mahsulot bor',
                            style: const TextStyle(
                              color: Color(0xFF8A9A97),
                              fontSize: 11.5,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        if (canAcceptOrReject) ...[
                          const SizedBox(height: 6),
                          Row(
                            children: [
                              Expanded(
                                child: OutlinedButton.icon(
                                  onPressed: _updating
                                      ? null
                                      : () => _reject(o),
                                  icon: const Icon(
                                    Icons.close_rounded,
                                    size: 18,
                                  ),
                                  label: const Text('Rad etish'),
                                  style: OutlinedButton.styleFrom(
                                    foregroundColor: const Color(0xFFE15C5C),
                                    minimumSize: const Size.fromHeight(38),
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 9,
                                    ),
                                    tapTargetSize:
                                        MaterialTapTargetSize.shrinkWrap,
                                    textStyle: const TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w700,
                                    ),
                                    side: BorderSide(
                                      color: const Color(
                                        0xFFE15C5C,
                                      ).withValues(alpha: 0.35),
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: OutlinedButton.icon(
                                  onPressed: _updating
                                      ? null
                                      : () => _accept(o),
                                  icon: const Icon(
                                    Icons.check_rounded,
                                    size: 18,
                                  ),
                                  label: const Text('Qabul qilish'),
                                  style: OutlinedButton.styleFrom(
                                    foregroundColor: primaryGreen,
                                    minimumSize: const Size.fromHeight(38),
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 9,
                                    ),
                                    tapTargetSize:
                                        MaterialTapTargetSize.shrinkWrap,
                                    textStyle: const TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w700,
                                    ),
                                    side: BorderSide(
                                      color: primaryGreen.withValues(
                                        alpha: 0.25,
                                      ),
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                        if (canMarkDelivered) ...[
                          const SizedBox(height: 6),
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF7FAF9),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: primaryGreen.withValues(alpha: 0.1),
                              ),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Buyurtmani tasdiqlash',
                                  style: TextStyle(
                                    color: primaryGreen,
                                    fontSize: 12.5,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Builder(
                                  builder: (_) {
                                    final ctrl = _codeCtrl(o.id);
                                    final code = ctrl.text.trim();
                                    final canConfirm =
                                        !_updating && _isSixDigits(code);
                                    return TextField(
                                      controller: ctrl,
                                      keyboardType: TextInputType.number,
                                      maxLength: 6,
                                      onChanged: (v) {
                                        _deliveryCodes[o.id] = v.trim();
                                        setState(() {});
                                      },
                                      decoration: InputDecoration(
                                        counterText: '',
                                        hintText: "User bergan 6 xonali kod",
                                        isDense: true,
                                        filled: true,
                                        fillColor: Colors.white,
                                        contentPadding:
                                            const EdgeInsets.symmetric(
                                              horizontal: 12,
                                              vertical: 12,
                                            ),
                                        border: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(
                                            10,
                                          ),
                                        ),
                                        enabledBorder: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(
                                            10,
                                          ),
                                          borderSide: BorderSide(
                                            color: primaryGreen.withValues(
                                              alpha: 0.15,
                                            ),
                                          ),
                                        ),
                                        suffixIcon: IconButton(
                                          tooltip: 'Tasdiqlash',
                                          onPressed: canConfirm
                                              ? () => _markDelivered(o, code)
                                              : null,
                                          icon: const Icon(
                                            Icons.check_circle_rounded,
                                          ),
                                        ),
                                      ),
                                    );
                                  },
                                ),
                                const SizedBox(height: 8),
                                Align(
                                  alignment: Alignment.centerLeft,
                                  child: OutlinedButton.icon(
                                    onPressed: _updating
                                        ? null
                                        : () => _scanDeliveryQr(o),
                                    icon: const Icon(Icons.qr_code_scanner),
                                    label: const Text('QR kodni skanerlash'),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ],
                    ),
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _QrCodeScannerScreen extends StatefulWidget {
  const _QrCodeScannerScreen();

  @override
  State<_QrCodeScannerScreen> createState() => _QrCodeScannerScreenState();
}

class _QrCodeScannerScreenState extends State<_QrCodeScannerScreen> {
  bool _handled = false;

  @override
  Widget build(BuildContext context) {
    const primaryGreen = Color(0xFF1F5A50);
    return Scaffold(
      appBar: AppBar(
        title: const Text('QR skaner'),
        backgroundColor: Colors.white,
        foregroundColor: primaryGreen,
      ),
      body: Stack(
        children: [
          MobileScanner(
            onDetect: (capture) {
              if (_handled) return;
              final code = capture.barcodes.isNotEmpty
                  ? (capture.barcodes.first.rawValue ?? '')
                  : '';
              if (code.trim().isEmpty) return;
              _handled = true;
              Navigator.of(context).pop(code.trim());
            },
          ),
          Align(
            alignment: Alignment.bottomCenter,
            child: Container(
              margin: const EdgeInsets.all(16),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.55),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Text(
                "QR ni kamera oldiga olib boring",
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _StateCard extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _StateCard({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    const primaryGreen = Color(0xFF1F5A50);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(18, 18, 18, 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: primaryGreen.withValues(alpha: 0.16)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: const Color(0xFFEAF4F1),
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Icon(
              Icons.receipt_long_rounded,
              size: 34,
              color: primaryGreen,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            message,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: primaryGreen,
              fontSize: 18,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            "Yangi buyurtmalar tushganda shu yerda ko'rinadi",
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Color(0xFF6F7F7B),
              fontSize: 12.5,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 14),
          OutlinedButton.icon(
            onPressed: onRetry,
            icon: const Icon(Icons.refresh_rounded),
            label: const Text('Yangilash'),
            style: OutlinedButton.styleFrom(
              foregroundColor: primaryGreen,
              side: BorderSide(color: primaryGreen.withValues(alpha: 0.25)),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
