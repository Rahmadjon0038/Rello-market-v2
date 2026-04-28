import 'dart:convert';
import 'dart:io';

import 'package:hello_flutter_app/config/api_config.dart';
import 'package:hello_flutter_app/models/seller_application.dart';
import 'package:hello_flutter_app/models/store.dart';
import 'package:hello_flutter_app/models/store_details.dart';
import 'package:hello_flutter_app/services/auth_api_service.dart';

class SellerApplicationCreateInput {
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
  final File? storeLogoFile;
  final List<File> storeBannerImageFiles;

  const SellerApplicationCreateInput({
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
    required this.storeLogoFile,
    required this.storeBannerImageFiles,
  });

  Map<String, dynamic> toJson() {
    return {
      'fullName': fullName,
      'birthDate': birthDate,
      if (gender.isNotEmpty) 'gender': gender,
      'primaryPhone': primaryPhone,
      if (additionalPhone.isNotEmpty) 'additionalPhone': additionalPhone,
      'email': email,
      'livingAddress': livingAddress,
      'passportSeriesNumber': passportSeriesNumber,
      'passportIssuedBy': passportIssuedBy,
      'passportIssuedDate': passportIssuedDate,
      'jshshir': jshshir,
      'jshshr': jshshir,
      'storeName': storeName,
      'storeType': storeType,
      'activityType': activityType,
      'storeDescription': storeDescription,
      if (storeAddress.isNotEmpty) 'storeAddress': storeAddress,
      'storeMapLocation': storeMapLocation,
      'workingHours': workingHours,
      'hasDelivery': hasDelivery,
      if (deliveryArea.isNotEmpty) 'deliveryArea': deliveryArea,
      'deliveryPrice': deliveryPrice,
    };
  }
}

class SellerApplicationBadge {
  final int count;
  final bool hasNew;

  const SellerApplicationBadge({required this.count, required this.hasNew});

  factory SellerApplicationBadge.fromJson(Map<String, dynamic> json) {
    final rawCount = json['count'];
    final count = rawCount is num
        ? rawCount.toInt()
        : int.tryParse(rawCount?.toString() ?? '') ?? 0;

    return SellerApplicationBadge(
      count: count,
      hasNew: json['hasNew'] == true || count > 0,
    );
  }
}

class StoreApiService {
  StoreApiService({HttpClient? client, AuthApiService? authApi})
    : _client = client ?? HttpClient(),
      _authApi = authApi ?? AuthApiService();

  final HttpClient _client;
  final AuthApiService _authApi;

  Future<SellerApplication?> getMyApplication() async {
    final data = await _send('GET', '/seller-applications/me');
    final raw = data['application'];
    if (raw is Map<String, dynamic>) return SellerApplication.fromJson(raw);
    return null;
  }

  Future<SellerApplication> createSellerApplication(
    SellerApplicationCreateInput input,
  ) async {
    final logoFile = input.storeLogoFile;
    if (logoFile == null) {
      throw const AuthApiException("Do'kon rasmi/logo tanlang");
    }
    final data = await _sendMultipart(
      'POST',
      '/seller-applications',
      fields: input.toJson(),
      files: {
        'storeLogo': [logoFile],
        if (input.storeBannerImageFiles.isNotEmpty)
          'storeBannerImages': input.storeBannerImageFiles,
      },
    );
    final raw = data['application'];
    if (raw is Map<String, dynamic>) return SellerApplication.fromJson(raw);
    throw const AuthApiException("Ariza javobi noto'g'ri formatda");
  }

  Future<StoreModel> updateStore(
    String id, {
    Map<String, dynamic> fields = const {},
    File? storeLogoFile,
    List<File> storeBannerImageFiles = const [],
  }) async {
    final data = await _sendMultipart(
      'PATCH',
      '/me/stores/$id',
      fields: fields,
      files: {
        if (storeLogoFile != null) 'storeLogo': [storeLogoFile],
        if (storeBannerImageFiles.isNotEmpty)
          'storeBannerImages': storeBannerImageFiles,
      },
    );
    final raw = data['store'];
    if (raw is Map<String, dynamic>) return StoreModel.fromJson(raw);
    throw const AuthApiException("Do'kon javobi noto'g'ri formatda");
  }

