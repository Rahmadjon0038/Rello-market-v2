import 'dart:async';

import 'package:flutter/material.dart';

class HomeHeader extends StatefulWidget {
  final bool showContent;
  final bool showSearch;

  const HomeHeader({super.key, this.showContent = true, this.showSearch = true});

  @override
  State<HomeHeader> createState() => _HomeHeaderState();
}

class _HomeHeaderState extends State<HomeHeader>
    with SingleTickerProviderStateMixin {
  bool _showSearch = false;
  String _selectedLang = "UZ";
  int _selectedCategoryId = 0;
  final Set<int> _likedProductIds = {};
  AnimationController? _sheetController;
  PageController? _carouselController;
  Timer? _carouselTimer;
  int _carouselIndex = 0;

  final List<_CarouselItem> _carouselItems = const [
    _CarouselItem(
      id: 1,
      name: 'Yangi Aksiyalar',
      description: 'Eng yaxshi takliflar',
      price: '1 250 000 so‘m',
      imagePath: 'assets/corusel1.png',
    ),
    _CarouselItem(
      id: 2,
      name: 'Elektronika',
      description: 'Katta chegirmalar',
      price: '3 499 000 so‘m',
      imagePath: 'assets/corusel2.png',
    ),
    _CarouselItem(
      id: 3,
      name: 'Kiyimlar',
      description: 'Bahor kolleksiyasi',
      price: '299 000 so‘m',
      imagePath: 'assets/corusel3.png',
    ),
  ];

  final List<_CategoryItem> _categories = const [
    _CategoryItem(
      id: 0,
      name: 'Barchasi',
      icon: Icons.grid_view_rounded,
      color: Color(0xFF2E7D6F),
    ),
    _CategoryItem(
      id: 1,
      name: 'Maishiy texnika',
      icon: Icons.kitchen_rounded,
      color: Color(0xFF4F8CC9),
    ),
    _CategoryItem(
      id: 2,
      name: 'Kiyim-kechak',
      icon: Icons.checkroom_rounded,
      color: Color(0xFF9B59B6),
    ),
    _CategoryItem(
      id: 3,
      name: 'Poyabzallar',
      icon: Icons.hiking_rounded,
      color: Color(0xFF2DB783),
    ),
    _CategoryItem(
      id: 4,
      name: 'Elektronika',
      icon: Icons.devices_rounded,
      color: Color(0xFFE67E22),
    ),
    _CategoryItem(
      id: 5,
      name: 'Mebellar',
      icon: Icons.chair_rounded,
      color: Color(0xFF1F8A70),
    ),
  ];

  final List<_ProductItem> _products = const [
    _ProductItem(
      id: 1,
      categoryId: 1,
      name: 'Smart Blender',
      description: 'Tez va sokin ishlaydi, 5 xil rejim.',
      price: '1 250 000 so‘m',
      imagePath: 'assets/corusel1.png',
    ),
    _ProductItem(
      id: 2,
      categoryId: 4,
      name: 'Quloqchin Pro',
      description: 'Yuqori sifatli ovoz, 24 soat battery.',
      price: '499 000 so‘m',
      imagePath: 'assets/corusel2.png',
    ),
    _ProductItem(
      id: 3,
      categoryId: 2,
      name: 'Kurtka Classic',
      description: 'Kuz-bahor uchun qulay va yengil.',
      price: '359 000 so‘m',
      imagePath: 'assets/corusel3.png',
    ),
    _ProductItem(
      id: 4,
      categoryId: 3,
      name: 'Krossovka Air',
      description: 'Yumshoq taglik, sport uchun ideal.',
      price: '289 000 so‘m',
      imagePath: 'assets/corusel1.png',
    ),
    _ProductItem(
      id: 5,
      categoryId: 5,
      name: 'Yumshoq stul',
      description: 'Minimalist dizayn, mustahkam.',
      price: '799 000 so‘m',
      imagePath: 'assets/corusel2.png',
    ),
  ];

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    _carouselTimer?.cancel();
    _carouselController?.dispose();
    _sheetController?.dispose();
    super.dispose();
  }

  void _openLanguageSheet() {
    const primaryGreen = Color(0xFF0F2F2B);
    _sheetController ??= AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 160),
      reverseDuration: const Duration(milliseconds: 110),
    );

    showModalBottomSheet(
      context: context,
      showDragHandle: true,
      transitionAnimationController: _sheetController,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: TweenAnimationBuilder<double>(
            tween: Tween(begin: 0.0, end: 1.0),
            duration: const Duration(milliseconds: 160),
            curve: Curves.easeOutCubic,
            builder: (context, value, child) {
              return Opacity(
                opacity: value,
                child: Transform.translate(
                  offset: Offset(0, (1 - value) * 56),
                  child: Transform.scale(
                    scale: 0.98 + (0.02 * value),
                    child: child,
                  ),
                ),
              );
            },
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _LangOption(
                    label: "O'zbekcha",
                    value: "UZ",
                    selected: _selectedLang == "UZ",
                    onTap: () {
                      setState(() => _selectedLang = "UZ");
                      Navigator.pop(ctx);
                    },
                  ),
                  const SizedBox(height: 8),
                  _LangOption(
                    label: "English",
                    value: "EN",
                    selected: _selectedLang == "EN",
                    onTap: () {
                      setState(() => _selectedLang = "EN");
                      Navigator.pop(ctx);
                    },
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    const primaryGreen = Color(0xFF0F2F2B);
    const lightGreen = Color(0xFFE6F4EF);

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.fromLTRB(14, 10, 14, 10),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(26),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.10),
                  blurRadius: 22,
                  offset: const Offset(0, 10),
                ),
              ],
              border: Border.all(color: Colors.black.withOpacity(0.05)),
            ),
            child: Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: primaryGreen,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: Image.asset(
                    'assets/logo.jpg',
                    fit: BoxFit.cover,
                  ),
                ),
                const SizedBox(width: 10),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'Rello Market',
                        style: TextStyle(
                          color: primaryGreen,
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      SizedBox(height: 2),
                      Text(
                        'Online shop',
                        style: TextStyle(
                          color: Color(0xFF8A9A97),
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                if (widget.showSearch) ...[
                  _HeaderIconButton(
                    icon: Icons.search,
                    onTap: () => setState(() => _showSearch = !_showSearch),
                  ),
                  const SizedBox(width: 10),
                ],
                _HeaderIconButton(
                  onTap: _openLanguageSheet,
                  child: _LangFlag(
                    assetPath:
                        _selectedLang == "UZ" ? 'assets/uz.png' : 'assets/en.png',
                  ),
                ),
              ],
            ),
          ),

          if (widget.showSearch)
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 180),
              switchInCurve: Curves.easeOutCubic,
              switchOutCurve: Curves.easeInCubic,
              transitionBuilder: (child, animation) {
                final slide = Tween<Offset>(
                  begin: const Offset(0, -0.08),
                  end: Offset.zero,
                ).animate(animation);
                return SizeTransition(
                  sizeFactor: animation,
                  axisAlignment: -1,
                  child: FadeTransition(
                    opacity: animation,
                    child: SlideTransition(
                      position: slide,
                      child: child,
                    ),
                  ),
                );
              },
              child: _showSearch
                  ? Padding(
                      padding: const EdgeInsets.only(top: 10),
                      child: Container(
                        height: 46,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.06),
                              blurRadius: 10,
                              offset: const Offset(0, 6),
                            ),
                          ],
                        ),
                        child: TextField(
                          cursorColor: primaryGreen,
                          style: const TextStyle(
                            color: primaryGreen,
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                          decoration: InputDecoration(
                            hintText: 'Mahsulot qidirish...',
                            hintStyle:
                                TextStyle(color: primaryGreen.withOpacity(0.5)),
                            prefixIcon:
                                const Icon(Icons.search, color: primaryGreen),
                            filled: true,
                            fillColor: Colors.white,
                            contentPadding:
                                const EdgeInsets.symmetric(horizontal: 14),
                            isDense: true,
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(16),
                              borderSide: BorderSide(
                                color: primaryGreen.withOpacity(0.12),
                                width: 1,
                              ),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(16),
                              borderSide: const BorderSide(
                                color: primaryGreen,
                                width: 1.2,
                              ),
                            ),
                          ),
                        ),
                      ),
                    )
                  : const SizedBox.shrink(),
            ),

          if (widget.showContent) ...[
            const SizedBox(height: 20),

            SizedBox(
              height: 180,
              child: PageView.builder(
                controller: _ensureCarousel(),
                itemCount: _carouselItems.length,
                padEnds: false,
                clipBehavior: Clip.hardEdge,
                onPageChanged: (index) {
                  setState(() => _carouselIndex = index);
                },
                itemBuilder: (context, index) {
                  final item = _carouselItems[index];
                  return _CarouselCard(item: item);
                },
              ),
            ),

            const SizedBox(height: 8),

            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(_carouselItems.length, (index) {
                final active = index == _carouselIndex;
                return AnimatedContainer(
                  duration: const Duration(milliseconds: 250),
                  margin: const EdgeInsets.symmetric(horizontal: 3),
                  width: active ? 16 : 6,
                  height: 6,
                  decoration: BoxDecoration(
                    color: active ? primaryGreen : primaryGreen.withOpacity(0.25),
                    borderRadius: BorderRadius.circular(6),
                  ),
                );
              }),
            ),

            const SizedBox(height: 14),

            SizedBox(
              height: 42,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: _categories.length,
                separatorBuilder: (_, __) => const SizedBox(width: 10),
                itemBuilder: (context, index) {
                  final c = _categories[index];
                  return _CategoryChip(
                    item: c,
                    selected: c.id == _selectedCategoryId,
                    onTap: () {
                      setState(() => _selectedCategoryId = c.id);
                    },
                  );
                },
              ),
            ),

            const SizedBox(height: 16),

            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _filteredProducts().length,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                mainAxisSpacing: 12,
                crossAxisSpacing: 12,
                childAspectRatio: 0.62,
              ),
              itemBuilder: (context, index) {
                final p = _filteredProducts()[index];
                return _ProductCard(
                  item: p,
                  liked: _likedProductIds.contains(p.id),
                  onLike: () {
                    setState(() {
                      if (_likedProductIds.contains(p.id)) {
                        _likedProductIds.remove(p.id);
                      } else {
                        _likedProductIds.add(p.id);
                      }
                    });
                  },
                  onAddToCart: () {},
                );
              },
            ),
          ],
        ],
      ),
    );
  }

  void _startCarousel() {
    _carouselTimer?.cancel();
    _carouselTimer = Timer.periodic(
      const Duration(seconds: 4),
      (_) {
        if (!mounted) return;
        if (_carouselController == null) return;
        final next = (_carouselIndex + 1) % _carouselItems.length;
        _carouselController!.animateToPage(
          next,
          duration: const Duration(milliseconds: 450),
          curve: Curves.easeOutCubic,
        );
      },
    );
  }

  PageController _ensureCarousel() {
    if (_carouselController == null ||
        _carouselController!.viewportFraction != 1.0) {
      _carouselController?.dispose();
      _carouselController = PageController(viewportFraction: 1.0);
    }
    _startCarousel();
    return _carouselController!;
  }

  List<_ProductItem> _filteredProducts() {
    if (_selectedCategoryId == 0) return _products;
    return _products
        .where((p) => p.categoryId == _selectedCategoryId)
        .toList();
  }
}

