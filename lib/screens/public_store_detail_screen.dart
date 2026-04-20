import 'package:flutter/material.dart';
import 'package:hello_flutter_app/models/product.dart';
import 'package:hello_flutter_app/models/store_summary.dart';
import 'package:hello_flutter_app/services/auth_api_service.dart';
import 'package:hello_flutter_app/services/product_api_service.dart';
import 'package:url_launcher/url_launcher.dart';

class PublicStoreDetailScreen extends StatefulWidget {
  final String storeId;
  final StoreSummary? initialStore;

  const PublicStoreDetailScreen({
    super.key,
    required this.storeId,
    this.initialStore,
  });

  @override
  State<PublicStoreDetailScreen> createState() =>
      _PublicStoreDetailScreenState();
}

class _PublicStoreDetailScreenState extends State<PublicStoreDetailScreen> {
  final ProductApiService _productApi = ProductApiService();
  StoreSummary? _store;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _store = widget.initialStore;
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _isLoading = _store == null;
      _error = null;
    });

    try {
      final response = await _productApi.getStoreProducts(widget.storeId);
      if (!mounted) return;
      setState(() {
        _store = response.store;
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
        _error = "Do'kon ma'lumotlarini yuklab bo'lmadi";
        _isLoading = false;
      });
    }
  }

  String _formatMoney(num value) {
    final s = value.toStringAsFixed(0);
    final buffer = StringBuffer();
    for (var i = 0; i < s.length; i++) {
      final remaining = s.length - i;
      buffer.write(s[i]);
      if (remaining > 1 && remaining % 3 == 1) buffer.write(' ');
    }
    return buffer.toString();
  }

  @override
  Widget build(BuildContext context) {
    const primaryGreen = Color(0xFF1F5A50);

    return Scaffold(
      backgroundColor: const Color(0xFFF7F8FA),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        foregroundColor: primaryGreen,
        title: const Text(
          "Do'kon ma'lumotlari",
          style: TextStyle(fontWeight: FontWeight.w900),
        ),
        actions: [
          IconButton(
            onPressed: _load,
            icon: const Icon(Icons.refresh_rounded),
            tooltip: 'Yangilash',
          ),
        ],
      ),
      body: SafeArea(
        child: _isLoading
            ? const Center(
                child: CircularProgressIndicator(color: primaryGreen),
              )
            : _error != null && _store == null
            ? _StoreDetailState(message: _error!, onRetry: _load)
            : _StoreDetailContent(
                store: _store!,
                deliveryPriceText: _formatMoney(_store!.deliveryPrice),
                onRefresh: _load,
              ),
      ),
    );
  }
}

class _StoreDetailContent extends StatelessWidget {
  final StoreSummary store;
  final String deliveryPriceText;
  final Future<void> Function() onRefresh;

  const _StoreDetailContent({
    required this.store,
    required this.deliveryPriceText,
    required this.onRefresh,
  });

  String _serviceTypeValue(String raw) {
    final v = raw.trim().toLowerCase();
    return switch (v) {
      'online' => 'Onlayn',
      'offline' => 'Oflayn',
      'both' => 'Onlayn va oflayn',
      _ => raw.trim(),
    };
  }

  String _serviceTypeText(String raw) =>
      'Xizmat turi: ${_serviceTypeValue(raw)}';

  void _showImageDialog(BuildContext context, String url) {
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

  Future<void> _openUrl(BuildContext context, String raw) async {
    final value = raw.trim();
    if (value.isEmpty) return;
    final uri = Uri.tryParse(value);
    if (uri == null) return;

    final ok = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!ok && context.mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Linkni ochib bo'lmadi")));
    }
  }

