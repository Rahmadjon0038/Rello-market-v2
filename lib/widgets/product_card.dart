import 'package:flutter/material.dart';
import 'package:hello_flutter_app/models/product.dart';
import 'package:hello_flutter_app/utils/text_utils.dart';
import 'package:hello_flutter_app/widgets/product_image.dart';

class ProductCard extends StatelessWidget {
  final Product item;
  final VoidCallback onTap;
  final VoidCallback onLike;
  final VoidCallback? onAddToCart;
  final String? addToCartDisabledText;
  final double imageHeight;

  const ProductCard({
    super.key,
    required this.item,
    required this.onTap,
    required this.onLike,
    this.onAddToCart,
    this.addToCartDisabledText,
    this.imageHeight = 100,
  });

  @override
  Widget build(BuildContext context) {
    const primaryGreen = Color(0xFF1F5A50);
    const descriptionColor = Color(0xFF1F2933);
    final descriptionPreview = truncateWords(item.description, maxWords: 26);
    final nameLen = item.name.runes.length;
    final nameFontSize = nameLen > 56
        ? 11.0
        : nameLen > 40
        ? 12.0
        : nameLen > 28
        ? 13.0
        : 14.0;

    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.08),
                blurRadius: 16,
                offset: const Offset(0, 8),
              ),
            ],
            border: Border.all(color: primaryGreen.withOpacity(0.12)),
          ),
          child: Stack(
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: ProductImage(
                      path: item.resolvedImagePath,
                      height: imageHeight,
                    ),
                  ),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(10, 6, 10, 4),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            item.name,
                            maxLines: 3,
                            softWrap: true,
                            style: TextStyle(
                              color: primaryGreen,
                              fontSize: nameFontSize,
                              fontWeight: FontWeight.w700,
                              height: 1.15,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            descriptionPreview,
                            maxLines: 3,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: descriptionColor.withValues(alpha: 0.72),
                              fontSize: 12,
                              height: 1.2,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            item.formattedPrice,
                            style: const TextStyle(
                              color: primaryGreen,
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(10, 0, 10, 6),
                    child: SizedBox(
                      height: 32,
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: primaryGreen,
                          disabledBackgroundColor: primaryGreen.withValues(
                            alpha: 0.55,
                          ),
                          foregroundColor: Colors.white,
                          disabledForegroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          padding: const EdgeInsets.symmetric(horizontal: 10),
                        ),
                        onPressed: onAddToCart,
                        icon: Icon(
                          item.isCart
                              ? Icons.shopping_cart_checkout
                              : Icons.add_shopping_cart,
                          size: 16,
                        ),
                        label: Text(
                          onAddToCart == null
                              ? (addToCartDisabledText ?? "Sotib olinmaydi")
                              : (item.isCart ? 'Savatda' : 'Savatga'),
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              Positioned(
                top: 6,
                right: 6,
                child: SizedBox(
                  width: 34,
                  height: 34,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.9),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: primaryGreen.withOpacity(0.08)),
                    ),
                    child: IconButton(
                      padding: EdgeInsets.zero,
                      onPressed: onLike,
                      icon: Icon(
                        item.isLiked ? Icons.favorite : Icons.favorite_border,
                        color: item.isLiked ? Colors.redAccent : primaryGreen,
                        size: 18,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
