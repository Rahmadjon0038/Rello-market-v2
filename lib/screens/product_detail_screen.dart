import 'package:flutter/material.dart';
import 'package:hello_flutter_app/models/product.dart';
import 'package:hello_flutter_app/models/store_summary.dart';
import 'package:hello_flutter_app/screens/store_products_screen.dart';
import 'package:hello_flutter_app/services/auth_api_service.dart';
import 'package:hello_flutter_app/services/product_api_service.dart';
import 'package:hello_flutter_app/widgets/product_image.dart';

class ProductDetailScreen extends StatefulWidget {
  final String productId;

  const ProductDetailScreen({super.key, required this.productId});

  @override
  State<ProductDetailScreen> createState() => _ProductDetailScreenState();
}

class _ProductDetailScreenState extends State<ProductDetailScreen> {
  final ProductApiService _productApi = ProductApiService();
  final AuthApiService _authApi = AuthApiService();
  final PageController _imageController = PageController();
  Product? _product;
  bool _isLoading = true;
  bool _isActionLoading = false;
  String? _error;
  int _imageIndex = 0;
  bool _isOwnProduct = false;

  @override
  void initState() {
    super.initState();
    _loadProduct();
  }

  @override
  void dispose() {
    _imageController.dispose();
    super.dispose();
  }