  @override
  Widget build(BuildContext context) {
    const primaryGreen = Color(0xFF1F5A50);
    final logo = store.imagePath.trim();
    final directorName = store.director?.fullName.trim() ?? '';
    final directorContact = store.director?.contact.trim() ?? '';

    return RefreshIndicator(
      color: primaryGreen,
      onRefresh: onRefresh,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
        children: [
          _PublicStoreHero(
            name: store.name,
            logo: logo,
            banner: store.bannerImages.isNotEmpty
                ? store.bannerImages.first
                : store.imagePath,
            storeType: _serviceTypeText(store.storeType),
            activityType: store.activityType,
            onBannerTap: () => _showImageDialog(
              context,
              Product.resolveImagePath(
                store.bannerImages.isNotEmpty
                    ? store.bannerImages.first
                    : store.imagePath,
              ),
            ),
            onLogoTap: () =>
                _showImageDialog(context, Product.resolveImagePath(logo)),
          ),
          const SizedBox(height: 14),
          _PublicQuickGrid(
            items: [
              _PublicQuickItem(
                icon: Icons.schedule_rounded,
                label: 'Ish vaqti',
                value: store.workingHours,
              ),
              _PublicQuickItem(
                icon: Icons.local_shipping_rounded,
                label: 'Yetkazish',
                value: store.hasDelivery ? 'Mavjud' : "Mavjud emas",
              ),
            ],
          ),
          const SizedBox(height: 12),
          _DetailSection(
            title: 'Aloqa va manzil',
            children: [
              _DetailLine(
                icon: Icons.location_on_rounded,
                label: 'Manzil',
                value: store.address,
              ),
              _DetailLine(
                icon: Icons.map_rounded,
                label: 'Xarita',
                value: store.mapLocation,
                onTap: store.mapLocation.trim().isEmpty
                    ? null
                    : () => _openUrl(context, store.mapLocation),
              ),
              if (directorContact.isNotEmpty)
                _DetailLine(
                  icon: Icons.call_rounded,
                  label: 'Kontakt',
                  value: directorContact,
                ),
            ],
          ),
          const SizedBox(height: 12),
          _DetailSection(
            title: "Do'kon profili",
            children: [
              _DetailLine(
                icon: Icons.store_rounded,
                label: 'Xizmat turi',
                value: _serviceTypeValue(store.storeType),
              ),
              _DetailLine(
                icon: Icons.category_rounded,
                label: "Faoliyat yo'nalishi",
                value: store.activityType,
              ),
              _DetailLine(
                icon: Icons.schedule_rounded,
                label: 'Ish vaqti',
                value: store.workingHours,
              ),
            ],
          ),
          const SizedBox(height: 12),
          _DetailSection(
            title: "Yetkazib berish",
            children: [
              _DetailLine(
                icon: Icons.local_shipping_rounded,
                label: 'Holati',
                value: store.hasDelivery ? 'Mavjud' : "Mavjud emas",
              ),
              if (store.hasDelivery) ...[
                _DetailLine(
                  icon: Icons.location_city_rounded,
                  label: 'Hudud',
                  value: store.deliveryArea,
                ),
                _DetailLine(
                  icon: Icons.payments_rounded,
                  label: 'Narx',
                  value: "$deliveryPriceText so'm",
                ),
              ],
            ],
          ),
          if (directorName.isNotEmpty || directorContact.isNotEmpty) ...[
            const SizedBox(height: 12),
            _DetailSection(
              title: "Aloqa",
              children: [
                _DetailLine(
                  icon: Icons.person_rounded,
                  label: 'Masul',
                  value: directorName,
                ),
                _DetailLine(
                  icon: Icons.call_rounded,
                  label: 'Kontakt',
                  value: directorContact,
                ),
              ],
            ),
          ],
          if (store.bannerImages.isNotEmpty) ...[
            const SizedBox(height: 12),
            _DetailSection(
              title: 'Rasmlar',
              children: [
                SizedBox(
                  height: 96,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: store.bannerImages.length,
                    separatorBuilder: (context, index) =>
                        const SizedBox(width: 10),
                    itemBuilder: (context, index) {
                      final image = store.bannerImages[index];
                      final resolved = Product.resolveImagePath(image);
                      return ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: GestureDetector(
                          onTap: () => _showImageDialog(context, resolved),
                          child: AspectRatio(
                            aspectRatio: 4 / 3,
                            child: Image.network(
                              resolved,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) =>
                                  Container(
                                    color: const Color(0xFFE6F4EF),
                                    alignment: Alignment.center,
                                    child: const Icon(
                                      Icons.image_not_supported_rounded,
                                      color: primaryGreen,
                                    ),
                                  ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _DetailSection extends StatelessWidget {
  final String title;
  final List<Widget> children;

  const _DetailSection({required this.title, required this.children});

  @override
  Widget build(BuildContext context) {
    const primaryGreen = Color(0xFF1F5A50);

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: primaryGreen.withValues(alpha: 0.12)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              color: primaryGreen,
              fontSize: 15,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 10),
          ...children,
        ],
      ),
    );
  }
}

class _PublicStoreHero extends StatelessWidget {
  final String name;
  final String logo;
  final String banner;
  final String storeType;
  final String activityType;
  final VoidCallback? onBannerTap;
  final VoidCallback? onLogoTap;

  const _PublicStoreHero({
    required this.name,
    required this.logo,
    required this.banner,
    required this.storeType,
    required this.activityType,
    this.onBannerTap,
    this.onLogoTap,
  });

  @override
  Widget build(BuildContext context) {
    const primaryGreen = Color(0xFF1F5A50);
    final bannerValue = banner.trim();
    final logoValue = logo.trim();

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
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
          ClipRRect(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(18)),
            child: SizedBox(
              height: 128,
              width: double.infinity,
              child: GestureDetector(
                onTap: bannerValue.isEmpty ? null : onBannerTap,
                child: bannerValue.isEmpty
                    ? Container(
                        color: const Color(0xFFE6F4EF),
                        alignment: Alignment.center,
                        child: const Icon(
                          Icons.storefront_rounded,
                          color: primaryGreen,
                          size: 48,
                        ),
                      )
                    : Image.network(
                        Product.resolveImagePath(bannerValue),
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) => Container(
                          color: const Color(0xFFE6F4EF),
                          alignment: Alignment.center,
                          child: const Icon(
                            Icons.storefront_rounded,
                            color: primaryGreen,
                            size: 48,
                          ),
                        ),
                      ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: Transform.translate(
              offset: const Offset(0, -22),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Container(
                        width: 72,
                        height: 72,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 4),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.12),
                              blurRadius: 12,
                              offset: const Offset(0, 5),
                            ),
                          ],
                        ),
                        child: ClipOval(
                          child: GestureDetector(
                            onTap: logoValue.isEmpty ? null : onLogoTap,
                            child: logoValue.isEmpty
                                ? const Icon(
                                    Icons.storefront_rounded,
                                    color: primaryGreen,
                                    size: 34,
                                  )
                                : Image.network(
                                    Product.resolveImagePath(logoValue),
                                    fit: BoxFit.cover,
                                    errorBuilder:
                                        (context, error, stackTrace) =>
                                            const Icon(
                                              Icons.storefront_rounded,
                                              color: primaryGreen,
                                              size: 34,
                                            ),
                                  ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.only(bottom: 6),
                          child: Text(
                            "Do'kon",
                            style: TextStyle(
                              color: primaryGreen.withValues(alpha: 0.62),
                              fontSize: 12,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Text(
                    name.trim().isEmpty ? "Do'kon" : name.trim(),
                    style: const TextStyle(
                      color: primaryGreen,
                      fontSize: 24,
                      height: 1.12,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      if (storeType.trim().isNotEmpty)
                        _PublicPill(
                          icon: Icons.store_rounded,
                          label: storeType.trim(),
                        ),
                      if (activityType.trim().isNotEmpty)
                        _PublicPill(
                          icon: Icons.category_rounded,
                          label: activityType.trim(),
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PublicPill extends StatelessWidget {
  final IconData icon;
  final String label;

  const _PublicPill({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    const primaryGreen = Color(0xFF1F5A50);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFFE6F4EF),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: primaryGreen, size: 15),
          const SizedBox(width: 6),
          Text(
            label,
            style: const TextStyle(
              color: primaryGreen,
              fontSize: 12,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }
}

class _PublicQuickItem {
  final IconData icon;
  final String label;
  final String value;

  const _PublicQuickItem({
    required this.icon,
    required this.label,
    required this.value,
  });
}

class _PublicQuickGrid extends StatelessWidget {
  final List<_PublicQuickItem> items;

  const _PublicQuickGrid({required this.items});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        for (var i = 0; i < items.length; i++) ...[
          Expanded(child: _PublicQuickTile(item: items[i])),
          if (i != items.length - 1) const SizedBox(width: 10),
        ],
      ],
    );
  }
}

class _PublicQuickTile extends StatelessWidget {
  final _PublicQuickItem item;

  const _PublicQuickTile({required this.item});

  @override
  Widget build(BuildContext context) {
    const primaryGreen = Color(0xFF1F5A50);
    final value = item.value.trim().isEmpty ? '-' : item.value.trim();

    return Container(
      constraints: const BoxConstraints(minHeight: 92),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: primaryGreen.withValues(alpha: 0.1)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(item.icon, color: primaryGreen, size: 22),
          const SizedBox(height: 10),
          Text(
            item.label,
            style: TextStyle(
              color: primaryGreen.withValues(alpha: 0.62),
              fontSize: 11,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            value,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: primaryGreen,
              fontSize: 13,
              height: 1.2,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }
}

class _DetailLine extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final VoidCallback? onTap;

  const _DetailLine({
    required this.icon,
    required this.label,
    required this.value,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    const primaryGreen = Color(0xFF1F5A50);
    final displayValue = value.trim().isEmpty ? '-' : value.trim();
    final isLink = onTap != null;

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: const Color(0xFFE6F4EF),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: primaryGreen, size: 18),
          ),
          const SizedBox(width: 10),
          SizedBox(
            width: 92,
            child: Padding(
              padding: const EdgeInsets.only(top: 2),
              child: Text(
                label,
                style: TextStyle(
                  color: primaryGreen.withValues(alpha: 0.62),
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(top: 1),
              child: InkWell(
                onTap: onTap,
                child: Text(
                  displayValue,
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: isLink ? const Color(0xFF0F766E) : primaryGreen,
                    decoration: isLink
                        ? TextDecoration.underline
                        : TextDecoration.none,
                    fontSize: 13,
                    height: 1.35,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _StoreDetailState extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _StoreDetailState({required this.message, required this.onRetry});

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
