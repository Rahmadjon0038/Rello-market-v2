import 'package:flutter/material.dart';
import 'package:hello_flutter_app/models/category.dart';
import 'package:hello_flutter_app/models/seller_application.dart';
import 'package:hello_flutter_app/services/auth_api_service.dart';
import 'package:hello_flutter_app/services/product_api_service.dart';
import 'package:hello_flutter_app/services/store_api_service.dart';
import 'package:hello_flutter_app/widgets/category_icon.dart';

class AdminPanelScreen extends StatefulWidget {
  const AdminPanelScreen({super.key});

  @override
  State<AdminPanelScreen> createState() => _AdminPanelScreenState();
}

class _AdminPanelScreenState extends State<AdminPanelScreen> {
  int _currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    const primaryGreen = Color(0xFF1F5A50);
    final pages = const [_AdminCategoriesPage(), _AdminStoreRequestsPage()];

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        foregroundColor: primaryGreen,
        title: const Text(
          'Boshqaruv paneli',
          style: TextStyle(fontWeight: FontWeight.w900),
        ),
      ),
      body: SafeArea(child: pages[_currentIndex]),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: (index) {
          setState(() => _currentIndex = index);
        },
        indicatorColor: const Color(0xFFE6F4EF),
        backgroundColor: Colors.white,
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.category_outlined),
            selectedIcon: Icon(Icons.category_rounded),
            label: 'Categoriyalar',
          ),
          NavigationDestination(
            icon: Icon(Icons.storefront_outlined),
            selectedIcon: Icon(Icons.storefront_rounded),
            label: 'Arizalar',
          ),
        ],
      ),
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
        _error = 'Categoriyalarni yuklab bo‘lmadi';
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
            '"${category.name}" o‘chiriladi. Unga bog‘langan mahsulotlarda category bo‘sh qolishi mumkin.',
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
                  'Categoriyalar',
                  style: TextStyle(
                    color: primaryGreen,
                    fontSize: 22,
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
              message: 'Categoriyalar topilmadi',
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
                  category.icon.isEmpty ? 'category' : category.icon,
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
              'Icon',
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
              iconKey,
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
  final List<String> _statuses = ['pending', 'approved', 'rejected'];
  String _selectedStatus = 'pending';
  List<SellerApplication> _applications = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadApplications();
  }

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
    final noteCtrl = TextEditingController();
    final note = await showDialog<String>(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: Colors.white,
          title: const Text('Arizani rad etish'),
          content: TextField(
            controller: noteCtrl,
            minLines: 2,
            maxLines: 4,
            decoration: const InputDecoration(
              labelText: 'Izoh',
              border: OutlineInputBorder(),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Bekor qilish'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(noteCtrl.text),
              child: const Text(
                'Rad etish',
                style: TextStyle(color: Colors.redAccent),
              ),
            ),
          ],
        );
      },
    );
    noteCtrl.dispose();
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

    return RefreshIndicator(
      color: primaryGreen,
      onRefresh: _loadApplications,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 24),
        children: [
          const Text(
            'Do‘kon arizalari',
            style: TextStyle(
              color: primaryGreen,
              fontSize: 22,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 38,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: _statuses.length,
              separatorBuilder: (_, __) => const SizedBox(width: 8),
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
                    color: selected ? Colors.white : primaryGreen,
                    fontWeight: FontWeight.w700,
                  ),
                  backgroundColor: Colors.white,
                  side: BorderSide(color: primaryGreen.withValues(alpha: 0.18)),
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
          else
            ..._applications.map(
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

    return Container(
      padding: const EdgeInsets.all(14),
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
                    color: primaryGreen,
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
            application.fullName,
            style: TextStyle(
              color: primaryGreen.withValues(alpha: 0.72),
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Text(
                application.phone,
                style: TextStyle(color: primaryGreen.withValues(alpha: 0.72)),
              ),
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
      'approved' => 'approved',
      'rejected' => 'rejected',
      _ => 'pending',
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

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: ListView(
        shrinkWrap: true,
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 20),
        children: [
          _DetailRow(title: 'Ism familiya', value: application.fullName),
          _DetailRow(title: 'Telefon', value: application.phone),
          _DetailRow(title: "Do'kon nomi", value: application.storeName),
          _DetailRow(title: 'Maqsad', value: application.purpose),
          _DetailRow(title: 'Mahsulotlar', value: application.productsInfo),
          _DetailRow(title: 'Manzil', value: application.address),
          if (application.reviewNote.isNotEmpty)
            _DetailRow(title: 'Izoh', value: application.reviewNote),
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
