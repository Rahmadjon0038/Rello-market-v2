import 'dart:async';

import 'package:flutter/material.dart';
import 'package:hello_flutter_app/models/category.dart';
import 'package:hello_flutter_app/models/product.dart';
import 'package:hello_flutter_app/screens/product_detail_screen.dart';
import 'package:hello_flutter_app/services/auth_api_service.dart';
import 'package:hello_flutter_app/services/product_api_service.dart';
import 'package:hello_flutter_app/widgets/category_icon.dart';
import 'package:hello_flutter_app/widgets/product_card.dart';
import 'package:hello_flutter_app/widgets/product_image.dart';

class HomeHeader extends StatefulWidget {
  final bool showContent;
  final bool showSearch;
  final VoidCallback? onSummaryChanged;

  const HomeHeader({
    super.key,
    this.showContent = true,
    this.showSearch = true,
    this.onSummaryChanged,
  });

  @override
  State<HomeHeader> createState() => _HomeHeaderState();
}

class _HomeHeaderState extends State<HomeHeader>
    with SingleTickerProviderStateMixin, WidgetsBindingObserver {
  bool _showSearch = false;
  String _selectedLang = "UZ";
  String? _selectedCategoryId;
  bool _isLoadingProducts = true;
  String? _productsError;
  AnimationController? _sheetController;
  PageController? _carouselController;
  Timer? _carouselTimer;
  int _carouselIndex = 0;
  final ProductApiService _productApi = ProductApiService();
  final AuthApiService _authApi = AuthApiService();
  AuthSession? _session;
  List<Product> _products = [];
  List<Product> _carouselProducts = [];
  List<CategoryModel> _categories = [];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _loadSession();
    _loadHomeData();
  }

  Future<void> _loadSession() async {
    final session = await _authApi.loadSavedSession();
    if (!mounted) return;
    setState(() => _session = session);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _carouselTimer?.cancel();
    _carouselController?.dispose();
    _sheetController?.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(covariant HomeHeader oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!oldWidget.showContent && widget.showContent) {
      _loadHomeData();
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed && widget.showContent) {
      _loadHomeData();
    }
  }

  void _openLanguageSheet() {
    _sheetController ??= AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 160),
      reverseDuration: const Duration(milliseconds: 110),
    );

    showModalBottomSheet(
      context: context,
      showDragHandle: true,
      transitionAnimationController: _sheetController,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: TweenAnimationBuilder<double>(
            tween: Tween(begin: 0.0, end: 1.0),
            duration: const Duration(milliseconds: 160),
            curve: Curves.easeOutCubic,
            builder: (context, value, child) {
              return Opacity(
                opacity: value,
                child: Transform.translate(
                  offset: Offset(0, (1 - value) * 56),
                  child: Transform.scale(
                    scale: 0.98 + (0.02 * value),
                    child: child,
                  ),
                ),
              );
            },
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _LangOption(
                    label: "O'zbekcha",
                    value: "UZ",
                    selected: _selectedLang == "UZ",
                    onTap: () {
                      setState(() => _selectedLang = "UZ");
                      Navigator.pop(ctx);
                    },
                  ),
                  const SizedBox(height: 8),
                  _LangOption(
                    label: "English",
                    value: "EN",
                    selected: _selectedLang == "EN",
                    onTap: () {
                      setState(() => _selectedLang = "EN");
                      Navigator.pop(ctx);
                    },
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Future<void> _loadHomeData() async {
    setState(() {
      _isLoadingProducts = true;
      _productsError = null;
    });
    try {
      final categories = await _productApi.getCategories();
      final carouselProducts = await _productApi.getCarousel();
      final products = await _productApi.getProducts(
        categoryId: _selectedCategoryId,
      );
      if (!mounted) return;
      setState(() {
        _categories = categories;
        _carouselProducts = carouselProducts;
        _products = products;
        _isLoadingProducts = false;
        if (_carouselIndex >= _carouselProducts.length) {
          _carouselIndex = 0;
        }
      });
    } on Object {
      if (!mounted) return;
      setState(() {
        _productsError = 'Mahsulotlarni yuklab bo‘lmadi';
        _isLoadingProducts = false;
      });
    }
  }

  Future<void> _loadProducts() async {
    setState(() {
      _isLoadingProducts = true;
      _productsError = null;
    });
    try {
      final products = await _productApi.getProducts(
        categoryId: _selectedCategoryId,
      );
      if (!mounted) return;
      setState(() {
        _products = products;
        _isLoadingProducts = false;
      });
    } on Object {
      if (!mounted) return;
      setState(() {
        _productsError = 'Mahsulotlarni yuklab bo‘lmadi';
        _isLoadingProducts = false;
      });
    }
  }

  Future<void> _selectCategory(String? categoryId) async {
    if (_selectedCategoryId == categoryId) return;
    setState(() => _selectedCategoryId = categoryId);
    await _loadProducts();
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
      widget.onSummaryChanged?.call();
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
      setState(() {
        final currentIdx = _products.indexWhere(
          (item) => item.id == product.id,
        );
        if (currentIdx != -1) {
          _products[currentIdx] = _products[currentIdx].copyWith(
            isLiked: product.isLiked,
          );
        }
      });
      _showSnack(error.message);
    } on Object {
      if (!mounted) return;
      setState(() {
        final currentIdx = _products.indexWhere(
          (item) => item.id == product.id,
        );
        if (currentIdx != -1) {
          _products[currentIdx] = _products[currentIdx].copyWith(
            isLiked: product.isLiked,
          );
        }
      });
      _showSnack('Server bilan bog‘lanib bo‘lmadi');
    }
  }

  Future<void> _addToCart(Product product) async {
    final sessionPhone = _session?.phone.trim() ?? '';
    final sellerPhone = product.seller?.phone.trim() ?? '';
    final storePhone = product.store?.director?.phone.trim() ?? '';
    final isOwn =
        sessionPhone.isNotEmpty &&
        ((sellerPhone.isNotEmpty && sellerPhone == sessionPhone) ||
            (storePhone.isNotEmpty && storePhone == sessionPhone));
    if (isOwn) {
      _showSnack("O'zingizning mahsulotingizni sotib ololmaysiz");
      return;
    }
    final qty = product.cartQty > 0 ? product.cartQty + 1 : 1;
    try {
      final serverQty = await _productApi.addToCart(product.id, qty: qty);
      if (!mounted) return;
      widget.onSummaryChanged?.call();
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
    widget.onSummaryChanged?.call();
    _loadProducts();
  }

  @override
  Widget build(BuildContext context) {
    const primaryGreen = Color(0xFF1F5A50);

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.fromLTRB(14, 10, 14, 10),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(26),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.10),
                  blurRadius: 22,
                  offset: const Offset(0, 10),
                ),
              ],
              border: Border.all(color: Colors.black.withOpacity(0.05)),
            ),
            child: Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: primaryGreen,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: Image.asset('assets/logo.jpg', fit: BoxFit.cover),
                ),
                const SizedBox(width: 10),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'Rello Market',
                        style: TextStyle(
                          color: primaryGreen,
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      SizedBox(height: 2),
                      Text(
                        'Online shop',
                        style: TextStyle(
                          color: Color(0xFF8A9A97),
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                if (widget.showSearch) ...[
                  _HeaderIconButton(
                    icon: Icons.search,
                    onTap: () => setState(() => _showSearch = !_showSearch),
                  ),
                  const SizedBox(width: 10),
                ],
                _HeaderIconButton(
                  onTap: _openLanguageSheet,
                  child: _LangFlag(
                    assetPath: _selectedLang == "UZ"
                        ? 'assets/uz.png'
                        : 'assets/en.png',
                  ),
                ),
              ],
            ),
          ),

          if (widget.showSearch)
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 180),
              switchInCurve: Curves.easeOutCubic,
              switchOutCurve: Curves.easeInCubic,
              transitionBuilder: (child, animation) {
                final slide = Tween<Offset>(
                  begin: const Offset(0, -0.08),
                  end: Offset.zero,
                ).animate(animation);
                return SizeTransition(
                  sizeFactor: animation,
                  axisAlignment: -1,
                  child: FadeTransition(
                    opacity: animation,
                    child: SlideTransition(position: slide, child: child),
                  ),
                );
              },
              child: _showSearch
                  ? Padding(
                      padding: const EdgeInsets.only(top: 10),
                      child: Container(
                        height: 46,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.06),
                              blurRadius: 10,
                              offset: const Offset(0, 6),
                            ),
                          ],
                        ),
                        child: TextField(
                          cursorColor: primaryGreen,
                          style: const TextStyle(
                            color: primaryGreen,
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                          decoration: InputDecoration(
                            hintText: 'Mahsulot qidirish...',
                            hintStyle: TextStyle(
                              color: primaryGreen.withOpacity(0.5),
                            ),
                            prefixIcon: const Icon(
                              Icons.search,
                              color: primaryGreen,
                            ),
                            filled: true,
                            fillColor: Colors.white,
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 14,
                            ),
                            isDense: true,
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(16),
                              borderSide: BorderSide(
                                color: primaryGreen.withOpacity(0.12),
                                width: 1,
                              ),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(16),
                              borderSide: const BorderSide(
                                color: primaryGreen,
                                width: 1.2,
                              ),
                            ),
                          ),
                        ),
                      ),
                    )
                  : const SizedBox.shrink(),
            ),

          if (widget.showContent) ...[
            const SizedBox(height: 20),

            if (_carouselProducts.isNotEmpty)
              SizedBox(
                height: 180,
                child: PageView.builder(
                  controller: _ensureCarousel(),
                  itemCount: _carouselProducts.length,
                  padEnds: false,
                  clipBehavior: Clip.hardEdge,
                  onPageChanged: (index) {
                    setState(() => _carouselIndex = index);
                  },
                  itemBuilder: (context, index) {
                    final item = _carouselProducts[index];
                    return _CarouselCard(
                      item: item,
                      onTap: () => _openProductDetail(item),
                    );
                  },
                ),
              ),

            if (_carouselProducts.isNotEmpty) const SizedBox(height: 8),

            if (_carouselProducts.isNotEmpty)
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(_carouselProducts.length, (index) {
                  final active = index == _carouselIndex;
                  return AnimatedContainer(
                    duration: const Duration(milliseconds: 250),
                    margin: const EdgeInsets.symmetric(horizontal: 3),
                    width: active ? 16 : 6,
                    height: 6,
                    decoration: BoxDecoration(
                      color: active
                          ? primaryGreen
                          : primaryGreen.withOpacity(0.25),
                      borderRadius: BorderRadius.circular(6),
                    ),
                  );
                }),
              ),

            const SizedBox(height: 14),

            SizedBox(
              height: 42,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: _categories.length + 1,
                separatorBuilder: (_, __) => const SizedBox(width: 10),
                itemBuilder: (context, index) {
                  if (index == 0) {
                    return _CategoryChip(
                      name: 'Barchasi',
                      selected: _selectedCategoryId == null,
                      onTap: () => _selectCategory(null),
                    );
                  }
                  final c = _categories[index - 1];
                  return _CategoryChip(
                    name: c.name,
                    icon: c.icon,
                    selected: c.id == _selectedCategoryId,
                    onTap: () => _selectCategory(c.id),
                  );
                },
              ),
            ),

            const SizedBox(height: 16),

            if (_isLoadingProducts)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 28),
                child: Center(
                  child: CircularProgressIndicator(color: primaryGreen),
                ),
              )
            else if (_productsError != null)
              _ProductsStateCard(
                message: _productsError!,
                onRetry: _loadProducts,
              )
            else if (_products.isEmpty)
              _ProductsStateCard(
                message: 'Mahsulotlar topilmadi',
                onRetry: _loadProducts,
              )
            else
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _products.length,
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  mainAxisSpacing: 12,
                  crossAxisSpacing: 12,
                  childAspectRatio: 0.58,
                ),
                itemBuilder: (context, index) {
                  final p = _products[index];
                  return ProductCard(
                    item: p,
                    onTap: () => _openProductDetail(p),
                    onLike: () => _toggleLike(p),
                    onAddToCart: () => _addToCart(p),
                    imageHeight: 130,
                  );
                },
              ),
          ],
        ],
      ),
    );
  }

  void _startCarousel() {
    _carouselTimer?.cancel();
    if (_carouselProducts.isEmpty) return;
    _carouselTimer = Timer.periodic(const Duration(seconds: 4), (_) {
      if (!mounted) return;
      if (_carouselController == null) return;
      if (_carouselProducts.isEmpty) return;
      final next = (_carouselIndex + 1) % _carouselProducts.length;
      _carouselController!.animateToPage(
        next,
        duration: const Duration(milliseconds: 450),
        curve: Curves.easeOutCubic,
      );
    });
  }

  PageController _ensureCarousel() {
    if (_carouselController == null ||
        _carouselController!.viewportFraction != 1.0) {
      _carouselController?.dispose();
      _carouselController = PageController(viewportFraction: 1.0);
    }
    _startCarousel();
    return _carouselController!;
  }
}

