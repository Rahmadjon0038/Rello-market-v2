import 'package:flutter/material.dart';
import 'dart:io';
import 'package:hello_flutter_app/models/category.dart';
import 'package:hello_flutter_app/models/product.dart';
import 'package:hello_flutter_app/models/store_summary.dart';
import 'package:hello_flutter_app/screens/product_detail_screen.dart';
import 'package:hello_flutter_app/screens/public_store_detail_screen.dart';
import 'package:hello_flutter_app/services/auth_api_service.dart';
import 'package:hello_flutter_app/services/product_api_service.dart';
import 'package:hello_flutter_app/widgets/product_card.dart';
import 'package:image_picker/image_picker.dart';

class StoreProductsScreen extends StatefulWidget {
  final String storeId;
  final bool allowManage;

  const StoreProductsScreen({
    super.key,
    required this.storeId,
    this.allowManage = false,
  });

  @override
  State<StoreProductsScreen> createState() => _StoreProductsScreenState();
}

class _StoreProductsScreenState extends State<StoreProductsScreen> {
  final ProductApiService _productApi = ProductApiService();
  final AuthApiService _authApi = AuthApiService();
  StoreSummary? _store;
  List<Product> _products = [];
  bool _isLoading = true;
  String? _error;
  bool _isSeller = false;
  bool _canManageStore = false;
  AuthSession? _session;

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    await _loadRole();
    await _load();
  }

  Future<void> _loadRole() async {
    final session = await _authApi.loadSavedSession();
    if (!mounted) return;
    setState(() {
      _session = session;
      _isSeller = session?.role == 'seller';
    });
  }

  Future<void> _load() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final response = await _productApi.getStoreProducts(widget.storeId);
      final canManage =
          _isSeller &&
          (_session?.phone.isNotEmpty == true) &&
          (response.store.director?.phone.isNotEmpty == true) &&
          (response.store.director!.phone == _session!.phone);
      if (!mounted) return;
      setState(() {
        _store = response.store;
        _products = response.products;
        _canManageStore = canManage;
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
        _error = "Do'kon mahsulotlarini yuklab bo'lmadi";
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
    _load();
  }

  Future<void> _openStoreDetails() async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => PublicStoreDetailScreen(
          storeId: widget.storeId,
          initialStore: _store,
        ),
      ),
    );
    if (!mounted) return;
    _load();
  }

  Future<void> _toggleLike(Product product) async {
    final idx = _products.indexWhere((item) => item.id == product.id);
    if (idx == -1) return;
    final nextLiked = !product.isLiked;
    setState(() => _products[idx] = product.copyWith(isLiked: nextLiked));
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
      _showSnack("Server bilan bog'lanib bo'lmadi");
    }
  }

  Future<void> _addToCart(Product product) async {
    if (_canManageStore) {
      _showSnack("O'zingizning do'koningiz mahsulotini sotib ololmaysiz");
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
      _showSnack("Mahsulot savatchaga qo'shildi");
    } on AuthApiException catch (error) {
      _showSnack(error.message);
    } on Object {
      _showSnack("Server bilan bog'lanib bo'lmadi");
    }
  }

  void _restoreProduct(Product product) {
    final idx = _products.indexWhere((item) => item.id == product.id);
    if (idx == -1) return;
    setState(() => _products[idx] = product);
  }

  void _showSnack(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), duration: const Duration(seconds: 2)),
    );
  }

  Future<void> _openCreateProduct() async {
    if (!widget.allowManage || !_canManageStore) {
      _showSnack("Bu do'konga mahsulot qo'sha olmaysiz");
      return;
    }
    final created = await showModalBottomSheet<bool>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) =>
          _CreateProductSheet(storeId: widget.storeId, productApi: _productApi),
    );
    if (!mounted) return;
    if (created == true) {
      _showSnack("Mahsulot qo'shildi");
      _load();
    }
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
        title: Text(
          _store?.name.isNotEmpty == true ? _store!.name : "Do'kon",
          style: const TextStyle(fontWeight: FontWeight.w900),
        ),
        actions: [
          if (widget.allowManage && _canManageStore)
            IconButton(
              onPressed: _openCreateProduct,
              icon: const Icon(Icons.add_box_rounded),
              tooltip: "Mahsulot qo'shish",
            ),
        ],
      ),
      floatingActionButton: widget.allowManage && _canManageStore
          ? FloatingActionButton.extended(
              onPressed: _openCreateProduct,
              backgroundColor: primaryGreen,
              foregroundColor: Colors.white,
              icon: const Icon(Icons.add_rounded),
              label: const Text(
                "Mahsulot qo'shish",
                style: TextStyle(fontWeight: FontWeight.w900),
              ),
            )
          : null,
      body: SafeArea(
        child: _isLoading
            ? const Center(
                child: CircularProgressIndicator(color: primaryGreen),
              )
            : _error != null
            ? _StoreState(message: _error!, onRetry: _load)
            : RefreshIndicator(
                color: primaryGreen,
                onRefresh: _load,
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                  children: [
                    if (_store != null)
                      _StoreHeader(
                        store: _store!,
                        onDetailsTap: _openStoreDetails,
                      ),
                    const SizedBox(height: 18),
                    const Text(
                      'Mahsulotlar',
                      style: TextStyle(
                        color: primaryGreen,
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    if (widget.allowManage &&
                        _isSeller &&
                        !_canManageStore) ...[
                      const SizedBox(height: 6),
                      Text(
                        "Siz bu do'konga mahsulot qo'sha olmaysiz",
                        style: TextStyle(
                          color: primaryGreen.withValues(alpha: 0.65),
                          fontWeight: FontWeight.w700,
                          fontSize: 12,
                        ),
                      ),
                    ],
                    const SizedBox(height: 12),
                    if (_products.isEmpty)
                      _StoreState(
                        message: "Bu do'konda mahsulotlar topilmadi",
                        onRetry: _load,
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
                              childAspectRatio: 0.58,
                            ),
                        itemBuilder: (context, index) {
                          final product = _products[index];
                          return ProductCard(
                            item: product,
                            onTap: () => _openProduct(product),
                            onLike: () => _toggleLike(product),
                            onAddToCart: _canManageStore
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

class _StoreHeader extends StatelessWidget {
  final StoreSummary store;
  final VoidCallback onDetailsTap;

  const _StoreHeader({required this.store, required this.onDetailsTap});

  @override
  Widget build(BuildContext context) {
    const primaryGreen = Color(0xFF1F5A50);
    final imageUrl = store.imagePath.trim();

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFE6F4EF),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: primaryGreen.withValues(alpha: 0.12)),
      ),
      child: Column(
        children: [
          Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(999),
                child: Container(
                  width: 60,
                  height: 60,
                  color: Colors.white,
                  child: imageUrl.isEmpty
                      ? const Icon(
                          Icons.storefront_rounded,
                          color: primaryGreen,
                        )
                      : Image.network(
                          Product.resolveImagePath(imageUrl),
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) =>
                              const Icon(
                                Icons.storefront_rounded,
                                color: primaryGreen,
                              ),
                        ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      "Do'kon",
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: Color(0xFF6F8982),
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      store.name.isEmpty ? "Do'kon" : store.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: primaryGreen,
                        fontSize: 16,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      store.activityType.isEmpty ? "-" : store.activityType,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: primaryGreen.withValues(alpha: 0.7),
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton.icon(
              onPressed: onDetailsTap,
              icon: const Icon(Icons.info_outline_rounded, size: 18),
              label: const Text("Do'kon ma'lumotlari"),
              style: TextButton.styleFrom(
                foregroundColor: primaryGreen,
                padding: EdgeInsets.zero,
                minimumSize: const Size(0, 34),
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                textStyle: const TextStyle(fontWeight: FontWeight.w900),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _StoreState extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _StoreState({required this.message, required this.onRetry});

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
    );
  }
}

class _CreateProductSheet extends StatefulWidget {
  final String storeId;
  final ProductApiService productApi;

  const _CreateProductSheet({required this.storeId, required this.productApi});

  @override
  State<_CreateProductSheet> createState() => _CreateProductSheetState();
}

class _CreateProductSheetState extends State<_CreateProductSheet> {
  final _nameCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  final _priceCtrl = TextEditingController();
  final _qtyCtrl = TextEditingController(text: '1');
  final _brandCtrl = TextEditingController();
  final ImagePicker _picker = ImagePicker();
  List<File> _imageFiles = [];

  List<CategoryModel> _categories = const [];
  CategoryModel? _selectedCategory;
  bool _isLoading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadCategories();
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _descCtrl.dispose();
    _priceCtrl.dispose();
    _qtyCtrl.dispose();
    _brandCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadCategories() async {
    try {
      final categories = await widget.productApi.getCategories();
      if (!mounted) return;
      setState(() {
        _categories = categories;
        _selectedCategory = categories.isNotEmpty ? categories.first : null;
      });
    } on Object {
      // Categories are optional for UI; keep empty state.
    }
  }

  Future<void> _pickImages() async {
    if (_isLoading) return;
    final picked = await _picker.pickMultiImage(imageQuality: 85);
    if (picked.isEmpty || !mounted) return;
    setState(() {
      final next = [..._imageFiles, ...picked.map((item) => File(item.path))];
      _imageFiles = next.length > 6 ? next.sublist(0, 6) : next;
      _error = null;
    });
  }

  Future<void> _submit() async {
    final name = _nameCtrl.text.trim();
    final desc = _descCtrl.text.trim();
    final price = int.tryParse(_priceCtrl.text.trim()) ?? -1;
    final qty = int.tryParse(_qtyCtrl.text.trim()) ?? -1;
    final brand = _brandCtrl.text.trim();
    final categoryId = _selectedCategory?.id ?? '';

    if (name.isEmpty) {
      setState(() => _error = "Mahsulot nomi majburiy");
      return;
    }
    if (desc.isEmpty) {
      setState(() => _error = "Tavsif majburiy");
      return;
    }
    if (price < 0) {
      setState(() => _error = "Narx noto'g'ri");
      return;
    }
    if (qty <= 0) {
      setState(() => _error = "Soni (qty) 1 yoki undan katta bo'lishi kerak");
      return;
    }
    if (categoryId.isEmpty) {
      setState(() => _error = "Category tanlang");
      return;
    }
    if (_imageFiles.isEmpty) {
      setState(() => _error = "Mahsulot uchun kamida 1 ta rasm tanlang");
      return;
    }

    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      await widget.productApi.createProductMultipart(
        fields: {
          'storeId': widget.storeId,
          'name': name,
          'description': desc,
          'price': price,
          'qty': qty,
          'categoryId': categoryId,
          if (brand.isNotEmpty) 'brand': brand,
        },
        images: _imageFiles,
      );
      if (!mounted) return;
      Navigator.of(context).pop(true);
    } on AuthApiException catch (error) {
      if (!mounted) return;
      setState(() => _error = error.message);
    } on Object {
      if (!mounted) return;
      setState(() => _error = "Server bilan bog'lanib bo'lmadi");
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    const primaryGreen = Color(0xFF1F5A50);
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return SafeArea(
      child: AnimatedPadding(
        duration: const Duration(milliseconds: 150),
        curve: Curves.easeOut,
        padding: EdgeInsets.fromLTRB(16, 8, 16, 16 + bottomInset),
        child: SingleChildScrollView(
          keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Expanded(
                    child: Text(
                      "Mahsulot qo'shish",
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(false),
                    icon: const Icon(Icons.close_rounded),
                    tooltip: 'Yopish',
                  ),
                ],
              ),
              if (_error != null) ...[
                const SizedBox(height: 6),
                Text(
                  _error!,
                  style: const TextStyle(
                    color: Colors.redAccent,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
              const SizedBox(height: 10),
              _Field(label: 'Nomi', controller: _nameCtrl),
              const SizedBox(height: 10),
              _Field(label: 'Tavsif', controller: _descCtrl, maxLines: 3),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: _Field(
                      label: 'Narx (so‘m)',
                      controller: _priceCtrl,
                      keyboardType: TextInputType.number,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _Field(
                      label: 'Soni (qty)',
                      controller: _qtyCtrl,
                      keyboardType: TextInputType.number,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              _Field(label: 'Brand', controller: _brandCtrl),
              const SizedBox(height: 10),
              Text(
                'Kategoriya',
                style: TextStyle(
                  color: primaryGreen.withValues(alpha: 0.7),
                  fontWeight: FontWeight.w800,
                  fontSize: 12,
                ),
              ),
              const SizedBox(height: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                decoration: BoxDecoration(
                  color: const Color(0xFFF7F8FA),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: primaryGreen.withValues(alpha: 0.12),
                  ),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<CategoryModel>(
                    isExpanded: true,
                    value: _selectedCategory,
                    items: _categories
                        .map(
                          (c) => DropdownMenuItem(
                            value: c,
                            child: Text(
                              c.name.isEmpty ? c.id : c.name,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        )
                        .toList(),
                    onChanged: (v) => setState(() => _selectedCategory = v),
                  ),
                ),
              ),
              const SizedBox(height: 10),
              Text(
                'Rasmlar (1–6)',
                style: TextStyle(
                  color: primaryGreen.withValues(alpha: 0.7),
                  fontWeight: FontWeight.w800,
                  fontSize: 12,
                ),
              ),
              const SizedBox(height: 6),
              Row(
                children: [
                  Expanded(
                    child: SizedBox(
                      height: 44,
                      child: OutlinedButton.icon(
                        onPressed: _isLoading ? null : _pickImages,
                        icon: const Icon(Icons.photo_library_rounded, size: 18),
                        label: Text(
                          _imageFiles.isEmpty
                              ? 'Galereyadan tanlash'
                              : "Tanlandi: ${_imageFiles.length}",
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: primaryGreen,
                          side: BorderSide(
                            color: primaryGreen.withValues(alpha: 0.22),
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ),
                  ),
                  if (_imageFiles.isNotEmpty) ...[
                    const SizedBox(width: 10),
                    TextButton(
                      onPressed: _isLoading
                          ? null
                          : () => setState(() => _imageFiles = []),
                      child: const Text("Tozalash"),
                    ),
                  ],
                ],
              ),
              if (_imageFiles.isNotEmpty) ...[
                const SizedBox(height: 10),
                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: [
                    for (final file in _imageFiles)
                      SizedBox(
                        width: 72,
                        child: Stack(
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(12),
                              child: Image.file(
                                file,
                                width: 72,
                                height: 72,
                                fit: BoxFit.cover,
                              ),
                            ),
                            Positioned(
                              top: 4,
                              right: 4,
                              child: InkWell(
                                onTap: _isLoading
                                    ? null
                                    : () => setState(() {
                                        _imageFiles = _imageFiles
                                            .where((item) => item != file)
                                            .toList();
                                      }),
                                child: DecoratedBox(
                                  decoration: BoxDecoration(
                                    color: Colors.white.withValues(alpha: 0.92),
                                    borderRadius: BorderRadius.circular(999),
                                    border: Border.all(
                                      color: primaryGreen.withValues(
                                        alpha: 0.14,
                                      ),
                                    ),
                                  ),
                                  child: const Padding(
                                    padding: EdgeInsets.all(4),
                                    child: Icon(
                                      Icons.close_rounded,
                                      size: 16,
                                      color: primaryGreen,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ],
              const SizedBox(height: 14),
              SizedBox(
                height: 48,
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _isLoading ? null : _submit,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryGreen,
                    foregroundColor: Colors.white,
                    disabledBackgroundColor: primaryGreen.withValues(
                      alpha: 0.7,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  icon: _isLoading
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.2,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              Colors.white,
                            ),
                          ),
                        )
                      : const Icon(Icons.cloud_upload_rounded),
                  label: const Text(
                    'Yuklash',
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.w900),
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

class _Field extends StatelessWidget {
  final String label;
  final TextEditingController controller;
  final int maxLines;
  final TextInputType? keyboardType;

  const _Field({
    required this.label,
    required this.controller,
    this.maxLines = 1,
    this.keyboardType,
  });

  @override
  Widget build(BuildContext context) {
    const primaryGreen = Color(0xFF1F5A50);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            color: primaryGreen.withValues(alpha: 0.7),
            fontWeight: FontWeight.w800,
            fontSize: 12,
          ),
        ),
        const SizedBox(height: 6),
        TextField(
          controller: controller,
          maxLines: maxLines,
          keyboardType: keyboardType,
          decoration: InputDecoration(
            filled: true,
            fillColor: const Color(0xFFF7F8FA),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: primaryGreen.withValues(alpha: 0.12),
              ),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: primaryGreen.withValues(alpha: 0.12),
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: primaryGreen, width: 1.2),
            ),
          ),
        ),
      ],
    );
  }
}
