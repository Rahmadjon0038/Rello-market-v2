import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hello_flutter_app/config/api_config.dart';
import 'package:hello_flutter_app/models/store.dart';
import 'package:hello_flutter_app/models/store_details.dart';
import 'package:hello_flutter_app/screens/seller_product_management_screen.dart';
import 'package:hello_flutter_app/screens/store_orders_screen.dart';
import 'package:hello_flutter_app/screens/store_statistics_screen.dart';
import 'package:hello_flutter_app/services/auth_api_service.dart';
import 'package:hello_flutter_app/services/store_api_service.dart';
import 'package:image_picker/image_picker.dart';

class StoreDetailScreen extends StatefulWidget {
  final String storeId;
  final StoreModel? initialStore;

  const StoreDetailScreen({
    super.key,
    required this.storeId,
    this.initialStore,
  });

  @override
  State<StoreDetailScreen> createState() => _StoreDetailScreenState();
}

class _StoreDetailScreenState extends State<StoreDetailScreen> {
  final StoreApiService _storeApi = StoreApiService();
  StoreDetails? _store;
  bool _isLoading = true;
  String? _error;
  int _navIndex = 0;

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
      final store = await _storeApi.getMyStore(widget.storeId);
      if (!mounted) return;
      setState(() {
        _store = store;
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
        _error = "Server bilan bog'lanib bo'lmadi";
        _isLoading = false;
      });
    }
  }

  String _pad2(int v) => v.toString().padLeft(2, '0');

  DateTime? _tryParseDateTime(String raw) {
    if (raw.trim().isEmpty) return null;
    try {
      return DateTime.parse(raw);
    } on Object {
      return null;
    }
  }

  String _formatDateTime(String raw) {
    final parsed = _tryParseDateTime(raw);
    if (parsed == null) return raw.isEmpty ? '-' : raw;
    final local = parsed.toLocal();
    return '${local.year}-${_pad2(local.month)}-${_pad2(local.day)} '
        '${_pad2(local.hour)}:${_pad2(local.minute)}';
  }

  String _formatMoney(num? value) {
    if (value == null) return '-';
    final s = value.toStringAsFixed(0);
    final digits = s.replaceAll(RegExp(r'\D'), '');
    final buf = StringBuffer();
    for (var i = 0; i < digits.length; i++) {
      final remaining = digits.length - i;
      buf.write(digits[i]);
      if (remaining > 1 && remaining % 3 == 1) buf.write(' ');
    }
    return buf.toString();
  }

  String _serviceTypeValue(String raw) {
    final v = raw.trim().toLowerCase();
    return switch (v) {
      'online' => 'Onlayn',
      'offline' => 'Oflayn',
      'both' => 'Onlayn va oflayn',
      _ => raw.trim(),
    };
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

  Future<void> _copy(String label, String value) async {
    final v = value.trim();
    if (v.isEmpty) return;
    await Clipboard.setData(ClipboardData(text: v));
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$label nusxalandi'),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _showLink(String title, String? link) {
    final value = (link ?? '').trim();
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        title,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.of(context).pop(),
                      icon: const Icon(Icons.close_rounded),
                      tooltip: 'Yopish',
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                SelectableText(value.isEmpty ? '-' : value),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: value.isEmpty
                        ? null
                        : () {
                            _copy(title, value);
                            Navigator.of(context).pop();
                          },
                    icon: const Icon(Icons.copy_rounded),
                    label: const Text('Nusxalash'),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showImage(String url) {
    final value = url.trim();
    if (value.isEmpty) return;
    showDialog<void>(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.85),
      builder: (context) {
        return GestureDetector(
          onTap: () => Navigator.of(context).pop(),
          child: Center(
            child: InteractiveViewer(
              minScale: 0.8,
              maxScale: 4,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: Image.network(value, fit: BoxFit.contain),
              ),
            ),
          ),
        );
      },
    );
  }

  Future<void> _openEditStore() async {
    final store = _store;
    if (store == null) return;

    final updated = await showModalBottomSheet<bool>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
      ),
      builder: (context) {
        return _EditStoreSheet(store: store, storeApi: _storeApi);
      },
    );

    if (!mounted) return;
    if (updated == true) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Do'kon ma'lumotlari yangilandi"),
          duration: Duration(seconds: 2),
        ),
      );
      _load();
    }
  }

  @override
  Widget build(BuildContext context) {
    const primaryGreen = Color(0xFF1F5A50);
    const ink = Color(0xFF1F2933);
    const bg = Color(0xFFF7F8FA);

    return Scaffold(
      backgroundColor: bg,
      bottomNavigationBar: NavigationBar(
        selectedIndex: _navIndex,
        onDestinationSelected: (index) {
          if (!mounted) return;
          setState(() => _navIndex = index);
        },
        indicatorColor: const Color(0xFFE6F4EF),
        backgroundColor: Colors.white,
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined, color: ink),
            selectedIcon: Icon(Icons.home_rounded, color: primaryGreen),
            label: "Do'kon",
          ),
          NavigationDestination(
            icon: Icon(Icons.inventory_2_outlined, color: ink),
            selectedIcon: Icon(Icons.inventory_2_rounded, color: primaryGreen),
            label: 'Mahsulotlar',
          ),
          NavigationDestination(
            icon: Icon(Icons.receipt_long_outlined, color: ink),
            selectedIcon: Icon(Icons.receipt_long_rounded, color: primaryGreen),
            label: 'Buyurtmalar',
          ),
          NavigationDestination(
            icon: Icon(Icons.query_stats_outlined, color: ink),
            selectedIcon: Icon(Icons.query_stats_rounded, color: primaryGreen),
            label: 'Statistika',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: primaryGreen))
          : _error != null
          ? _StateCard(message: _error!, onRetry: _load)
          : _store == null
          ? _StateCard(message: "Do'kon topilmadi", onRetry: _load)
          : IndexedStack(
              index: _navIndex,
              children: [
                _StoreOverviewTab(
                  store: _store!,
                  onBack: () => Navigator.of(context).pop(),
                  onEdit: _openEditStore,
                  onRefresh: _load,
                  absoluteUrl: _absoluteUrl,
                  formatDateTime: _formatDateTime,
                  formatMoney: _formatMoney,
                  serviceTypeValue: _serviceTypeValue,
                  onCopy: _copy,
                  onShowLink: _showLink,
                  onShowImage: _showImage,
                ),
                SellerProductManagementScreen(storeId: widget.storeId),
                StoreOrdersScreen(storeId: widget.storeId),
                StoreStatisticsScreen(
                  storeId: widget.storeId,
                  storeName: _store!.name,
                ),
              ],
            ),
    );
  }
}

