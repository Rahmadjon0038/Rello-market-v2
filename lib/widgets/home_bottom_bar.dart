import 'package:flutter/material.dart';

class HomeBottomBar extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;

  const HomeBottomBar({
    super.key,
    required this.currentIndex,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    const accent = Color(0xFF3A6B5B);
    const bg = Colors.white;

    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 0, 12, 8),
        child: Container(
          padding: const EdgeInsets.fromLTRB(14, 8, 14, 8),
          decoration: BoxDecoration(
            color: bg,
            borderRadius: BorderRadius.circular(22),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.12),
                blurRadius: 18,
                offset: const Offset(0, 8),
              ),
            ],
            border: Border.all(color: Colors.black.withValues(alpha: 0.10)),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _BarItem(
                icon: Icons.home_rounded,
                label: 'Bosh sahifa',
                color: accent,
                active: currentIndex == 0,
                onTap: () => onTap(0),
              ),
              _BarItem(
                icon: Icons.favorite_rounded,
                label: 'Sevimlilar',
                color: accent,
                active: currentIndex == 1,
                onTap: () => onTap(1),
              ),
              _CartItem(active: currentIndex == 2, onTap: () => onTap(2)),
              _BarItem(
                icon: Icons.person_rounded,
                label: 'Profil',
                color: accent,
                active: currentIndex == 3,
                onTap: () => onTap(3),
              ),
              _BarItem(
                icon: Icons.settings_rounded,
                label: 'Sozlamalar',
                color: accent,
                active: currentIndex == 4,
                onTap: () => onTap(4),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _BarItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final bool active;
  final VoidCallback onTap;

  const _BarItem({
    required this.icon,
    required this.label,
    required this.color,
    required this.active,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: label,
      child: Semantics(
        label: label,
        button: true,
        selected: active,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: onTap,
          child: SizedBox(
            width: 48,
            height: 46,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, color: color, size: 24),
                const SizedBox(height: 5),
                AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  width: active ? 20 : 4,
                  height: 3,
                  decoration: BoxDecoration(
                    color: active ? color : Colors.transparent,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _CartItem extends StatelessWidget {
  final bool active;
  final VoidCallback onTap;

  const _CartItem({required this.active, required this.onTap});

  @override
  Widget build(BuildContext context) {
    const accent = Color(0xFF3A6B5B);
    return Tooltip(
      message: 'Savat',
      child: Semantics(
        label: 'Savat',
        button: true,
        selected: active,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: onTap,
          child: SizedBox(
            width: 48,
            height: 46,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Stack(
                  clipBehavior: Clip.none,
                  children: [
                    const Icon(
                      Icons.shopping_cart_rounded,
                      color: accent,
                      size: 24,
                    ),
                    Positioned(
                      right: -7,
                      top: -7,
                      child: Container(
                        width: 16,
                        height: 16,
                        decoration: const BoxDecoration(
                          color: Colors.red,
                          shape: BoxShape.circle,
                        ),
                        alignment: Alignment.center,
                        child: const Text(
                          '1',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 5),
                AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  width: active ? 20 : 4,
                  height: 3,
                  decoration: BoxDecoration(
                    color: active ? accent : Colors.transparent,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