  Future<List<SellerApplication>> getAdminSellerApplications({
    String? status,
  }) async {
    final query = status == null || status.isEmpty ? '' : '?status=$status';
    final data = await _send('GET', '/admin/seller-applications$query');
    final raw = data['data'];
    if (raw is! List) return const [];
    return raw
        .whereType<Map<String, dynamic>>()
        .map(SellerApplication.fromJson)
        .toList();
  }

  Future<SellerApplicationBadge> getAdminSellerApplicationsBadge() async {
    final data = await _send('GET', '/admin/seller-applications/badge');
    return SellerApplicationBadge.fromJson(data);
  }

  Future<void> approveSellerApplication(String id) async {
    await _send('PATCH', '/admin/seller-applications/$id/approve', body: {});
  }

  Future<void> rejectSellerApplication(String id, {String reviewNote = ''}) {
    return _send(
      'PATCH',
      '/admin/seller-applications/$id/reject',
      body: {if (reviewNote.trim().isNotEmpty) 'reviewNote': reviewNote.trim()},
    );
  }

  Future<List<StoreModel>> getMyStores() async {
    final data = await _send('GET', '/me/stores');
    final raw = data['data'];
    if (raw is! List) return const [];
    return raw
        .whereType<Map<String, dynamic>>()
        .map(StoreModel.fromJson)
        .toList();
  }

  Future<StoreDetails> getMyStore(String id) async {
    final data = await _send('GET', '/me/stores/$id');
    final raw = data['store'];
    if (raw is Map<String, dynamic>) return StoreDetails.fromJson(raw);
    throw const AuthApiException("Do'kon javobi noto'g'ri formatda");
  }

  Future<Map<String, dynamic>> _send(
    String method,
    String path, {
    Map<String, dynamic>? body,
  }) async {
    final session = await _authApi.loadSavedSession();
    if (session == null) throw const AuthApiException('Avval tizimga kiring');

    try {
      final uri = Uri.parse('${ApiConfig.baseUrl}$path');
      final request = await _client.openUrl(method, uri);
      request.headers.contentType = ContentType.json;
      request.headers.set(
        HttpHeaders.authorizationHeader,
        'Bearer ${session.accessToken}',
      );
      if (body != null) request.write(jsonEncode(body));

      final response = await request.close();
      final rawBody = await response.transform(utf8.decoder).join();

      if (response.statusCode < 200 || response.statusCode >= 300) {
        final decoded = _decodeJsonOrError(rawBody);
        final exception = AuthApiException(
          decoded['error']?.toString() ??
              decoded['message']?.toString() ??
              'Server xatosi (${response.statusCode})',
          statusCode: response.statusCode,
        );
        if (AuthApiService.isInvalidSessionError(exception)) {
          await _authApi.clearSession();
        }
        throw exception;
      }

      final decoded = _decodeJson(rawBody);
      return decoded;
    } on AuthApiException {
      rethrow;
    } on SocketException {
      throw AuthApiException(
        "Serverga ulanib bo'lmadi. API manzil: ${ApiConfig.baseUrl}",
      );
    } on FormatException catch (error) {
      throw AuthApiException(
        "Server noto'g'ri formatda javob qaytardi: $error",
      );
    } on HttpException catch (error) {
      throw AuthApiException(error.message);
    } on Object catch (error) {
      throw AuthApiException(
        "Server bilan bog'lanib bo'lmadi: ${error.runtimeType}: $error",
      );
    }
  }

