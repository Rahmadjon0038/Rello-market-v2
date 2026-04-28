import 'package:flutter/material.dart';
import 'package:hello_flutter_app/models/category.dart';
import 'package:hello_flutter_app/services/product_api_service.dart';
import 'package:hello_flutter_app/services/store_orders_api_service.dart';

class StoreStatisticsScreen extends StatefulWidget {
  final String storeId;
  final String storeName;

  const StoreStatisticsScreen({
    super.key,
    required this.storeId,
    required this.storeName,
  });

  @override
  State<StoreStatisticsScreen> createState() => _StoreStatisticsScreenState();
}

class _StoreStatisticsScreenState extends State<StoreStatisticsScreen> {
  static const primaryGreen = Color(0xFF1F5A50);

  final StoreOrdersApiService _ordersApi = StoreOrdersApiService();
  final ProductApiService _productApi = ProductApiService();

  bool _loading = true;
  String? _error;
  StoreOrdersStats _stats = const StoreOrdersStats.empty();

  List<CategoryModel> _categories = const [];

  String _period = 'all';
  String _status = '';
  String _categoryId = '';
  String? _month;
  String? _from;
  String? _to;

  @override
  void initState() {
    super.initState();
    _loadCategories();
    _loadStats();
  }

  Future<void> _loadCategories() async {
    try {
      final list = await _productApi.getCategories();
      if (!mounted) return;
      setState(() => _categories = list);
    } on Object {
      // ignore categories error
    }
  }

