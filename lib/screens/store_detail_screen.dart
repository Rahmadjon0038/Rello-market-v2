import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hello_flutter_app/config/api_config.dart';
import 'package:hello_flutter_app/models/store.dart';
import 'package:hello_flutter_app/models/store_details.dart';
import 'package:hello_flutter_app/screens/orders_screen.dart';
import 'package:hello_flutter_app/screens/store_statistics_screen.dart';
import 'package:hello_flutter_app/screens/store_products_screen.dart';
import 'package:hello_flutter_app/services/auth_api_service.dart';
import 'package:hello_flutter_app/services/store_api_service.dart';

class StoreDetailScreen extends StatefulWidget {
  final String storeId;
  final StoreModel? initialStore;

  const StoreDetailScreen({
    super.key,
    required this.storeId,
    this.initialStore,
  });

  @override
  State<StoreDetailScreen> createState() => _StoreDetailScreenState();
}

class _StoreDetailScreenState extends State<StoreDetailScreen> {
  final StoreApiService _storeApi = StoreApiService();
  StoreDetails? _store;
  bool _isLoading = true;
  String? _error;
  int _navIndex = 0;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final store = await _storeApi.getMyStore(widget.storeId);
      if (!mounted) return;
      setState(() {
        _store = store;
        _isLoading = false;
      });
    } on AuthApiException catch (error) {
      if (!mounted) return;
      setState(() {
        _error = error.message;
        _isLoading = false;
      });
    } on Object {
      if (!mounted) return;
      setState(() {
        _error = "Server bilan bog'lanib bo'lmadi";
        _isLoading = false;
      });
    }
  }

  String _pad2(int v) => v.toString().padLeft(2, '0');

  DateTime? _tryParseDateTime(String raw) {
    if (raw.trim().isEmpty) return null;
    try {
      return DateTime.parse(raw);
    } on Object {
      return null;
    }
  }

  String _formatDateTime(String raw) {
    final parsed = _tryParseDateTime(raw);
    if (parsed == null) return raw.isEmpty ? '-' : raw;
    final local = parsed.toLocal();
    return '${local.year}-${_pad2(local.month)}-${_pad2(local.day)} '
        '${_pad2(local.hour)}:${_pad2(local.minute)}';
  }

  String _formatMoney(num? value) {
    if (value == null) return '-';
    final s = value.toStringAsFixed(0);
    final digits = s.replaceAll(RegExp(r'\D'), '');
    final buf = StringBuffer();
    for (var i = 0; i < digits.length; i++) {
      final remaining = digits.length - i;
      buf.write(digits[i]);
      if (remaining > 1 && remaining % 3 == 1) buf.write(' ');
    }
    return buf.toString();
  }

  String? _absoluteUrl(String pathOrUrl) {
    final value = pathOrUrl.trim();
    if (value.isEmpty) return null;
    if (value.startsWith('http://') || value.startsWith('https://'))
      return value;
    final base = ApiConfig.baseUrl.replaceAll(RegExp(r'/+$'), '');
    final path = value.startsWith('/') ? value : '/$value';
    return '$base$path';
  }

  Future<void> _copy(String label, String value) async {
    final v = value.trim();
    if (v.isEmpty) return;
    await Clipboard.setData(ClipboardData(text: v));
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$label nusxalandi'),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _showLink(String title, String? link) {
    final value = (link ?? '').trim();
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        title,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.of(context).pop(),
                      icon: const Icon(Icons.close_rounded),
                      tooltip: 'Yopish',
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                SelectableText(value.isEmpty ? '-' : value),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: value.isEmpty
                        ? null
                        : () {
                            _copy(title, value);
                            Navigator.of(context).pop();
                          },
                    icon: const Icon(Icons.copy_rounded),
                    label: const Text('Nusxalash'),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showImage(String url) {
    final value = url.trim();
    if (value.isEmpty) return;
    showDialog<void>(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.85),
      builder: (context) {
        return GestureDetector(
          onTap: () => Navigator.of(context).pop(),
          child: Center(
            child: InteractiveViewer(
              minScale: 0.8,
              maxScale: 4,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: Image.network(value, fit: BoxFit.contain),
              ),
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    const primaryGreen = Color(0xFF1F5A50);
    const ink = Color(0xFF1F2933);
    const bg = Color(0xFFF7F8FA);

    return Scaffold(
      backgroundColor: bg,
      bottomNavigationBar: NavigationBar(
        selectedIndex: _navIndex,
        onDestinationSelected: (index) async {
          if (index == 0) {
            Navigator.of(context).popUntil((route) => route.isFirst);
            return;
          }

          setState(() => _navIndex = index);

          if (index == 1) {
            await Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => StoreProductsScreen(storeId: widget.storeId),
              ),
            );
            if (mounted) setState(() => _navIndex = 0);
            return;
          }

          if (index == 2) {
            await Navigator.of(
              context,
            ).push(MaterialPageRoute(builder: (_) => const OrdersScreen()));
            if (mounted) setState(() => _navIndex = 0);
            return;
          }

          if (index == 3) {
            await Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) =>
                    StoreStatisticsScreen(storeName: _store?.name ?? ''),
              ),
            );
            if (mounted) setState(() => _navIndex = 0);
            return;
          }
        },
        indicatorColor: const Color(0xFFE6F4EF),
        backgroundColor: Colors.white,
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined, color: ink),
            selectedIcon: Icon(Icons.home_rounded, color: primaryGreen),
            label: 'Bosh sahifa',
          ),
          NavigationDestination(
            icon: Icon(Icons.inventory_2_outlined, color: ink),
            selectedIcon: Icon(Icons.inventory_2_rounded, color: primaryGreen),
            label: 'Mahsulotlar',
          ),
          NavigationDestination(
            icon: Icon(Icons.receipt_long_outlined, color: ink),
            selectedIcon: Icon(Icons.receipt_long_rounded, color: primaryGreen),
            label: 'Buyurtmalar',
          ),
          NavigationDestination(
            icon: Icon(Icons.query_stats_outlined, color: ink),
            selectedIcon: Icon(Icons.query_stats_rounded, color: primaryGreen),
            label: 'Statistika',
          ),
        ],
      ),
      body: SafeArea(
        child: _isLoading
            ? const Center(
                child: CircularProgressIndicator(color: primaryGreen),
              )
            : _error != null
            ? _StateCard(message: _error!, onRetry: _load)
            : _store == null
            ? _StateCard(message: "Do'kon topilmadi", onRetry: _load)
            : CustomScrollView(
                slivers: [
                  SliverAppBar(
                    pinned: true,
                    elevation: 0,
                    backgroundColor: Colors.transparent,
                    foregroundColor: primaryGreen,
                    systemOverlayStyle: SystemUiOverlayStyle.light,
                    surfaceTintColor: Colors.transparent,
                    scrolledUnderElevation: 0,
                    title: const SizedBox.shrink(),
                    leading: _AppBarCircleButton(
                      icon: Icons.arrow_back_rounded,
                      onTap: () => Navigator.of(context).pop(),
                    ),
                    actions: [
                      Padding(
                        padding: const EdgeInsets.only(right: 10),
                        child: _AppBarCircleButton(
                          icon: Icons.refresh_rounded,
                          onTap: _load,
                        ),
                      ),
                    ],
                    expandedHeight: 240,
                    flexibleSpace: FlexibleSpaceBar(
                      background: _HeaderHero(
                        title: _store!.name,
                        subtitle: (_store!.description ?? '').trim(),
                        imageUrl: _absoluteUrl(_store!.imagePath ?? ''),
                        storeType: (_store!.storeType ?? '').trim(),
                        isActive: _store!.isActive,
                      ),
                    ),
                  ),
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(16, 14, 16, 24),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _ContactCard(
                            address: (_store!.address ?? '').trim(),
                            phone: (_store!.director?.phone ?? '').trim(),
                            mapLink: (_store!.mapLocation ?? '').trim(),
                            onCopyAddress: () =>
                                _copy('Manzil', (_store!.address ?? '').trim()),
                            onCopyPhone: () => _copy(
                              'Telefon',
                              (_store!.director?.phone ?? '').trim(),
                            ),
                            onShowMap: () => _showLink(
                              'Google Map link',
                              _store!.mapLocation,
                            ),
                          ),
                          const SizedBox(height: 12),
                          _SectionCard(
                            title: "Asosiy ma'lumotlar",
                            child: Column(
                              children: [
                                _KeyValue(
                                  label: 'Holati',
                                  value: _store!.isActive ? 'Faol' : 'Nofaol',
                                ),
                                _KeyValue(
                                  label: "Do'kon turi",
                                  value: (_store!.storeType ?? '-').trim(),
                                ),
                                _KeyValue(
                                  label: "Faoliyat yo'nalishi",
                                  value: (_store!.activityType ?? '-').trim(),
                                ),
                                _KeyValue(
                                  label: "Ish vaqti",
                                  value: (_store!.workingHours ?? '-').trim(),
                                ),
                                _KeyValue(
                                  label: "Yaratilgan",
                                  value: _formatDateTime(
                                    _store!.createdAt ?? '',
                                  ),
                                ),
                                _KeyValue(
                                  label: "Yangilangan",
                                  value: _formatDateTime(
                                    _store!.updatedAt ?? '',
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 12),
                          _ExpandableCard(
                            title: "Yetkazib berish",
                            subtitle: _store!.hasDelivery
                                ? 'Mavjud'
                                : "Mavjud emas",
                            child: Column(
                              children: [
                                _KeyValue(
                                  label: 'Holati',
                                  value: _store!.hasDelivery ? 'Ha' : "Yo'q",
                                ),
                                if (_store!.hasDelivery) ...[
                                  _KeyValue(
                                    label: 'Hudud',
                                    value: (_store!.deliveryArea ?? '-').trim(),
                                  ),
                                  _KeyValue(
                                    label: 'Narx',
                                    value:
                                        '${_formatMoney(_store!.deliveryPrice)} so‘m',
                                  ),
                                ],
                              ],
                            ),
                          ),
                          const SizedBox(height: 12),
                          _SectionCard(
                            title: "Rahbar",
                            child: Column(
                              children: [
                                _KeyValue(
                                  label: 'Ism',
                                  value: _store!.director == null
                                      ? '-'
                                      : '${_store!.director!.firstName} ${_store!.director!.lastName}'
                                            .trim(),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 12),
                          _SectionCard(
                            title: "Rasmlar",
                            child: _ImageStrip(
                              urls: [
                                ...[
                                  _absoluteUrl(_store!.imagePath ?? ''),
                                  ..._store!.bannerImages.map(_absoluteUrl),
                                ].whereType<String>(),
                              ],
                              onTap: _showImage,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  final String title;
  final String value;

  const _DetailRow({required this.title, required this.value});

  @override
  Widget build(BuildContext context) {
    const primaryGreen = Color(0xFF1F5A50);

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              color: primaryGreen.withValues(alpha: 0.62),
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value.trim().isEmpty ? '-' : value,
            style: const TextStyle(
              color: primaryGreen,
              fontSize: 14,
              fontWeight: FontWeight.w800,
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

    return Center(
      child: Container(
        margin: const EdgeInsets.all(16),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFFE6F4EF),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: primaryGreen,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 10),
            TextButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Qayta urinish'),
              style: TextButton.styleFrom(foregroundColor: primaryGreen),
            ),
          ],
        ),
      ),
    );
  }
}

class _ImageDetailRow extends StatelessWidget {
  final String title;
  final String? url;

  const _ImageDetailRow({required this.title, required this.url});

  @override
  Widget build(BuildContext context) {
    const primaryGreen = Color(0xFF1F5A50);
    final hasUrl = url != null && url!.trim().isNotEmpty;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              color: primaryGreen.withValues(alpha: 0.62),
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          if (!hasUrl)
            const Text(
              '-',
              style: TextStyle(
                color: primaryGreen,
                fontSize: 14,
                fontWeight: FontWeight.w800,
              ),
            )
          else
            ClipRRect(
              borderRadius: BorderRadius.circular(14),
              child: AspectRatio(
                aspectRatio: 16 / 9,
                child: Image.network(
                  url!,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) => Container(
                    color: primaryGreen.withValues(alpha: 0.06),
                    alignment: Alignment.center,
                    child: const Text(
                      "Rasm yuklanmadi",
                      style: TextStyle(
                        color: primaryGreen,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  loadingBuilder: (context, child, loadingProgress) {
                    if (loadingProgress == null) return child;
                    return Container(
                      color: primaryGreen.withValues(alpha: 0.06),
                      alignment: Alignment.center,
                      child: const SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(strokeWidth: 2),
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

class _ImagesDetailRow extends StatelessWidget {
  final String title;
  final List<String> urls;

  const _ImagesDetailRow({required this.title, required this.urls});

  @override
  Widget build(BuildContext context) {
    const primaryGreen = Color(0xFF1F5A50);

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              color: primaryGreen.withValues(alpha: 0.62),
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          if (urls.isEmpty)
            const Text(
              '-',
              style: TextStyle(
                color: primaryGreen,
                fontSize: 14,
                fontWeight: FontWeight.w800,
              ),
            )
          else
            SizedBox(
              height: 120,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: urls.length,
                separatorBuilder: (_, __) => const SizedBox(width: 10),
                itemBuilder: (context, index) {
                  final url = urls[index];
                  return ClipRRect(
                    borderRadius: BorderRadius.circular(14),
                    child: AspectRatio(
                      aspectRatio: 16 / 9,
                      child: Image.network(
                        url,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) => Container(
                          color: primaryGreen.withValues(alpha: 0.06),
                          alignment: Alignment.center,
                          child: const Text(
                            "Rasm yuklanmadi",
                            style: TextStyle(
                              color: primaryGreen,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                        loadingBuilder: (context, child, loadingProgress) {
                          if (loadingProgress == null) return child;
                          return Container(
                            color: primaryGreen.withValues(alpha: 0.06),
                            alignment: Alignment.center,
                            child: const SizedBox(
                              width: 22,
                              height: 22,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            ),
                          );
                        },
                      ),
                    ),
                  );
                },
              ),
            ),
        ],
      ),
    );
  }
}

class _HeaderHero extends StatelessWidget {
  final String title;
  final String subtitle;
  final String? imageUrl;
  final String storeType;
  final bool isActive;

  const _HeaderHero({
    required this.title,
    required this.subtitle,
    required this.imageUrl,
    required this.storeType,
    required this.isActive,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        if (imageUrl != null && imageUrl!.isNotEmpty)
          Image.network(
            imageUrl!,
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) => _heroFallback(),
          )
        else
          _heroFallback(),
        Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Colors.black.withValues(alpha: 0.28),
                Colors.black.withValues(alpha: 0.55),
              ],
            ),
          ),
        ),
        Positioned(
          left: 16,
          right: 16,
          bottom: 16,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  _HeroPill(
                    label: isActive ? 'Faol' : 'Nofaol',
                    icon: isActive
                        ? Icons.check_circle_rounded
                        : Icons.do_not_disturb_on_rounded,
                  ),
                  const SizedBox(width: 8),
                  if (storeType.trim().isNotEmpty)
                    _HeroPill(label: storeType, icon: Icons.store_rounded),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _heroFallback() {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFE6F4EF), Color(0xFFF7F8FA)],
        ),
      ),
      child: const Center(
        child: Icon(
          Icons.storefront_rounded,
          size: 72,
          color: Color(0xFF1F5A50),
        ),
      ),
    );
  }
}

class _HeroPill extends StatelessWidget {
  final String label;
  final IconData icon;

  const _HeroPill({required this.label, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.18),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: Colors.white.withValues(alpha: 0.22)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: Colors.white),
          const SizedBox(width: 6),
          Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w900,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}

class _AppBarCircleButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;

  const _AppBarCircleButton({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.only(left: 10, top: 6),
        child: Material(
          color: Colors.black.withValues(alpha: 0.28),
          shape: const CircleBorder(),
          child: InkWell(
            customBorder: const CircleBorder(),
            onTap: onTap,
            child: SizedBox(
              width: 40,
              height: 40,
              child: Icon(icon, color: Colors.white),
            ),
          ),
        ),
      ),
    );
  }
}

class _ContactCard extends StatelessWidget {
  final String address;
  final String phone;
  final String mapLink;
  final VoidCallback onCopyAddress;
  final VoidCallback onCopyPhone;
  final VoidCallback onShowMap;

  const _ContactCard({
    required this.address,
    required this.phone,
    required this.mapLink,
    required this.onCopyAddress,
    required this.onCopyPhone,
    required this.onShowMap,
  });

  @override
  Widget build(BuildContext context) {
    const primaryGreen = Color(0xFF1F5A50);

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: primaryGreen.withValues(alpha: 0.1)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 14,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          _ContactRow(
            icon: Icons.location_on_rounded,
            title: 'Manzil',
            value: address,
            action: _ContactAction(
              icon: Icons.copy_rounded,
              label: 'Nusxa',
              onTap: address.trim().isEmpty ? null : onCopyAddress,
            ),
          ),
          const SizedBox(height: 10),
          _ContactRow(
            icon: Icons.call_rounded,
            title: 'Telefon',
            value: phone,
            action: _ContactAction(
              icon: Icons.copy_rounded,
              label: 'Nusxa',
              onTap: phone.trim().isEmpty ? null : onCopyPhone,
            ),
          ),
          const SizedBox(height: 10),
          _ContactRow(
            icon: Icons.map_rounded,
            title: 'Xarita',
            value: mapLink,
            action: _ContactAction(
              icon: Icons.open_in_new_rounded,
              label: "Ko'rish",
              onTap: mapLink.trim().isEmpty ? null : onShowMap,
            ),
          ),
        ],
      ),
    );
  }
}

class _ContactRow extends StatelessWidget {
  final IconData icon;
  final String title;
  final String value;
  final _ContactAction action;

  const _ContactRow({
    required this.icon,
    required this.title,
    required this.value,
    required this.action,
  });

  @override
  Widget build(BuildContext context) {
    const primaryGreen = Color(0xFF1F5A50);
    final v = value.trim().isEmpty ? '-' : value.trim();

    return Row(
      children: [
        Container(
          width: 42,
          height: 42,
          decoration: BoxDecoration(
            color: const Color(0xFFE6F4EF),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Icon(icon, color: primaryGreen),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  color: primaryGreen.withValues(alpha: 0.65),
                  fontWeight: FontWeight.w800,
                  fontSize: 12,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                v,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: primaryGreen,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 10),
        _ContactActionButton(action: action),
      ],
    );
  }
}

class _ContactAction {
  final IconData icon;
  final String label;
  final VoidCallback? onTap;

  const _ContactAction({
    required this.icon,
    required this.label,
    required this.onTap,
  });
}

class _ContactActionButton extends StatelessWidget {
  final _ContactAction action;

  const _ContactActionButton({required this.action});

  @override
  Widget build(BuildContext context) {
    const primaryGreen = Color(0xFF1F5A50);

    return SizedBox(
      height: 40,
      child: OutlinedButton.icon(
        onPressed: action.onTap,
        icon: Icon(action.icon, size: 18),
        label: Text(action.label),
        style: OutlinedButton.styleFrom(
          foregroundColor: primaryGreen,
          side: BorderSide(color: primaryGreen.withValues(alpha: 0.25)),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 10),
          textStyle: const TextStyle(fontWeight: FontWeight.w900, fontSize: 12),
        ),
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  final String title;
  final Widget child;

  const _SectionCard({required this.title, required this.child});

  @override
  Widget build(BuildContext context) {
    const primaryGreen = Color(0xFF1F5A50);

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: primaryGreen.withValues(alpha: 0.1)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 14,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontWeight: FontWeight.w900,
              color: primaryGreen,
              fontSize: 15,
            ),
          ),
          const SizedBox(height: 10),
          child,
        ],
      ),
    );
  }
}

