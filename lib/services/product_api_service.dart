import 'dart:convert';
import 'dart:io';

import 'package:hello_flutter_app/config/api_config.dart';
import 'package:hello_flutter_app/models/category.dart';
import 'package:hello_flutter_app/models/product.dart';
import 'package:hello_flutter_app/services/auth_api_service.dart';

class ProductApiService {
  ProductApiService({HttpClient? client, AuthApiService? authApi})
    : _client = client ?? HttpClient(),
      _authApi = authApi ?? AuthApiService();

  final HttpClient _client;
  final AuthApiService _authApi;

  Future<List<Product>> getProducts({String? categoryId}) async {
    final query = categoryId == null || categoryId.isEmpty
        ? ''
        : '?categoryId=${Uri.encodeQueryComponent(categoryId)}';
    final data = await _send('GET', '/products$query');
    final rawProducts = data['data'];
    if (rawProducts is! List) return const [];
    return rawProducts
        .whereType<Map<String, dynamic>>()
        .map(Product.fromJson)
        .toList();
  }

  Future<List<Product>> getCarousel() async {
    final data = await _send('GET', '/carousel');
    final rawProducts = data['data'];
    if (rawProducts is! List) return const [];
    return rawProducts
        .whereType<Map<String, dynamic>>()
        .map(Product.fromJson)
        .toList();
  }

  Future<List<CategoryModel>> getCategories() async {
    final data = await _send('GET', '/categories');
    final rawCategories = data['data'];
    if (rawCategories is! List) return const [];
    return rawCategories
        .whereType<Map<String, dynamic>>()
        .map(CategoryModel.fromJson)
        .toList();
  }

  Future<Product> getProduct(String id) async {
    final data = await _send('GET', '/products/$id');
    return Product.fromJson(data);
  }

  Future<Product> createProduct(Map<String, dynamic> body) async {
    final data = await _send(
      'POST',
      '/products',
      authRequired: true,
      body: body,
    );
    return Product.fromJson(data);
  }

  Future<Product> updateProduct(String id, Map<String, dynamic> body) async {
    final data = await _send(
      'PATCH',
      '/products/$id',
      authRequired: true,
      body: body,
    );
    return Product.fromJson(data);
  }

  Future<void> deleteProduct(String id) {
    return _send('DELETE', '/products/$id', authRequired: true);
  }

  Future<void> addProductToCarousel(String id) {
    return _send('POST', '/products/$id/carousel', authRequired: true);
  }

  Future<void> removeProductFromCarousel(String id) {
    return _send('DELETE', '/products/$id/carousel', authRequired: true);
  }

  Future<CategoryModel> createCategory({
    required String name,
    required String icon,
  }) async {
    final data = await _send(
      'POST',
      '/categories',
      authRequired: true,
      body: {'name': name, 'icon': icon},
    );
    return CategoryModel.fromJson(data);
  }

  Future<CategoryModel> updateCategory(
    String id, {
    String? name,
    String? icon,
  }) async {
    final body = <String, dynamic>{};
    if (name != null) body['name'] = name;
    if (icon != null) body['icon'] = icon;
    final data = await _send(
      'PATCH',
      '/categories/$id',
      authRequired: true,
      body: body,
    );
    return CategoryModel.fromJson(data);
  }

  Future<void> deleteCategory(String id) {
    return _send('DELETE', '/categories/$id', authRequired: true);
  }

  Future<bool> likeProduct(String id) async {
    final data = await _send('POST', '/products/$id/like', authRequired: true);
    return data['isLiked'] is bool ? data['isLiked'] as bool : true;
  }

  Future<bool> unlikeProduct(String id) async {
    final data = await _send(
      'DELETE',
      '/products/$id/like',
      authRequired: true,
    );
    return data['isLiked'] is bool ? data['isLiked'] as bool : false;
  }

  Future<int> addToCart(String id, {int qty = 1, bool selected = true}) async {
    final data = await _send(
      'POST',
      '/products/$id/cart',
      authRequired: true,
      body: {'qty': qty, 'selected': selected},
    );
    final nextQty = data['qty'];
    if (nextQty is int) return nextQty;
    if (nextQty is num) return nextQty.toInt();
    return int.tryParse(nextQty?.toString() ?? '') ?? qty;
  }

  Future<void> removeFromCart(String id) {
    return _send('DELETE', '/products/$id/cart', authRequired: true);
  }

  Future<Map<String, dynamic>> _send(
    String method,
    String path, {
    bool authRequired = false,
    Map<String, dynamic>? body,
  }) async {
    final uri = Uri.parse('${ApiConfig.baseUrl}$path');
    final request = await _client.openUrl(method, uri);
    request.headers.contentType = ContentType.json;

    final session = await _authApi.loadSavedSession();
    if (session != null) {
      request.headers.set(
        HttpHeaders.authorizationHeader,
        'Bearer ${session.accessToken}',
      );
    } else if (authRequired) {
      throw const AuthApiException('Avval tizimga kiring');
    }

    if (body != null) request.write(jsonEncode(body));

    final response = await request.close();
    final rawBody = await response.transform(utf8.decoder).join();
    final decoded = _decodeJson(rawBody);

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw AuthApiException(
        decoded['error']?.toString() ??
            decoded['message']?.toString() ??
            'Server xatosi',
        statusCode: response.statusCode,
      );
    }

    return decoded;
  }

  Map<String, dynamic> _decodeJson(String rawBody) {
    if (rawBody.trim().isEmpty) return <String, dynamic>{};
    final decoded = jsonDecode(rawBody);
    if (decoded is Map<String, dynamic>) return decoded;
    throw const AuthApiException("Server javobi noto'g'ri formatda");
  }
}