class _LangFlag extends StatelessWidget {
  final String assetPath;

  const _LangFlag({required this.assetPath});

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(4),
      child: Image.asset(
        assetPath,
        width: 26,
        height: 18,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) {
          return Container(
            width: 26,
            height: 18,
            color: const Color(0xFFE6E9E8),
            alignment: Alignment.center,
            child: const Text(
              'UZ',
              style: TextStyle(
                color: Color(0xFF1F5A50),
                fontSize: 8,
                fontWeight: FontWeight.w700,
              ),
            ),
          );
        },
      ),
    );
  }
}

class _HeaderIconButton extends StatelessWidget {
  final IconData? icon;
  final Widget? child;
  final VoidCallback onTap;

  const _HeaderIconButton({this.icon, this.child, required this.onTap});

  @override
  Widget build(BuildContext context) {
    const primaryGreen = Color(0xFF1F5A50);
    return InkWell(
      borderRadius: BorderRadius.circular(20),
      onTap: onTap,
      child: Container(
        width: 48,
        height: 48,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.black.withOpacity(0.08)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.08),
              blurRadius: 12,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Center(
          child: icon != null
              ? Icon(icon, color: primaryGreen, size: 24)
              : SizedBox(
                  width: 28,
                  height: 20,
                  child: FittedBox(fit: BoxFit.contain, child: child),
                ),
        ),
      ),
    );
  }
}

