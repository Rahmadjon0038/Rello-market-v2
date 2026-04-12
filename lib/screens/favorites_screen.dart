import 'package:flutter/material.dart';

class FavoritesScreen extends StatelessWidget {
  final VoidCallback onGoHome;

  const FavoritesScreen({super.key, required this.onGoHome});

  static const _products = [
    _FavProduct(
      id: 1,
      name: 'Smart Blender',
      description: 'Tez va sokin ishlaydi, 5 xil rejim.',
      price: '1 250 000 so‘m',
      imagePath: 'assets/corusel1.png',
    ),
    _FavProduct(
      id: 2,
      name: 'Quloqchin Pro',
      description: 'Yuqori sifatli ovoz, 24 soat battery.',
      price: '499 000 so‘m',
      imagePath: 'assets/corusel2.png',
    ),
    _FavProduct(
      id: 3,
      name: 'Kurtka Classic',
      description: 'Kuz-bahor uchun qulay va yengil.',
      price: '359 000 so‘m',
      imagePath: 'assets/corusel3.png',
    ),
    _FavProduct(
      id: 4,
      name: 'Krossovka Air',
      description: 'Yumshoq taglik, sport uchun ideal.',
      price: '289 000 so‘m',
      imagePath: 'assets/corusel1.png',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    if (_products.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        child: Container(
          padding: const EdgeInsets.fromLTRB(18, 18, 18, 18),
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
            border: Border.all(color: const Color(0xFF0F2F2B).withOpacity(0.18)),
          ),
          child: Column(
            children: [
              const Icon(Icons.favorite_border,
                  size: 52, color: Color(0xFF0F2F2B)),
              const SizedBox(height: 12),
              const Text(
                'Sevimlilar bo‘sh',
                style: TextStyle(
                  color: Color(0xFF0F2F2B),
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 6),
              const Text(
                'Sevimli mahsulotlarni topish uchun mahsulotlar sahifasiga o‘ting.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Color(0xFF8A9A97),
                  fontSize: 12,
                ),
              ),
              const SizedBox(height: 14),
              SizedBox(
                height: 40,
                child: ElevatedButton(
                  onPressed: onGoHome,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF0F2F2B),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                  ),
                  child: const Text(
                    'Mahsulotlar sahifasi',
                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: _products.length,
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          mainAxisSpacing: 12,
          crossAxisSpacing: 12,
          childAspectRatio: 0.64,
        ),
        itemBuilder: (context, index) {
          final p = _products[index];
          return _FavProductCard(item: p);
        },
      ),
    );
  }
}

class _FavProduct {
  final int id;
  final String name;
  final String description;
  final String price;
  final String imagePath;

  const _FavProduct({
    required this.id,
    required this.name,
    required this.description,
    required this.price,
    required this.imagePath,
  });
}

class _FavProductCard extends StatelessWidget {
  final _FavProduct item;

  const _FavProductCard({required this.item});

  @override
  Widget build(BuildContext context) {
    const primaryGreen = Color(0xFF0F2F2B);
    const softGray = Color(0xFFF6F7F8);

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
        border: Border.all(color: primaryGreen.withOpacity(0.12)),
      ),
      child: Stack(
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.asset(
                  item.imagePath,
                  width: double.infinity,
                  height: 92,
                  fit: BoxFit.cover,
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(10, 6, 10, 6),
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
                      item.description,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: primaryGreen.withOpacity(0.7),
                        fontSize: 11,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      item.price,
                      style: const TextStyle(
                        color: primaryGreen,
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
              const Spacer(),
              Padding(
                padding: const EdgeInsets.fromLTRB(10, 0, 10, 8),
                child: SizedBox(
                  height: 30,
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: primaryGreen,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 10),
                    ),
                    onPressed: () {},
                    icon: const Icon(Icons.add_shopping_cart, size: 16),
                    label: const Text(
                      'Savatga',
                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                    ),
                  ),
                ),
              ),
            ],
          ),
          Positioned(
            top: 6,
            right: 6,
            child: SizedBox(
              width: 34,
              height: 34,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.9),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: primaryGreen.withOpacity(0.08),
                  ),
                ),
                child: const Icon(
                  Icons.favorite,
                  color: Colors.redAccent,
                  size: 18,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
