import 'package:hello_flutter_app/models/seller.dart';

class SellerApplication {
  final String id;
  final String userId;
  final String firstName;
  final String lastName;
  final String phone;
  final String storeName;
  final String purpose;
  final String productsInfo;
  final String address;
  final String status;
  final String reviewNote;
  final String reviewedBy;
  final String reviewedAt;
  final Seller? user;
  final String createdAt;
  final String updatedAt;

  const SellerApplication({
    required this.id,
    required this.userId,
    required this.firstName,
    required this.lastName,
    required this.phone,
    required this.storeName,
    required this.purpose,
    required this.productsInfo,
    required this.address,
    required this.status,
    required this.reviewNote,
    required this.reviewedBy,
    required this.reviewedAt,
    required this.user,
    required this.createdAt,
    required this.updatedAt,
  });

  factory SellerApplication.fromJson(Map<String, dynamic> json) {
    final rawUser = json['user'];
    return SellerApplication(
      id: json['id']?.toString() ?? '',
      userId: json['userId']?.toString() ?? '',
      firstName: json['firstName']?.toString() ?? '',
      lastName: json['lastName']?.toString() ?? '',
      phone: json['phone']?.toString() ?? '',
      storeName: json['storeName']?.toString() ?? '',
      purpose: json['purpose']?.toString() ?? '',
      productsInfo: json['productsInfo']?.toString() ?? '',
      address: json['address']?.toString() ?? '',
      status: json['status']?.toString() ?? '',
      reviewNote: json['reviewNote']?.toString() ?? '',
      reviewedBy: json['reviewedBy']?.toString() ?? '',
      reviewedAt: json['reviewedAt']?.toString() ?? '',
      user: rawUser is Map<String, dynamic> ? Seller.fromJson(rawUser) : null,
      createdAt: json['createdAt']?.toString() ?? '',
      updatedAt: json['updatedAt']?.toString() ?? '',
    );
  }

  String get fullName {
    final name = '$firstName $lastName'.trim();
    if (name.isNotEmpty) return name;
    return user?.fullName ?? '';
  }
}
