import 'package:hello_flutter_app/models/seller.dart';

class StoreModel {
  final String id;
  final String ownerId;
  final String applicationId;
  final String name;
  final String imagePath;
  final String description;
  final bool isActive;
  final bool isNew;
  final String? newBadgeText;
  final Seller? director;
  final String createdAt;
  final String updatedAt;

  const StoreModel({
    required this.id,
    required this.ownerId,
    required this.applicationId,
    required this.name,
    required this.imagePath,
    required this.description,
    required this.isActive,
    required this.isNew,
    required this.newBadgeText,
    required this.director,
    required this.createdAt,
    required this.updatedAt,
  });

  factory StoreModel.fromJson(Map<String, dynamic> json) {
    final rawDirector = json['director'];
    return StoreModel(
      id: json['id']?.toString() ?? '',
      ownerId: json['ownerId']?.toString() ?? '',
      applicationId: json['applicationId']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      imagePath: json['imagePath']?.toString() ?? '',
      description: json['description']?.toString() ?? '',
      isActive: json['isActive'] is bool ? json['isActive'] as bool : false,
      isNew: json['isNew'] == true,
      newBadgeText: json['newBadgeText']?.toString(),
      director: rawDirector is Map<String, dynamic>
          ? Seller.fromJson(rawDirector)
          : null,
      createdAt: json['createdAt']?.toString() ?? '',
      updatedAt: json['updatedAt']?.toString() ?? '',
    );
  }
}
