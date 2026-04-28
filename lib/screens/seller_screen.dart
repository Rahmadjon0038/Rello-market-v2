import 'package:flutter/material.dart';
import 'package:hello_flutter_app/models/product.dart';
import 'package:hello_flutter_app/models/seller.dart';
import 'package:hello_flutter_app/screens/product_detail_screen.dart';
import 'package:hello_flutter_app/services/auth_api_service.dart';
import 'package:hello_flutter_app/services/product_api_service.dart';
import 'package:hello_flutter_app/widgets/product_card.dart';

class SellerScreen extends StatefulWidget {
  final String sellerId;

  const SellerScreen({super.key, required this.sellerId});

  @override
  State<SellerScreen> createState() => _SellerScreenState();
}

class _SellerScreenState extends State<SellerScreen> {
  final ProductApiService _productApi = ProductApiService();
  final AuthApiService _authApi = AuthApiService();
  Seller? _seller;
  List<Product> _products = [];
  bool _isLoading = true;
  String? _error;
  AuthSession? _session;
  bool _isMySeller = false;

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    await _loadSession();
    await _loadSellerProducts();
  }

  Future<void> _loadSession() async {
    final session = await _authApi.loadSavedSession();
    if (!mounted) return;
    setState(() => _session = session);
  }

  Future<void> _loadSellerProducts() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final response = await _productApi.getSellerProducts(widget.sellerId);
      if (!mounted) return;
      final isMine =
          (_session?.phone.isNotEmpty == true) &&
          (response.seller.phone.isNotEmpty) &&
          (response.seller.phone == _session!.phone);
      setState(() {
        _seller = response.seller;
        _products = response.products;
        _isMySeller = isMine;
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
        _error = 'Sotuvchi mahsulotlarini yuklab bo‘lmadi';
        _isLoading = false;
      });
    }
  }

  Future<void> _openProduct(Product product) async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ProductDetailScreen(productId: product.id),
      ),
    );
    if (!mounted) return;
    _loadSellerProducts();
  }

  Future<void> _toggleLike(Product product) async {
    final idx = _products.indexWhere((item) => item.id == product.id);
    if (idx == -1) return;
    final nextLiked = !product.isLiked;
    setState(() {
      _products[idx] = product.copyWith(isLiked: nextLiked);
    });
    try {
      final serverLiked = nextLiked
          ? await _productApi.likeProduct(product.id)
          : await _productApi.unlikeProduct(product.id);
      if (!mounted) return;
      setState(() {
        final currentIdx = _products.indexWhere(
          (item) => item.id == product.id,
        );
        if (currentIdx != -1) {
          _products[currentIdx] = _products[currentIdx].copyWith(
            isLiked: serverLiked,
          );
        }
      });
    } on AuthApiException catch (error) {
      if (!mounted) return;
      _restoreProduct(product);
      _showSnack(error.message);
    } on Object {
      if (!mounted) return;
      _restoreProduct(product);
      _showSnack('Server bilan bog‘lanib bo‘lmadi');
    }
  }

  Future<void> _addToCart(Product product) async {
    if (_isMySeller) {
      _showSnack("O'zingizning mahsulotingizni sotib ololmaysiz");
      return;
    }
    final qty = product.cartQty > 0 ? product.cartQty + 1 : 1;
    try {
      final serverQty = await _productApi.addToCart(product.id, qty: qty);
      if (!mounted) return;
      setState(() {
        final idx = _products.indexWhere((item) => item.id == product.id);
        if (idx != -1) {
          _products[idx] = _products[idx].copyWith(
            isCart: true,
            cartQty: serverQty,
          );
        }
      });
      _showSnack('Mahsulot savatchaga qo‘shildi');
    } on AuthApiException catch (error) {
      _showSnack(error.message);
    } on Object {
      _showSnack('Server bilan bog‘lanib bo‘lmadi');
    }
  }

  void _restoreProduct(Product product) {
    setState(() {
      final idx = _products.indexWhere((item) => item.id == product.id);
      if (idx != -1) _products[idx] = product;
    });
  }

  void _showSnack(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), duration: const Duration(seconds: 2)),
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
          'Do‘kon',
          style: TextStyle(fontWeight: FontWeight.w800),
        ),
      ),
      body: SafeArea(
        child: _isLoading
            ? const Center(
                child: CircularProgressIndicator(color: primaryGreen),
              )
            : _error != null
            ? _SellerState(message: _error!, onRetry: _loadSellerProducts)
            : RefreshIndicator(
                color: primaryGreen,
                onRefresh: _loadSellerProducts,
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                  children: [
                    if (_seller != null) _SellerHeader(seller: _seller!),
                    const SizedBox(height: 18),
                    const Text(
                      'Mahsulotlar',
                      style: TextStyle(
                        color: primaryGreen,
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 12),
                    if (_products.isEmpty)
                      _SellerState(
                        message: 'Bu do‘konda mahsulotlar topilmadi',
                        onRetry: _loadSellerProducts,
                      )
                    else
                      GridView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: _products.length,
                        gridDelegate:
                            const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 2,
                              mainAxisSpacing: 12,
                              crossAxisSpacing: 12,
                              childAspectRatio: 0.64,
                            ),
                        itemBuilder: (context, index) {
                          final product = _products[index];
                          return ProductCard(
                            item: product,
                            onTap: () => _openProduct(product),
                            onLike: () => _toggleLike(product),
                            onAddToCart: _isMySeller
                                ? null
                                : () => _addToCart(product),
                            addToCartDisabledText: "O'zingizniki",
                          );
                        },
                      ),
                  ],
                ),
              ),
      ),
    );
  }
}

class _SellerHeader extends StatelessWidget {
  final Seller seller;

  const _SellerHeader({required this.seller});

  @override
  Widget build(BuildContext context) {
    const primaryGreen = Color(0xFF1F5A50);
    final imageUrl = seller.resolvedProfileImg;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFE6F4EF),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: primaryGreen.withOpacity(0.12)),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 30,
            backgroundColor: Colors.white,
            backgroundImage: _profileImageProvider(imageUrl),
            child: imageUrl.isEmpty
                ? const Icon(Icons.storefront_rounded, color: primaryGreen)
                : null,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  seller.fullName.isEmpty ? 'Sotuvchi' : seller.fullName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: primaryGreen,
                    fontSize: 17,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                if (seller.contact.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    seller.contact,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: primaryGreen.withOpacity(0.72),
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

ImageProvider? _profileImageProvider(String imageUrl) {
  if (imageUrl.isEmpty) return null;
  if (imageUrl.startsWith('http://') || imageUrl.startsWith('https://')) {
    return NetworkImage(imageUrl);
  }
  return AssetImage(imageUrl);
}

class _SellerState extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _SellerState({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    const primaryGreen = Color(0xFF1F5A50);

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.storefront_rounded, color: primaryGreen, size: 44),
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
