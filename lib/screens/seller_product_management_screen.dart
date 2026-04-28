import 'package:flutter/material.dart';
import 'dart:io';
import 'package:hello_flutter_app/models/category.dart';
import 'package:hello_flutter_app/models/product.dart';
import 'package:hello_flutter_app/services/auth_api_service.dart';
import 'package:hello_flutter_app/services/product_api_service.dart';
import 'package:image_picker/image_picker.dart';

class SellerProductManagementScreen extends StatefulWidget {
  final String storeId;

  const SellerProductManagementScreen({super.key, required this.storeId});

  @override
  State<SellerProductManagementScreen> createState() =>
      _SellerProductManagementScreenState();
}

class _SellerProductManagementScreenState
    extends State<SellerProductManagementScreen> {
  static const _primaryGreen = Color(0xFF1F5A50);

  final ProductApiService _productApi = ProductApiService();
  final _CreateProductDraft _createDraft = _CreateProductDraft();
  final _statuses = const <String, String>{
    'all': 'Barchasi',
    'active': 'Faol',
    'inactive': 'Faolsiz',
  };

  List<Product> _items = [];
  bool _isLoading = true;
  String? _error;
  String _status = 'all';

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
      final items = await _productApi.getMyProducts(
        storeId: widget.storeId,
        status: _status,
      );
      if (!mounted) return;
      setState(() {
        _items = items;
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
        _error = "Mahsulotlarni yuklab bo'lmadi";
        _isLoading = false;
      });
    }
  }

  void _snack(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _create() async {
    final created = await showModalBottomSheet<bool>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => _CreateProductSheet(
        storeId: widget.storeId,
        productApi: _productApi,
        draft: _createDraft,
      ),
    );
    if (!mounted) return;
    if (created == true) {
      _snack("Mahsulot qo'shildi");
      _createDraft.clear();
      _load();
    }
  }

  Future<void> _edit(Product product) async {
    final updated = await showModalBottomSheet<bool>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) =>
          _EditProductSheet(productId: product.id, productApi: _productApi),
    );
    if (!mounted) return;
    if (updated == true) {
      _snack("Mahsulot yangilandi");
      _load();
    }
  }

  Future<void> _toggleActive(Product product) async {
    try {
      if (product.isActive) {
        await _productApi.deactivateProduct(product.id);
        _snack("Mahsulot faolsizlantirildi");
      } else {
        await _productApi.activateProduct(product.id);
        _snack("Mahsulot faollashtirildi");
      }
      _load();
    } on AuthApiException catch (error) {
      _snack(error.message);
    } on Object {
      _snack("Server bilan bog'lanib bo'lmadi");
    }
  }

  Future<void> _delete(Product product) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text("O'chirish"),
          content: Text(
            "'${product.name.trim().isEmpty ? 'Mahsulot' : product.name.trim()}' o'chirilsinmi?",
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Bekor'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text("O'chirish"),
            ),
          ],
        );
      },
    );
    if (ok != true) return;
    try {
      await _productApi.deleteProduct(product.id);
      _snack("Mahsulot o'chirildi");
      _load();
    } on AuthApiException catch (error) {
      _snack(error.message);
    } on Object {
      _snack("Server bilan bog'lanib bo'lmadi");
    }
  }

  Widget _statusChips() {
    Widget chip(String value, String label) {
      final selected = _status == value;
      return ChoiceChip(
        selected: selected,
        label: Text(label),
        onSelected: (v) {
          if (!v) return;
          setState(() => _status = value);
          _load();
        },
        selectedColor: _primaryGreen.withValues(alpha: 0.12),
        labelStyle: TextStyle(
          color: selected
              ? _primaryGreen
              : _primaryGreen.withValues(alpha: 0.75),
          fontWeight: FontWeight.w900,
        ),
        side: BorderSide(color: _primaryGreen.withValues(alpha: 0.18)),
        backgroundColor: const Color(0xFFF7F8FA),
        showCheckmark: false,
      );
    }

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        for (final entry in _statuses.entries) chip(entry.key, entry.value),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        foregroundColor: _primaryGreen,
        elevation: 0,
        title: const Text(
          'Mahsulotlar',
          style: TextStyle(fontWeight: FontWeight.w900),
        ),
        actions: [
          _RoundedActionButton(
            onTap: _create,
            icon: Icons.add_rounded,
            tooltip: "Mahsulot qo'shish",
          ),
          const SizedBox(width: 8),
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: _RoundedActionButton(
              onTap: _load,
              icon: Icons.refresh_rounded,
              tooltip: 'Yangilash',
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: _isLoading
            ? const Center(
                child: CircularProgressIndicator(color: _primaryGreen),
              )
            : _error != null
            ? _StateCard(message: _error!, onRetry: _load)
            : RefreshIndicator(
                color: _primaryGreen,
                onRefresh: _load,
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
                  children: [
                    _statusChips(),
                    const SizedBox(height: 12),
                    if (_items.isEmpty)
                      _StateCard(
                        message: 'Mahsulotlar topilmadi',
                        onRetry: _load,
                      )
                    else
                      ..._items.map(
                        (p) => Padding(
                          padding: const EdgeInsets.only(bottom: 10),
                          child: _SellerProductRow(
                            product: p,
                            onEdit: () => _edit(p),
                            onToggleActive: () => _toggleActive(p),
                            onDelete: () => _delete(p),
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

class _RoundedActionButton extends StatelessWidget {
  final VoidCallback onTap;
  final IconData icon;
  final String tooltip;

  const _RoundedActionButton({
    required this.onTap,
    required this.icon,
    required this.tooltip,
  });

  @override
  Widget build(BuildContext context) {
    const primaryGreen = Color(0xFF1F5A50);
    return Tooltip(
      message: tooltip,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: onTap,
          child: Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: primaryGreen.withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: primaryGreen.withValues(alpha: 0.12)),
            ),
            alignment: Alignment.center,
            child: Icon(icon, color: primaryGreen, size: 26),
          ),
        ),
      ),
    );
  }
}

class _CreateProductDraft {
  String name = '';
  String description = '';
  String price = '';
  String qty = '1';
  String brand = '';
  String categoryId = '';
  final List<File> images = [];

  void clear() {
    name = '';
    description = '';
    price = '';
    qty = '1';
    brand = '';
    categoryId = '';
    images.clear();
  }
}

class _SellerProductRow extends StatelessWidget {
  final Product product;
  final VoidCallback onEdit;
  final VoidCallback onToggleActive;
  final VoidCallback onDelete;

  const _SellerProductRow({
    required this.product,
    required this.onEdit,
    required this.onToggleActive,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    const primaryGreen = Color(0xFF1F5A50);
    final imageUrl = product.resolvedImagePath;
    final images = product.resolvedImages.isNotEmpty
        ? product.resolvedImages
        : [imageUrl];
    final name = product.name.trim().isEmpty ? 'Mahsulot' : product.name.trim();
    final description = product.description.trim();
    final statusColor = product.isActive
        ? const Color(0xFF1F5A50)
        : const Color(0xFF9A3412);
    final priceText = product.price > 0 ? product.formattedPrice : '-';
    final totalText = product.price > 0 && product.qty > 0
        ? _formatMoney(product.price * product.qty)
        : '-';

    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: primaryGreen.withValues(alpha: 0.12)),
        ),
        child: Row(
          children: [
            GestureDetector(
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    fullscreenDialog: true,
                    builder: (_) => _ImageGalleryPreview(images: images),
                  ),
                );
              },
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child:
                    imageUrl.startsWith('http://') ||
                        imageUrl.startsWith('https://')
                    ? Image.network(
                        imageUrl,
                        width: 56,
                        height: 56,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) => Container(
                          width: 56,
                          height: 56,
                          color: const Color(0xFFE6F4EF),
                          alignment: Alignment.center,
                          child: const Icon(
                            Icons.image_not_supported_rounded,
                            color: primaryGreen,
                          ),
                        ),
                      )
                    : Image.asset(
                        imageUrl,
                        width: 56,
                        height: 56,
                        fit: BoxFit.cover,
                      ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: InkWell(
                borderRadius: BorderRadius.circular(12),
                onTap: onEdit,
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 2),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Text(
                              name,
                              style: const TextStyle(
                                color: primaryGreen,
                                fontWeight: FontWeight.w900,
                                fontSize: 14,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 5,
                            ),
                            decoration: BoxDecoration(
                              color: statusColor.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(999),
                            ),
                            child: Text(
                              product.isActive ? 'Faol' : 'Faolsiz',
                              style: TextStyle(
                                color: statusColor,
                                fontWeight: FontWeight.w900,
                                fontSize: 11,
                              ),
                            ),
                          ),
                        ],
                      ),
                      if (description.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Text(
                          description,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: primaryGreen.withValues(alpha: 0.72),
                            fontWeight: FontWeight.w700,
                            fontSize: 12,
                            height: 1.2,
                          ),
                        ),
                      ],
                      const SizedBox(height: 6),
                      Text(
                        priceText,
                        softWrap: true,
                        style: TextStyle(
                          color: primaryGreen.withValues(alpha: 0.75),
                          fontWeight: FontWeight.w800,
                          fontSize: 12,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Mahsulot soni: ${product.qty}',
                        softWrap: true,
                        style: TextStyle(
                          color: primaryGreen.withValues(alpha: 0.65),
                          fontWeight: FontWeight.w700,
                          fontSize: 11,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Umumiy: $totalText',
                        softWrap: true,
                        style: TextStyle(
                          color: primaryGreen.withValues(alpha: 0.65),
                          fontWeight: FontWeight.w700,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
            PopupMenuButton<_SellerProductAction>(
              icon: Icon(
                Icons.more_vert_rounded,
                color: primaryGreen.withValues(alpha: 0.8),
              ),
              onSelected: (action) {
                switch (action) {
                  case _SellerProductAction.edit:
                    onEdit();
                  case _SellerProductAction.toggleActive:
                    onToggleActive();
                  case _SellerProductAction.delete:
                    onDelete();
                }
              },
              itemBuilder: (context) {
                return [
                  const PopupMenuItem(
                    value: _SellerProductAction.edit,
                    child: Text('Tahrirlash'),
                  ),
                  PopupMenuItem(
                    value: _SellerProductAction.toggleActive,
                    child: Text(
                      product.isActive ? 'Faolsizlantirish' : 'Faollashtirish',
                    ),
                  ),
                  const PopupMenuItem(
                    value: _SellerProductAction.delete,
                    child: Text("O'chirish"),
                  ),
                ];
              },
            ),
          ],
        ),
      ),
    );
  }

  String _formatMoney(int value) {
    final s = value.toString();
    final b = StringBuffer();
    for (var i = 0; i < s.length; i++) {
      final idx = s.length - i;
      b.write(s[i]);
      if (idx > 1 && idx % 3 == 1) b.write(' ');
    }
    return '$b so‘m';
  }
}

