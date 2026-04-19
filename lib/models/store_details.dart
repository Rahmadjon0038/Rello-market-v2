import 'package:hello_flutter_app/models/seller.dart';

class StoreDetails {
  final String id;
  final String ownerId;
  final String applicationId;
  final String name;
  final String? imagePath;
  final String? description;
  final String? storeType;
  final String? activityType;
  final String? address;
  final String? mapLocation;
  final String? workingHours;
  final bool hasDelivery;
  final String? deliveryArea;
  final num? deliveryPrice;
  final List<String> bannerImages;
  final bool isActive;
  final Seller? director;
  final String? createdAt;
  final String? updatedAt;

  const StoreDetails({
    required this.id,
    required this.ownerId,
    required this.applicationId,
    required this.name,
    required this.imagePath,
    required this.description,
    required this.storeType,
    required this.activityType,
    required this.address,
    required this.mapLocation,
    required this.workingHours,
    required this.hasDelivery,
    required this.deliveryArea,
    required this.deliveryPrice,
    required this.bannerImages,
    required this.isActive,
    required this.director,
    required this.createdAt,
    required this.updatedAt,
  });

  factory StoreDetails.fromJson(Map<String, dynamic> json) {
    final rawDirector = json['director'];
    final rawDeliveryPrice = json['deliveryPrice'];
    final bannerRaw = json['bannerImages'];

    num? deliveryPrice;
    if (rawDeliveryPrice is num) deliveryPrice = rawDeliveryPrice;
    if (rawDeliveryPrice is String)
      deliveryPrice = num.tryParse(rawDeliveryPrice);

    return StoreDetails(
      id: json['id']?.toString() ?? '',
      ownerId: json['ownerId']?.toString() ?? '',
      applicationId: json['applicationId']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      imagePath: json['imagePath']?.toString(),
      description: json['description']?.toString(),
      storeType: json['storeType']?.toString(),
      activityType: json['activityType']?.toString(),
      address: json['address']?.toString(),
      mapLocation: json['mapLocation']?.toString(),
      workingHours: json['workingHours']?.toString(),
      hasDelivery: json['hasDelivery'] == true,
      deliveryArea: json['deliveryArea']?.toString(),
      deliveryPrice: deliveryPrice,
      bannerImages: bannerRaw is List
          ? bannerRaw
                .map((e) => e.toString())
                .where((e) => e.trim().isNotEmpty)
                .toList()
          : const [],
      isActive: json['isActive'] == true,
      director: rawDirector is Map<String, dynamic>
          ? Seller.fromJson(rawDirector)
          : null,
      createdAt: json['createdAt']?.toString(),
      updatedAt: json['updatedAt']?.toString(),
    );
  }
}
