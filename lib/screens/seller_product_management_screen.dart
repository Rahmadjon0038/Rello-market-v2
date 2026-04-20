import 'package:flutter/material.dart';
import 'package:hello_flutter_app/models/category.dart';
import 'package:hello_flutter_app/models/product.dart';
import 'package:hello_flutter_app/services/auth_api_service.dart';
import 'package:hello_flutter_app/services/product_api_service.dart';

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
    final name = product.name.trim().isEmpty ? 'Mahsulot' : product.name.trim();
    final statusColor = product.isActive
        ? const Color(0xFF1F5A50)
        : const Color(0xFF9A3412);
    final priceText = product.price > 0 ? product.formattedPrice : '-';

    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onEdit,
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: primaryGreen.withValues(alpha: 0.12)),
          ),
          child: Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.network(
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
                            name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
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
                    const SizedBox(height: 6),
                    Text(
                      '$priceText • Qty: ${product.qty}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: primaryGreen.withValues(alpha: 0.75),
                        fontWeight: FontWeight.w700,
                        fontSize: 12,
                      ),
                    ),
                  ],
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
                        product.isActive
                            ? 'Faolsizlantirish'
                            : 'Faollashtirish',
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
      ),
    );
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

  String? _validate() {
    if (_nameCtrl.text.trim().isEmpty) return "Nomi majburiy";
    if (_descCtrl.text.trim().isEmpty) return "Tavsif majburiy";
    final price = int.tryParse(_priceCtrl.text.trim());
    if (price == null || price <= 0) return "Narx noto'g'ri";
    final qty = int.tryParse(_qtyCtrl.text.trim());
    if (qty == null || qty < 0) return "Soni noto'g'ri";
    if (_selectedCategory == null) return "Kategoriya tanlang";
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
      await widget.productApi.updateProduct(widget.productId, {
        'name': _nameCtrl.text.trim(),
        'description': _descCtrl.text.trim(),
        'price': int.parse(_priceCtrl.text.trim()),
        'qty': int.parse(_qtyCtrl.text.trim()),
        'categoryId': _selectedCategory!.id,
        'brand': _brandCtrl.text.trim(),
      });
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
                          onChanged: (v) =>
                              setState(() => _selectedCategory = v),
                        ),
                      ),
                    ),
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