enum _SellerProductAction { edit, toggleActive, delete }

class _StateCard extends StatelessWidget {
  final String message;
  final Future<void> Function() onRetry;

  const _StateCard({required this.message, required this.onRetry});

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

class _ImageGalleryPreview extends StatefulWidget {
  final List<String> images;
  final int initialIndex;

  const _ImageGalleryPreview({required this.images, this.initialIndex = 0});

  @override
  State<_ImageGalleryPreview> createState() => _ImageGalleryPreviewState();
}

class _ImageGalleryPreviewState extends State<_ImageGalleryPreview> {
  late final PageController _controller;
  late final int _safeInitial;

  @override
  void initState() {
    super.initState();
    final count = widget.images.length;
    _safeInitial = widget.initialIndex < 0
        ? 0
        : widget.initialIndex >= count
        ? (count == 0 ? 0 : count - 1)
        : widget.initialIndex;
    _controller = PageController(initialPage: _safeInitial);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Stack(
          children: [
            if (widget.images.isEmpty)
              const Center(
                child: Text(
                  'Rasm topilmadi',
                  style: TextStyle(color: Colors.white),
                ),
              )
            else
              PageView.builder(
                controller: _controller,
                itemCount: widget.images.length,
                itemBuilder: (context, index) {
                  final path = widget.images[index];
                  return Center(
                    child: InteractiveViewer(
                      child:
                          path.startsWith('http://') ||
                              path.startsWith('https://')
                          ? Image.network(path)
                          : Image.asset(path),
                    ),
                  );
                },
              ),
            Positioned(
              top: 12,
              right: 12,
              child: IconButton(
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.close, color: Colors.white),
              ),
            ),
            if (widget.images.isNotEmpty)
              Positioned(
                bottom: 14,
                left: 0,
                right: 0,
                child: Center(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.45),
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      child: AnimatedBuilder(
                        animation: _controller,
                        builder: (context, _) {
                          final page = _controller.hasClients
                              ? (_controller.page ??
                                    _controller.initialPage.toDouble())
                              : _safeInitial.toDouble();
                          final current = page.round().clamp(
                            0,
                            widget.images.length - 1,
                          );
                          return Text(
                            '${current + 1}/${widget.images.length}',
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w700,
                            ),
                          );
                        },
                      ),
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

class _EditProductSheet extends StatefulWidget {
  final String productId;
  final ProductApiService productApi;

  const _EditProductSheet({required this.productId, required this.productApi});

  @override
  State<_EditProductSheet> createState() => _EditProductSheetState();
}

class _EditProductSheetState extends State<_EditProductSheet> {
  static const _primaryGreen = Color(0xFF1F5A50);

  final _nameCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  final _priceCtrl = TextEditingController();
  final _qtyCtrl = TextEditingController();
  final _brandCtrl = TextEditingController();
  final ImagePicker _picker = ImagePicker();
  List<String> _currentImages = const [];
  List<String> _currentImagesRaw = const [];
  List<String> _initialImagesRaw = const [];
  List<File> _newImages = [];
  final List<String> _removedImages = [];
  bool _orderChanged = false;

  List<CategoryModel> _categories = [];
  CategoryModel? _selectedCategory;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
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

  Future<void> _load() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final results = await Future.wait([
        widget.productApi.getProduct(widget.productId),
        widget.productApi.getCategories(),
      ]);
      final product = results[0] as Product;
      final categories = results[1] as List<CategoryModel>;
      final rawImages = product.images.isNotEmpty
          ? product.images
          : [product.imagePath];
      final resolvedImages = rawImages.map(Product.resolveImagePath).toList();

      CategoryModel? selected;
      for (final c in categories) {
        if (c.id == product.categoryId) {
          selected = c;
          break;
        }
      }
      selected ??= categories.isNotEmpty ? categories.first : null;

      if (!mounted) return;
      setState(() {
        _categories = categories;
        _nameCtrl.text = product.name;
        _descCtrl.text = product.description;
        _priceCtrl.text = product.price.toString();
        _qtyCtrl.text = product.qty.toString();
        _brandCtrl.text = product.brand;
        _selectedCategory = selected;
        _currentImagesRaw = rawImages;
        _initialImagesRaw = List<String>.from(rawImages);
        _orderChanged = false;
        _currentImages = resolvedImages.isNotEmpty
            ? resolvedImages
            : [product.resolvedImagePath];
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
        _error = "Ma'lumotlarni yuklab bo'lmadi";
        _isLoading = false;
      });
    }
  }

  Future<void> _pickNewImages() async {
    if (_isLoading) return;
    final picked = await _picker.pickMultiImage(imageQuality: 85);
    if (picked.isEmpty || !mounted) return;
    setState(() {
      final next = [..._newImages, ...picked.map((e) => File(e.path))];
      _newImages = next.length > 6 ? next.sublist(0, 6) : next;
      _error = null;
    });
  }

  void _removeNewImageAt(int index) {
    if (_isLoading) return;
    if (index < 0 || index >= _newImages.length) return;
    setState(() => _newImages.removeAt(index));
  }

  void _removeCurrentImageAt(int index) {
    if (_isLoading) return;
    if (index < 0 || index >= _currentImages.length) return;
    setState(() {
      final removedRaw = _currentImagesRaw.removeAt(index);
      _currentImages.removeAt(index);
      _removedImages.add(removedRaw);
    });
  }

  void _reorderCurrentImages(int oldIndex, int newIndex) {
    if (_isLoading) return;
    setState(() {
      if (newIndex > oldIndex) newIndex -= 1;
      final img = _currentImages.removeAt(oldIndex);
      _currentImages.insert(newIndex, img);
      final raw = _currentImagesRaw.removeAt(oldIndex);
      _currentImagesRaw.insert(newIndex, raw);
      _orderChanged = true;
    });
  }

  void _reorderNewImages(int oldIndex, int newIndex) {
    if (_isLoading) return;
    setState(() {
      if (newIndex > oldIndex) newIndex -= 1;
      final file = _newImages.removeAt(oldIndex);
      _newImages.insert(newIndex, file);
    });
  }

  String? _validate() {
    if (_nameCtrl.text.trim().isEmpty) return "Nomi majburiy";
    if (_descCtrl.text.trim().isEmpty) return "Tavsif majburiy";
    final price = int.tryParse(_priceCtrl.text.trim());
    if (price == null || price <= 0) return "Narx noto'g'ri";
    final qty = int.tryParse(_qtyCtrl.text.trim());
    if (qty == null || qty < 0) return "Soni noto'g'ri";
    if (_selectedCategory == null) return "Kategoriya tanlang";
    if (_currentImagesRaw.isEmpty && _newImages.isEmpty) {
      return "Kamida 1 ta rasm bo'lishi kerak";
    }
    return null;
  }

  Future<void> _save() async {
    final err = _validate();
    if (err != null) {
      setState(() => _error = err);
      return;
    }
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final fields = <String, dynamic>{
        'name': _nameCtrl.text.trim(),
        'description': _descCtrl.text.trim(),
        'price': int.parse(_priceCtrl.text.trim()),
        'qty': int.parse(_qtyCtrl.text.trim()),
        'categoryId': _selectedCategory!.id,
        'brand': _brandCtrl.text.trim(),
      };
      final needsMultipart =
          _newImages.isNotEmpty || _removedImages.isNotEmpty || _orderChanged;
      if (needsMultipart) {
        fields['keepImages'] = List<String>.from(_currentImagesRaw);
      }
      if (_removedImages.isNotEmpty) {
        fields['removeImages'] = List<String>.from(_removedImages);
      }
      if (needsMultipart) {
        await widget.productApi.updateProductMultipart(
          widget.productId,
          fields: fields,
          images: _newImages,
        );
      } else {
        await widget.productApi.updateProduct(widget.productId, fields);
      }
      if (!mounted) return;
      Navigator.of(context).pop(true);
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

  InputDecoration _inputDecoration(String label) {
    return InputDecoration(
      labelText: label,
      filled: true,
      fillColor: const Color(0xFFF7F8FA),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: _primaryGreen.withValues(alpha: 0.12)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: _primaryGreen.withValues(alpha: 0.35)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return Padding(
      padding: EdgeInsets.only(bottom: bottomInset),
      child: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
          child: _isLoading
              ? const SizedBox(
                  height: 220,
                  child: Center(
                    child: CircularProgressIndicator(color: _primaryGreen),
                  ),
                )
              : Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Expanded(
                          child: Text(
                            "Mahsulotni tahrirlash",
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ),
                        IconButton(
                          onPressed: () => Navigator.of(context).pop(false),
                          icon: const Icon(Icons.close_rounded),
                        ),
                      ],
                    ),
                    if (_error != null) ...[
                      const SizedBox(height: 8),
                      Text(
                        _error!,
                        style: const TextStyle(
                          color: Color(0xFFB91C1C),
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                    const SizedBox(height: 10),
                    TextField(
                      controller: _nameCtrl,
                      decoration: _inputDecoration('Nomi'),
                      textInputAction: TextInputAction.next,
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      controller: _descCtrl,
                      decoration: _inputDecoration('Tavsif'),
                      minLines: 6,
                      maxLines: null,
                      keyboardType: TextInputType.multiline,
                      textInputAction: TextInputAction.newline,
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _priceCtrl,
                            decoration: _inputDecoration("Narx (so'm)"),
                            keyboardType: TextInputType.number,
                            textInputAction: TextInputAction.next,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: TextField(
                            controller: _qtyCtrl,
                            decoration: _inputDecoration('Soni'),
                            keyboardType: TextInputType.number,
                            textInputAction: TextInputAction.next,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      controller: _brandCtrl,
                      decoration: _inputDecoration('Brend'),
                      textInputAction: TextInputAction.done,
                    ),
                    const SizedBox(height: 10),
                    Text(
                      'Kategoriya',
                      style: TextStyle(
                        color: _primaryGreen.withValues(alpha: 0.7),
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
                          color: _primaryGreen.withValues(alpha: 0.12),
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
                          onChanged: (v) =>
                              setState(() => _selectedCategory = v),
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      'Rasmlar',
                      style: TextStyle(
                        color: _primaryGreen.withValues(alpha: 0.7),
                        fontWeight: FontWeight.w800,
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      "Rasmlar o'rnini almashtirish uchun rasmni bosib ushlab, sudrab qo'ying.",
                      style: TextStyle(
                        color: _primaryGreen.withValues(alpha: 0.6),
                        fontWeight: FontWeight.w700,
                        fontSize: 11,
                        height: 1.2,
                      ),
                    ),
                    const SizedBox(height: 6),
                    SizedBox(
                      height: 44,
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        onPressed: _isLoading ? null : _pickNewImages,
                        icon: const Icon(Icons.photo_library_rounded, size: 18),
                        label: Text(
                          _newImages.isEmpty
                              ? 'Yangi rasmlar tanlash (ixtiyoriy)'
                              : "Tanlandi: ${_newImages.length}",
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: _primaryGreen,
                          side: BorderSide(
                            color: _primaryGreen.withValues(alpha: 0.22),
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ),
                    if (_currentImages.isNotEmpty) ...[
                      const SizedBox(height: 10),
                      SizedBox(
                        height: 76,
                        child: ReorderableListView.builder(
                          scrollDirection: Axis.horizontal,
                          buildDefaultDragHandles: false,
                          padding: EdgeInsets.zero,
                          itemCount: _currentImages.length,
                          onReorder: _reorderCurrentImages,
                          itemBuilder: (context, index) {
                            final path = _currentImages[index];
                            return ReorderableDelayedDragStartListener(
                              key: ValueKey('cur_$path'),
                              index: index,
                              child: Padding(
                                padding: const EdgeInsets.only(right: 8),
                                child: Stack(
                                  children: [
                                    GestureDetector(
                                      onTap: () {
                                        Navigator.of(context).push(
                                          MaterialPageRoute(
                                            fullscreenDialog: true,
                                            builder: (_) =>
                                                _ImageGalleryPreview(
                                                  images: _currentImages,
                                                  initialIndex: index,
                                                ),
                                          ),
                                        );
                                      },
                                      child: ClipRRect(
                                        borderRadius: BorderRadius.circular(12),
                                        child:
                                            path.startsWith('http://') ||
                                                path.startsWith('https://')
                                            ? Image.network(
                                                path,
                                                width: 76,
                                                height: 76,
                                                fit: BoxFit.cover,
                                              )
                                            : Image.asset(
                                                path,
                                                width: 76,
                                                height: 76,
                                                fit: BoxFit.cover,
                                              ),
                                      ),
                                    ),
                                    Positioned(
                                      top: 4,
                                      right: 4,
                                      child: InkWell(
                                        onTap: () =>
                                            _removeCurrentImageAt(index),
                                        child: Container(
                                          width: 24,
                                          height: 24,
                                          decoration: BoxDecoration(
                                            color: Colors.black.withValues(
                                              alpha: 0.55,
                                            ),
                                            borderRadius: BorderRadius.circular(
                                              999,
                                            ),
                                          ),
                                          child: const Icon(
                                            Icons.close_rounded,
                                            size: 16,
                                            color: Colors.white,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                    if (_newImages.isNotEmpty) ...[
                      const SizedBox(height: 10),
                      SizedBox(
                        height: 76,
                        child: ReorderableListView.builder(
                          scrollDirection: Axis.horizontal,
                          itemCount: _newImages.length,
                          buildDefaultDragHandles: false,
                          padding: EdgeInsets.zero,
                          onReorder: _reorderNewImages,
                          itemBuilder: (context, index) {
                            final file = _newImages[index];
                            return ReorderableDelayedDragStartListener(
                              key: ValueKey('new_${file.path}'),
                              index: index,
                              child: Padding(
                                padding: const EdgeInsets.only(right: 8),
                                child: Stack(
                                  children: [
                                    ClipRRect(
                                      borderRadius: BorderRadius.circular(12),
                                      child: Image.file(
                                        file,
                                        width: 76,
                                        height: 76,
                                        fit: BoxFit.cover,
                                      ),
                                    ),
                                    Positioned(
                                      top: 2,
                                      right: 2,
                                      child: InkWell(
                                        onTap: () => _removeNewImageAt(index),
                                        child: Container(
                                          width: 24,
                                          height: 24,
                                          decoration: BoxDecoration(
                                            color: Colors.black.withValues(
                                              alpha: 0.55,
                                            ),
                                            borderRadius: BorderRadius.circular(
                                              999,
                                            ),
                                          ),
                                          child: const Icon(
                                            Icons.close_rounded,
                                            size: 16,
                                            color: Colors.white,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                    const SizedBox(height: 14),
                    SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _save,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _primaryGreen,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: const Text(
                          'Saqlash',
                          style: TextStyle(fontWeight: FontWeight.w900),
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

class _CreateProductSheet extends StatefulWidget {
  final String storeId;
  final ProductApiService productApi;
  final _CreateProductDraft draft;

  const _CreateProductSheet({
    required this.storeId,
    required this.productApi,
    required this.draft,
  });

  @override
  State<_CreateProductSheet> createState() => _CreateProductSheetState();
}

class _CreateProductSheetState extends State<_CreateProductSheet> {
  static const _primaryGreen = Color(0xFF1F5A50);

  final _nameCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  final _priceCtrl = TextEditingController();
  final _qtyCtrl = TextEditingController(text: '1');
  final _brandCtrl = TextEditingController();
  final ImagePicker _picker = ImagePicker();
  List<File> _imageFiles = [];

  List<CategoryModel> _categories = [];
  CategoryModel? _selectedCategory;
  bool _isLoading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _nameCtrl.text = widget.draft.name;
    _descCtrl.text = widget.draft.description;
    _priceCtrl.text = widget.draft.price;
    _qtyCtrl.text = widget.draft.qty;
    _brandCtrl.text = widget.draft.brand;
    _imageFiles = List<File>.from(widget.draft.images);

    _nameCtrl.addListener(() => widget.draft.name = _nameCtrl.text);
    _descCtrl.addListener(() => widget.draft.description = _descCtrl.text);
    _priceCtrl.addListener(() => widget.draft.price = _priceCtrl.text);
    _qtyCtrl.addListener(() => widget.draft.qty = _qtyCtrl.text);
    _brandCtrl.addListener(() => widget.draft.brand = _brandCtrl.text);

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
        CategoryModel? selected;
        if (widget.draft.categoryId.trim().isNotEmpty) {
          for (final c in categories) {
            if (c.id == widget.draft.categoryId.trim()) {
              selected = c;
              break;
            }
          }
        }
        selected ??= categories.isNotEmpty ? categories.first : null;
        _selectedCategory = selected;
        widget.draft.categoryId = selected?.id ?? '';
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
      widget.draft.images
        ..clear()
        ..addAll(_imageFiles);
      _error = null;
    });
  }

  void _removeImageAt(int index) {
    if (_isLoading) return;
    if (index < 0 || index >= _imageFiles.length) return;
    setState(() {
      _imageFiles.removeAt(index);
      widget.draft.images
        ..clear()
        ..addAll(_imageFiles);
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
    } on Object catch (error) {
      if (!mounted) return;
      setState(() => _error = "Xatolik: ${error.toString()}");
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  InputDecoration _inputDecoration(String label) {
    return InputDecoration(
      labelText: label,
      filled: true,
      fillColor: const Color(0xFFF7F8FA),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: _primaryGreen.withValues(alpha: 0.12)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: _primaryGreen.withValues(alpha: 0.35)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return Padding(
      padding: EdgeInsets.only(bottom: bottomInset),
      child: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
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
                const SizedBox(height: 8),
                Text(
                  _error!,
                  style: const TextStyle(
                    color: Color(0xFFB91C1C),
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
              const SizedBox(height: 10),
              TextField(
                controller: _nameCtrl,
                decoration: _inputDecoration('Nomi'),
                textInputAction: TextInputAction.next,
              ),
              const SizedBox(height: 10),
              TextField(
                controller: _descCtrl,
                decoration: _inputDecoration('Tavsif'),
                maxLines: 3,
                textInputAction: TextInputAction.newline,
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _priceCtrl,
                      decoration: _inputDecoration("Narx (so'm)"),
                      keyboardType: TextInputType.number,
                      textInputAction: TextInputAction.next,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: TextField(
                      controller: _qtyCtrl,
                      decoration: _inputDecoration('Soni'),
                      keyboardType: TextInputType.number,
                      textInputAction: TextInputAction.next,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              TextField(
                controller: _brandCtrl,
                decoration: _inputDecoration('Brend'),
                textInputAction: TextInputAction.done,
              ),
              const SizedBox(height: 10),
              Text(
                'Kategoriya',
                style: TextStyle(
                  color: _primaryGreen.withValues(alpha: 0.7),
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
                    color: _primaryGreen.withValues(alpha: 0.12),
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
                    onChanged: _isLoading
                        ? null
                        : (v) => setState(() {
                            _selectedCategory = v;
                            widget.draft.categoryId = v?.id ?? '';
                          }),
                  ),
                ),
              ),
              const SizedBox(height: 10),
              Text(
                'Rasmlar (1–6)',
                style: TextStyle(
                  color: _primaryGreen.withValues(alpha: 0.7),
                  fontWeight: FontWeight.w800,
                  fontSize: 12,
                ),
              ),
              const SizedBox(height: 6),
              SizedBox(
                height: 44,
                width: double.infinity,
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
                    foregroundColor: _primaryGreen,
                    side: BorderSide(
                      color: _primaryGreen.withValues(alpha: 0.22),
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
              if (_imageFiles.isNotEmpty) ...[
                const SizedBox(height: 10),
                SizedBox(
                  height: 62,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: _imageFiles.length,
                    separatorBuilder: (context, index) =>
                        const SizedBox(width: 8),
                    itemBuilder: (context, index) {
                      final file = _imageFiles[index];
                      return Stack(
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: Image.file(
                              file,
                              width: 62,
                              height: 62,
                              fit: BoxFit.cover,
                            ),
                          ),
                          Positioned(
                            top: 2,
                            right: 2,
                            child: InkWell(
                              onTap: _isLoading
                                  ? null
                                  : () => _removeImageAt(index),
                              child: Container(
                                width: 22,
                                height: 22,
                                decoration: BoxDecoration(
                                  color: Colors.black.withValues(alpha: 0.55),
                                  borderRadius: BorderRadius.circular(999),
                                ),
                                child: const Icon(
                                  Icons.close_rounded,
                                  size: 14,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                ),
              ],
              const SizedBox(height: 14),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _submit,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _primaryGreen,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.2,
                            color: Colors.white,
                          ),
                        )
                      : const Text(
                          "Qo'shish",
                          style: TextStyle(fontWeight: FontWeight.w900),
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
