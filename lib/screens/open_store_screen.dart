import 'package:flutter/material.dart';

class OpenStoreScreen extends StatelessWidget {
  const OpenStoreScreen({super.key});

  @override
  Widget build(BuildContext context) {
    const primaryGreen = Color(0xFF1F5A50);
    const mutedText = Color(0xFF8A9A97);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        foregroundColor: primaryGreen,
        elevation: 0,
        centerTitle: true,
        title: const Text(
          "Do'kon ochish",
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
        ),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: primaryGreen.withValues(alpha: 0.12)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.08),
                    blurRadius: 16,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 52,
                    height: 52,
                    decoration: BoxDecoration(
                      color: primaryGreen.withValues(alpha: 0.10),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: const Icon(
                      Icons.storefront_rounded,
                      color: primaryGreen,
                      size: 28,
                    ),
                  ),
                  const SizedBox(height: 14),
                  const Text(
                    "Do'kon ochish shartnomasi",
                    style: TextStyle(
                      color: primaryGreen,
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    "Hozircha bu sahifada do'kon ochish uchun shartnoma "
                    "to'ldirish bo'limi turadi.",
                    style: TextStyle(
                      color: mutedText,
                      fontSize: 13,
                      height: 1.4,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 18),
                  const _ContractPlaceholderRow(
                    icon: Icons.description_outlined,
                    title: "Shartnoma ma'lumotlari",
                    value: "Tez orada",
                  ),
                  const SizedBox(height: 10),
                  const _ContractPlaceholderRow(
                    icon: Icons.edit_document,
                    title: "Ariza to'ldirish",
                    value: "Tayyorlanmoqda",
                  ),
                  const SizedBox(height: 10),
                  const _ContractPlaceholderRow(
                    icon: Icons.verified_user_outlined,
                    title: "Tekshiruv",
                    value: "Kutilmoqda",
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ContractPlaceholderRow extends StatelessWidget {
  final IconData icon;
  final String title;
  final String value;

  const _ContractPlaceholderRow({
    required this.icon,
    required this.title,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    const primaryGreen = Color(0xFF1F5A50);
    const mutedText = Color(0xFF8A9A97);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFFF6F7F8),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: primaryGreen.withValues(alpha: 0.08)),
      ),
      child: Row(
        children: [
          Icon(icon, color: primaryGreen, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              title,
              style: const TextStyle(
                color: primaryGreen,
                fontSize: 13,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              color: mutedText,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
