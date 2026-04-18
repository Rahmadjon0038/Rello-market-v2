import 'package:hello_flutter_app/config/api_config.dart';

class Seller {
  final String id;
  final String firstName;
  final String lastName;
  final String phone;
  final String username;
  final String role;
  final String profileImg;
  final String createdAt;

  const Seller({
    required this.id,
    required this.firstName,
    required this.lastName,
    required this.phone,
    required this.username,
    required this.role,
    required this.profileImg,
    required this.createdAt,
  });

  factory Seller.fromJson(Map<String, dynamic> json) {
    return Seller(
      id: json['id']?.toString() ?? '',
      firstName: json['firstName']?.toString() ?? '',
      lastName: json['lastName']?.toString() ?? '',
      phone: json['phone']?.toString() ?? '',
      username: json['username']?.toString() ?? '',
      role: json['role']?.toString() ?? '',
      profileImg: json['profileImg']?.toString() ?? '',
      createdAt: json['createdAt']?.toString() ?? '',
    );
  }

  String get fullName {
    final name = '$firstName $lastName'.trim();
    if (name.isNotEmpty) return name;
    if (username.isNotEmpty) return username;
    return phone;
  }

  String get contact {
    if (phone.isNotEmpty) return phone;
    return username;
  }

  String get resolvedProfileImg {
    if (profileImg.isEmpty) return '';
    if (profileImg.startsWith('assets/')) return profileImg;
    if (profileImg.startsWith('http://') || profileImg.startsWith('https://')) {
      return profileImg;
    }
    if (!profileImg.startsWith('/')) return '${ApiConfig.baseUrl}/$profileImg';
    return '${ApiConfig.baseUrl}$profileImg';
  }
}