class _LangFlag extends StatelessWidget {
  final String assetPath;

  const _LangFlag({required this.assetPath});

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(4),
      child: Image.asset(
        assetPath,
        width: 26,
        height: 18,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) {
          return Container(
            width: 26,
            height: 18,
            color: const Color(0xFFE6E9E8),
            alignment: Alignment.center,
            child: const Text(
              'UZ',
              style: TextStyle(
                color: Color(0xFF0F2F2B),
                fontSize: 8,
                fontWeight: FontWeight.w700,
              ),
            ),
          );
        },
      ),
    );
  }
}

class _HeaderIconButton extends StatelessWidget {
  final IconData? icon;
  final Widget? child;
  final VoidCallback onTap;

  const _HeaderIconButton({
    this.icon,
    this.child,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    const primaryGreen = Color(0xFF0F2F2B);
    return InkWell(
      borderRadius: BorderRadius.circular(20),
      onTap: onTap,
      child: Container(
        width: 48,
        height: 48,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.black.withOpacity(0.08)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.08),
              blurRadius: 12,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Center(
          child: icon != null
              ? Icon(icon, color: primaryGreen, size: 24)
              : SizedBox(
                  width: 28,
                  height: 20,
                  child: FittedBox(
                    fit: BoxFit.contain,
                    child: child,
                  ),
                ),
        ),
      ),
    );
  }
}