class _StoreOverviewTab extends StatelessWidget {
  final StoreDetails store;
  final VoidCallback onBack;
  final VoidCallback onEdit;
  final VoidCallback onRefresh;
  final String? Function(String) absoluteUrl;
  final String Function(String) formatDateTime;
  final String Function(num?) formatMoney;
  final String Function(String) serviceTypeValue;
  final Future<void> Function(String label, String value) onCopy;
  final void Function(String title, String? link) onShowLink;
  final void Function(String url) onShowImage;

  const _StoreOverviewTab({
    required this.store,
    required this.onBack,
    required this.onEdit,
    required this.onRefresh,
    required this.absoluteUrl,
    required this.formatDateTime,
    required this.formatMoney,
    required this.serviceTypeValue,
    required this.onCopy,
    required this.onShowLink,
    required this.onShowImage,
  });

  @override
  Widget build(BuildContext context) {
    const primaryGreen = Color(0xFF1F5A50);

    return CustomScrollView(
      slivers: [
        SliverAppBar(
          pinned: true,
          elevation: 0,
          backgroundColor: Colors.transparent,
          foregroundColor: primaryGreen,
          systemOverlayStyle: SystemUiOverlayStyle.light,
          surfaceTintColor: Colors.transparent,
          scrolledUnderElevation: 0,
          title: const SizedBox.shrink(),
          leading: _AppBarCircleButton(
            icon: Icons.arrow_back_rounded,
            onTap: onBack,
          ),
          actions: [
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: _AppBarCircleButton(
                icon: Icons.edit_rounded,
                onTap: onEdit,
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(right: 10),
              child: _AppBarCircleButton(
                icon: Icons.refresh_rounded,
                onTap: onRefresh,
              ),
            ),
          ],
          expandedHeight: 240,
          flexibleSpace: FlexibleSpaceBar(
            background: _HeaderHero(
              title: store.name,
              subtitle: (store.description ?? '').trim(),
              imageUrl: absoluteUrl(store.imagePath ?? ''),
              storeType: serviceTypeValue(store.storeType ?? ''),
              isActive: store.isActive,
              isNew: store.isNew,
              newBadgeText: store.newBadgeText,
            ),
          ),
        ),
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _OwnerStoreSummaryCard(
                  name: store.name,
                  description: (store.description ?? '').trim(),
                  activityType: (store.activityType ?? '').trim(),
                ),
                const SizedBox(height: 12),
                _QuickInfoGrid(
                  items: [
                    _QuickInfoItem(
                      icon: Icons.schedule_rounded,
                      label: 'Ish vaqti',
                      value: (store.workingHours ?? '').trim(),
                    ),
                    _QuickInfoItem(
                      icon: Icons.local_shipping_rounded,
                      label: 'Yetkazish',
                      value: store.hasDelivery ? 'Mavjud' : "Mavjud emas",
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                _SectionCard(
                  title: "Do'kon profili",
                  child: Column(
                    children: [
                      _KeyValue(
                        label: "Do'kon turi",
                        value: serviceTypeValue(
                          (store.storeType ?? '-').trim(),
                        ),
                      ),
                      _KeyValue(
                        label: "Faoliyat yo'nalishi",
                        value: (store.activityType ?? '-').trim(),
                      ),
                      _KeyValue(
                        label: "Ish vaqti",
                        value: (store.workingHours ?? '-').trim(),
                      ),
                      _KeyValue(
                        label: "Yaratilgan",
                        value: formatDateTime(store.createdAt ?? ''),
                      ),
                      _KeyValue(
                        label: "Yangilangan",
                        value: formatDateTime(store.updatedAt ?? ''),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                _SectionCard(
                  title: "Yetkazib berish",
                  child: Column(
                    children: [
                      _KeyValue(
                        label: 'Holati',
                        value: store.hasDelivery ? 'Mavjud' : "Mavjud emas",
                      ),
                      if (store.hasDelivery) ...[
                        _KeyValue(
                          label: 'Hudud',
                          value: (store.deliveryArea ?? '-').trim(),
                        ),
                        _KeyValue(
                          label: 'Narx',
                          value: "${formatMoney(store.deliveryPrice)} so'm",
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                _SectionCard(
                  title: "Rahbar va aloqa",
                  child: Column(
                    children: [
                      _KeyValue(
                        label: 'Ism',
                        value: store.director == null
                            ? '-'
                            : '${store.director!.firstName} ${store.director!.lastName}'
                                  .trim(),
                      ),
                      _KeyValue(
                        label: 'Telefon',
                        value: (store.director?.phone ?? '-').trim(),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                _ContactCard(
                  address: (store.address ?? '').trim(),
                  mapLink: (store.mapLocation ?? '').trim(),
                  onCopyAddress: () =>
                      onCopy('Manzil', (store.address ?? '').trim()),
                  onShowMap: () =>
                      onShowLink('Google Map link', store.mapLocation),
                ),
                const SizedBox(height: 12),
                _SectionCard(
                  title: "Rasmlar",
                  child: _ImageStrip(
                    urls: [
                      ...[
                        absoluteUrl(store.imagePath ?? ''),
                        ...store.bannerImages.map(absoluteUrl),
                      ].whereType<String>(),
                    ],
                    onTap: onShowImage,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _EditStoreSheet extends StatefulWidget {
  final StoreDetails store;
  final StoreApiService storeApi;

  const _EditStoreSheet({required this.store, required this.storeApi});

  @override
  State<_EditStoreSheet> createState() => _EditStoreSheetState();
}

class _EditStoreSheetState extends State<_EditStoreSheet> {
  static const _primaryGreen = Color(0xFF1F5A50);
  static const _muted = Color(0xFF6F8982);
  static const _surface = Color(0xFFF7F8FA);
  static const _line = Color(0xFFD8E5E1);

  final ImagePicker _picker = ImagePicker();
  late final TextEditingController _nameCtrl;
  late final TextEditingController _descriptionCtrl;
  late final TextEditingController _activityCtrl;
  late final TextEditingController _addressCtrl;
  late final TextEditingController _mapCtrl;
  late final TextEditingController _hoursCtrl;
  late final TextEditingController _deliveryAreaCtrl;
  late final TextEditingController _deliveryPriceCtrl;
  late String _storeType;
  late bool _hasDelivery;
  File? _logoFile;
  List<File> _bannerFiles = const [];
  bool _isSubmitting = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    final store = widget.store;
    _nameCtrl = TextEditingController(text: store.name);
    _descriptionCtrl = TextEditingController(text: store.description ?? '');
    _activityCtrl = TextEditingController(text: store.activityType ?? '');
    _addressCtrl = TextEditingController(text: store.address ?? '');
    _mapCtrl = TextEditingController(text: store.mapLocation ?? '');
    _hoursCtrl = TextEditingController(text: store.workingHours ?? '');
    _deliveryAreaCtrl = TextEditingController(text: store.deliveryArea ?? '');
    _deliveryPriceCtrl = TextEditingController(
      text: store.deliveryPrice?.toStringAsFixed(0) ?? '',
    );
    _storeType = _normalizeStoreType(store.storeType ?? 'both');
    _hasDelivery = store.hasDelivery;
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _descriptionCtrl.dispose();
    _activityCtrl.dispose();
    _addressCtrl.dispose();
    _mapCtrl.dispose();
    _hoursCtrl.dispose();
    _deliveryAreaCtrl.dispose();
    _deliveryPriceCtrl.dispose();
    super.dispose();
  }

  String _normalizeStoreType(String value) {
    final v = value.trim().toLowerCase();
    if (v == 'online' || v == 'offline' || v == 'both') return v;
    return 'both';
  }

  Future<void> _pickLogo() async {
    final picked = await _picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 85,
    );
    if (picked == null || !mounted) return;
    setState(() {
      _logoFile = File(picked.path);
      _error = null;
    });
  }

  Future<void> _pickBanners() async {
    final picked = await _picker.pickMultiImage(imageQuality: 85);
    if (picked.isEmpty || !mounted) return;
    setState(() {
      _bannerFiles = picked.map((item) => File(item.path)).toList();
      _error = null;
    });
  }

  String? _validate() {
    if (_nameCtrl.text.trim().isEmpty) return "Do'kon nomini kiriting";
    if (_descriptionCtrl.text.trim().isEmpty) {
      return "Do'kon tavsifini kiriting";
    }
    if (_activityCtrl.text.trim().isEmpty) return "Faoliyat turini kiriting";
    if (_mapCtrl.text.trim().isEmpty) return "Xarita linkini kiriting";
    if (_hoursCtrl.text.trim().isEmpty) return "Ish vaqtini kiriting";
    if ((_storeType == 'offline' || _storeType == 'both') &&
        _addressCtrl.text.trim().isEmpty) {
      return "Offline do'kon uchun manzil majburiy";
    }
    if (_hasDelivery) {
      if (_deliveryAreaCtrl.text.trim().isEmpty) {
        return "Yetkazib berish hududini kiriting";
      }
      final price = num.tryParse(_deliveryPriceCtrl.text.trim());
      if (price == null || price < 0) {
        return "Yetkazib berish narxi 0 yoki undan katta bo'lishi kerak";
      }
    }
    return null;
  }

  Future<void> _submit() async {
    final validation = _validate();
    if (validation != null) {
      setState(() => _error = validation);
      return;
    }

    setState(() {
      _isSubmitting = true;
      _error = null;
    });

    final fields = <String, dynamic>{
      'storeName': _nameCtrl.text.trim(),
      'storeDescription': _descriptionCtrl.text.trim(),
      'storeType': _storeType,
      'activityType': _activityCtrl.text.trim(),
      'storeAddress': _addressCtrl.text.trim(),
      'storeMapLocation': _mapCtrl.text.trim(),
      'workingHours': _hoursCtrl.text.trim(),
      'hasDelivery': _hasDelivery,
      if (_hasDelivery) 'deliveryArea': _deliveryAreaCtrl.text.trim(),
      if (_hasDelivery)
        'deliveryPrice': num.tryParse(_deliveryPriceCtrl.text.trim()) ?? 0,
    };

    try {
      await widget.storeApi.updateStore(
        widget.store.id,
        fields: fields,
        storeLogoFile: _logoFile,
        storeBannerImageFiles: _bannerFiles,
      );
      if (!mounted) return;
      Navigator.of(context).pop(true);
    } on AuthApiException catch (error) {
      if (!mounted) return;
      setState(() => _error = error.message);
    } on Object {
      if (!mounted) return;
      setState(() => _error = "Do'kon ma'lumotlarini yangilab bo'lmadi");
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  InputDecoration _inputDecoration(String label) {
    OutlineInputBorder border(Color color, {double width = 1}) {
      return OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: color, width: width),
      );
    }

    return InputDecoration(
      labelText: label,
      labelStyle: const TextStyle(
        color: _muted,
        fontSize: 13,
        fontWeight: FontWeight.w700,
      ),
      floatingLabelStyle: const TextStyle(
        color: _primaryGreen,
        fontSize: 13,
        fontWeight: FontWeight.w900,
      ),
      filled: true,
      fillColor: _surface,
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      enabledBorder: border(_line),
      disabledBorder: border(_line.withValues(alpha: 0.72)),
      focusedBorder: border(_primaryGreen, width: 1.4),
      errorBorder: border(Colors.redAccent.withValues(alpha: 0.7)),
      focusedErrorBorder: border(Colors.redAccent, width: 1.4),
    );
  }

  TextStyle get _fieldStyle {
    return const TextStyle(
      color: _primaryGreen,
      fontSize: 14,
      fontWeight: FontWeight.w800,
    );
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return SafeArea(
      child: AnimatedPadding(
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeOut,
        padding: EdgeInsets.only(bottom: bottomInset),
        child: FractionallySizedBox(
          heightFactor: 0.92,
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 2, 8, 10),
                child: Row(
                  children: [
                    const Expanded(
                      child: Text(
                        "Do'konni tahrirlash",
                        style: TextStyle(
                          color: _primaryGreen,
                          fontSize: 18,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                    IconButton(
                      onPressed: _isSubmitting
                          ? null
                          : () => Navigator.of(context).pop(false),
                      icon: const Icon(Icons.close_rounded),
                      color: _primaryGreen,
                      tooltip: 'Yopish',
                    ),
                  ],
                ),
              ),
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 18),
                  children: [
                    if (_error != null) ...[
                      _EditError(message: _error!),
                      const SizedBox(height: 12),
                    ],
                    _EditSectionTitle(title: "Asosiy ma'lumotlar"),
                    const SizedBox(height: 10),
                    TextField(
                      controller: _nameCtrl,
                      enabled: !_isSubmitting,
                      cursorColor: _primaryGreen,
                      textCapitalization: TextCapitalization.words,
                      style: _fieldStyle,
                      decoration: _inputDecoration("Do'kon nomi"),
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      controller: _descriptionCtrl,
                      enabled: !_isSubmitting,
                      minLines: 3,
                      maxLines: 5,
                      cursorColor: _primaryGreen,
                      textCapitalization: TextCapitalization.sentences,
                      style: _fieldStyle.copyWith(height: 1.35),
                      decoration: _inputDecoration("Do'kon tavsifi"),
                    ),
                    const SizedBox(height: 10),
                    DropdownButtonFormField<String>(
                      initialValue: _storeType,
                      items: const [
                        DropdownMenuItem(
                          value: 'online',
                          child: Text('Online'),
                        ),
                        DropdownMenuItem(
                          value: 'offline',
                          child: Text('Offline'),
                        ),
                        DropdownMenuItem(
                          value: 'both',
                          child: Text('Ikkalasi'),
                        ),
                      ],
                      onChanged: _isSubmitting
                          ? null
                          : (value) {
                              if (value == null) return;
                              setState(() => _storeType = value);
                            },
                      decoration: _inputDecoration("Do'kon turi"),
                      dropdownColor: Colors.white,
                      style: _fieldStyle,
                      iconEnabledColor: _primaryGreen,
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      controller: _activityCtrl,
                      enabled: !_isSubmitting,
                      cursorColor: _primaryGreen,
                      textCapitalization: TextCapitalization.words,
                      style: _fieldStyle,
                      decoration: _inputDecoration("Faoliyat turi"),
                    ),
                    const SizedBox(height: 16),
                    _EditSectionTitle(title: "Manzil va ish vaqti"),
                    const SizedBox(height: 10),
                    TextField(
                      controller: _addressCtrl,
                      enabled: !_isSubmitting,
                      minLines: 2,
                      maxLines: 4,
                      cursorColor: _primaryGreen,
                      textCapitalization: TextCapitalization.sentences,
                      style: _fieldStyle.copyWith(height: 1.35),
                      decoration: _inputDecoration("Do'kon manzili"),
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      controller: _mapCtrl,
                      enabled: !_isSubmitting,
                      cursorColor: _primaryGreen,
                      keyboardType: TextInputType.url,
                      style: _fieldStyle,
                      decoration: _inputDecoration("Xarita linki"),
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      controller: _hoursCtrl,
                      enabled: !_isSubmitting,
                      cursorColor: _primaryGreen,
                      style: _fieldStyle,
                      decoration: _inputDecoration(
                        "Ish vaqti",
                      ).copyWith(hintText: '09:00-21:00'),
                    ),
                    const SizedBox(height: 16),
                    _DeliveryEditor(
                      hasDelivery: _hasDelivery,
                      onChanged: _isSubmitting
                          ? null
                          : (value) => setState(() => _hasDelivery = value),
                    ),
                    if (_hasDelivery) ...[
                      const SizedBox(height: 10),
                      TextField(
                        controller: _deliveryAreaCtrl,
                        enabled: !_isSubmitting,
                        cursorColor: _primaryGreen,
                        textCapitalization: TextCapitalization.sentences,
                        style: _fieldStyle,
                        decoration: _inputDecoration("Yetkazish hududi"),
                      ),
                      const SizedBox(height: 10),
                      TextField(
                        controller: _deliveryPriceCtrl,
                        enabled: !_isSubmitting,
                        cursorColor: _primaryGreen,
                        keyboardType: TextInputType.number,
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                        ],
                        style: _fieldStyle,
                        decoration: _inputDecoration("Yetkazish narxi"),
                      ),
                    ],
                    const SizedBox(height: 16),
                    _EditSectionTitle(title: 'Rasmlar'),
                    const SizedBox(height: 10),
                    _ImagePickRow(
                      title: 'Logo',
                      subtitle: _logoFile == null
                          ? 'Yangi logo tanlanmagan'
                          : _logoFile!.path.split(Platform.pathSeparator).last,
                      icon: Icons.image_rounded,
                      onTap: _isSubmitting ? null : _pickLogo,
                    ),
                    const SizedBox(height: 10),
                    _ImagePickRow(
                      title: 'Banner rasmlar',
                      subtitle: _bannerFiles.isEmpty
                          ? 'Yangi banner tanlanmagan'
                          : '${_bannerFiles.length} ta rasm tanlandi',
                      icon: Icons.collections_rounded,
                      onTap: _isSubmitting ? null : _pickBanners,
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.fromLTRB(16, 10, 16, 16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  border: Border(
                    top: BorderSide(color: _line.withValues(alpha: 0.8)),
                  ),
                ),
                child: SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton.icon(
                    onPressed: _isSubmitting ? null : _submit,
                    icon: _isSubmitting
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Icon(Icons.save_rounded),
                    label: Text(
                      _isSubmitting ? 'Saqlanmoqda' : 'Saqlash',
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _primaryGreen,
                      disabledBackgroundColor: _primaryGreen.withValues(
                        alpha: 0.65,
                      ),
                      foregroundColor: Colors.white,
                      disabledForegroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
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

class _EditSectionTitle extends StatelessWidget {
  final String title;

  const _EditSectionTitle({required this.title});

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: const TextStyle(
        color: Color(0xFF1F5A50),
        fontSize: 15,
        fontWeight: FontWeight.w900,
      ),
    );
  }
}

class _EditError extends StatelessWidget {
  final String message;

  const _EditError({required this.message});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.redAccent.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline_rounded, color: Colors.redAccent),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(
                color: Colors.redAccent,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _DeliveryEditor extends StatelessWidget {
  final bool hasDelivery;
  final ValueChanged<bool>? onChanged;

  const _DeliveryEditor({required this.hasDelivery, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    const primaryGreen = Color(0xFF1F5A50);

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFF7F8FA),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFD8E5E1)),
      ),
      child: Row(
        children: [
          const Icon(Icons.local_shipping_rounded, color: primaryGreen),
          const SizedBox(width: 10),
          const Expanded(
            child: Text(
              'Yetkazib berish',
              style: TextStyle(
                color: primaryGreen,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
          Switch(
            value: hasDelivery,
            onChanged: onChanged,
            activeThumbColor: primaryGreen,
          ),
        ],
      ),
    );
  }
}

class _ImagePickRow extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final VoidCallback? onTap;

  const _ImagePickRow({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    const primaryGreen = Color(0xFF1F5A50);

    return Material(
      color: const Color(0xFFF7F8FA),
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFFD8E5E1)),
          ),
          child: Row(
            children: [
              Icon(icon, color: primaryGreen),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        color: primaryGreen,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      subtitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: primaryGreen.withValues(alpha: 0.65),
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right_rounded, color: primaryGreen),
            ],
          ),
        ),
      ),
    );
  }
}

class _StateCard extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _StateCard({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    const primaryGreen = Color(0xFF1F5A50);

    return Center(
      child: Container(
        margin: const EdgeInsets.all(16),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFFE6F4EF),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
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
      ),
    );
  }
}

class _HeaderHero extends StatelessWidget {
  final String title;
  final String subtitle;
  final String? imageUrl;
  final String storeType;
  final bool isActive;
  final bool isNew;
  final String? newBadgeText;

  const _HeaderHero({
    required this.title,
    required this.subtitle,
    required this.imageUrl,
    required this.storeType,
    required this.isActive,
    required this.isNew,
    required this.newBadgeText,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        if (imageUrl != null && imageUrl!.isNotEmpty)
          Image.network(
            imageUrl!,
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) => _heroFallback(),
          )
        else
          _heroFallback(),
        Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Colors.black.withValues(alpha: 0.28),
                Colors.black.withValues(alpha: 0.55),
              ],
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
                title.trim().isEmpty ? "Do'kon" : title.trim(),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 26,
                  height: 1.08,
                  fontWeight: FontWeight.w900,
                ),
              ),
              if (subtitle.trim().isNotEmpty) ...[
                const SizedBox(height: 8),
                Text(
                  subtitle.trim(),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.86),
                    fontSize: 13,
                    height: 1.35,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
              const SizedBox(height: 12),
              Row(
                children: [
                  _HeroPill(
                    label: isActive ? 'Faol' : 'Nofaol',
                    icon: isActive
                        ? Icons.check_circle_rounded
                        : Icons.do_not_disturb_on_rounded,
                  ),
                  const SizedBox(width: 8),
                  if (isNew) ...[
                    const SizedBox(width: 8),
                    _HeroPill(
                      label: (newBadgeText ?? '').trim().isEmpty
                          ? "Yangi do'kon"
                          : newBadgeText!.trim(),
                      icon: Icons.auto_awesome_rounded,
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _heroFallback() {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFE6F4EF), Color(0xFFF7F8FA)],
        ),
      ),
      child: const Center(
        child: Icon(
          Icons.storefront_rounded,
          size: 72,
          color: Color(0xFF1F5A50),
        ),
      ),
    );
  }
}

class _HeroPill extends StatelessWidget {
  final String label;
  final IconData icon;

  const _HeroPill({required this.label, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.18),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: Colors.white.withValues(alpha: 0.22)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: Colors.white),
          const SizedBox(width: 6),
          Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w900,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}

class _AppBarCircleButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;

  const _AppBarCircleButton({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.only(left: 10, top: 6),
        child: Material(
          color: Colors.black.withValues(alpha: 0.28),
          shape: const CircleBorder(),
          child: InkWell(
            customBorder: const CircleBorder(),
            onTap: onTap,
            child: SizedBox(
              width: 40,
              height: 40,
              child: Icon(icon, color: Colors.white),
            ),
          ),
        ),
      ),
    );
  }
}

class _OwnerStoreSummaryCard extends StatelessWidget {
  final String name;
  final String description;
  final String activityType;

  const _OwnerStoreSummaryCard({
    required this.name,
    required this.description,
    required this.activityType,
  });

  @override
  Widget build(BuildContext context) {
    const primaryGreen = Color(0xFF1F5A50);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: primaryGreen.withValues(alpha: 0.1)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 14,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  name.trim().isEmpty ? "Do'kon" : name.trim(),
                  style: const TextStyle(
                    color: primaryGreen,
                    fontSize: 21,
                    height: 1.15,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ],
          ),
          if (description.trim().isNotEmpty) ...[
            const SizedBox(height: 10),
            Text(
              description.trim(),
              style: const TextStyle(
                color: Color(0xFF42524E),
                fontSize: 13,
                height: 1.45,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
          if (activityType.isNotEmpty) ...[
            const SizedBox(height: 12),
            _MetaPill(icon: Icons.category_rounded, label: activityType),
          ],
        ],
      ),
    );
  }
}

class _MetaPill extends StatelessWidget {
  final IconData icon;
  final String label;

  const _MetaPill({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    const primaryGreen = Color(0xFF1F5A50);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFFE6F4EF),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: primaryGreen, size: 15),
          const SizedBox(width: 6),
          Text(
            label,
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
}

class _QuickInfoItem {
  final IconData icon;
  final String label;
  final String value;

  const _QuickInfoItem({
    required this.icon,
    required this.label,
    required this.value,
  });
}

class _QuickInfoGrid extends StatelessWidget {
  final List<_QuickInfoItem> items;

  const _QuickInfoGrid({required this.items});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        for (var i = 0; i < items.length; i++) ...[
          Expanded(child: _QuickInfoTile(item: items[i])),
          if (i != items.length - 1) const SizedBox(width: 10),
        ],
      ],
    );
  }
}

class _QuickInfoTile extends StatelessWidget {
  final _QuickInfoItem item;

  const _QuickInfoTile({required this.item});

  @override
  Widget build(BuildContext context) {
    const primaryGreen = Color(0xFF1F5A50);
    final value = item.value.trim().isEmpty ? '-' : item.value.trim();

    return Container(
      constraints: const BoxConstraints(minHeight: 92),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: primaryGreen.withValues(alpha: 0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(item.icon, color: primaryGreen, size: 22),
          const SizedBox(height: 10),
          Text(
            item.label,
            style: TextStyle(
              color: primaryGreen.withValues(alpha: 0.62),
              fontSize: 11,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            value,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: primaryGreen,
              fontSize: 13,
              height: 1.2,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }
}

class _ContactCard extends StatelessWidget {
  final String address;
  final String mapLink;
  final VoidCallback onCopyAddress;
  final VoidCallback onShowMap;

  const _ContactCard({
    required this.address,
    required this.mapLink,
    required this.onCopyAddress,
    required this.onShowMap,
  });

  @override
  Widget build(BuildContext context) {
    const primaryGreen = Color(0xFF1F5A50);

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: primaryGreen.withValues(alpha: 0.1)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 14,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          _ContactRow(
            icon: Icons.location_on_rounded,
            title: 'Manzil',
            value: address,
            action: _ContactAction(
              icon: Icons.copy_rounded,
              label: 'Nusxa',
              onTap: address.trim().isEmpty ? null : onCopyAddress,
            ),
          ),
          const SizedBox(height: 10),
          _ContactRow(
            icon: Icons.map_rounded,
            title: 'Xarita',
            value: mapLink,
            action: _ContactAction(
              icon: Icons.open_in_new_rounded,
              label: "Ko'rish",
              onTap: mapLink.trim().isEmpty ? null : onShowMap,
            ),
          ),
        ],
      ),
    );
  }
}

class _ContactRow extends StatelessWidget {
  final IconData icon;
  final String title;
  final String value;
  final _ContactAction action;

  const _ContactRow({
    required this.icon,
    required this.title,
    required this.value,
    required this.action,
  });

  @override
  Widget build(BuildContext context) {
    const primaryGreen = Color(0xFF1F5A50);
    final v = value.trim().isEmpty ? '-' : value.trim();

    return Row(
      children: [
        Container(
          width: 42,
          height: 42,
          decoration: BoxDecoration(
            color: const Color(0xFFE6F4EF),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Icon(icon, color: primaryGreen),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  color: primaryGreen.withValues(alpha: 0.65),
                  fontWeight: FontWeight.w800,
                  fontSize: 12,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                v,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: primaryGreen,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 10),
        _ContactActionButton(action: action),
      ],
    );
  }
}

class _ContactAction {
  final IconData icon;
  final String label;
  final VoidCallback? onTap;

  const _ContactAction({
    required this.icon,
    required this.label,
    required this.onTap,
  });
}

class _ContactActionButton extends StatelessWidget {
  final _ContactAction action;

  const _ContactActionButton({required this.action});

  @override
  Widget build(BuildContext context) {
    const primaryGreen = Color(0xFF1F5A50);

    return SizedBox(
      height: 40,
      child: OutlinedButton.icon(
        onPressed: action.onTap,
        icon: Icon(action.icon, size: 18),
        label: Text(action.label),
        style: OutlinedButton.styleFrom(
          foregroundColor: primaryGreen,
          side: BorderSide(color: primaryGreen.withValues(alpha: 0.25)),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 10),
          textStyle: const TextStyle(fontWeight: FontWeight.w900, fontSize: 12),
        ),
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  final String title;
  final Widget child;

  const _SectionCard({required this.title, required this.child});

  @override
  Widget build(BuildContext context) {
    const primaryGreen = Color(0xFF1F5A50);

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: primaryGreen.withValues(alpha: 0.1)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 14,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontWeight: FontWeight.w900,
              color: primaryGreen,
              fontSize: 15,
            ),
          ),
          const SizedBox(height: 10),
          child,
        ],
      ),
    );
  }
}

class _KeyValue extends StatelessWidget {
  final String label;
  final String value;

  const _KeyValue({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    const primaryGreen = Color(0xFF1F5A50);
    final v = value.trim().isEmpty ? '-' : value.trim();

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 4,
            child: Text(
              label,
              style: TextStyle(
                color: primaryGreen.withValues(alpha: 0.62),
                fontWeight: FontWeight.w800,
                fontSize: 12,
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            flex: 6,
            child: Text(
              v,
              style: const TextStyle(
                color: primaryGreen,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ImageStrip extends StatelessWidget {
  final List<String> urls;
  final void Function(String url) onTap;

  const _ImageStrip({required this.urls, required this.onTap});

  @override
  Widget build(BuildContext context) {
    const primaryGreen = Color(0xFF1F5A50);

    final unique = <String>[];
    for (final url in urls) {
      final u = url.trim();
      if (u.isEmpty) continue;
      if (unique.contains(u)) continue;
      unique.add(u);
    }

    if (unique.isEmpty) {
      return Text(
        "Rasm yo'q",
        style: TextStyle(
          color: primaryGreen.withValues(alpha: 0.62),
          fontWeight: FontWeight.w700,
        ),
      );
    }

    return SizedBox(
      height: 120,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: unique.length,
        separatorBuilder: (context, index) => const SizedBox(width: 10),
        itemBuilder: (context, index) {
          final url = unique[index];
          return Material(
            color: const Color(0xFFF1F5F4),
            borderRadius: BorderRadius.circular(16),
            child: InkWell(
              onTap: () => onTap(url),
              borderRadius: BorderRadius.circular(16),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: AspectRatio(
                  aspectRatio: 16 / 9,
                  child: Image.network(
                    url,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) => Container(
                      color: primaryGreen.withValues(alpha: 0.06),
                      alignment: Alignment.center,
                      child: const Text(
                        "Rasm yuklanmadi",
                        style: TextStyle(
                          color: primaryGreen,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
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
            ),
          );
        },
      ),
    );
  }
}
