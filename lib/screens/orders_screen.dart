import 'package:flutter/material.dart';
import 'package:hello_flutter_app/models/order.dart';
import 'package:hello_flutter_app/screens/order_detail_screen.dart';
import 'package:hello_flutter_app/screens/public_store_detail_screen.dart';
import 'package:hello_flutter_app/services/auth_api_service.dart';
import 'package:hello_flutter_app/services/order_api_service.dart';
import 'package:hello_flutter_app/services/product_api_service.dart';
import 'package:hello_flutter_app/widgets/product_image.dart';

class OrdersScreen extends StatefulWidget {
  const OrdersScreen({super.key});

  @override
  State<OrdersScreen> createState() => _OrdersScreenState();
}

class _OrdersScreenState extends State<OrdersScreen> {
  static const primaryGreen = Color(0xFF1F5A50);
  final OrderApiService _orderApi = OrderApiService();
  final ProductApiService _productApi = ProductApiService();

  bool _loading = true;
  String? _error;
  List<OrderModel> _orders = const [];
  final Map<String, String> _storeNames = {};

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final orders = await _orderApi.getMyOrders();
      if (!mounted) return;
      setState(() {
        _orders = orders;
        _loading = false;
      });
      _loadStoreNames(orders);
    } on AuthApiException catch (error) {
      if (!mounted) return;
      setState(() {
        _error = error.message;
        _loading = false;
      });
    } on Object {
      if (!mounted) return;
      setState(() {
        _error = "Buyurtmalarni yuklab bo‘lmadi";
        _loading = false;
      });
    }
  }

  Future<void> _loadStoreNames(List<OrderModel> orders) async {
    final storeIds = orders
        .map((e) => e.storeId)
        .where((e) => e.trim().isNotEmpty)
        .map((e) => e.trim())
        .toSet()
        .toList();
    final missing = storeIds
        .where((id) => !_storeNames.containsKey(id))
        .toList();
    if (missing.isEmpty) return;

    for (final storeId in missing) {
      try {
        final resp = await _productApi.getStoreProducts(storeId);
        if (!mounted) return;
        final name = resp.store.name.trim();
        if (name.isEmpty) continue;
        setState(() => _storeNames[storeId] = name);
      } on Object {
        // Ignore store resolving errors; we'll show storeId instead.
      }
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

  String _statusLabel(String status) {
    switch (status.trim().toLowerCase()) {
      case 'pending':
        return 'Kutilmoqda';
      case 'accepted':
      case 'confirmed':
        return 'Qabul qilindi';
      case 'delivering':
      case 'shipped':
        return 'Yetkazilmoqda';
      case 'completed':
      case 'delivered':
        return 'Yakunlandi';
      case 'rejected':
        return 'Rad etildi';
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
      case 'accepted':
      case 'confirmed':
        return const Color(0xFF2E86DE);
      case 'completed':
      case 'delivered':
        return const Color(0xFF1FA971);
      case 'rejected':
      case 'canceled':
        return const Color(0xFFE15C5C);
      case 'pending':
      default:
        return primaryGreen;
    }
  }

  String _dateLabel(DateTime? dt) {
    if (dt == null) return '';
    final local = dt.toLocal();
    final dd = local.day.toString().padLeft(2, '0');
    final mm = local.month.toString().padLeft(2, '0');
    final yy = local.year.toString();
    return '$dd.$mm.$yy';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mening buyurtmalarim'),
        backgroundColor: Colors.white,
        foregroundColor: primaryGreen,
        elevation: 0,
        actions: [
          IconButton(
            tooltip: 'Yangilash',
            onPressed: _loading ? null : _load,
            icon: const Icon(Icons.refresh_rounded),
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: primaryGreen))
          : _error != null
          ? Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              child: Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(
                    color: primaryGreen.withValues(alpha: 0.18),
                  ),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.receipt_long_rounded,
                      size: 52,
                      color: primaryGreen,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      _error!,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: primaryGreen,
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextButton.icon(
                      onPressed: _load,
                      icon: const Icon(Icons.refresh_rounded),
                      label: const Text('Qayta urinish'),
                      style: TextButton.styleFrom(
                        foregroundColor: primaryGreen,
                      ),
                    ),
                  ],
                ),
              ),
            )
          : _orders.isEmpty
          ? const Center(
              child: Text(
                'Hozircha buyurtma yo‘q',
                style: TextStyle(
                  color: Color(0xFF8A9A97),
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            )
          : RefreshIndicator(
              color: primaryGreen,
              onRefresh: _load,
              child: ListView.separated(
                padding: const EdgeInsets.all(16),
                itemCount: _orders.length,
                separatorBuilder: (_, separatorIndex) =>
                    const SizedBox(height: 12),
                itemBuilder: (context, i) {
                  final o = _orders[i];
                  final statusColor = _statusColor(o.status);
                  final statusLabel = _statusLabel(o.status);
                  final storeLabel = _storeNames[o.storeId] ?? o.storeId;
                  final firstItem = o.items.isNotEmpty ? o.items.first : null;
                  final acceptedDate = _dateLabel(o.createdAt);
                  return InkWell(
                    borderRadius: BorderRadius.circular(14),
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => OrderDetailScreen(orderId: o.id),
                        ),
                      );
                    },
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: primaryGreen.withValues(alpha: 0.12),
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.06),
                            blurRadius: 12,
                            offset: const Offset(0, 6),
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
                                  color: statusColor.withValues(alpha: 0.14),
                                  borderRadius: BorderRadius.circular(999),
                                  border: Border.all(
                                    color: statusColor.withValues(alpha: 0.4),
                                  ),
                                ),
                                child: Text(
                                  statusLabel,
                                  style: TextStyle(
                                    color: statusColor,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                              const Spacer(),
                              Text(
                                'Jami: ${_formatMoney(o.total)} so‘m',
                                style: const TextStyle(
                                  color: primaryGreen,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              ClipRRect(
                                borderRadius: BorderRadius.circular(10),
                                child: SizedBox(
                                  width: 62,
                                  height: 62,
                                  child: ProductImage(
                                    path: firstItem?.productImage ?? '',
                                    height: 62,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Mahsulot nomi: ${firstItem?.productName.isNotEmpty == true ? firstItem!.productName : '-'}',
                                      softWrap: true,
                                      style: const TextStyle(
                                        color: primaryGreen,
                                        fontSize: 12.5,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                    const SizedBox(height: 5),
                                    Text(
                                      'Soni: ${firstItem?.qty ?? 0}',
                                      style: const TextStyle(
                                        color: Color(0xFF3D4B48),
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    const SizedBox(height: 5),
                                    Text(
                                      'Narxi: ${_formatMoney(firstItem?.lineTotal ?? 0)} so‘m',
                                      style: const TextStyle(
                                        color: Color(0xFF3D4B48),
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    if (acceptedDate.isNotEmpty) ...[
                                      const SizedBox(height: 5),
                                      Text(
                                        'Buyurtma qabul qilingan sana: $acceptedDate',
                                        style: const TextStyle(
                                          color: Color(0xFF6F7F7B),
                                          fontSize: 11.5,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          if (storeLabel.trim().isNotEmpty)
                            Wrap(
                              crossAxisAlignment: WrapCrossAlignment.center,
                              spacing: 6,
                              children: [
                                const Text(
                                  "Do'kon:",
                                  style: TextStyle(
                                    color: Color(0xFF6F7F7B),
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                GestureDetector(
                                  onTap: () {
                                    Navigator.of(context).push(
                                      MaterialPageRoute(
                                        builder: (_) => PublicStoreDetailScreen(
                                          storeId: o.storeId,
                                        ),
                                      ),
                                    );
                                  },
                                  child: Text(
                                    storeLabel,
                                    style: const TextStyle(
                                      color: Color(0xFF2E86DE),
                                      fontSize: 12,
                                      fontWeight: FontWeight.w700,
                                      decoration: TextDecoration.underline,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          if (o.items.length > 1) ...[
                            const SizedBox(height: 8),
                            Text(
                              'Yana ${o.items.length - 1} ta mahsulot bor. Barchasini ko‘rish uchun card ustiga bosing.',
                              style: const TextStyle(
                                color: Color(0xFF8A9A97),
                                fontSize: 11.5,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
    );
  }
}
