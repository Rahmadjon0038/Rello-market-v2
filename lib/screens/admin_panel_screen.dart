import 'package:flutter/material.dart';
import 'package:hello_flutter_app/config/api_config.dart';
import 'package:hello_flutter_app/models/category.dart';
import 'package:hello_flutter_app/models/seller_application.dart';
import 'package:hello_flutter_app/screens/pick_location_screen.dart';
import 'package:hello_flutter_app/services/auth_api_service.dart';
import 'package:hello_flutter_app/services/product_api_service.dart';
import 'package:hello_flutter_app/services/store_api_service.dart';
import 'package:hello_flutter_app/widgets/category_icon.dart';
import 'package:latlong2/latlong.dart';

class AdminPanelScreen extends StatefulWidget {
  const AdminPanelScreen({super.key});

  @override
  State<AdminPanelScreen> createState() => _AdminPanelScreenState();
}

class _AdminPanelScreenState extends State<AdminPanelScreen> {
  final StoreApiService _storeApi = StoreApiService();
  int _currentIndex = 0;
  int _applicationBadgeCount = 0;
  bool _hasNewApplications = false;

  @override
  void initState() {
    super.initState();
    _loadApplicationBadge();
  }

  Future<void> _loadApplicationBadge() async {
    try {
      final badge = await _storeApi.getAdminSellerApplicationsBadge();
      if (!mounted || _currentIndex == 1) return;
      setState(() {
        _applicationBadgeCount = badge.count;
        _hasNewApplications = badge.hasNew;
      });
    } on Object {
      if (!mounted) return;
      setState(() {
        _applicationBadgeCount = 0;
        _hasNewApplications = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    const primaryGreen = Color(0xFF1F5A50);
    const ink = Color(0xFF1F2933);
    final pages = const [_AdminCategoriesPage(), _AdminStoreRequestsPage()];

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        foregroundColor: ink,
        title: const Text(
          'Boshqaruv paneli',
          style: TextStyle(color: ink, fontWeight: FontWeight.w900),
        ),
      ),
      body: SafeArea(child: pages[_currentIndex]),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: (index) {
          setState(() {
            _currentIndex = index;
            if (index == 1) {
              _applicationBadgeCount = 0;
              _hasNewApplications = false;
            }
          });
        },
        indicatorColor: const Color(0xFFE6F4EF),
        backgroundColor: Colors.white,
        destinations: [
          const NavigationDestination(
            icon: Icon(Icons.category_outlined, color: ink),
            selectedIcon: Icon(Icons.category_rounded, color: primaryGreen),
            label: 'Kategoriyalar',
          ),
          NavigationDestination(
            icon: _ApplicationsNavIcon(
              count: _applicationBadgeCount,
              showBadge: _hasNewApplications,
              selected: false,
            ),
            selectedIcon: _ApplicationsNavIcon(
              count: _applicationBadgeCount,
              showBadge: _hasNewApplications,
              selected: true,
            ),
            label: 'Arizalar',
          ),
        ],
      ),
    );
  }
}

class _ApplicationsNavIcon extends StatelessWidget {
  final int count;
  final bool showBadge;
  final bool selected;

  const _ApplicationsNavIcon({
    required this.count,
    required this.showBadge,
    required this.selected,
  });

  @override
  Widget build(BuildContext context) {
    const primaryGreen = Color(0xFF1F5A50);
    const ink = Color(0xFF1F2933);
    final label = count > 99 ? '99+' : count.toString();

    return Stack(
      clipBehavior: Clip.none,
      children: [
        Icon(
          selected ? Icons.storefront_rounded : Icons.storefront_outlined,
          color: selected ? primaryGreen : ink,
        ),
        if (showBadge)
          Positioned(
            right: -9,
            top: -7,
            child: Container(
              constraints: const BoxConstraints(minWidth: 18, minHeight: 18),
              padding: const EdgeInsets.symmetric(horizontal: 5),
              decoration: BoxDecoration(
                color: Colors.redAccent,
                borderRadius: BorderRadius.circular(999),
                border: Border.all(color: Colors.white, width: 1.5),
              ),
              alignment: Alignment.center,
              child: Text(
                count > 0 ? label : '',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 10,
                  fontWeight: FontWeight.w900,
                  height: 1,
                ),
              ),
            ),
          ),
      ],
    );
  }
}