class _LangOption extends StatelessWidget {
  final String label;
  final String value;
  final bool selected;
  final VoidCallback onTap;

  const _LangOption({
    required this.label,
    required this.value,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    const primaryGreen = Color(0xFF1F5A50);
    const lightGreen = Color(0xFFE6F4EF);

    return InkWell(
      borderRadius: BorderRadius.circular(14),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        decoration: BoxDecoration(
          color: selected ? lightGreen : Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: primaryGreen.withOpacity(0.2), width: 1),
        ),
        child: Row(
          children: [
            _LangFlag(
              assetPath: value == "UZ" ? 'assets/uz.png' : 'assets/en.png',
            ),
            const SizedBox(width: 10),
            Text(
              label,
              style: const TextStyle(
                color: primaryGreen,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
            const Spacer(),
            if (selected)
              const Icon(Icons.check, color: primaryGreen, size: 18),
          ],
        ),
      ),
    );
  }
}

class _CarouselCard extends StatelessWidget {
  final Product item;
  final VoidCallback onTap;

  const _CarouselCard({required this.item, required this.onTap});

  String _truncateWords(String text, {int maxWords = 5}) {
    final words = text
        .trim()
        .split(RegExp(r'\s+'))
        .where((word) => word.isNotEmpty)
        .toList();
    if (words.length <= maxWords) return words.join(' ');
    return '${words.take(maxWords).join(' ')}...';
  }

