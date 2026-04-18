import 'package:hello_flutter_app/config/api_config.dart';
import 'package:hello_flutter_app/models/category.dart';
import 'package:hello_flutter_app/models/seller.dart';

class Product {
  final String id;
  final String name;
  final String description;
  final int price;
  final int qty;
  final bool selected;
  final String imagePath;
  final String categoryId;
  final CategoryModel? category;
  final String brand;
  final bool isCarousel;
  final bool isActive;
  final bool isLiked;
  final bool isCart;
  final int cartQty;
  final List<String> images;
  final Seller? seller;

  const Product({
    required this.id,
    required this.name,
    required this.description,
    required this.price,
    required this.qty,
    required this.selected,
    required this.imagePath,
    required this.categoryId,
    required this.category,
    required this.brand,
    required this.isCarousel,
    required this.isActive,
    required this.isLiked,
    required this.isCart,
    required this.cartQty,
    required this.images,
    required this.seller,
  });

  factory Product.fromJson(Map<String, dynamic> json) {
    final rawImages = json['images'];
    final images = rawImages is List
        ? rawImages.map((item) => item.toString()).toList()
        : <String>[];
    final imagePath =
        json['imagePath']?.toString() ??
        (images.isNotEmpty ? images.first : 'assets/corusel1.png');
    final rawCategory = json['category'];
    final category = rawCategory is Map<String, dynamic>
        ? CategoryModel.fromJson(rawCategory)
        : rawCategory is String
        ? CategoryModel(
            id: json['categoryId']?.toString() ?? '',
            name: rawCategory,
            icon: '',
          )
        : null;
    final rawSeller = json['seller'];
    final seller = rawSeller is Map<String, dynamic>
        ? Seller.fromJson(rawSeller)
        : null;

    return Product(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      description: json['description']?.toString() ?? '',
      price: _intFromJson(json['price']),
      qty: _intFromJson(json['qty'], fallback: 1),
      selected: json['selected'] is bool ? json['selected'] as bool : true,
      imagePath: imagePath,
      categoryId: json['categoryId']?.toString() ?? category?.id ?? '',
      category: category,
      brand: json['brand']?.toString() ?? '',
      isCarousel: json['isCarousel'] is bool
          ? json['isCarousel'] as bool
          : false,
      isActive: json['isActive'] is bool ? json['isActive'] as bool : true,
      isLiked: json['isLiked'] is bool ? json['isLiked'] as bool : false,
      isCart: json['isCart'] is bool ? json['isCart'] as bool : false,
      cartQty: _intFromJson(json['cartQty']),
      images: images.isEmpty ? [imagePath] : images,
      seller: seller,
    );
  }

  Product copyWith({
    bool? isLiked,
    bool? isCart,
    int? cartQty,
    int? qty,
    bool? selected,
    Seller? seller,
  }) {
    return Product(
      id: id,
      name: name,
      description: description,
      price: price,
      qty: qty ?? this.qty,
      selected: selected ?? this.selected,
      imagePath: imagePath,
      categoryId: categoryId,
      category: category,
      brand: brand,
      isCarousel: isCarousel,
      isActive: isActive,
      isLiked: isLiked ?? this.isLiked,
      isCart: isCart ?? this.isCart,
      cartQty: cartQty ?? this.cartQty,
      images: images,
      seller: seller ?? this.seller,
    );
  }

  String get categoryName {
    return category?.name ?? '';
  }

  String get categoryIcon {
    return category?.icon ?? '';
  }

  String get formattedPrice {
    final s = price.toString();
    final b = StringBuffer();
    for (var i = 0; i < s.length; i++) {
      final idx = s.length - i;
      b.write(s[i]);
      if (idx > 1 && idx % 3 == 1) b.write(' ');
    }
    return '$b so‘m';
  }

  String get resolvedImagePath {
    return resolveImagePath(imagePath);
  }

  List<String> get resolvedImages {
    return images.map(resolveImagePath).toList();
  }

  static String resolveImagePath(String path) {
    if (path.startsWith('assets/')) return path;
    if (path.startsWith('http://') || path.startsWith('https://')) {
      return path;
    }
    if (!path.startsWith('/')) return '${ApiConfig.baseUrl}/$path';
    return '${ApiConfig.baseUrl}$path';
  }

  static int _intFromJson(Object? value, {int fallback = 0}) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse(value?.toString() ?? '') ?? fallback;
  }
}
