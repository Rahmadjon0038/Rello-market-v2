import 'dart:convert';
import 'dart:io';

import 'package:hello_flutter_app/config/api_config.dart';
import 'package:hello_flutter_app/models/category.dart';
import 'package:hello_flutter_app/models/product.dart';
import 'package:hello_flutter_app/models/seller.dart';
import 'package:hello_flutter_app/models/store_summary.dart';
import 'package:hello_flutter_app/services/auth_api_service.dart';

class SellerProductsResponse {
  final Seller seller;
  final List<Product> products;

  const SellerProductsResponse({required this.seller, required this.products});
}

class StoreProductsResponse {
  final StoreSummary store;
  final List<Product> products;

  const StoreProductsResponse({required this.store, required this.products});
}

class ProductSummary {
  final int favoriteCount;
  final int cartItemCount;
  final int cartTotalQty;

  const ProductSummary({
    required this.favoriteCount,
    required this.cartItemCount,
    required this.cartTotalQty,
  });

  const ProductSummary.empty()
    : favoriteCount = 0,
      cartItemCount = 0,
      cartTotalQty = 0;

  factory ProductSummary.fromJson(Map<String, dynamic> json) {
    return ProductSummary(
      favoriteCount: _summaryIntFromJson(json['favoriteCount']),
      cartItemCount: _summaryIntFromJson(json['cartItemCount']),
      cartTotalQty: _summaryIntFromJson(json['cartTotalQty']),
    );
  }

  static int _summaryIntFromJson(Object? value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse(value?.toString() ?? '') ?? 0;
  }
}

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

  Future<ProductSummary> getProductSummary() async {
    final data = await _send('GET', '/me/product-summary', authRequired: true);
    return ProductSummary.fromJson(data);
  }

  Future<List<Product>> getFavoriteProducts() async {
    final data = await _send('GET', '/me/favorites', authRequired: true);
    return _productsFromData(data);
  }

  Future<List<Product>> getCartProducts() async {
    final data = await _send('GET', '/me/cart', authRequired: true);
    return _productsFromData(data);
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

  Future<SellerProductsResponse> getSellerProducts(String sellerId) async {
    final data = await _send('GET', '/sellers/$sellerId/products');
    final rawSeller = data['seller'];
    if (rawSeller is! Map<String, dynamic>) {
      throw const AuthApiException("Sotuvchi ma'lumoti topilmadi");
    }
    final rawProducts = data['data'];
    final products = rawProducts is List
        ? rawProducts
              .whereType<Map<String, dynamic>>()
              .map(Product.fromJson)
              .toList()
        : <Product>[];
    return SellerProductsResponse(
      seller: Seller.fromJson(rawSeller),
      products: products,
    );
  }

  Future<StoreProductsResponse> getStoreProducts(String storeId) async {
    final data = await _send('GET', '/stores/$storeId/products');
    final rawStore = data['store'];
    if (rawStore is! Map<String, dynamic>) {
      throw const AuthApiException("Do'kon ma'lumoti topilmadi");
    }
    final rawProducts = data['data'];
    final products = rawProducts is List
        ? rawProducts
              .whereType<Map<String, dynamic>>()
              .map(Product.fromJson)
              .toList()
        : <Product>[];
    return StoreProductsResponse(
      store: StoreSummary.fromJson(rawStore),
      products: products,
    );
  }

  Future<List<Product>> getMyProducts({
    String? storeId,
    String status = 'all',
  }) async {
    final params = <String, String>{'status': status};
    if (storeId != null && storeId.trim().isNotEmpty) {
      params['storeId'] = storeId.trim();
    }
    final query = params.entries
        .map(
          (e) =>
              '${Uri.encodeQueryComponent(e.key)}=${Uri.encodeQueryComponent(e.value)}',
        )
        .join('&');
    final data = await _send('GET', '/products/me?$query', authRequired: true);
    return _productsFromData(data);
  }

  Future<Product> deactivateProduct(String id) async {
    final data = await _send(
      'PATCH',
      '/products/$id/deactivate',
      authRequired: true,
    );
    final raw = data['product'];
    if (raw is Map<String, dynamic>) return Product.fromJson(raw);
    return Product.fromJson(data);
  }

  Future<Product> activateProduct(String id) async {
    final data = await _send(
      'PATCH',
      '/products/$id/activate',
      authRequired: true,
    );
    final raw = data['product'];
    if (raw is Map<String, dynamic>) return Product.fromJson(raw);
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

  Future<Product> createProductMultipart({
    required Map<String, dynamic> fields,
    required List<File> images,
  }) async {
    final data = await _sendMultipart(
      'POST',
      '/products',
      fields: fields,
      files: {if (images.isNotEmpty) 'images': images},
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

  Future<Product> updateProductMultipart(
    String id, {
    required Map<String, dynamic> fields,
    List<File> images = const [],
  }) async {
    final data = await _sendMultipart(
      'PATCH',
      '/products/$id',
      fields: fields,
      files: {if (images.isNotEmpty) 'images': images},
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

  List<Product> _productsFromData(Map<String, dynamic> data) {
    final rawProducts = data['data'];
    if (rawProducts is! List) return const [];
    return rawProducts
        .whereType<Map<String, dynamic>>()
        .map(Product.fromJson)
        .toList();
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
      final exception = AuthApiException(
        decoded['error']?.toString() ??
            decoded['message']?.toString() ??
            'Server xatosi',
        statusCode: response.statusCode,
      );
      if (AuthApiService.isInvalidSessionError(exception)) {
        await _authApi.clearSession();
      }
      throw exception;
    }

    return decoded;
  }

  Future<Map<String, dynamic>> _sendMultipart(
    String method,
    String path, {
    required Map<String, dynamic> fields,
    required Map<String, List<File>> files,
  }) async {
    final session = await _authApi.loadSavedSession();
    if (session == null) throw const AuthApiException('Avval tizimga kiring');

    final boundary = '----RelloMarket${DateTime.now().microsecondsSinceEpoch}';
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
    final decoded = _decodeJson(rawBody);

    if (response.statusCode < 200 || response.statusCode >= 300) {
      final exception = AuthApiException(
        decoded['error']?.toString() ??
            decoded['message']?.toString() ??
            'Server xatosi',
        statusCode: response.statusCode,
      );
      if (AuthApiService.isInvalidSessionError(exception)) {
        await _authApi.clearSession();
      }
      throw exception;
    }

    return decoded;
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
    Object decoded;
    try {
      decoded = jsonDecode(rawBody);
    } on FormatException {
      final sample = rawBody.trim().replaceAll(RegExp(r'\s+'), ' ');
      final preview = sample.length > 180 ? sample.substring(0, 180) : sample;
      throw AuthApiException(
        "Server javobi JSON emas. Javob: ${preview.isEmpty ? '-' : preview}",
      );
    }
    if (decoded is Map<String, dynamic>) return decoded;
    throw const AuthApiException("Server javobi noto'g'ri formatda");
  }
}