  Future<void> _loadProduct() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final product = await _productApi.getProduct(widget.productId);
      final session = await _authApi.loadSavedSession();
      final sessionPhone = session?.phone.trim() ?? '';
      final sellerPhone = product.seller?.phone.trim() ?? '';
      final storePhone = product.store?.director?.phone.trim() ?? '';
      final isOwn =
          sessionPhone.isNotEmpty &&
          ((sellerPhone.isNotEmpty && sellerPhone == sessionPhone) ||
              (storePhone.isNotEmpty && storePhone == sessionPhone));
      if (!mounted) return;
      setState(() {
        _product = product;
        _isOwnProduct = isOwn;
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
        _error = 'Mahsulotni yuklab bo‘lmadi';
        _isLoading = false;
      });
    }
  }

  Future<void> _toggleLike() async {
    final product = _product;
    if (product == null || _isActionLoading) return;
    final nextLiked = !product.isLiked;
    setState(() {
      _isActionLoading = true;
      _product = product.copyWith(isLiked: nextLiked);
    });
    try {
      final serverLiked = nextLiked
          ? await _productApi.likeProduct(product.id)
          : await _productApi.unlikeProduct(product.id);
      if (!mounted) return;
      setState(() {
        _product = _product?.copyWith(isLiked: serverLiked);
      });
    } on AuthApiException catch (error) {
      if (!mounted) return;
      setState(() => _product = product);
      _showSnack(error.message);
    } on Object {
      if (!mounted) return;
      setState(() => _product = product);
      _showSnack('Server bilan bog‘lanib bo‘lmadi');
    } finally {
      if (mounted) setState(() => _isActionLoading = false);
    }
  }

  Future<void> _addToCart() async {
    final product = _product;
    if (product == null || _isActionLoading) return;
    if (_isOwnProduct) {
      _showSnack("O'zingizning mahsulotingizni sotib ololmaysiz");
      return;
    }
    final nextQty = product.cartQty > 0 ? product.cartQty + 1 : 1;
    setState(() => _isActionLoading = true);
    try {
      final serverQty = await _productApi.addToCart(product.id, qty: nextQty);
      if (!mounted) return;
      setState(() {
        _product = product.copyWith(isCart: true, cartQty: serverQty);
      });
      _showSnack('Mahsulot savatchaga qo‘shildi');
    } on AuthApiException catch (error) {
      _showSnack(error.message);
    } on Object {
      _showSnack('Server bilan bog‘lanib bo‘lmadi');
    } finally {
      if (mounted) setState(() => _isActionLoading = false);
    }
  }

  void _showSnack(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), duration: const Duration(seconds: 2)),
    );
  }

  void _openStore(StoreSummary store) {
    if (store.id.isEmpty) return;
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => StoreProductsScreen(storeId: store.id)),
    );
  }

  void _openFullScreenGallery(List<String> images, int initialIndex) {
    if (images.isEmpty) return;
    Navigator.of(context).push(
      PageRouteBuilder<void>(
        opaque: false,
        barrierDismissible: true,
        barrierColor: Colors.black.withValues(alpha: 0.55),
        pageBuilder: (context, animation, secondaryAnimation) {
          return _FullScreenGallery(
            images: images,
            initialIndex: initialIndex.clamp(0, images.length - 1),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    const primaryGreen = Color(0xFF1F5A50);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        foregroundColor: primaryGreen,
        title: const Text(
          'Mahsulot',
          style: TextStyle(fontWeight: FontWeight.w800),
        ),
      ),
      body: SafeArea(
        child: _isLoading
            ? const Center(
                child: CircularProgressIndicator(color: primaryGreen),
              )
            : _error != null
            ? _DetailError(message: _error!, onRetry: _loadProduct)
            : _buildContent(context, _product!),
      ),
    );
  }

  Widget _buildContent(BuildContext context, Product product) {
    const primaryGreen = Color(0xFF1F5A50);
    final images = product.resolvedImages;
    final isOwn = _isOwnProduct;

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 18),
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: SizedBox(
            height: 320,
            child: Stack(
              fit: StackFit.expand,
              children: [
                PageView.builder(
                  controller: _imageController,
                  itemCount: images.length,
                  onPageChanged: (index) => setState(() => _imageIndex = index),
                  itemBuilder: (context, index) {
                    return GestureDetector(
                      onTap: () => _openFullScreenGallery(images, _imageIndex),
                      child: ProductImage(path: images[index], height: 320),
                    );
                  },
                ),
                Positioned(
                  bottom: 10,
                  right: 10,
                  child: Material(
                    color: Colors.black.withValues(alpha: 0.35),
                    shape: const CircleBorder(),
                    child: IconButton(
                      onPressed: images.isEmpty
                          ? null
                          : () => _openFullScreenGallery(images, _imageIndex),
                      icon: const Icon(Icons.fullscreen_rounded),
                      color: Colors.white,
                      tooltip: "To'liq ekran",
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        if (images.length > 1) ...[
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(images.length, (index) {
              final active = index == _imageIndex;
              return AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                margin: const EdgeInsets.symmetric(horizontal: 3),
                width: active ? 18 : 7,
                height: 7,
                decoration: BoxDecoration(
                  color: active
                      ? primaryGreen
                      : primaryGreen.withValues(alpha: 0.24),
                  borderRadius: BorderRadius.circular(7),
                ),
              );
            }),
          ),
        ],
        const SizedBox(height: 16),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Text(
                product.name,
                style: const TextStyle(
                  color: primaryGreen,
                  fontSize: 22,
                  fontWeight: FontWeight.w900,
                  height: 1.15,
                ),
              ),
            ),
            const SizedBox(width: 10),
            IconButton(
              onPressed: _isActionLoading ? null : _toggleLike,
              icon: Icon(
                product.isLiked ? Icons.favorite : Icons.favorite_border,
                color: product.isLiked ? Colors.redAccent : primaryGreen,
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        Text(
          product.formattedPrice,
          style: const TextStyle(
            color: primaryGreen,
            fontSize: 18,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            if (product.categoryName.isNotEmpty)
              _InfoChip(
                icon: Icons.category_rounded,
                text: 'Kategoriya: ${product.categoryName}',
              ),
            if (product.brand.isNotEmpty)
              _InfoChip(
                icon: Icons.sell_rounded,
                text: 'Brend: ${product.brand}',
              ),
            _InfoChip(
              icon: Icons.inventory_2_rounded,
              text: 'Tovar soni: ${product.qty} ta',
            ),
          ],
        ),
        const SizedBox(height: 18),
        const Text(
          'Tavsif',
          style: TextStyle(
            color: primaryGreen,
            fontSize: 16,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          product.description,
          style: const TextStyle(
            color: Color(0xFF42524E),
            fontSize: 14,
            height: 1.45,
            fontWeight: FontWeight.w500,
          ),
        ),
        if (product.store != null && product.store!.id.isNotEmpty) ...[
          const SizedBox(height: 20),
          _StoreBlock(
            store: product.store!,
            onTap: () => _openStore(product.store!),
          ),
        ],
        const SizedBox(height: 20),
        if (isOwn)
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFE6F4EF),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: primaryGreen.withValues(alpha: 0.18)),
              ),
              child: const Text(
                "Bu sizning mahsulotingiz. O'zingiz sotib ololmaysiz.",
                softWrap: true,
                style: TextStyle(
                  color: primaryGreen,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  height: 1.25,
                ),
              ),
            ),
          ),
        SizedBox(
          height: 50,
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: (_isActionLoading || isOwn) ? null : _addToCart,
            style: ElevatedButton.styleFrom(
              backgroundColor: primaryGreen,
              disabledBackgroundColor: primaryGreen.withValues(alpha: 0.7),
              foregroundColor: Colors.white,
              disabledForegroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            icon: _isActionLoading
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  )
                : Icon(
                    product.isCart
                        ? Icons.shopping_cart_checkout
                        : Icons.add_shopping_cart,
                  ),
            label: Text(
              isOwn
                  ? "O'zingizniki"
                  : (product.isCart
                        ? 'Savatda (${product.cartQty})'
                        : 'Savatga qo‘shish'),
              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800),
            ),
          ),
        ),
      ],
    );
  }
}

