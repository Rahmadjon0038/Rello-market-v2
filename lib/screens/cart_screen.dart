import 'package:flutter/material.dart';
import 'package:hello_flutter_app/screens/pick_location_screen.dart';
import 'package:latlong2/latlong.dart';

class CartScreen extends StatefulWidget {
  const CartScreen({super.key});

  @override
  State<CartScreen> createState() => _CartScreenState();
}

class _CartScreenState extends State<CartScreen> {
  final List<_CartItem> _items = [
    _CartItem(
      id: 1,
      name: 'Smart Blender',
      price: 1250000,
      qty: 1,
      selected: true,
      imagePath: 'assets/corusel1.png',
    ),
    _CartItem(
      id: 2,
      name: 'Quloqchin Pro',
      price: 499000,
      qty: 2,
      selected: true,
      imagePath: 'assets/corusel2.png',
    ),
  ];
  String _payMethod = 'Click';
  String _receiverName = 'Mening profilim';
  String _receiverPhone = '+998';
  String _deliveryPlace = 'Manzil tanlanmagan';
  LatLng? _deliveryPoint;

  int _total() {
    int sum = 0;
    for (final i in _items) {
      if (i.selected) {
        sum += i.price * i.qty;
      }
    }
    return sum;
  }

  String _format(int v) {
    final s = v.toString();
    final b = StringBuffer();
    for (int i = 0; i < s.length; i++) {
      final idx = s.length - i;
      b.write(s[i]);
      if (idx > 1 && idx % 3 == 1) b.write(' ');
    }
    return b.toString();
  }

  void _changeQty(int id, int delta) {
    setState(() {
      final idx = _items.indexWhere((e) => e.id == id);
      if (idx == -1) return;
      final next = _items[idx].qty + delta;
      _items[idx] = _items[idx].copyWith(qty: next < 1 ? 1 : next);
    });
  }

  void _removeItem(int id) {
    setState(() {
      _items.removeWhere((e) => e.id == id);
    });
  }

  void _toggleSelected(int id) {
    setState(() {
      final idx = _items.indexWhere((e) => e.id == id);
      if (idx == -1) return;
      _items[idx] =
          _items[idx].copyWith(selected: !_items[idx].selected);
    });
  }

  void _selectPay(String method) {
    setState(() => _payMethod = method);
  }