  Future<void> _loadStats() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final stats = await _ordersApi.getStoreOrdersStats(
        widget.storeId,
        period: _period,
        month: _month,
        from: _from,
        to: _to,
        status: _status.isEmpty ? null : _status,
        categoryId: _categoryId.isEmpty ? null : _categoryId,
      );
      if (!mounted) return;
      setState(() {
        _stats = stats;
        _loading = false;
      });
    } on Object {
      if (!mounted) return;
      setState(() {
        _error = "Statistikani yuklab bo'lmadi";
        _loading = false;
      });
    }
  }

  String _money(int v) {
    final s = v.toString();
    final b = StringBuffer();
    for (int i = 0; i < s.length; i++) {
      final idx = s.length - i;
      b.write(s[i]);
      if (idx > 1 && idx % 3 == 1) b.write(' ');
    }
    return "$b so'm";
  }

  Future<void> _pickMonth() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime(now.year + 2),
      initialDate: now,
    );
    if (picked == null || !mounted) return;
    setState(() {
      _month = '${picked.year}-${picked.month.toString().padLeft(2, '0')}';
      _period = 'month';
      _from = null;
      _to = null;
    });
    _loadStats();
  }

  Future<void> _pickRange({required bool fromDate}) async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime(now.year + 2),
      initialDate: now,
    );
    if (picked == null || !mounted) return;
    final value =
        '${picked.year}-${picked.month.toString().padLeft(2, '0')}-${picked.day.toString().padLeft(2, '0')}';
    setState(() {
      _period = 'range';
      _month = null;
      if (fromDate) {
        _from = value;
      } else {
        _to = value;
      }
    });
    _loadStats();
  }

  @override
  Widget build(BuildContext context) {
    const bg = Color(0xFFF7F8FA);
    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(
        backgroundColor: Colors.white,
        foregroundColor: primaryGreen,
        elevation: 0,
        title: const Text(
          'Statistika',
          style: TextStyle(fontWeight: FontWeight.w900),
        ),
        actions: [
          IconButton(
            onPressed: _loading ? null : _loadStats,
            icon: const Icon(Icons.refresh_rounded),
          ),
        ],
      ),
      body: SafeArea(
        child: _loading
            ? const Center(
                child: CircularProgressIndicator(color: primaryGreen),
              )
            : _error != null
            ? Center(
                child: Text(
                  _error!,
                  style: const TextStyle(color: primaryGreen),
                ),
              )
            : ListView(
                padding: const EdgeInsets.fromLTRB(16, 14, 16, 24),
                children: [
                  _filtersCard(),
                  const SizedBox(height: 12),
                  _statsGrid(),
                  const SizedBox(height: 12),
                  _statusCard(),
                  const SizedBox(height: 12),
                  _categoryCard(),
                ],
              ),
      ),
    );
  }

  Widget _filtersCard() {
    return _card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            widget.storeName.trim().isEmpty
                ? "Do'kon statistikasi"
                : widget.storeName,
            style: const TextStyle(
              color: primaryGreen,
              fontSize: 16,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: _select<String>(
                  value: _period,
                  label: 'Davr',
                  items: const [
                    DropdownMenuItem(value: 'all', child: Text('Barchasi')),
                    DropdownMenuItem(value: 'today', child: Text('Bugun')),
                    DropdownMenuItem(value: 'yesterday', child: Text('Kecha')),
                    DropdownMenuItem(
                      value: 'this_month',
                      child: Text('Shu oy'),
                    ),
                    DropdownMenuItem(
                      value: 'last_month',
                      child: Text('O‘tgan oy'),
                    ),
                    DropdownMenuItem(value: 'month', child: Text('Oy tanlash')),
                    DropdownMenuItem(
                      value: 'range',
                      child: Text('Sana oralig‘i'),
                    ),
                  ],
                  onChanged: (v) {
                    if (v == null) return;
                    setState(() {
                      _period = v;
                      if (v != 'month') _month = null;
                      if (v != 'range') {
                        _from = null;
                        _to = null;
                      }
                    });
                    _loadStats();
                  },
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _select<String>(
                  value: _status,
                  label: 'Status',
                  items: const [
                    DropdownMenuItem(value: '', child: Text('Barchasi')),
                    DropdownMenuItem(
                      value: 'pending',
                      child: Text('Kutilmoqda'),
                    ),
                    DropdownMenuItem(
                      value: 'delivering',
                      child: Text('Yetkazilmoqda'),
                    ),
                    DropdownMenuItem(
                      value: 'rejected',
                      child: Text('Rad etilgan'),
                    ),
                    DropdownMenuItem(
                      value: 'delivered',
                      child: Text('Yetkazilgan'),
                    ),
                  ],
                  onChanged: (v) {
                    setState(() => _status = v ?? '');
                    _loadStats();
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          _select<String>(
            value: _categoryId,
            label: 'Kategoriya',
            items: [
              const DropdownMenuItem(value: '', child: Text('Barchasi')),
              ..._categories.map(
                (c) => DropdownMenuItem(value: c.id, child: Text(c.name)),
              ),
            ],
            onChanged: (v) {
              setState(() => _categoryId = v ?? '');
              _loadStats();
            },
          ),
          if (_period == 'month' || _period == 'range') ...[
            const SizedBox(height: 10),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: [
                if (_period == 'month')
                  OutlinedButton.icon(
                    onPressed: _pickMonth,
                    icon: const Icon(Icons.calendar_month_rounded),
                    label: Text(_month == null ? 'Oy tanlash' : _month!),
                  ),
                if (_period == 'range')
                  OutlinedButton.icon(
                    onPressed: () => _pickRange(fromDate: true),
                    icon: const Icon(Icons.event_rounded),
                    label: Text(_from == null ? 'Boshlanish' : _from!),
                  ),
                if (_period == 'range')
                  OutlinedButton.icon(
                    onPressed: () => _pickRange(fromDate: false),
                    icon: const Icon(Icons.event_available_rounded),
                    label: Text(_to == null ? 'Tugash' : _to!),
                  ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _statsGrid() {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _miniStat('Buyurtmalar', _stats.ordersCount.toString()),
            ),
            const SizedBox(width: 10),
            Expanded(child: _miniStat('Jami summa', _money(_stats.totalSum))),
          ],
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: _miniStat('Yetkazilgan', _money(_stats.deliveredSum)),
            ),
            const SizedBox(width: 10),
            Expanded(child: _miniStat('Dona soni', _stats.itemsQty.toString())),
          ],
        ),
      ],
    );
  }

  Widget _statusCard() {
    final s = _stats.byStatus;
    return _card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Status bo‘yicha',
            style: TextStyle(
              color: primaryGreen,
              fontSize: 14,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _chip('Kutilmoqda', s.pending, const Color(0xFF607D8B)),
              _chip('Yetkazilmoqda', s.delivering, const Color(0xFF2E86DE)),
              _chip('Rad etilgan', s.rejected, const Color(0xFFE15C5C)),
              _chip('Yetkazilgan', s.delivered, const Color(0xFF1FA971)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _categoryCard() {
    return _card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Kategoriya bo‘yicha',
            style: TextStyle(
              color: primaryGreen,
              fontSize: 14,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 8),
          if (_stats.byCategory.isEmpty)
            const Text(
              'Ma’lumot yo‘q',
              style: TextStyle(
                color: Color(0xFF6F7F7B),
                fontWeight: FontWeight.w600,
              ),
            )
          else
            ..._stats.byCategory.map(
              (c) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        c.categoryName?.trim().isNotEmpty == true
                            ? c.categoryName!
                            : 'Noma’lum kategoriya',
                        style: const TextStyle(
                          color: primaryGreen,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    Text(
                      '${c.qty} dona • ${_money(c.sum)}',
                      style: const TextStyle(
                        color: Color(0xFF304542),
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _card({required Widget child}) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: primaryGreen.withValues(alpha: 0.1)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: child,
    );
  }

  Widget _miniStat(String title, String value) {
    return _card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              color: Color(0xFF6F7F7B),
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: const TextStyle(
              color: primaryGreen,
              fontSize: 16,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }

  Widget _chip(String label, int count, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withValues(alpha: 0.35)),
      ),
      child: Text(
        '$label: $count',
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.w700,
          fontSize: 12,
        ),
      ),
    );
  }

  Widget _select<T>({
    required T value,
    required String label,
    required List<DropdownMenuItem<T>> items,
    required ValueChanged<T?> onChanged,
  }) {
    return DropdownButtonFormField<T>(
      initialValue: value,
      items: items,
      onChanged: onChanged,
      decoration: InputDecoration(
        labelText: label,
        isDense: true,
        filled: true,
        fillColor: const Color(0xFFF8FAF9),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: primaryGreen.withValues(alpha: 0.15)),
        ),
      ),
    );
  }
}