  Future<Map<String, dynamic>> _sendMultipart(
    String method,
    String path, {
    required Map<String, dynamic> fields,
    required Map<String, List<File>> files,
  }) async {
    final session = await _authApi.loadSavedSession();
    if (session == null) throw const AuthApiException('Avval tizimga kiring');

    try {
      final boundary =
          '----RelloMarket${DateTime.now().microsecondsSinceEpoch}';
      final uri = Uri.parse('${ApiConfig.baseUrl}$path');
      final request = await _client.openUrl(method, uri);
      request.headers.set(
        HttpHeaders.authorizationHeader,
        'Bearer ${session.accessToken}',
      );
      request.headers.set(
        HttpHeaders.contentTypeHeader,
        'multipart/form-data; boundary=$boundary',
      );

      void writePart(String value) {
        request.add(utf8.encode(value));
      }

      void writeField(String name, String value) {
        writePart('--$boundary\r\n');
        writePart('Content-Disposition: form-data; name="$name"\r\n\r\n');
        writePart('$value\r\n');
      }

      for (final entry in fields.entries) {
        final value = entry.value;
        if (value is List) {
          for (final item in value) {
            writeField(entry.key, item.toString());
          }
        } else {
          writeField(entry.key, value.toString());
        }
      }

      for (final entry in files.entries) {
        var fileIndex = 0;
        for (final file in entry.value) {
          final fileName = file.path.split(Platform.pathSeparator).last;
          final lower = fileName.toLowerCase();
          final ext = lower.endsWith('.png')
              ? '.png'
              : lower.endsWith('.webp')
              ? '.webp'
              : lower.endsWith('.gif')
              ? '.gif'
              : '.jpg';
          final uploadName =
              'upload_${DateTime.now().microsecondsSinceEpoch}_${fileIndex++}$ext';
          writePart('--$boundary\r\n');
          writePart(
            'Content-Disposition: form-data; name="${entry.key}"; filename="$uploadName"\r\n',
          );
          writePart('Content-Type: ${_imageContentType(fileName)}\r\n\r\n');
          await request.addStream(file.openRead());
          writePart('\r\n');
        }
      }

      writePart('--$boundary--\r\n');
      final response = await request.close();
      final rawBody = await response.transform(utf8.decoder).join();

      if (response.statusCode < 200 || response.statusCode >= 300) {
        final decoded = _decodeJsonOrError(rawBody);
        final exception = AuthApiException(
          decoded['error']?.toString() ??
              decoded['message']?.toString() ??
              'Server xatosi (${response.statusCode})',
          statusCode: response.statusCode,
        );
        if (AuthApiService.isInvalidSessionError(exception)) {
          await _authApi.clearSession();
        }
        throw exception;
      }

      final decoded = _decodeJson(rawBody);
      return decoded;
    } on AuthApiException {
      rethrow;
    } on SocketException {
      throw AuthApiException(
        "Serverga ulanib bo'lmadi. API manzil: ${ApiConfig.baseUrl}",
      );
    } on FormatException catch (error) {
      throw AuthApiException(
        "Server noto'g'ri formatda javob qaytardi: $error",
      );
    } on HttpException catch (error) {
      throw AuthApiException(error.message);
    } on Object catch (error) {
      throw AuthApiException(
        "Server bilan bog'lanib bo'lmadi: ${error.runtimeType}: $error",
      );
    }
  }

  String _imageContentType(String fileName) {
    final lower = fileName.toLowerCase();
    if (lower.endsWith('.png')) return 'image/png';
    if (lower.endsWith('.webp')) return 'image/webp';
    if (lower.endsWith('.gif')) return 'image/gif';
    return 'image/jpeg';
  }

  Map<String, dynamic> _decodeJson(String rawBody) {
    if (rawBody.trim().isEmpty) return <String, dynamic>{};
    final decoded = jsonDecode(rawBody);
    if (decoded is Map<String, dynamic>) return decoded;
    throw const AuthApiException("Server javobi noto'g'ri formatda");
  }

  Map<String, dynamic> _decodeJsonOrError(String rawBody) {
    final trimmed = rawBody.trim();
    if (trimmed.isEmpty) return <String, dynamic>{};
    try {
      final decoded = jsonDecode(trimmed);
      if (decoded is Map<String, dynamic>) return decoded;
      return {'error': decoded.toString()};
    } on FormatException {
      return {'error': _shortResponse(trimmed)};
    }
  }

  String _shortResponse(String value) {
    final singleLine = value.replaceAll(RegExp(r'\s+'), ' ').trim();
    if (singleLine.length <= 240) return singleLine;
    return '${singleLine.substring(0, 240)}...';
  }
}
