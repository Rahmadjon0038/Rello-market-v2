import 'package:flutter/material.dart';
import 'package:hello_flutter_app/models/store.dart';
import 'package:hello_flutter_app/services/auth_api_service.dart';
import 'package:hello_flutter_app/services/store_api_service.dart';
import 'package:hello_flutter_app/screens/store_detail_screen.dart';

class MyStoresScreen extends StatefulWidget {
  const MyStoresScreen({super.key});

  @override
  State<MyStoresScreen> createState() => _MyStoresScreenState();
}

class _MyStoresScreenState extends State<MyStoresScreen> {
  final StoreApiService _storeApi = StoreApiService();
  List<StoreModel> _stores = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadStores();
  }

  Future<void> _loadStores() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final stores = await _storeApi.getMyStores();
      if (!mounted) return;
      setState(() {
        _stores = stores;
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
        _error = 'Do‘konlarni yuklab bo‘lmadi';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    const primaryGreen = Color(0xFF1F5A50);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        foregroundColor: primaryGreen,
        elevation: 0,
        title: const Text(
          "Mening do'konlarim",
          style: TextStyle(fontWeight: FontWeight.w900),
        ),
      ),
      body: SafeArea(
        child: _isLoading
            ? const Center(
                child: CircularProgressIndicator(color: primaryGreen),
              )
            : RefreshIndicator(
                color: primaryGreen,
                onRefresh: _loadStores,
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(16, 14, 16, 24),
                  children: [
                    if (_error != null)
                      _StoresStateCard(message: _error!, onRetry: _loadStores)
                    else if (_stores.isEmpty)
                      _StoresStateCard(
                        message: "Do'konlar topilmadi",
                        onRetry: _loadStores,
                      )
                    else
                      ..._stores.map(
                        (store) => Padding(
                          padding: const EdgeInsets.only(bottom: 10),
                          child: _StoreTile(
                            store: store,
                            onReturn: _loadStores,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
      ),
    );
  }
}

class _StoreTile extends StatelessWidget {
  final StoreModel store;
  final VoidCallback? onReturn;

  const _StoreTile({required this.store, this.onReturn});

  @override
  Widget build(BuildContext context) {
    const primaryGreen = Color(0xFF1F5A50);
    final ordersBadgeCount = store.badges.orders;

    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: () {
          Navigator.of(context)
              .push(
                MaterialPageRoute(
                  builder: (_) =>
                      StoreDetailScreen(storeId: store.id, initialStore: store),
                ),
              )
              .then((_) => onReturn?.call());
        },
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: primaryGreen.withValues(alpha: 0.12)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.06),
                    blurRadius: 14,
                    offset: const Offset(0, 7),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Container(
                    width: 46,
                    height: 46,
                    decoration: BoxDecoration(
                      color: const Color(0xFFE6F4EF),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.storefront_rounded,
                      color: primaryGreen,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                store.name.isEmpty ? "Do'kon" : store.name,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  color: primaryGreen,
                                  fontSize: 16,
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                            ),
                            if (store.isNew) ...[
                              const SizedBox(width: 8),
                              _NewStoreBadge(
                                text: store.newBadgeText ?? "Yangi do'kon",
                              ),
                            ],
                            if (ordersBadgeCount > 0) ...[
                              const SizedBox(width: 8),
                              _OrdersBadge(count: ordersBadgeCount),
                            ],
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          store.description.isEmpty
                              ? 'Tavsif yo‘q'
                              : store.description,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: primaryGreen.withValues(alpha: 0.68),
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Icon(
                    Icons.chevron_right_rounded,
                    color: primaryGreen.withValues(alpha: 0.7),
                  ),
                ],
              ),
            ),
            if (ordersBadgeCount > 0)
              Positioned(
                right: 10,
                top: 10,
                child: _CornerCountBadge(count: ordersBadgeCount),
              ),
          ],
        ),
      ),
    );
  }
}

class _CornerCountBadge extends StatelessWidget {
  final int count;

  const _CornerCountBadge({required this.count});

  @override
  Widget build(BuildContext context) {
    final label = count > 99 ? '99+' : '$count';
    return Container(
      constraints: const BoxConstraints(minWidth: 18),
      height: 18,
      padding: const EdgeInsets.symmetric(horizontal: 5),
      decoration: BoxDecoration(
        color: const Color(0xFFE11D48),
        borderRadius: BorderRadius.circular(999),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.18),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      alignment: Alignment.center,
      child: Text(
        label,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 10,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }
}

class _NewStoreBadge extends StatelessWidget {
  final String text;

  const _NewStoreBadge({required this.text});

  @override
  Widget build(BuildContext context) {
    const accent = Color(0xFF0F766E);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      decoration: BoxDecoration(
        color: accent.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: accent.withValues(alpha: 0.2)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.auto_awesome_rounded, color: accent, size: 13),
          const SizedBox(width: 4),
          Text(
            text,
            style: const TextStyle(
              color: accent,
              fontSize: 11,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }
}

class _OrdersBadge extends StatelessWidget {
  final int count;

  const _OrdersBadge({required this.count});

  @override
  Widget build(BuildContext context) {
    final label = count > 99 ? '99+' : '$count';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      decoration: BoxDecoration(
        color: const Color(0xFFE11D48).withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(
          color: const Color(0xFFE11D48).withValues(alpha: 0.25),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.receipt_long_rounded,
            color: Color(0xFFE11D48),
            size: 13,
          ),
          const SizedBox(width: 4),
          Text(
            label,
            style: const TextStyle(
              color: Color(0xFFE11D48),
              fontSize: 11,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }
}

class _StoresStateCard extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _StoresStateCard({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    const primaryGreen = Color(0xFF1F5A50);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFE6F4EF),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        children: [
          Text(
            message,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Color.fromARGB(255, 90, 31, 46),
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
    );
  }
}