class _LangOption extends StatelessWidget {
  final String label;
  final String value;
  final bool selected;
  final VoidCallback onTap;

  const _LangOption({
    required this.label,
    required this.value,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    const primaryGreen = Color(0xFF0F2F2B);
    const lightGreen = Color(0xFFE6F4EF);

    return InkWell(
      borderRadius: BorderRadius.circular(14),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        decoration: BoxDecoration(
          color: selected ? lightGreen : Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: primaryGreen.withOpacity(0.2),
            width: 1,
          ),
        ),
        child: Row(
          children: [
            _LangFlag(
              assetPath: value == "UZ" ? 'assets/uz.png' : 'assets/en.png',
            ),
            const SizedBox(width: 10),
            Text(
              label,
              style: const TextStyle(
                color: primaryGreen,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
            const Spacer(),
            if (selected)
              const Icon(Icons.check, color: primaryGreen, size: 18),
          ],
        ),
      ),
    );
  }
}

class _CarouselItem {
  final int id;
  final String name;
  final String description;
  final String price;
  final String imagePath;

  const _CarouselItem({
    required this.id,
    required this.name,
    required this.description,
    required this.price,
    required this.imagePath,
  });
}

class _CarouselCard extends StatelessWidget {
  final _CarouselItem item;

  const _CarouselCard({required this.item});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 0),
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: () {},
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            image: DecorationImage(
              image: AssetImage(item.imagePath),
              fit: BoxFit.cover,
            ),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: Stack(
              children: [
                Positioned.fill(
                  child: Container(
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.bottomCenter,
                        end: Alignment.topCenter,
                        colors: [
                          Color(0xCC000000),
                          Color(0x22000000),
                          Color(0x00000000),
                        ],
                      ),
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
                        item.name,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        item.description,
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 12,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.45),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          item.price,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
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

class _CategoryItem {
  final int id;
  final String name;
  final IconData icon;
  final Color color;

  const _CategoryItem({
    required this.id,
    required this.name,
    required this.icon,
    required this.color,
  });
}

class _CategoryChip extends StatelessWidget {
  final _CategoryItem item;
  final bool selected;
  final VoidCallback onTap;

  const _CategoryChip({
    required this.item,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    const primaryGreen = Color(0xFF0F2F2B);

    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: selected ? const Color(0xFF0F2F2B) : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: selected
                ? const Color(0xFF0F2F2B)
                : primaryGreen.withOpacity(0.15),
            width: 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              item.icon,
              color: selected ? Colors.white : item.color,
              size: 14,
            ),
            const SizedBox(width: 6),
            Text(
              item.name,
              style: TextStyle(
                color: selected ? Colors.white : const Color(0xFF0F2F2B),
                fontSize: 11,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ProductItem {
  final int id;
  final int categoryId;
  final String name;
  final String description;
  final String price;
  final String imagePath;

  const _ProductItem({
    required this.id,
    required this.categoryId,
    required this.name,
    required this.description,
    required this.price,
    required this.imagePath,
  });
}

class _ProductCard extends StatelessWidget {
  final _ProductItem item;
  final bool liked;
  final VoidCallback onLike;
  final VoidCallback onAddToCart;

  const _ProductCard({
    required this.item,
    required this.liked,
    required this.onLike,
    required this.onAddToCart,
  });

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
                  height: 108,
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
                  height: 32,
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
                    onPressed: onAddToCart,
                    icon: const Icon(Icons.add_shopping_cart, size: 16),
                    label: const Text(
                      'Savatga',
                      style:
                          TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
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
                child: IconButton(
                  padding: EdgeInsets.zero,
                  onPressed: onLike,
                  icon: Icon(
                    liked ? Icons.favorite : Icons.favorite_border,
                    color: liked ? Colors.redAccent : primaryGreen,
                    size: 18,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
