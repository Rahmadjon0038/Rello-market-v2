import 'package:flutter/material.dart';
import 'package:hello_flutter_app/models/product.dart';
import 'package:hello_flutter_app/screens/product_detail_screen.dart';
import 'package:hello_flutter_app/services/auth_api_service.dart';
import 'package:hello_flutter_app/services/product_api_service.dart';
import 'package:hello_flutter_app/widgets/product_image.dart';

class FavoritesScreen extends StatefulWidget {
  final VoidCallback onGoHome;
  final VoidCallback? onSummaryChanged;

  const FavoritesScreen({
    super.key,
    required this.onGoHome,
    this.onSummaryChanged,
  });

  @override
  State<FavoritesScreen> createState() => _FavoritesScreenState();
}

class _FavoritesScreenState extends State<FavoritesScreen> {
  final ProductApiService _productApi = ProductApiService();
  bool _isLoading = true;
  String? _error;
  List<Product> _products = [];

  @override
  void initState() {
    super.initState();
    _loadFavorites();
  }

  Future<void> _loadFavorites() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final products = await _productApi.getFavoriteProducts();
      if (!mounted) return;
      setState(() {
        _products = products;
        _isLoading = false;
      });
    } on Object {
      if (!mounted) return;
      setState(() {
        _error = 'Sevimlilarni yuklab bo‘lmadi';
        _isLoading = false;
      });
    }
  }

  Future<void> _unlike(Product product) async {
    final index = _products.indexWhere((item) => item.id == product.id);
    if (index == -1) return;
    setState(() => _products.removeAt(index));
    try {
      await _productApi.unlikeProduct(product.id);
      widget.onSummaryChanged?.call();
    } on AuthApiException catch (error) {
      if (!mounted) return;
      setState(() => _products.insert(index, product));
      _showSnack(error.message);
    } on Object {
      if (!mounted) return;
      setState(() => _products.insert(index, product));
      _showSnack('Server bilan bog‘lanib bo‘lmadi');
    }
  }

  Future<void> _addToCart(Product product) async {
    final qty = product.cartQty > 0 ? product.cartQty + 1 : 1;
    try {
      await _productApi.addToCart(product.id, qty: qty);
      widget.onSummaryChanged?.call();
      _showSnack('Mahsulot savatchaga qo‘shildi');
    } on AuthApiException catch (error) {
      _showSnack(error.message);
    } on Object {
      _showSnack('Server bilan bog‘lanib bo‘lmadi');
    }
  }

  void _showSnack(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), duration: const Duration(seconds: 2)),
    );
  }

  Future<void> _openProductDetail(Product product) async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ProductDetailScreen(productId: product.id),
      ),
    );
    if (!mounted) return;
    _loadFavorites();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 28),
        child: Center(
          child: CircularProgressIndicator(color: Color(0xFF1F5A50)),
        ),
      );
    }

    if (_error != null) {
      return _EmptyFavoritesCard(
        title: _error!,
        message: 'Qayta urinib ko‘ring.',
        actionText: 'Qayta urinish',
        onAction: _loadFavorites,
      );
    }

    if (_products.isEmpty) {
      return _EmptyFavoritesCard(
        title: 'Sevimlilar bo‘sh',
        message:
            'Sevimli mahsulotlarni topish uchun mahsulotlar sahifasiga o‘ting.',
        actionText: 'Mahsulotlar sahifasi',
        onAction: widget.onGoHome,
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: _products.length,
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          mainAxisSpacing: 12,
          crossAxisSpacing: 12,
          childAspectRatio: 0.64,
        ),
        itemBuilder: (context, index) {
          final product = _products[index];
          return _FavProductCard(
            item: product,
            onTap: () => _openProductDetail(product),
            onUnlike: () => _unlike(product),
            onAddToCart: () => _addToCart(product),
          );
        },
      ),
    );
  }
}

class _EmptyFavoritesCard extends StatelessWidget {
  final String title;
  final String message;
  final String actionText;
  final VoidCallback onAction;

  const _EmptyFavoritesCard({
    required this.title,
    required this.message,
    required this.actionText,
    required this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    const primaryGreen = Color(0xFF1F5A50);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      child: Container(
        padding: const EdgeInsets.fromLTRB(18, 18, 18, 18),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.12),
              blurRadius: 22,
              offset: const Offset(0, 10),
            ),
          ],
          border: Border.all(color: primaryGreen.withValues(alpha: 0.18)),
        ),
        child: Column(
          children: [
            const Icon(Icons.favorite_border, size: 52, color: primaryGreen),
            const SizedBox(height: 12),
            Text(
              title,
              style: const TextStyle(
                color: primaryGreen,
                fontSize: 16,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Color(0xFF8A9A97), fontSize: 12),
            ),
            const SizedBox(height: 14),
            SizedBox(
              height: 40,
              child: ElevatedButton(
                onPressed: onAction,
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryGreen,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                ),
                child: Text(
                  actionText,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
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

class _FavProductCard extends StatelessWidget {
  final Product item;
  final VoidCallback onTap;
  final VoidCallback onUnlike;
  final VoidCallback onAddToCart;

  const _FavProductCard({
    required this.item,
    required this.onTap,
    required this.onUnlike,
    required this.onAddToCart,
  });

  @override
  Widget build(BuildContext context) {
    const primaryGreen = Color(0xFF1F5A50);

    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.08),
                blurRadius: 16,
                offset: const Offset(0, 8),
              ),
            ],
            border: Border.all(color: primaryGreen.withValues(alpha: 0.12)),
          ),
          child: Stack(
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: ProductImage(
                      path: item.resolvedImagePath,
                      height: 92,
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(10, 6, 10, 6),
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
                          item.description,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: primaryGreen.withValues(alpha: 0.7),
                            fontSize: 11,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          item.formattedPrice,
                          style: const TextStyle(
                            color: primaryGreen,
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Spacer(),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(10, 0, 10, 8),
                    child: SizedBox(
                      height: 30,
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: primaryGreen,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          padding: const EdgeInsets.symmetric(horizontal: 10),
                        ),
                        onPressed: onAddToCart,
                        icon: const Icon(Icons.add_shopping_cart, size: 16),
                        label: const Text(
                          'Savatga',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              Positioned(
                top: 6,
                right: 6,
                child: SizedBox(
                  width: 34,
                  height: 34,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.9),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: primaryGreen.withValues(alpha: 0.08),
                      ),
                    ),
                    child: IconButton(
                      padding: EdgeInsets.zero,
                      onPressed: onUnlike,
                      icon: const Icon(
                        Icons.favorite,
                        color: Colors.redAccent,
                        size: 18,
                      ),
                    ),
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
