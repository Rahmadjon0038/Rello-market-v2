import 'package:flutter/material.dart';

class StoreStatisticsScreen extends StatelessWidget {
  final String storeName;

  const StoreStatisticsScreen({super.key, required this.storeName});

  @override
  Widget build(BuildContext context) {
    const primaryGreen = Color(0xFF1F5A50);
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
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 24),
          children: [
            _HeaderCard(storeName: storeName),
            const SizedBox(height: 12),
            const _StatsGrid(),
            const SizedBox(height: 12),
            _SectionCard(
              title: 'Oxirgi 7 kun',
              child: Container(
                height: 160,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: const Color(0xFFE6F4EF),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Text(
                  "Grafik keyin qo'shiladi",
                  style: TextStyle(
                    color: primaryGreen,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),
            _SectionCard(
              title: 'Eslatma',
              child: Text(
                "Bu sahifa hozircha UI placeholder. Statistika endpointlari tayyor bo'lganda real ma'lumotlarni ulaymiz.",
                style: TextStyle(
                  color: primaryGreen.withValues(alpha: 0.7),
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _HeaderCard extends StatelessWidget {
  final String storeName;

  const _HeaderCard({required this.storeName});

  @override
  Widget build(BuildContext context) {
    const primaryGreen = Color(0xFF1F5A50);
    final name = storeName.trim().isEmpty ? "Do'kon" : storeName.trim();

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
      child: Row(
        children: [
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              color: const Color(0xFFE6F4EF),
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Icon(Icons.query_stats_rounded, color: primaryGreen),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: primaryGreen,
                    fontWeight: FontWeight.w900,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  "Do'kon statistikasi",
                  style: TextStyle(
                    color: primaryGreen.withValues(alpha: 0.65),
                    fontWeight: FontWeight.w700,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _StatsGrid extends StatelessWidget {
  const _StatsGrid();

  @override
  Widget build(BuildContext context) {
    const primaryGreen = Color(0xFF1F5A50);

    return Row(
      children: const [
        Expanded(
          child: _StatCard(
            title: 'Bugun buyurtma',
            value: '—',
            icon: Icons.receipt_long_rounded,
          ),
        ),
        SizedBox(width: 12),
        Expanded(
          child: _StatCard(
            title: 'Daromad',
            value: '—',
            icon: Icons.payments_rounded,
          ),
        ),
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;

  const _StatCard({
    required this.title,
    required this.value,
    required this.icon,
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
      child: Row(
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
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: primaryGreen.withValues(alpha: 0.65),
                    fontWeight: FontWeight.w800,
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  value,
                  style: const TextStyle(
                    color: primaryGreen,
                    fontWeight: FontWeight.w900,
                    fontSize: 18,
                  ),
                ),
              ],
            ),
          ),
        ],
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
