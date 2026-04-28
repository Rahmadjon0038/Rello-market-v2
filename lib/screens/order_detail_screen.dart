import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hello_flutter_app/models/order.dart';
import 'package:hello_flutter_app/models/product.dart';
import 'package:hello_flutter_app/services/auth_api_service.dart';
import 'package:hello_flutter_app/services/order_api_service.dart';
import 'package:hello_flutter_app/services/product_api_service.dart';
import 'package:hello_flutter_app/widgets/product_image.dart';
import 'package:qr_flutter/qr_flutter.dart';

class OrderDetailScreen extends StatefulWidget {
  final String orderId;

  const OrderDetailScreen({super.key, required this.orderId});

  @override
  State<OrderDetailScreen> createState() => _OrderDetailScreenState();
}

class _OrderDetailScreenState extends State<OrderDetailScreen> {
  static const primaryGreen = Color(0xFF1F5A50);
  final OrderApiService _orderApi = OrderApiService();
  final ProductApiService _productApi = ProductApiService();

  bool _loading = true;
  String? _error;
  OrderModel? _order;
  final Map<String, List<String>> _productImagesById = {};
  OrderDeliveryConfirmModel? _deliveryConfirm;

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
      final order = await _orderApi.getOrder(widget.orderId);
      if (!mounted) return;
      setState(() {
        _order = order;
        _loading = false;
      });
      _loadProductImages(order);
      _loadDeliveryConfirm(order);
    } on AuthApiException catch (error) {
      if (!mounted) return;
      setState(() {
        _error = error.message;
        _loading = false;
      });
    } on Object {
      if (!mounted) return;
      setState(() {
        _error = 'Buyurtma ma’lumotlarini yuklab bo‘lmadi';
        _loading = false;
      });
    }
  }

  Future<void> _loadDeliveryConfirm(OrderModel order) async {
    final status = order.status.trim().toLowerCase();
    if (status != 'delivering' && status != 'shipped') {
      if (!mounted) return;
      setState(() => _deliveryConfirm = null);
      return;
    }
    try {
      final confirm = await _orderApi.getOrderDeliveryConfirm(order.id);
      if (!mounted) return;
      setState(() => _deliveryConfirm = confirm);
    } on Object {
      if (!mounted) return;
      setState(() => _deliveryConfirm = null);
    }
  }

  Future<void> _loadProductImages(OrderModel order) async {
    final uniqueProductIds = order.items
        .map((e) => e.productId.trim())
        .where((e) => e.isNotEmpty)
        .toSet();
    for (final productId in uniqueProductIds) {
      if (_productImagesById.containsKey(productId)) continue;
      try {
        final product = await _productApi.getProduct(productId);
        if (!mounted) return;
        final images = product.resolvedImages
            .map((e) => e.trim())
            .where((e) => e.isNotEmpty)
            .toList();
        if (images.isEmpty && product.resolvedImagePath.trim().isNotEmpty) {
          images.add(product.resolvedImagePath.trim());
        }
        setState(() {
          _productImagesById[productId] = images;
        });
      } on Object {
        if (!mounted) return;
        setState(() {
          _productImagesById[productId] = const [];
        });
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
        return const Color(0xFF4F8CC9);
      case 'completed':
      case 'delivered':
        return const Color(0xFF2DB783);
      case 'rejected':
        return const Color(0xFFE15C5C);
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
    final hh = local.hour.toString().padLeft(2, '0');
    final min = local.minute.toString().padLeft(2, '0');
    return '$dd.$mm.$yy  $hh:$min';
  }

  String _paymentLabel(String raw) {
    switch (raw.trim().toLowerCase()) {
      case 'cod':
        return "Naqd (qo'lda to'lov)";
      case 'payme':
        return 'Payme';
      case 'click':
        return 'Click';
      default:
        return raw.trim().isEmpty ? "Noma'lum" : raw;
    }
  }

  List<String> _itemImages(OrderItemModel item) {
    final fromProduct = _productImagesById[item.productId] ?? const [];
    if (fromProduct.isNotEmpty) return fromProduct;
    final fallback = item.productImage.trim();
    if (fallback.isEmpty) return const [];
    return [Product.resolveImagePath(fallback)];
  }

  Widget _section({required String title, required Widget child}) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: primaryGreen.withValues(alpha: 0.12)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              color: primaryGreen,
              fontSize: 13,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 10),
          child,
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final order = _order;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Buyurtma'),
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
          : order == null
          ? const Center(
              child: Text(
                'Buyurtma topilmadi',
                style: TextStyle(
                  color: Color(0xFF8A9A97),
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            )
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                _section(
                  title: 'Buyurtma ma’lumotlari',
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: _statusColor(
                                order.status,
                              ).withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                color: _statusColor(
                                  order.status,
                                ).withValues(alpha: 0.4),
                              ),
                            ),
                            child: Text(
                              _statusLabel(order.status),
                              style: TextStyle(
                                color: _statusColor(order.status),
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                if (_dateLabel(order.createdAt).isNotEmpty)
                                  Text(
                                    'Buyurtma qabul qilingan sana: ${_dateLabel(order.createdAt)}',
                                    style: const TextStyle(
                                      color: Color(0xFF8A9A97),
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          const Text(
                            'To‘lov: ',
                            style: TextStyle(
                              color: Color(0xFF8A9A97),
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          Expanded(
                            child: Text(
                              _paymentLabel(order.paymentMethod),
                              softWrap: true,
                              style: const TextStyle(
                                color: primaryGreen,
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          const Text(
                            'Jami: ',
                            style: TextStyle(
                              color: Color(0xFF8A9A97),
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          Expanded(
                            child: Text(
                              '${_formatMoney(order.total)} so‘m',
                              softWrap: true,
                              style: const TextStyle(
                                color: primaryGreen,
                                fontSize: 12,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                        ],
                      ),
                      if (_deliveryConfirm != null) ...[
                        const SizedBox(height: 12),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF8FAF9),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: primaryGreen.withValues(alpha: 0.12),
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Qabul qilish kodi (OTP)',
                                style: TextStyle(
                                  color: Color(0xFF6F7F7B),
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              const SizedBox(height: 6),
                              Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      _deliveryConfirm!.code,
                                      style: const TextStyle(
                                        color: primaryGreen,
                                        fontSize: 26,
                                        letterSpacing: 3,
                                        fontWeight: FontWeight.w900,
                                      ),
                                    ),
                                  ),
                                  IconButton(
                                    tooltip: 'Nusxalash',
                                    onPressed: () async {
                                      final messenger = ScaffoldMessenger.of(
                                        context,
                                      );
                                      await Clipboard.setData(
                                        ClipboardData(
                                          text: _deliveryConfirm!.code,
                                        ),
                                      );
                                      if (!mounted) return;
                                      messenger.showSnackBar(
                                        const SnackBar(
                                          content: Text('Kod nusxalandi'),
                                        ),
                                      );
                                    },
                                    icon: const Icon(Icons.copy_rounded),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Center(
                                child: QrImageView(
                                  data: _deliveryConfirm!.qrPayload,
                                  size: 150,
                                  backgroundColor: Colors.white,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                if (order.receiver != null)
                  _section(
                    title: 'Qabul qiluvchi',
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          order.receiver!.fullName,
                          style: const TextStyle(
                            color: primaryGreen,
                            fontSize: 13,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          order.receiver!.phone,
                          style: const TextStyle(
                            color: Color(0xFF3D4B48),
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                if (order.receiver != null) const SizedBox(height: 12),
                if (order.delivery != null)
                  _section(
                    title: 'Yetkazib berish',
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          order.delivery!.addressText,
                          softWrap: true,
                          style: const TextStyle(
                            color: primaryGreen,
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 6),
                        if (order.delivery!.lat != null &&
                            order.delivery!.lng != null)
                          Text(
                            '(${order.delivery!.lat}, ${order.delivery!.lng})',
                            style: const TextStyle(
                              color: Color(0xFF8A9A97),
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                      ],
                    ),
                  ),
                if (order.delivery != null) const SizedBox(height: 12),
                _section(
                  title: 'Mahsulotlar',
                  child: Column(
                    children: order.items.map((it) {
                      final images = _itemImages(it);
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF8FAF9),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: primaryGreen.withValues(alpha: 0.1),
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          'Mahsulot nomi: ${it.productName}',
                                          softWrap: true,
                                          style: const TextStyle(
                                            color: primaryGreen,
                                            fontSize: 13,
                                            fontWeight: FontWeight.w800,
                                          ),
                                        ),
                                        const SizedBox(height: 6),
                                        Text(
                                          'Soni: ${it.qty}',
                                          style: const TextStyle(
                                            color: Color(0xFF3D4B48),
                                            fontSize: 12,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.end,
                                    children: [
                                      const Text(
                                        'Jami',
                                        style: TextStyle(
                                          color: Color(0xFF7F8D89),
                                          fontSize: 11.5,
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        '${_formatMoney(it.lineTotal)} so‘m',
                                        style: const TextStyle(
                                          color: primaryGreen,
                                          fontSize: 13,
                                          fontWeight: FontWeight.w800,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                              const SizedBox(height: 10),
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(10),
                                    child: SizedBox(
                                      width: 56,
                                      height: 56,
                                      child: ProductImage(
                                        path: it.productImage,
                                        height: 56,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  const Expanded(
                                    child: Text(
                                      'Asosiy rasm',
                                      style: TextStyle(
                                        color: Color(0xFF7F8D89),
                                        fontSize: 11.5,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 10),
                              if (images.isNotEmpty)
                                SizedBox(
                                  height: 66,
                                  child: ListView.separated(
                                    scrollDirection: Axis.horizontal,
                                    itemCount: images.length,
                                    separatorBuilder: (_, separatorIndex) =>
                                        const SizedBox(width: 8),
                                    itemBuilder: (context, imageIndex) {
                                      final imagePath = images[imageIndex];
                                      return ClipRRect(
                                        borderRadius: BorderRadius.circular(10),
                                        child: SizedBox(
                                          width: 66,
                                          height: 66,
                                          child: ProductImage(
                                            path: imagePath,
                                            height: 66,
                                          ),
                                        ),
                                      );
                                    },
                                  ),
                                ),
                            ],
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ],
            ),
    );
  }
}
