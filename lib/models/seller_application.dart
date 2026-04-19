import 'package:hello_flutter_app/models/seller.dart';

class SellerApplication {
  final String id;
  final String userId;
  final String fullName;
  final String birthDate;
  final String gender;
  final String primaryPhone;
  final String additionalPhone;
  final String email;
  final String livingAddress;
  final String passportSeriesNumber;
  final String passportIssuedBy;
  final String passportIssuedDate;
  final String jshshir;
  final String storeName;
  final String storeType;
  final String activityType;
  final String storeDescription;
  final String storeAddress;
  final String storeMapLocation;
  final String workingHours;
  final bool hasDelivery;
  final String deliveryArea;
  final num deliveryPrice;
  final String storeLogo;
  final List<String> storeBannerImages;
  final String status;
  final bool adminSeen;
  final String reviewNote;
  final String reviewedBy;
  final String reviewedAt;
  final String submittedAt;
  final String approvedAt;
  final String rejectedAt;
  final Seller? user;
  final String createdAt;
  final String updatedAt;

  const SellerApplication({
    required this.id,
    required this.userId,
    required this.fullName,
    required this.birthDate,
    required this.gender,
    required this.primaryPhone,
    required this.additionalPhone,
    required this.email,
    required this.livingAddress,
    required this.passportSeriesNumber,
    required this.passportIssuedBy,
    required this.passportIssuedDate,
    required this.jshshir,
    required this.storeName,
    required this.storeType,
    required this.activityType,
    required this.storeDescription,
    required this.storeAddress,
    required this.storeMapLocation,
    required this.workingHours,
    required this.hasDelivery,
    required this.deliveryArea,
    required this.deliveryPrice,
    required this.storeLogo,
    required this.storeBannerImages,
    required this.status,
    required this.adminSeen,
    required this.reviewNote,
    required this.reviewedBy,
    required this.reviewedAt,
    required this.submittedAt,
    required this.approvedAt,
    required this.rejectedAt,
    required this.user,
    required this.createdAt,
    required this.updatedAt,
  });

  factory SellerApplication.fromJson(Map<String, dynamic> json) {
    final rawUser = json['user'];
    final firstName = json['firstName']?.toString() ?? '';
    final lastName = json['lastName']?.toString() ?? '';
    final legacyFullName = '$firstName $lastName'.trim();

    return SellerApplication(
      id: json['id']?.toString() ?? '',
      userId: json['userId']?.toString() ?? '',
      fullName: json['fullName']?.toString() ?? legacyFullName,
      birthDate: json['birthDate']?.toString() ?? '',
      gender: json['gender']?.toString() ?? '',
      primaryPhone:
          json['primaryPhone']?.toString() ?? json['phone']?.toString() ?? '',
      additionalPhone: json['additionalPhone']?.toString() ?? '',
      email: json['email']?.toString() ?? '',
      livingAddress:
          json['livingAddress']?.toString() ??
          json['address']?.toString() ??
          '',
      passportSeriesNumber: json['passportSeriesNumber']?.toString() ?? '',
      passportIssuedBy: json['passportIssuedBy']?.toString() ?? '',
      passportIssuedDate: json['passportIssuedDate']?.toString() ?? '',
      jshshir:
          json['jshshir']?.toString() ??
          json['jshshr']?.toString() ??
          json['pinfl']?.toString() ??
          '',
      storeName: json['storeName']?.toString() ?? '',
      storeType: json['storeType']?.toString() ?? '',
      activityType: json['activityType']?.toString() ?? '',
      storeDescription: json['storeDescription']?.toString() ?? '',
      storeAddress: json['storeAddress']?.toString() ?? '',
      storeMapLocation: json['storeMapLocation']?.toString() ?? '',
      workingHours: json['workingHours']?.toString() ?? '',
      hasDelivery: json['hasDelivery'] == true,
      deliveryArea: json['deliveryArea']?.toString() ?? '',
      deliveryPrice: json['deliveryPrice'] is num
          ? json['deliveryPrice'] as num
          : num.tryParse(json['deliveryPrice']?.toString() ?? '') ?? 0,
      storeLogo: json['storeLogo']?.toString() ?? '',
      storeBannerImages: json['storeBannerImages'] is List
          ? (json['storeBannerImages'] as List)
                .map((item) => item.toString())
                .toList()
          : const [],
      status: json['status']?.toString() ?? '',
      adminSeen: json['adminSeen'] == true,
      reviewNote: json['reviewNote']?.toString() ?? '',
      reviewedBy: json['reviewedBy']?.toString() ?? '',
      reviewedAt: json['reviewedAt']?.toString() ?? '',
      submittedAt: json['submittedAt']?.toString() ?? '',
      approvedAt: json['approvedAt']?.toString() ?? '',
      rejectedAt: json['rejectedAt']?.toString() ?? '',
      user: rawUser is Map<String, dynamic> ? Seller.fromJson(rawUser) : null,
      createdAt: json['createdAt']?.toString() ?? '',
      updatedAt: json['updatedAt']?.toString() ?? '',
    );
  }

  String get contact =>
      primaryPhone.isNotEmpty ? primaryPhone : user?.contact ?? '';
}
