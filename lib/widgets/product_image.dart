import 'package:flutter/material.dart';

class ProductImage extends StatelessWidget {
  final String path;
  final double height;

  const ProductImage({super.key, required this.path, required this.height});

  @override
  Widget build(BuildContext context) {
    if (path.startsWith('http://') || path.startsWith('https://')) {
      return Image.network(
        path,
        width: double.infinity,
        height: height,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) =>
            _ImageFallback(height: height),
      );
    }

    return Image.asset(
      path,
      width: double.infinity,
      height: height,
      fit: BoxFit.cover,
      errorBuilder: (context, error, stackTrace) =>
          _ImageFallback(height: height),
    );
  }
}

class _ImageFallback extends StatelessWidget {
  final double height;

  const _ImageFallback({required this.height});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: height,
      color: const Color(0xFFE6F4EF),
      alignment: Alignment.center,
      child: const Icon(
        Icons.image_not_supported_rounded,
        color: Color(0xFF1F5A50),
      ),
    );
  }
}
