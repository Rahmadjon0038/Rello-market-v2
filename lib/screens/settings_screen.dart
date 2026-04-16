import 'package:flutter/material.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _push = true;
  bool _sms = false;
  bool _email = true;
  bool _dark = false;

  @override
  Widget build(BuildContext context) {
    const primaryGreen = Color(0xFF1F5A50);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        children: [
          _SectionTitle(title: 'Bildirishnomalar'),
          _SwitchTile(
            title: 'Push bildirishnomalar',
            value: _push,
            onChanged: (v) => setState(() => _push = v),
          ),
          const SizedBox(height: 12),
          _SectionTitle(title: 'Ko‘rinish'),
          _SwitchTile(
            title: 'Kunduzgi rejim',
            value: _dark,
            onChanged: (v) => setState(() => _dark = v),
          ),
          const SizedBox(height: 12),
          _SectionTitle(title: 'Ilova'),
          _ActionTile(title: 'Xavfsizlik', value: 'PIN / Biometrik'),
          const SizedBox(height: 8),
          _ActionTile(title: 'Yordam', value: 'FAQ'),
          const SizedBox(height: 8),
          _ActionTile(title: 'Versiya', value: '1.0.0'),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String title;

  const _SectionTitle({required this.title});

  @override
  Widget build(BuildContext context) {
    return Container(
      alignment: Alignment.centerLeft,
      margin: const EdgeInsets.only(bottom: 6),
      child: Text(
        title,
        style: const TextStyle(
          color: Color(0xFF1F5A50),
          fontSize: 13,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _SwitchTile extends StatelessWidget {
  final String title;
  final bool value;
  final ValueChanged<bool> onChanged;

  const _SwitchTile({
    required this.title,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    const primaryGreen = Color(0xFF1F5A50);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: primaryGreen.withOpacity(0.12)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              title,
              style: const TextStyle(
                color: primaryGreen,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          Switch(value: value, activeColor: primaryGreen, onChanged: onChanged),
        ],
      ),
    );
  }
}

class _ActionTile extends StatelessWidget {
  final String title;
  final String value;

  const _ActionTile({required this.title, required this.value});

  @override
  Widget build(BuildContext context) {
    const primaryGreen = Color(0xFF1F5A50);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: primaryGreen.withOpacity(0.12)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              title,
              style: const TextStyle(
                color: primaryGreen,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          Text(
            value,
            style: const TextStyle(color: Color(0xFF8A9A97), fontSize: 12),
          ),
          const SizedBox(width: 6),
          const Icon(Icons.chevron_right, color: primaryGreen, size: 18),
        ],
      ),
    );
  }
}