class _AdminCategoriesPage extends StatefulWidget {
  const _AdminCategoriesPage();

  @override
  State<_AdminCategoriesPage> createState() => _AdminCategoriesPageState();
}

class _AdminCategoriesPageState extends State<_AdminCategoriesPage> {
  final ProductApiService _productApi = ProductApiService();
  List<CategoryModel> _categories = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadCategories();
  }

  Future<void> _loadCategories() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final categories = await _productApi.getCategories();
      if (!mounted) return;
      setState(() {
        _categories = categories;
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
        _error = 'Kategoriyalarni yuklab bo‘lmadi';
        _isLoading = false;
      });
    }
  }

  Future<void> _openCategoryForm([CategoryModel? category]) async {
    final saved = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) {
        return _CategoryFormSheet(category: category, productApi: _productApi);
      },
    );
    if (!mounted || saved != true) return;
    _loadCategories();
  }

  Future<void> _confirmDelete(CategoryModel category) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: Colors.white,
          title: const Text('Kategoriyani o‘chirish'),
          content: Text(
            '"${category.name}" o‘chiriladi. Unga bog‘langan mahsulotlarda kategoriya bo‘sh qolishi mumkin.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Bekor qilish'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text(
                'O‘chirish',
                style: TextStyle(color: Colors.redAccent),
              ),
            ),
          ],
        );
      },
    );
    if (confirmed != true) return;

    try {
      await _productApi.deleteCategory(category.id);
      if (!mounted) return;
      setState(() {
        _categories.removeWhere((item) => item.id == category.id);
      });
      _showSnack('Kategoriya o‘chirildi');
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

  @override
  Widget build(BuildContext context) {
    const primaryGreen = Color(0xFF1F5A50);

    return RefreshIndicator(
      color: primaryGreen,
      onRefresh: _loadCategories,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 24),
        children: [
          Row(
            children: [
              const Expanded(
                child: Text(
                  'Kategoriyalar',
                  style: TextStyle(
                    color: primaryGreen,
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              IconButton.filled(
                onPressed: () => _openCategoryForm(),
                icon: const Icon(Icons.add_rounded),
                style: IconButton.styleFrom(
                  backgroundColor: primaryGreen,
                  foregroundColor: Colors.white,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (_isLoading)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 40),
              child: Center(
                child: CircularProgressIndicator(color: primaryGreen),
              ),
            )
          else if (_error != null)
            _AdminStateCard(message: _error!, onRetry: _loadCategories)
          else if (_categories.isEmpty)
            _AdminStateCard(
              message: 'Kategoriyalar topilmadi',
              onRetry: _loadCategories,
            )
          else
            ..._categories.map(
              (category) => Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: _CategoryAdminTile(
                  category: category,
                  onEdit: () => _openCategoryForm(category),
                  onDelete: () => _confirmDelete(category),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _CategoryAdminTile extends StatelessWidget {
  final CategoryModel category;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _CategoryAdminTile({
    required this.category,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    const primaryGreen = Color(0xFF1F5A50);

    return Container(
      padding: const EdgeInsets.fromLTRB(12, 10, 8, 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: primaryGreen.withValues(alpha: 0.12)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 14,
            offset: const Offset(0, 7),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: const Color(0xFFE6F4EF),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              categoryIconOf(category.icon),
              color: primaryGreen,
              size: 22,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  category.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: primaryGreen,
                    fontSize: 15,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  categoryIconLabelOf(category.icon),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: primaryGreen.withValues(alpha: 0.64),
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            tooltip: 'Tahrirlash',
            onPressed: onEdit,
            icon: const Icon(Icons.edit_rounded),
            color: primaryGreen,
          ),
          IconButton(
            tooltip: 'O‘chirish',
            onPressed: onDelete,
            icon: const Icon(Icons.delete_outline_rounded),
            color: Colors.redAccent,
          ),
        ],
      ),
    );
  }
}

class _CategoryFormSheet extends StatefulWidget {
  final CategoryModel? category;
  final ProductApiService productApi;

  const _CategoryFormSheet({required this.category, required this.productApi});

  @override
  State<_CategoryFormSheet> createState() => _CategoryFormSheetState();
}

class _CategoryFormSheetState extends State<_CategoryFormSheet> {
  late final TextEditingController _nameCtrl;
  late String _selectedIcon;
  bool _isSaving = false;
  String? _error;

  bool get _isEditing => widget.category != null;

  @override
  void initState() {
    super.initState();
    final category = widget.category;
    _nameCtrl = TextEditingController(text: category?.name ?? '');
    _selectedIcon = allowedCategoryIconKeys.contains(category?.icon)
        ? category!.icon
        : allowedCategoryIconKeys.first;
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_isSaving) return;
    final name = _nameCtrl.text.trim();
    if (name.isEmpty) {
      setState(() => _error = 'Kategoriya nomini kiriting');
      return;
    }

    setState(() {
      _isSaving = true;
      _error = null;
    });

    try {
      if (_isEditing) {
        await widget.productApi.updateCategory(
          widget.category!.id,
          name: name,
          icon: _selectedIcon,
        );
      } else {
        await widget.productApi.createCategory(name: name, icon: _selectedIcon);
      }
      if (!mounted) return;
      Navigator.of(context).pop(true);
    } on AuthApiException catch (error) {
      if (!mounted) return;
      setState(() {
        _error = error.message;
        _isSaving = false;
      });
    } on Object {
      if (!mounted) return;
      setState(() {
        _error = 'Server bilan bog‘lanib bo‘lmadi';
        _isSaving = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    const primaryGreen = Color(0xFF1F5A50);

    return SafeArea(
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          16,
          8,
          16,
          MediaQuery.viewInsetsOf(context).bottom + 16,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              _isEditing ? 'Kategoriyani tahrirlash' : 'Kategoriya qo‘shish',
              style: const TextStyle(
                color: primaryGreen,
                fontSize: 18,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _nameCtrl,
              enabled: !_isSaving,
              cursorColor: primaryGreen,
              decoration: InputDecoration(
                labelText: 'Nomi',
                filled: true,
                fillColor: const Color(0xFFF6F7F8),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(
                    color: primaryGreen.withValues(alpha: 0.12),
                  ),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: primaryGreen),
                ),
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              'Belgi',
              style: TextStyle(
                color: primaryGreen,
                fontSize: 14,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 8),
            ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: 250),
              child: GridView.builder(
                shrinkWrap: true,
                itemCount: allowedCategoryIconKeys.length,
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 4,
                  mainAxisSpacing: 8,
                  crossAxisSpacing: 8,
                  childAspectRatio: 1.05,
                ),
                itemBuilder: (context, index) {
                  final key = allowedCategoryIconKeys[index];
                  final selected = key == _selectedIcon;
                  return _IconKeyOption(
                    iconKey: key,
                    selected: selected,
                    onTap: _isSaving
                        ? null
                        : () => setState(() => _selectedIcon = key),
                  );
                },
              ),
            ),
            if (_error != null) ...[
              const SizedBox(height: 10),
              Text(
                _error!,
                style: const TextStyle(
                  color: Colors.redAccent,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: _isSaving
                        ? null
                        : () => Navigator.of(context).pop(false),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: primaryGreen,
                      side: BorderSide(
                        color: primaryGreen.withValues(alpha: 0.28),
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text('Bekor qilish'),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: ElevatedButton(
                    onPressed: _isSaving ? null : _save,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: primaryGreen,
                      foregroundColor: Colors.white,
                      disabledBackgroundColor: primaryGreen.withValues(
                        alpha: 0.72,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: _isSaving
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
                        : const Text('Saqlash'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _IconKeyOption extends StatelessWidget {
  final String iconKey;
  final bool selected;
  final VoidCallback? onTap;

  const _IconKeyOption({
    required this.iconKey,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    const primaryGreen = Color(0xFF1F5A50);

    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? primaryGreen : const Color(0xFFF6F7F8),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: selected
                ? primaryGreen
                : primaryGreen.withValues(alpha: 0.1),
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              categoryIconOf(iconKey),
              color: selected ? Colors.white : primaryGreen,
              size: 22,
            ),
            const SizedBox(height: 5),
            Text(
              categoryIconLabelOf(iconKey),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: selected ? Colors.white : primaryGreen,
                fontSize: 10,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AdminStateCard extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _AdminStateCard({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    const primaryGreen = Color(0xFF1F5A50);

    return Container(
      width: double.infinity,
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
              fontSize: 14,
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

class _AdminStoreRequestsPage extends StatefulWidget {
  const _AdminStoreRequestsPage();

  @override
  State<_AdminStoreRequestsPage> createState() =>
      _AdminStoreRequestsPageState();
}

class _AdminStoreRequestsPageState extends State<_AdminStoreRequestsPage> {
  final StoreApiService _storeApi = StoreApiService();
  final TextEditingController _searchCtrl = TextEditingController();
  final List<String> _statuses = ['pending', 'approved', 'rejected'];
  String _selectedStatus = 'pending';
  List<SellerApplication> _applications = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _searchCtrl.addListener(() => setState(() {}));
    _loadApplications();
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  List<SellerApplication> get _filteredApplications {
    final rawQuery = _searchCtrl.text.trim();
    final queryText = _normalizeText(rawQuery);
    final queryPhone = _digitsOnly(rawQuery);
    final hasTextQuery = queryText.isNotEmpty;
    final hasPhoneQuery = queryPhone.isNotEmpty;
    if (!hasTextQuery && !hasPhoneQuery) return _applications;
    return _applications.where((application) {
      final textHaystack = _normalizeText(
        [
          application.storeName,
          application.fullName,
          application.email,
          application.primaryPhone,
          application.additionalPhone,
          application.user?.phone ?? '',
          application.user?.username ?? '',
        ].join(' '),
      );
      final phoneHaystack = _digitsOnly(
        [
          application.primaryPhone,
          application.additionalPhone,
          application.user?.phone ?? '',
          application.user?.username ?? '',
        ].join(' '),
      );

      return (hasTextQuery && textHaystack.contains(queryText)) ||
          (hasPhoneQuery && phoneHaystack.contains(queryPhone));
    }).toList();
  }

  String _normalizeText(String value) =>
      value.toLowerCase().replaceAll(RegExp(r'\s+'), '');

  String _digitsOnly(String value) => value.replaceAll(RegExp(r'\D'), '');

  Future<void> _loadApplications() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final applications = await _storeApi.getAdminSellerApplications(
        status: _selectedStatus,
      );
      if (!mounted) return;
      setState(() {
        _applications = applications;
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
        _error = 'Arizalarni yuklab bo‘lmadi';
        _isLoading = false;
      });
    }
  }

  Future<void> _approve(SellerApplication application) async {
    try {
      await _storeApi.approveSellerApplication(application.id);
      if (!mounted) return;
      _showSnack('Ariza tasdiqlandi');
      _loadApplications();
    } on AuthApiException catch (error) {
      _showSnack(error.message);
    } on Object {
      _showSnack('Server bilan bog‘lanib bo‘lmadi');
    }
  }

  Future<void> _reject(SellerApplication application) async {
    final note = await showDialog<String>(
      context: context,
      builder: (context) => const _RejectApplicationDialog(),
    );
    if (note == null) return;

    try {
      await _storeApi.rejectSellerApplication(application.id, reviewNote: note);
      if (!mounted) return;
      _showSnack('Ariza rad etildi');
      _loadApplications();
    } on AuthApiException catch (error) {
      _showSnack(error.message);
    } on Object {
      _showSnack('Server bilan bog‘lanib bo‘lmadi');
    }
  }

  void _showDetails(SellerApplication application) {
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => _ApplicationDetailsSheet(application: application),
    );
  }

  void _showSnack(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), duration: const Duration(seconds: 2)),
    );
  }

  @override
  Widget build(BuildContext context) {
    const primaryGreen = Color(0xFF1F5A50);
    const ink = Color(0xFF1F2933);
    const line = Color(0xFFE5E7EB);
    final filteredApplications = _filteredApplications;

    return RefreshIndicator(
      color: primaryGreen,
      onRefresh: _loadApplications,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 24),
        children: [
          Text(
            'Do‘kon arizalari',
            style: TextStyle(
              color: ink,
              fontSize: 22,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _searchCtrl,
            cursorColor: primaryGreen,
            keyboardType: TextInputType.text,
            decoration: InputDecoration(
              hintText: "Do'kon nomi yoki telefon raqami",
              prefixIcon: const Icon(Icons.search_rounded),
              suffixIcon: _searchCtrl.text.isEmpty
                  ? null
                  : IconButton(
                      onPressed: _searchCtrl.clear,
                      icon: const Icon(Icons.close_rounded),
                    ),
              filled: true,
              fillColor: Colors.white,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 14,
                vertical: 12,
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: const BorderSide(color: line),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: const BorderSide(color: primaryGreen, width: 1.3),
              ),
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 38,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: _statuses.length,
              separatorBuilder: (context, index) => const SizedBox(width: 8),
              itemBuilder: (context, index) {
                final status = _statuses[index];
                final selected = status == _selectedStatus;
                return ChoiceChip(
                  label: Text(_statusLabel(status)),
                  selected: selected,
                  onSelected: (_) {
                    setState(() => _selectedStatus = status);
                    _loadApplications();
                  },
                  selectedColor: primaryGreen,
                  labelStyle: TextStyle(
                    color: selected ? Colors.white : ink,
                    fontWeight: FontWeight.w700,
                  ),
                  backgroundColor: Colors.white,
                  side: BorderSide(color: selected ? primaryGreen : line),
                );
              },
            ),
          ),
          const SizedBox(height: 12),
          if (_isLoading)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 40),
              child: Center(
                child: CircularProgressIndicator(color: primaryGreen),
              ),
            )
          else if (_error != null)
            _AdminStateCard(message: _error!, onRetry: _loadApplications)
          else if (_applications.isEmpty)
            _AdminStateCard(
              message: 'Arizalar topilmadi',
              onRetry: _loadApplications,
            )
          else if (filteredApplications.isEmpty)
            _AdminStateCard(
              message: 'Qidiruv bo‘yicha ariza topilmadi',
              onRetry: () => setState(_searchCtrl.clear),
            )
          else
            ...filteredApplications.map(
              (application) => Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: _ApplicationTile(
                  application: application,
                  onDetails: () => _showDetails(application),
                  onApprove: application.status == 'pending'
                      ? () => _approve(application)
                      : null,
                  onReject: application.status == 'pending'
                      ? () => _reject(application)
                      : null,
                ),
              ),
            ),
        ],
      ),
    );
  }

  String _statusLabel(String status) {
    return switch (status) {
      'approved' => 'Tasdiqlangan',
      'rejected' => 'Rad etilgan',
      _ => 'Kutilmoqda',
    };
  }
}

class _ApplicationTile extends StatelessWidget {
  final SellerApplication application;
  final VoidCallback onDetails;
  final VoidCallback? onApprove;
  final VoidCallback? onReject;

  const _ApplicationTile({
    required this.application,
    required this.onDetails,
    required this.onApprove,
    required this.onReject,
  });

  @override
  Widget build(BuildContext context) {
    const primaryGreen = Color(0xFF1F5A50);
    const ink = Color(0xFF1F2933);
    const muted = Color(0xFF6B7280);
    const line = Color(0xFFE5E7EB);

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: application.adminSeen ? line : primaryGreen),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 14,
            offset: const Offset(0, 7),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.storefront_rounded, color: primaryGreen),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  application.storeName.isEmpty
                      ? application.fullName
                      : application.storeName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: ink,
                    fontSize: 15,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              _StatusPill(status: application.status),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            application.fullName.isEmpty
                ? application.email
                : application.fullName,
            style: const TextStyle(
              color: muted,
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Text(application.contact, style: const TextStyle(color: muted)),
              const Spacer(),
              TextButton(onPressed: onDetails, child: const Text('Batafsil')),
            ],
          ),
          if (onApprove != null || onReject != null) ...[
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: onReject,
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.redAccent,
                    ),
                    child: const Text('Rad etish'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton(
                    onPressed: onApprove,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: primaryGreen,
                      foregroundColor: Colors.white,
                    ),
                    child: const Text('Tasdiqlash'),
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

class _RejectApplicationDialog extends StatefulWidget {
  const _RejectApplicationDialog();

  @override
  State<_RejectApplicationDialog> createState() =>
      _RejectApplicationDialogState();
}

class _RejectApplicationDialogState extends State<_RejectApplicationDialog> {
  final TextEditingController _noteCtrl = TextEditingController();

  @override
  void dispose() {
    _noteCtrl.dispose();
    super.dispose();
  }

  void _submit() {
    FocusScope.of(context).unfocus();
    Navigator.of(context).pop(_noteCtrl.text.trim());
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: Colors.white,
      title: const Text('Arizani rad etish'),
      content: TextField(
        controller: _noteCtrl,
        minLines: 2,
        maxLines: 4,
        textInputAction: TextInputAction.done,
        onSubmitted: (_) => _submit(),
        decoration: const InputDecoration(
          labelText: 'Izoh',
          border: OutlineInputBorder(),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () {
            FocusScope.of(context).unfocus();
            Navigator.of(context).pop();
          },
          child: const Text('Bekor qilish'),
        ),
        TextButton(
          onPressed: _submit,
          child: const Text(
            'Rad etish',
            style: TextStyle(color: Colors.redAccent),
          ),
        ),
      ],
    );
  }
}

class _StatusPill extends StatelessWidget {
  final String status;

  const _StatusPill({required this.status});

  @override
  Widget build(BuildContext context) {
    final color = switch (status) {
      'approved' => const Color(0xFF1F5A50),
      'rejected' => Colors.redAccent,
      _ => Colors.orange,
    };
    final label = switch (status) {
      'approved' => 'Tasdiqlangan',
      'rejected' => 'Rad etilgan',
      _ => 'Kutilmoqda',
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 11,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

class _ApplicationDetailsSheet extends StatelessWidget {
  final SellerApplication application;

  const _ApplicationDetailsSheet({required this.application});

  String _pad2(int v) => v.toString().padLeft(2, '0');

  DateTime? _tryParseDateTime(String raw) {
    if (raw.trim().isEmpty) return null;
    try {
      return DateTime.parse(raw);
    } on Object {
      return null;
    }
  }

  String _formatDate(String raw) {
    final parsed = _tryParseDateTime(raw);
    if (parsed == null) return raw.isEmpty ? '' : raw;
    final local = parsed.toLocal();
    return '${local.year}-${_pad2(local.month)}-${_pad2(local.day)}';
  }

  String _formatDateTime(String raw) {
    final parsed = _tryParseDateTime(raw);
    if (parsed == null) return raw.isEmpty ? '' : raw;
    final local = parsed.toLocal();
    return '${local.year}-${_pad2(local.month)}-${_pad2(local.day)} '
        '${_pad2(local.hour)}:${_pad2(local.minute)}';
  }

  String _formatMoney(num value) {
    final s = value.toStringAsFixed(0);
    final b = StringBuffer();
    for (var i = 0; i < s.length; i++) {
      final remaining = s.length - i;
      b.write(s[i]);
      if (remaining > 1 && remaining % 3 == 1) b.write(' ');
    }
    return "$b so'm";
  }

  String? _absoluteUrl(String pathOrUrl) {
    final value = pathOrUrl.trim();
    if (value.isEmpty) return null;
    if (value.startsWith('http://') || value.startsWith('https://')) {
      return value;
    }
    final base = ApiConfig.baseUrl.replaceAll(RegExp(r'/+$'), '');
    final path = value.startsWith('/') ? value : '/$value';
    return '$base$path';
  }

  LatLng? _latLngFromMapLocation(String value) {
    final raw = value.trim();
    if (raw.isEmpty) return null;
    final match = RegExp(
      r'(-?\d+(?:\.\d+)?)\s*,\s*(-?\d+(?:\.\d+)?)',
    ).firstMatch(raw);
    if (match == null) return null;
    final lat = double.tryParse(match.group(1)!);
    final lng = double.tryParse(match.group(2)!);
    if (lat == null || lng == null) return null;
    if (lat < -90 || lat > 90 || lng < -180 || lng > 180) return null;
    return LatLng(lat, lng);
  }

  void _openMapLocation(BuildContext context, String value) {
    final point = _latLngFromMapLocation(value);
    if (point == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Map link ichidan koordinata topilmadi"),
          duration: Duration(seconds: 2),
        ),
      );
      return;
    }
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => PickLocationScreen(initial: point)),
    );
  }

  String _storeTypeLabel(String value) {
    return switch (value.trim().toLowerCase()) {
      'online' => 'Online',
      'offline' => 'Offline',
      'both' ||
      'ikkalasi' ||
      'online/offline' ||
      'offline/online' => 'Online va offline',
      _ => value,
    };
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 10, 8, 8),
            child: Row(
              children: [
                const Expanded(
                  child: Text(
                    "Ariza detail",
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900),
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.close),
                  tooltip: 'Yopish',
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          Flexible(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 10, 16, 20),
              children: [
                _DetailRow(title: 'Ism familiya', value: application.fullName),
                _DetailRow(
                  title: 'Tug‘ilgan sana',
                  value: _formatDate(application.birthDate),
                ),
                _DetailRow(title: 'Jinsi', value: application.gender),
                _DetailRow(
                  title: 'Asosiy telefon',
                  value: application.primaryPhone,
                ),
                _DetailRow(
                  title: 'Qo‘shimcha telefon',
                  value: application.additionalPhone,
                ),
                _DetailRow(title: 'Email', value: application.email),
                _DetailRow(
                  title: 'Yashash manzili',
                  value: application.livingAddress,
                ),
                _DetailRow(
                  title: 'Pasport seriya raqami',
                  value: application.passportSeriesNumber,
                ),
                _DetailRow(title: 'JSHSHIR', value: application.jshshir),
                _DetailRow(
                  title: 'Pasport kim tomonidan berilgan',
                  value: application.passportIssuedBy,
                ),
                _DetailRow(
                  title: 'Pasport berilgan sana',
                  value: _formatDate(application.passportIssuedDate),
                ),
                _DetailRow(title: "Do'kon nomi", value: application.storeName),
                _DetailRow(
                  title: "Do'kon turi",
                  value: _storeTypeLabel(application.storeType),
                ),
                _DetailRow(
                  title: "Faoliyat yo'nalishi",
                  value: application.activityType,
                ),
                _DetailRow(
                  title: "Do'kon tavsifi",
                  value: application.storeDescription,
                ),
                _DetailRow(
                  title: "Do'kon manzili",
                  value: application.storeAddress,
                ),
                _MapDetailRow(
                  title: 'Google Map link',
                  value: application.storeMapLocation,
                  onOpen: () =>
                      _openMapLocation(context, application.storeMapLocation),
                ),
                _DetailRow(title: 'Ish vaqti', value: application.workingHours),
                _DetailRow(
                  title: 'Yetkazib berish',
                  value: application.hasDelivery
                      ? 'Yetkazib berish xizmati bor'
                      : 'Yetkazib berish xizmati mavjud emas',
                ),
                if (application.hasDelivery) ...[
                  _DetailRow(
                    title: 'Yetkazib berish hududi',
                    value: application.deliveryArea,
                  ),
                  _DetailRow(
                    title: 'Yetkazib berish narxi',
                    value: _formatMoney(application.deliveryPrice),
                  ),
                ],
                _ImageDetailRow(
                  title: "Do'kon logo",
                  url: _absoluteUrl(application.storeLogo),
                ),
                _ImagesDetailRow(
                  title: 'Banner rasmlar',
                  urls: application.storeBannerImages
                      .map(_absoluteUrl)
                      .whereType<String>()
                      .toList(),
                ),
                _DetailRow(
                  title: 'Ariza yuborilgan vaqt',
                  value: _formatDateTime(application.submittedAt),
                ),
                if (application.approvedAt.isNotEmpty)
                  _DetailRow(
                    title: 'Tasdiqlangan vaqt',
                    value: _formatDateTime(application.approvedAt),
                  ),
                if (application.rejectedAt.isNotEmpty)
                  _DetailRow(
                    title: 'Rad etilgan vaqt',
                    value: _formatDateTime(application.rejectedAt),
                  ),
                if (application.reviewNote.isNotEmpty)
                  _DetailRow(title: 'Izoh', value: application.reviewNote),
              ],
            ),
          ),
        ],
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
            value.isEmpty ? '-' : value,
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

class _MapDetailRow extends StatelessWidget {
  final String title;
  final String value;
  final VoidCallback onOpen;

  const _MapDetailRow({
    required this.title,
    required this.value,
    required this.onOpen,
  });

  @override
  Widget build(BuildContext context) {
    const primaryGreen = Color(0xFF1F5A50);
    final hasValue = value.trim().isNotEmpty;

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
          InkWell(
            onTap: hasValue ? onOpen : null,
            borderRadius: BorderRadius.circular(10),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
              decoration: BoxDecoration(
                color: const Color(0xFFE6F4EF),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.location_on_rounded,
                    color: primaryGreen,
                    size: 18,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      hasValue ? value.trim() : '-',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: primaryGreen,
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  if (hasValue) ...[
                    const SizedBox(width: 8),
                    const Icon(
                      Icons.open_in_new_rounded,
                      color: primaryGreen,
                      size: 18,
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
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
                  errorBuilder: (context, error, stackTrace) {
                    return Container(
                      color: primaryGreen.withValues(alpha: 0.06),
                      alignment: Alignment.center,
                      child: const Text(
                        "Rasm yuklanmadi",
                        style: TextStyle(
                          color: primaryGreen,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    );
                  },
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
                separatorBuilder: (context, index) => const SizedBox(width: 10),
                itemBuilder: (context, index) {
                  final url = urls[index];
                  return ClipRRect(
                    borderRadius: BorderRadius.circular(14),
                    child: AspectRatio(
                      aspectRatio: 16 / 9,
                      child: Image.network(
                        url,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return Container(
                            color: primaryGreen.withValues(alpha: 0.06),
                            alignment: Alignment.center,
                            child: const Text(
                              "Rasm yuklanmadi",
                              style: TextStyle(
                                color: primaryGreen,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          );
                        },
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