class _ExpandableCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final Widget child;

  const _ExpandableCard({
    required this.title,
    required this.subtitle,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    const primaryGreen = Color(0xFF1F5A50);

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: primaryGreen.withValues(alpha: 0.1)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 14,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          tilePadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
          childrenPadding: const EdgeInsets.fromLTRB(14, 0, 14, 14),
          title: Text(
            title,
            style: const TextStyle(
              fontWeight: FontWeight.w900,
              color: primaryGreen,
              fontSize: 15,
            ),
          ),
          subtitle: subtitle.trim().isEmpty
              ? null
              : Text(
                  subtitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: primaryGreen.withValues(alpha: 0.62),
                    fontWeight: FontWeight.w700,
                  ),
                ),
          children: [child],
        ),
      ),
    );
  }
}

class _KeyValue extends StatelessWidget {
  final String label;
  final String value;
  final VoidCallback? onCopy;
  final VoidCallback? onOpen;

  const _KeyValue({
    required this.label,
    required this.value,
    this.onCopy,
    this.onOpen,
  });

  @override
  Widget build(BuildContext context) {
    const primaryGreen = Color(0xFF1F5A50);
    final v = value.trim().isEmpty ? '-' : value.trim();

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 4,
            child: Text(
              label,
              style: TextStyle(
                color: primaryGreen.withValues(alpha: 0.62),
                fontWeight: FontWeight.w800,
                fontSize: 12,
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            flex: 6,
            child: Text(
              v,
              style: const TextStyle(
                color: primaryGreen,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
          if (onCopy != null || onOpen != null) ...[
            const SizedBox(width: 8),
            IconButton(
              onPressed: onCopy ?? onOpen,
              icon: Icon(
                onCopy != null ? Icons.copy_rounded : Icons.open_in_new_rounded,
              ),
              color: primaryGreen,
              tooltip: onCopy != null ? 'Nusxalash' : "Ko'rish",
            ),
          ],
        ],
      ),
    );
  }
}

class _ImageStrip extends StatelessWidget {
  final List<String> urls;
  final void Function(String url) onTap;

