import 'package:flutter/material.dart';
import 'package:hello_flutter_app/services/store_orders_api_service.dart';

class StoreReportsScreen extends StatefulWidget {
  final String storeId;
  final String storeName;

  const StoreReportsScreen({
    super.key,
    required this.storeId,
    required this.storeName,
  });

  @override
  State<StoreReportsScreen> createState() => _StoreReportsScreenState();
}

class _StoreReportsScreenState extends State<StoreReportsScreen> {
  static const primaryGreen = Color(0xFF1F5A50);
  static const bg = Color(0xFFF7F8FA);

  final StoreOrdersApiService _api = StoreOrdersApiService();

  bool _loading = true;
  String? _error;
  StoreOrdersStats _stats = const StoreOrdersStats.empty();

  String _tab = 'day'; // day | week | month
  // Avoid `late` so hot-reload doesn't crash with uninitialized fields.
  final DateTime _initialNow = DateTime.now();
  late DateTime _selectedDay = DateTime(
    _initialNow.year,
    _initialNow.month,
    _initialNow.day,
  );
  late DateTime _selectedWeekStart = _weekStartStatic(_initialNow);
  late DateTime _selectedMonth = DateTime(_initialNow.year, _initialNow.month);

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _selectedDay = DateTime(now.year, now.month, now.day);
    _selectedWeekStart = _weekStartStatic(now);
    _selectedMonth = DateTime(now.year, now.month);
    _load();
  }

  String _pad2(int v) => v.toString().padLeft(2, '0');

  String _ymd(DateTime dt) {
    final local = dt.toLocal();
    return '${local.year}-${_pad2(local.month)}-${_pad2(local.day)}';
  }

  String _ym(DateTime dt) {
    final local = dt.toLocal();
    return '${local.year}-${_pad2(local.month)}';
  }

  String _dmy(DateTime dt) {
    final local = dt.toLocal();
    return '${_pad2(local.day)}.${_pad2(local.month)}.${local.year}';
  }

  static DateTime _weekStartStatic(DateTime dt) {
    final d = dt.toLocal();
    final normalized = DateTime(d.year, d.month, d.day);
    // Monday as week start.
    final diff = normalized.weekday - DateTime.monday;
    return normalized.subtract(Duration(days: diff));
  }

  String _formatIntUz(int v) {
    final s = v.toString();
    final b = StringBuffer();
    for (int i = 0; i < s.length; i++) {
      final idx = s.length - i;
      b.write(s[i]);
      if (idx > 1 && idx % 3 == 1) b.write(' ');
    }
    return b.toString();
  }

  String _money(int v) {
    return "${_formatIntUz(v)} so‘m";
  }

  ({String period, String? from, String? to, String label}) _range() {
    return switch (_tab) {
      'day' => (
        period: 'range',
        from: _ymd(_selectedDay),
        to: _ymd(_selectedDay),
        label: _dmy(_selectedDay),
      ),
      'month' => (
        period: 'month',
        from: null,
        to: null,
        label: _ym(_selectedMonth),
      ),
      _ => (
        period: 'range',
        from: _ymd(_selectedWeekStart),
        to: _ymd(_selectedWeekStart.add(const Duration(days: 6))),
        label:
            '${_dmy(_selectedWeekStart)} - ${_dmy(_selectedWeekStart.add(const Duration(days: 6)))}',
      ),
    };
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final r = _range();
      final stats = await _api.getStoreOrdersStats(
        widget.storeId,
        period: r.period,
        month: r.period == 'month' ? _ym(_selectedMonth) : null,
        from: r.from,
        to: r.to,
      );
      if (!mounted) return;
      setState(() {
        _stats = stats;
        _loading = false;
      });
    } on Object {
      if (!mounted) return;
      setState(() {
        _error = 'Hisobotni yuklab bo‘lmadi';
        _loading = false;
      });
    }
  }

  Future<void> _pickDay() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime(now.year + 3),
      initialDate: _selectedDay,
    );
    if (picked == null || !mounted) return;
    setState(
      () => _selectedDay = DateTime(picked.year, picked.month, picked.day),
    );
    _load();
  }

  Future<void> _pickMonth() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime(now.year + 3),
      initialDate: _selectedMonth,
      helpText: 'Oyni tanlang (kun farq qilmaydi)',
    );
    if (picked == null || !mounted) return;
    setState(() => _selectedMonth = DateTime(picked.year, picked.month));
    _load();
  }

  Widget _periodSelector() {
    final rangeLabel = _range().label;
    void prev() {
      setState(() {
        if (_tab == 'day') {
          _selectedDay = _selectedDay.subtract(const Duration(days: 1));
        } else if (_tab == 'week') {
          _selectedWeekStart = _selectedWeekStart.subtract(
            const Duration(days: 7),
          );
        } else {
          _selectedMonth = DateTime(
            _selectedMonth.year,
            _selectedMonth.month - 1,
          );
        }
      });
      _load();
    }

    void next() {
      setState(() {
        if (_tab == 'day') {
          _selectedDay = _selectedDay.add(const Duration(days: 1));
        } else if (_tab == 'week') {
          _selectedWeekStart = _selectedWeekStart.add(const Duration(days: 7));
        } else {
          _selectedMonth = DateTime(
            _selectedMonth.year,
            _selectedMonth.month + 1,
          );
        }
      });
      _load();
    }

    Future<void> pick() async {
      if (_tab == 'day') return _pickDay();
      if (_tab == 'month') return _pickMonth();
      // week: pick a day and derive week start
      final now = DateTime.now();
      final picked = await showDatePicker(
        context: context,
        firstDate: DateTime(2020),
        lastDate: DateTime(now.year + 3),
        initialDate: _selectedWeekStart,
        helpText: 'Haftani tanlang (kun farq qilmaydi)',
      );
      if (picked == null || !mounted) return;
      setState(() => _selectedWeekStart = _weekStartStatic(picked));
      _load();
    }

    return Row(
      children: [
        IconButton(
          tooltip: 'Oldingi',
          onPressed: _loading ? null : prev,
          icon: const Icon(Icons.chevron_left_rounded),
          color: primaryGreen,
        ),
        Expanded(
          child: InkWell(
            borderRadius: BorderRadius.circular(14),
            onTap: _loading ? null : pick,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: primaryGreen.withValues(alpha: 0.14)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.calendar_month_rounded,
                    size: 18,
                    color: primaryGreen,
                  ),
                  const SizedBox(width: 8),
                  Flexible(
                    child: Text(
                      rangeLabel,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: primaryGreen,
                        fontSize: 12.5,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        IconButton(
          tooltip: 'Keyingi',
          onPressed: _loading ? null : next,
          icon: const Icon(Icons.chevron_right_rounded),
          color: primaryGreen,
        ),
      ],
    );
  }

  Widget _tabs() {
    Widget tab({
      required String key,
      required String label,
      required IconData icon,
      required Color color,
    }) {
      final selected = _tab == key;
      return Expanded(
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: () {
            if (!mounted) return;
            if (_tab == key) return;
            setState(() => _tab = key);
            _load();
          },
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
            decoration: BoxDecoration(
              color: (selected ? color : Colors.white).withValues(
                alpha: selected ? 0.16 : 1,
              ),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: (selected ? color : primaryGreen).withValues(
                  alpha: selected ? 0.45 : 0.14,
                ),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, size: 18, color: selected ? color : primaryGreen),
                const SizedBox(width: 8),
                Text(
                  label,
                  style: TextStyle(
                    color: selected ? color : primaryGreen,
                    fontSize: 12.5,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Row(
      children: [
        tab(
          key: 'day',
          label: 'Kunlik',
          icon: Icons.today_rounded,
          color: const Color(0xFF2563EB),
        ),
        const SizedBox(width: 10),
        tab(
          key: 'week',
          label: 'Haftalik',
          icon: Icons.date_range_rounded,
          color: const Color(0xFFB45309),
        ),
        const SizedBox(width: 10),
        tab(
          key: 'month',
          label: 'Oylik',
          icon: Icons.calendar_month_rounded,
          color: const Color(0xFF16A34A),
        ),
      ],
    );
  }

  Widget _miniStat(String label, String value, {Color? color}) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: primaryGreen.withValues(alpha: 0.12)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 14,
            offset: const Offset(0, 7),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            label,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: Color(0xFF6F7F7B),
              fontSize: 11.5,
              fontWeight: FontWeight.w800,
              height: 1.1,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: color ?? primaryGreen,
              fontSize: 15,
              fontWeight: FontWeight.w900,
              height: 1.0,
            ),
          ),
        ],
      ),
    );
  }

  Widget _statusBreakdown() {
    final items = <({String label, int value, Color color})>[
      (
        label: 'Yangi',
        value: _stats.byStatus.pending,
        color: const Color(0xFF2563EB),
      ),
      (
        label: 'Tayyor',
        value: _stats.byStatus.delivering,
        color: const Color(0xFFB45309),
      ),
      (
        label: 'Rad',
        value: _stats.byStatus.rejected,
        color: const Color(0xFFE11D48),
      ),
      (
        label: 'Yetkazildi',
        value: _stats.byStatus.delivered,
        color: const Color(0xFF16A34A),
      ),
    ];

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: primaryGreen.withValues(alpha: 0.12)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Status bo‘yicha',
            style: TextStyle(
              color: primaryGreen,
              fontSize: 12.5,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: items.map((it) {
              return Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 7,
                ),
                decoration: BoxDecoration(
                  color: it.color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(color: it.color.withValues(alpha: 0.25)),
                ),
                child: Text(
                  '${it.label}: ${it.value}',
                  style: TextStyle(
                    color: it.color,
                    fontSize: 11,
                    fontWeight: FontWeight.w900,
                    height: 1.0,
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _barRow({
    required String label,
    required int value,
    required int max,
    required Color color,
    String Function(int value)? formatValue,
  }) {
    final safeMax = max <= 0 ? 1 : max;
    final ratio = (value <= 0) ? 0.0 : (value / safeMax).clamp(0.0, 1.0);
    final displayValue = (formatValue ?? (v) => v.toString())(value);
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          SizedBox(
            width: 88,
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: Color(0xFF3D4B48),
                fontSize: 12,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(999),
              child: Container(
                height: 10,
                color: color.withValues(alpha: 0.12),
                alignment: Alignment.centerLeft,
                child: FractionallySizedBox(
                  widthFactor: ratio,
                  child: Container(
                    height: 10,
                    color: color.withValues(alpha: 0.9),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 10),
          Text(
            displayValue,
            style: const TextStyle(
              color: primaryGreen,
              fontSize: 12,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }

  Widget _charts() {
    final pending = _stats.byStatus.pending;
    final delivering = _stats.byStatus.delivering;
    final rejected = _stats.byStatus.rejected;
    final delivered = _stats.byStatus.delivered;
    final maxStatus = [
      pending,
      delivering,
      rejected,
      delivered,
    ].fold<int>(0, (m, v) => v > m ? v : m);

    final categories = _stats.byCategory;
    final topCategories = categories.take(5).toList();
    final maxCat = topCategories
        .map((c) => c.sum)
        .fold<int>(0, (m, v) => v > m ? v : m);

    if (maxStatus <= 0 && topCategories.isEmpty) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: primaryGreen.withValues(alpha: 0.12)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Grafik',
            style: TextStyle(
              color: primaryGreen,
              fontSize: 13,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 10),
          if (maxStatus > 0) ...[
            const Text(
              'Status bo‘yicha',
              style: TextStyle(
                color: Color(0xFF6F7F7B),
                fontSize: 12,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 10),
            _barRow(
              label: 'Yangi',
              value: pending,
              max: maxStatus,
              color: const Color(0xFF2563EB),
              formatValue: (v) => v.toString(),
            ),
            _barRow(
              label: 'Tayyor',
              value: delivering,
              max: maxStatus,
              color: const Color(0xFFB45309),
              formatValue: (v) => v.toString(),
            ),
            _barRow(
              label: 'Rad',
              value: rejected,
              max: maxStatus,
              color: const Color(0xFFE11D48),
              formatValue: (v) => v.toString(),
            ),
            _barRow(
              label: 'Yetkazildi',
              value: delivered,
              max: maxStatus,
              color: const Color(0xFF16A34A),
              formatValue: (v) => v.toString(),
            ),
          ],
          if (topCategories.isNotEmpty) ...[
            if (maxStatus > 0) const SizedBox(height: 6),
            const Text(
              'Kategoriyalar (summa)',
              style: TextStyle(
                color: Color(0xFF6F7F7B),
                fontSize: 12,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 10),
            ...topCategories.map((c) {
              final name = (c.categoryName ?? 'Noma’lum').trim();
              final label = name.isEmpty ? 'Noma’lum' : name;
              return _barRow(
                label: label,
                value: c.sum,
                max: maxCat,
                color: const Color(0xFF7C3AED),
                formatValue: _formatIntUz,
              );
            }),
          ],
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: bg,
      child: SafeArea(
        top: true,
        bottom: false,
        child: RefreshIndicator(
          color: primaryGreen,
          onRefresh: _load,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 24),
            children: [
              Row(
                children: [
                  const Expanded(
                    child: Text(
                      'Hisobot',
                      style: TextStyle(
                        color: primaryGreen,
                        fontSize: 20,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                  IconButton(
                    tooltip: 'Yangilash',
                    onPressed: _loading ? null : _load,
                    icon: const Icon(Icons.refresh_rounded),
                    color: primaryGreen,
                  ),
                ],
              ),
              const SizedBox(height: 8),
              _tabs(),
              const SizedBox(height: 12),
              _periodSelector(),
              if (_loading)
                const Padding(
                  padding: EdgeInsets.only(top: 22),
                  child: Center(
                    child: CircularProgressIndicator(color: primaryGreen),
                  ),
                )
              else if (_error != null)
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: const Color(0xFFE15C5C).withValues(alpha: 0.25),
                    ),
                  ),
                  child: Column(
                    children: [
                      Text(
                        _error!,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: Color(0xFFE15C5C),
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 10),
                      OutlinedButton.icon(
                        onPressed: _load,
                        icon: const Icon(Icons.refresh_rounded),
                        label: const Text('Qayta urinish'),
                      ),
                    ],
                  ),
                )
              else ...[
                const SizedBox(height: 8),
                GridView.count(
                  crossAxisCount: 2,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  mainAxisSpacing: 10,
                  crossAxisSpacing: 10,
                  childAspectRatio: 2.15,
                  children: [
                    _miniStat(
                      'Buyurtmalar',
                      _stats.ordersCount.toString(),
                      color: const Color(0xFF2563EB),
                    ),
                    _miniStat(
                      'Jami tushum',
                      _money(_stats.totalSum),
                      color: const Color(0xFFB45309),
                    ),
                    _miniStat(
                      'Yetkazilgan',
                      _stats.byStatus.delivered.toString(),
                      color: const Color(0xFF16A34A),
                    ),
                    _miniStat(
                      'Yetkazilgan tushum',
                      _money(_stats.deliveredSum),
                      color: const Color(0xFF16A34A),
                    ),
                    _miniStat(
                      'Sotilgan tovar',
                      _stats.itemsQty.toString(),
                      color: const Color(0xFF7C3AED),
                    ),
                    _miniStat(
                      'Tovar summasi',
                      _money(_stats.itemsSum),
                      color: const Color(0xFF7C3AED),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                _statusBreakdown(),
                const SizedBox(height: 12),
                _charts(),
                if (_stats.byCategory.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: primaryGreen.withValues(alpha: 0.12),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Kategoriyalar bo‘yicha',
                          style: TextStyle(
                            color: primaryGreen,
                            fontSize: 13,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        const SizedBox(height: 10),
                        ..._stats.byCategory.take(6).map((c) {
                          final name = (c.categoryName ?? 'Noma’lum').trim();
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 8),
                            child: Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    name.isEmpty ? 'Noma’lum' : name,
                                    style: const TextStyle(
                                      color: Color(0xFF3D4B48),
                                      fontSize: 12,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ),
                                Text(
                                  '${c.qty} ta',
                                  style: const TextStyle(
                                    color: Color(0xFF6F7F7B),
                                    fontSize: 12,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Text(
                                  _money(c.sum),
                                  style: const TextStyle(
                                    color: primaryGreen,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w900,
                                  ),
                                ),
                              ],
                            ),
                          );
                        }),
                      ],
                    ),
                  ),
                ],
              ],
            ],
          ),
        ),
      ),
    );
  }
}