  void _openReceiverModal() {
    final nameCtrl = TextEditingController(text: _receiverName);
    final phoneCtrl = TextEditingController(text: _receiverPhone);
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Padding(
            padding: EdgeInsets.fromLTRB(
              16,
              8,
              16,
              MediaQuery.of(ctx).viewInsets.bottom + 16,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Buyurtmani oluvchi',
                  style: TextStyle(
                    color: Color(0xFF0F2F2B),
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: nameCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Ism familiya',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: phoneCtrl,
                  keyboardType: TextInputType.phone,
                  decoration: const InputDecoration(
                    labelText: 'Telefon raqami',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  height: 44,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF0F2F2B),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    onPressed: () {
                      setState(() {
                        _receiverName = nameCtrl.text.trim().isEmpty
                            ? _receiverName
                            : nameCtrl.text.trim();
                        _receiverPhone = phoneCtrl.text.trim().isEmpty
                            ? _receiverPhone
                            : phoneCtrl.text.trim();
                      });
                      Navigator.pop(ctx);
                    },
                    child: const Text(
                      'Saqlash',
                      style:
                          TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _openDeliveryModal() {
    Navigator.of(context)
        .push<_PickResult>(
      MaterialPageRoute(
        builder: (_) => PickLocationScreen(initial: _deliveryPoint),
      ),
    )
        .then((result) {
      if (result == null) return;
      setState(() {
        _deliveryPoint = result.point;
        _deliveryPlace = result.address.isEmpty
            ? 'Lat: ${result.point.latitude.toStringAsFixed(5)}, Lng: ${result.point.longitude.toStringAsFixed(5)}'
            : result.address;
      });
    });
  }

  void _openPaySummary() {
    showModalBottomSheet(
      context: context,
      showDragHandle: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'To‘lov: $_payMethod',
                  style: const TextStyle(
                    color: Color(0xFF0F2F2B),
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 10),
                _RowItem(
                  label: 'Jami summa',
                  value: '${_format(_total())} so‘m',
                  bold: true,
                ),
                const SizedBox(height: 12),
                SizedBox(
                  height: 44,
                  width: double.infinity,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF0F2F2B),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    onPressed: () {},
                    child: const Text(
                      "To'lash",
                      style:
                          TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    const primaryGreen = Color(0xFF0F2F2B);

    if (_items.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        child: Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(18),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.12),
                blurRadius: 22,
                offset: const Offset(0, 10),
              ),
            ],
            border: Border.all(color: primaryGreen.withOpacity(0.18)),
          ),
          child: Column(
            children: const [
              Icon(Icons.shopping_cart_outlined,
                  size: 52, color: primaryGreen),
              SizedBox(height: 12),
              Text(
                'Savat bo‘sh',
                style: TextStyle(
                  color: primaryGreen,
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
              ),
              SizedBox(height: 6),
              Text(
                'Mahsulot qo‘shing va buyurtma bering.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Color(0xFF8A9A97),
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        children: [
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _items.length,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final item = _items[index];
              return _CartCard(
                item: item,
                onToggle: () => _toggleSelected(item.id),
                onAdd: () => _changeQty(item.id, 1),
                onRemove: () => _changeQty(item.id, -1),
                onDelete: () => _removeItem(item.id),
              );
            },
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.08),
                  blurRadius: 16,
                  offset: const Offset(0, 8),
                ),
              ],
              border: Border.all(color: primaryGreen.withOpacity(0.12)),
            ),
            child: Column(
              children: [
                _SectionCard(
                  title: 'Buyurtmani oluvchi',
                  value: '$_receiverName\n$_receiverPhone',
                  onTap: _openReceiverModal,
                ),
                const SizedBox(height: 12),
                _SectionCard(
                  title: 'Yetkazib berish joyi',
                  value: _deliveryPlace,
                  onTap: _openDeliveryModal,
                ),
                const SizedBox(height: 12),
                const Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    "To'lov shaklini tanlang",
                    style: TextStyle(
                      color: Color(0xFF0F2F2B),
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                _PayOption(
                  title: 'Click',
                  leading: Image.asset('assets/click.png', width: 40, height: 40),
                  selected: _payMethod == 'Click',
                  onTap: () => _selectPay('Click'),
                ),
                const SizedBox(height: 8),
                _PayOption(
                  title: 'Payme',
                  leading: Image.asset('assets/payme.png', width: 40, height: 40),
                  selected: _payMethod == 'Payme',
                  onTap: () => _selectPay('Payme'),
                ),
                const SizedBox(height: 8),
                _PayOption(
                  title: "Mahsulotni olgandan so'ng",
                  selected: _payMethod == "Mahsulotni olgandan so'ng",
                  onTap: () => _selectPay("Mahsulotni olgandan so'ng"),
                ),
                const SizedBox(height: 12),
                _RowItem(
                  label: 'Jami',
                  value: '${_format(_total())} so‘m',
                  bold: true,
                ),
                const SizedBox(height: 12),
                SizedBox(
                  height: 44,
                  width: double.infinity,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: primaryGreen,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    onPressed: () {
                      final hasSelected = _items.any((e) => e.selected);
                      if (!hasSelected) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Maxsulotlarni belgilang'),
                            duration: Duration(seconds: 2),
                          ),
                        );
                        return;
                      }
                      _openPaySummary();
                    },
                    child: const Text(
                      'Buyurtma berish',
                      style:
                          TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}

class _CartItem {
  final int id;
  final String name;
  final int price;
  final int qty;
  final bool selected;
  final String imagePath;

  const _CartItem({
    required this.id,
    required this.name,
    required this.price,
    required this.qty,
    required this.selected,
    required this.imagePath,
  });

  _CartItem copyWith({int? qty, bool? selected}) {
    return _CartItem(
      id: id,
      name: name,
      price: price,
      qty: qty ?? this.qty,
      selected: selected ?? this.selected,
      imagePath: imagePath,
    );
  }
}

class _CartCard extends StatelessWidget {
  final _CartItem item;
  final VoidCallback onToggle;
  final VoidCallback onAdd;
  final VoidCallback onRemove;
  final VoidCallback onDelete;

  const _CartCard({
    required this.item,
    required this.onToggle,
    required this.onAdd,
    required this.onRemove,
    required this.onDelete,
  });

  String _format(int v) {
    final s = v.toString();
    final b = StringBuffer();
    for (int i = 0; i < s.length; i++) {
      final idx = s.length - i;
      b.write(s[i]);
      if (idx > 1 && idx % 3 == 1) b.write(' ');
    }
    return b.toString();
  }

  @override
  Widget build(BuildContext context) {
    const primaryGreen = Color(0xFF0F2F2B);
    const softGray = Color(0xFFF6F7F8);

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
        border: Border.all(color: primaryGreen.withOpacity(0.12)),
      ),
      child: Column(
        children: [
          Row(
            children: [
              GestureDetector(
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      fullscreenDialog: true,
                      builder: (_) => _ImagePreview(imagePath: item.imagePath),
                    ),
                  );
                },
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.asset(
                    item.imagePath,
                    width: 72,
                    height: 72,
                    fit: BoxFit.cover,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: primaryGreen,
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${_format(item.price)} so‘m',
                      style: TextStyle(
                        color: primaryGreen.withOpacity(0.7),
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        _QtyButton(icon: Icons.remove, onTap: onRemove),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: softGray,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            '${item.qty}',
                            style: const TextStyle(
                              color: primaryGreen,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        _QtyButton(icon: Icons.add, onTap: onAdd),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Column(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    width: 32,
                    height: 32,
                    padding: const EdgeInsets.all(2),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: primaryGreen.withOpacity(0.12)),
                    ),
                    child: Checkbox(
                      value: item.selected,
                      onChanged: (_) => onToggle(),
                      activeColor: primaryGreen,
                      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      visualDensity: VisualDensity.compact,
                    ),
                  ),
                  const SizedBox(height: 12),
                  IconButton(
                    onPressed: onDelete,
                    icon: const Icon(Icons.close, color: Colors.red, size: 18),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _QtyButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;

  const _QtyButton({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    const primaryGreen = Color(0xFF0F2F2B);
    const softGray = Color(0xFFF6F7F8);

    return Container(
      width: 28,
      height: 28,
      decoration: BoxDecoration(
        color: softGray,
        borderRadius: BorderRadius.circular(8),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(8),
        onTap: onTap,
        child: Icon(icon, size: 16, color: primaryGreen),
      ),
    );
  }
}

class _RowItem extends StatelessWidget {
  final String label;
  final String value;
  final bool bold;

  const _RowItem({
    required this.label,
    required this.value,
    this.bold = false,
  });

  @override
  Widget build(BuildContext context) {
    const primaryGreen = Color(0xFF0F2F2B);
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            color: primaryGreen.withOpacity(bold ? 1 : 0.7),
            fontSize: bold ? 14 : 12,
            fontWeight: bold ? FontWeight.w700 : FontWeight.w500,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            color: primaryGreen,
            fontSize: bold ? 14 : 12,
            fontWeight: bold ? FontWeight.w700 : FontWeight.w600,
          ),
        ),
      ],
    );
  }
}

class _PayOption extends StatelessWidget {
  final String title;
  final Widget? leading;
  final VoidCallback? onTap;
  final bool selected;

  const _PayOption({
    required this.title,
    this.leading,
    this.onTap,
    this.selected = false,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(14),
      onTap: onTap ?? () => Navigator.pop(context),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        decoration: BoxDecoration(
          color: selected
              ? const Color(0xFFE6F4EF)
              : const Color(0xFFF6F7F8),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: selected
                ? const Color(0xFF0F2F2B)
                : const Color(0xFF0F2F2B).withOpacity(0.1),
          ),
        ),
        child: Row(
          children: [
            if (leading != null) ...[
              leading!,
              const SizedBox(width: 10),
            ],
            Text(
              title,
              style: const TextStyle(
                color: Color(0xFF0F2F2B),
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
            const Spacer(),
            if (selected)
              const Icon(Icons.check_circle,
                  color: Color(0xFF0F2F2B), size: 18),
          ],
        ),
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  final String title;
  final String value;
  final VoidCallback onTap;

  const _SectionCard({
    required this.title,
    required this.value,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        decoration: BoxDecoration(
          color: const Color(0xFFF6F7F8),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: const Color(0xFF0F2F2B).withOpacity(0.1)),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      color: Color(0xFF0F2F2B),
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    value,
                    style: const TextStyle(
                      color: Color(0xFF0F2F2B),
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, color: Color(0xFF0F2F2B)),
          ],
        ),
      ),
    );
  }
}

class _ImagePreview extends StatelessWidget {
  final String imagePath;

  const _ImagePreview({required this.imagePath});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Stack(
          children: [
            Center(
              child: InteractiveViewer(
                child: Image.asset(imagePath),
              ),
            ),
            Positioned(
              top: 12,
              right: 12,
              child: IconButton(
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.close, color: Colors.white),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
