import 'package:hello_flutter_app/models/seller.dart';

class StoreSummary {
  final String id;
  final String name;
  final String imagePath;
  final String storeType;
  final String activityType;
  final String address;
  final String mapLocation;
  final String workingHours;
  final bool hasDelivery;
  final String deliveryArea;
  final num deliveryPrice;
  final List<String> bannerImages;
  final Seller? director;

  const StoreSummary({
    required this.id,
    required this.name,
    required this.imagePath,
    required this.storeType,
    required this.activityType,
    required this.address,
    required this.mapLocation,
    required this.workingHours,
    required this.hasDelivery,
    required this.deliveryArea,
    required this.deliveryPrice,
    required this.bannerImages,
    required this.director,
  });

  factory StoreSummary.fromJson(Map<String, dynamic> json) {
    final bannerRaw = json['bannerImages'];
    final rawDirector = json['director'];
    final rawDeliveryPrice = json['deliveryPrice'];
    final deliveryPrice = rawDeliveryPrice is num
        ? rawDeliveryPrice
        : num.tryParse(rawDeliveryPrice?.toString() ?? '') ?? 0;

    return StoreSummary(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      imagePath: json['imagePath']?.toString() ?? '',
      storeType: json['storeType']?.toString() ?? '',
      activityType: json['activityType']?.toString() ?? '',
      address: json['address']?.toString() ?? '',
      mapLocation: json['mapLocation']?.toString() ?? '',
      workingHours: json['workingHours']?.toString() ?? '',
      hasDelivery: json['hasDelivery'] == true,
      deliveryArea: json['deliveryArea']?.toString() ?? '',
      deliveryPrice: deliveryPrice,
      bannerImages: bannerRaw is List
          ? bannerRaw
                .map((e) => e.toString())
                .where((e) => e.trim().isNotEmpty)
                .toList()
          : const [],
      director: rawDirector is Map<String, dynamic>
          ? Seller.fromJson(rawDirector)
          : null,
    );
  }
}