  const _ImageStrip({required this.urls, required this.onTap});

  @override
  Widget build(BuildContext context) {
    const primaryGreen = Color(0xFF1F5A50);

    final unique = <String>[];
    for (final url in urls) {
      final u = url.trim();
      if (u.isEmpty) continue;
      if (unique.contains(u)) continue;
      unique.add(u);
    }

    if (unique.isEmpty) {
      return Text(
        "Rasm yo'q",
        style: TextStyle(
          color: primaryGreen.withValues(alpha: 0.62),
          fontWeight: FontWeight.w700,
        ),
      );
    }

    return SizedBox(
      height: 120,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: unique.length,
        separatorBuilder: (_, __) => const SizedBox(width: 10),
        itemBuilder: (context, index) {
          final url = unique[index];
          return Material(
            color: const Color(0xFFF1F5F4),
            borderRadius: BorderRadius.circular(16),
            child: InkWell(
              onTap: () => onTap(url),
              borderRadius: BorderRadius.circular(16),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: AspectRatio(
                  aspectRatio: 16 / 9,
                  child: Image.network(
                    url,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) => Container(
                      color: primaryGreen.withValues(alpha: 0.06),
                      alignment: Alignment.center,
                      child: const Text(
                        "Rasm yuklanmadi",
                        style: TextStyle(
                          color: primaryGreen,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                    loadingBuilder: (context, child, loadingProgress) {
                      if (loadingProgress == null) return child;
                      return Container(
                        color: primaryGreen.withValues(alpha: 0.06),
                        alignment: Alignment.center,
                        child: const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                      );
                    },
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