class _StoreBlock extends StatelessWidget {
  final StoreSummary store;
  final VoidCallback onTap;

  const _StoreBlock({required this.store, required this.onTap});

  @override
  Widget build(BuildContext context) {
    const primaryGreen = Color(0xFF1F5A50);
    final imageUrl = Product.resolveImagePath(store.imagePath);

    return Material(
      color: const Color(0xFFE6F4EF),
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              CircleAvatar(
                radius: 26,
                backgroundColor: Colors.white,
                backgroundImage: store.imagePath.trim().isEmpty
                    ? null
                    : NetworkImage(imageUrl),
                child: store.imagePath.trim().isEmpty
                    ? const Icon(Icons.storefront_rounded, color: primaryGreen)
                    : null,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Do'kon",
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: primaryGreen.withValues(alpha: 0.62),
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      store.name.isEmpty ? "Do'kon" : store.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: primaryGreen,
                        fontSize: 15,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    if (store.activityType.trim().isNotEmpty) ...[
                      const SizedBox(height: 3),
                      Text(
                        store.activityType,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: primaryGreen.withValues(alpha: 0.72),
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: 8),
              const Icon(
                Icons.chevron_right_rounded,
                color: primaryGreen,
                size: 26,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _InfoChip extends StatelessWidget {
  final IconData icon;
  final String text;

  const _InfoChip({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    const primaryGreen = Color(0xFF1F5A50);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFFE6F4EF),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: primaryGreen, size: 16),
          const SizedBox(width: 6),
          Flexible(
            child: Text(
              text,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: primaryGreen,
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _DetailError extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _DetailError({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    const primaryGreen = Color(0xFF1F5A50);

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, color: primaryGreen, size: 46),
            const SizedBox(height: 10),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: primaryGreen,
                fontSize: 15,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 12),
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

class _FullScreenGallery extends StatefulWidget {
  final List<String> images;
  final int initialIndex;

  const _FullScreenGallery({required this.images, required this.initialIndex});

  @override
  State<_FullScreenGallery> createState() => _FullScreenGalleryState();
}

class _FullScreenGalleryState extends State<_FullScreenGallery> {
  late final PageController _controller;
  int _index = 0;

  @override
  void initState() {
    super.initState();
    _index = widget.initialIndex;
    _controller = PageController(initialPage: widget.initialIndex);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final total = widget.images.length;
    final title = total <= 1 ? 'Rasm' : '${_index + 1}/$total';

    return Material(
      type: MaterialType.transparency,
      child: Stack(
        children: [
          Positioned.fill(
            child: PageView.builder(
              controller: _controller,
              itemCount: total,
              onPageChanged: (i) => setState(() => _index = i),
              itemBuilder: (context, i) {
                return InteractiveViewer(
                  minScale: 0.8,
                  maxScale: 4,
                  child: _GalleryImage(path: widget.images[i]),
                );
              },
            ),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(8, 6, 8, 6),
              child: Row(
                children: [
                  Material(
                    color: Colors.white.withValues(alpha: 0.14),
                    shape: const CircleBorder(),
                    child: IconButton(
                      onPressed: () => Navigator.of(context).pop(),
                      icon: const Icon(Icons.close_rounded),
                      color: Colors.white,
                      tooltip: 'Yopish',
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      title,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  const SizedBox(width: 48),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _GalleryImage extends StatelessWidget {
  final String path;

  const _GalleryImage({required this.path});

  @override
  Widget build(BuildContext context) {
    if (path.startsWith('http://') || path.startsWith('https://')) {
      return SizedBox.expand(
        child: Image.network(
          path,
          fit: BoxFit.contain,
          errorBuilder: (context, error, stackTrace) => const Center(
            child: Icon(
              Icons.image_not_supported_rounded,
              color: Colors.white70,
              size: 40,
            ),
          ),
        ),
      );
    }

    return SizedBox.expand(
      child: Image.asset(
        path,
        fit: BoxFit.contain,
        errorBuilder: (context, error, stackTrace) => const Center(
          child: Icon(
            Icons.image_not_supported_rounded,
            color: Colors.white70,
            size: 40,
          ),
        ),
      ),
    );
  }
}