  @override
  Widget build(BuildContext context) {
    final shortDescription = _truncateWords(item.description, maxWords: 5);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 0),
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: onTap,
        child: Container(
          decoration: BoxDecoration(borderRadius: BorderRadius.circular(20)),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: Stack(
              children: [
                Positioned.fill(
                  child: ProductImage(
                    path: item.resolvedImagePath,
                    height: 180,
                  ),
                ),
                Positioned.fill(
                  child: Container(
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.bottomCenter,
                        end: Alignment.topCenter,
                        colors: [
                          Color(0xCC000000),
                          Color(0x22000000),
                          Color(0x00000000),
                        ],
                      ),
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
                      Text(
                        item.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        shortDescription,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 12,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.45),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          item.formattedPrice,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _CategoryIcon extends StatelessWidget {
  final String icon;
  final bool selected;

  const _CategoryIcon({required this.icon, required this.selected});

  @override
  Widget build(BuildContext context) {
    final iconColor = selected ? Colors.white : const Color(0xFF2E7D6F);
    if (icon.isEmpty) {
      return Icon(Icons.grid_view_rounded, color: iconColor, size: 14);
    }
    return Icon(categoryIconOf(icon), color: iconColor, size: 14);
  }
}

class _CategoryChip extends StatelessWidget {
  final String name;
  final String icon;
  final bool selected;
  final VoidCallback onTap;

  const _CategoryChip({
    required this.name,
    this.icon = '',
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    const primaryGreen = Color(0xFF1F5A50);

    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: selected ? const Color(0xFF1F5A50) : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: selected
                ? const Color(0xFF1F5A50)
                : primaryGreen.withOpacity(0.15),
            width: 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _CategoryIcon(icon: icon, selected: selected),
            const SizedBox(width: 6),
            Text(
              name,
              style: TextStyle(
                color: selected ? Colors.white : const Color(0xFF1F5A50),
                fontSize: 11,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ProductsStateCard extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _ProductsStateCard({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    const primaryGreen = Color(0xFF1F5A50);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: primaryGreen.withOpacity(0.12)),
      ),
      child: Column(
        children: [
          Text(
            message,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: primaryGreen,
              fontSize: 14,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 10),
          TextButton.icon(
            onPressed: onRetry,
            icon: const Icon(Icons.refresh_rounded, size: 18),
            label: const Text('Qayta urinish'),
            style: TextButton.styleFrom(foregroundColor: primaryGreen),
          ),
        ],
      ),
    );
  }
}
