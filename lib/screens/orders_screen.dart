import 'package:flutter/material.dart';

class OrdersScreen extends StatelessWidget {
  const OrdersScreen({super.key});

  @override
  Widget build(BuildContext context) {
    const primaryGreen = Color(0xFF0F2F2B);
    const orders = [
      _Order(
        id: 'ORD-1023',
        status: 'Yetkazilmoqda',
        date: '12.09.2025',
        total: '1 749 000 so‘m',
        items: const [
          _OrderItem(
            name: 'Smart Blender',
            qty: 1,
            price: '1 250 000 so‘m',
            imagePath: 'assets/corusel1.png',
          ),
          _OrderItem(
            name: 'Quloqchin Pro',
            qty: 1,
            price: '499 000 so‘m',
            imagePath: 'assets/corusel2.png',
          ),
        ],
      ),
      _Order(
        id: 'ORD-1017',
        status: 'Qabul qilindi',
        date: '10.09.2025',
        total: '499 000 so‘m',
        items: const [
          _OrderItem(
            name: 'Quloqchin Pro',
            qty: 1,
            price: '499 000 so‘m',
            imagePath: 'assets/corusel2.png',
          ),
        ],
      ),
      _Order(
        id: 'ORD-1002',
        status: 'Yakunlandi',
        date: '01.09.2025',
        total: '2 120 000 so‘m',
        items: const [
          _OrderItem(
            name: 'Kurtka Classic',
            qty: 2,
            price: '359 000 so‘m',
            imagePath: 'assets/corusel3.png',
          ),
          _OrderItem(
            name: 'Yumshoq stul',
            qty: 1,
            price: '799 000 so‘m',
            imagePath: 'assets/corusel2.png',
          ),
        ],
      ),
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Mening buyurtmalarim'),
        backgroundColor: Colors.white,
        foregroundColor: primaryGreen,
        elevation: 0,
      ),
      body: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: orders.length,
        separatorBuilder: (_, __) => const SizedBox(height: 12),
        itemBuilder: (context, i) {
          final o = orders[i];
          final statusColor = _statusColor(o.status);
          return Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: primaryGreen.withOpacity(0.12)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.06),
                  blurRadius: 12,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: statusColor.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: statusColor.withOpacity(0.4)),
                      ),
                      child: Text(
                        o.status,
                        style: TextStyle(
                          color: statusColor,
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            o.id,
                            style: const TextStyle(
                              color: primaryGreen,
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            o.date,
                            style: const TextStyle(
                              color: Color(0xFF8A9A97),
                              fontSize: 11,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Text(
                      o.total,
                      style: const TextStyle(
                        color: primaryGreen,
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                ...o.items.map(
                  (it) => Padding(
                    padding: const EdgeInsets.only(bottom: 6),
                    child: Row(
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Image.asset(
                            it.imagePath,
                            width: 36,
                            height: 36,
                            fit: BoxFit.cover,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            '${it.name} x${it.qty}',
                            style: const TextStyle(
                              color: primaryGreen,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        Text(
                          it.price,
                          style: const TextStyle(
                            color: primaryGreen,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _Order {
  final String id;
  final String status;
  final String date;
  final String total;
  final List<_OrderItem> items;

  const _Order({
    required this.id,
    required this.status,
    required this.date,
    required this.total,
    required this.items,
  });
}

class _OrderItem {
  final String name;
  final int qty;
  final String price;
  final String imagePath;

  const _OrderItem({
    required this.name,
    required this.qty,
    required this.price,
    required this.imagePath,
  });
}

Color _statusColor(String status) {
  switch (status) {
    case 'Yetkazilmoqda':
      return const Color(0xFF2E7D6F);
    case 'Qabul qilindi':
      return const Color(0xFF4F8CC9);
    case 'Yakunlandi':
      return const Color(0xFF2DB783);
    default:
      return const Color(0xFF0F2F2B);
  }
}
