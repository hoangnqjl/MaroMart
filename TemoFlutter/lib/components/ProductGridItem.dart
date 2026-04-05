import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:temo/models/Product/Product.dart';
import 'package:intl/intl.dart';
import 'package:heroicons_flutter/heroicons_flutter.dart';
import 'package:temo/screens/Product/ProductDetail.dart';
import 'package:temo/app_router.dart';
import 'package:temo/models/User/ChatPartner.dart';
import 'package:temo/screens/Message/ChatScreen.dart';
import 'package:temo/utils/string_utils.dart';

class ProductGridItem extends StatelessWidget {
  final Product product;
  const ProductGridItem({super.key, required this.product});

  // Màu sắc chính xác từ Figma
  final Color titleColor = const Color(0xFF3F3F46);
  final Color locationColor = const Color(0x803F3F46); // 50% opacity
  final Color chatBtnColor = const Color(0xFFFFB86A);
  final Color pricePillColor = const Color(0xFFEAEAEA);
  final Color shadowColor = const Color(
    0x26000000,
  ); // 15% opacity của đen (#00000026)

  String _formatPrice(int price) {
    if (price >= 1000000000) {
      double t = price / 1000000000;
      return 'đ ${t % 1 == 0 ? t.toInt() : t.toStringAsFixed(1).replaceAll('.', ',')} tỷ';
    } else if (price >= 10000000) {
      double m = price / 1000000;
      return 'đ ${m % 1 == 0 ? m.toInt() : m.toStringAsFixed(1).replaceAll('.', ',')} tr';
    }
    
    // Standard format for smaller values
    final formatter = NumberFormat('#,###', 'vi_VN');
    return 'đ ${formatter.format(price).replaceAll(',', '.')}';
  }

  @override
  Widget build(BuildContext context) {
    String imageUrl = product.productMedia.isNotEmpty
        ? product.productMedia[0]
        : '';
    if (imageUrl.startsWith('image:')) imageUrl = imageUrl.substring(6).trim();

    String locationText = StringUtils.simplifyAddress(
      product.productAddress?.province ?? "Đà Nẵng",
    );
    final commune = product.productAddress?.commute;
    if (commune != null && commune.isNotEmpty) {
      locationText = "${StringUtils.simplifyAddress(commune)}, $locationText";
    }

    return GestureDetector(
      onTap: () =>
          smoothPush(context, ProductDetail(productId: product.productId)),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(28), // Reduced bo cong
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 15,
              offset: const Offset(0, 8),
            )
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(6.0), // Minimized internal margin
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min, // Wrap content
            children: [
              // Image Section
              AspectRatio(
                aspectRatio: 0.9, // Slightly shorter portrait aspect ratio
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(20), // Reduced image bo cong
                  child: CachedNetworkImage(
                    imageUrl: imageUrl,
                    fit: BoxFit.cover,
                    memCacheWidth: 400, // Reduced resolution for memory efficiency
                    maxWidthDiskCache: 400, // Reduced resolution for bandwidth/disk efficiency
                    placeholder: (context, url) =>
                        Container(color: const Color(0xFFF3F4F6)),
                    errorWidget: (_, __, ___) => Container(
                      color: const Color(0xFFF3F4F6),
                      child: const Icon(Icons.image, color: Colors.grey),
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 8), // Reduced from 16

              // Title
              Text(
                product.productName,
                style: TextStyle(
                  fontFamily: 'Quicksand',
                  fontWeight: FontWeight.bold,
                  fontSize: 15, // Nudged down slightly for better proportion
                  color: titleColor,
                  letterSpacing: -0.2,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),

              const SizedBox(height: 4), // Reduced from 6

              // Location Row
              Row(
                children: [
                  Icon(
                    HeroiconsOutline.mapPin, // Switched to Outline to match screenshot
                    size: 16,
                    color: locationColor,
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      locationText,
                      style: TextStyle(
                        fontFamily: 'Quicksand',
                        color: locationColor,
                        fontSize: 13, // Nudged down for balance
                        fontWeight: FontWeight.w500,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 12), // Reduced from 24

              // Bottom Row: Price & Chat
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Price Pill
                  Flexible(
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 10,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF1F1F1),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        _formatPrice(product.productPrice),
                        style: TextStyle(
                          fontFamily: 'Quicksand',
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                          color: titleColor,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ),
                  // Chat Button
                  GestureDetector(
                    onTap: () {
                      if (product.userInfo != null) {
                        final userInfo = product.userInfo!;
                        final partner = ChatPartner(
                          userId: userInfo.userId,
                          fullName: userInfo.fullName,
                          avatarUrl: userInfo.avatarUrl,
                          email: userInfo.email,
                        );
                        smoothPush(
                          context,
                          ChatScreen(
                            conversationId: "",
                            partnerUser: partner,
                          ),
                        );
                      }
                    },
                    child: Container(
                      width: 42,
                      height: 42,
                      decoration: BoxDecoration(
                        color: chatBtnColor,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: chatBtnColor.withOpacity(0.3),
                            blurRadius: 8,
                            offset: const Offset(0, 4),
                          )
                        ],
                      ),
                      child: const Icon(
                        HeroiconsOutline.chatBubbleOvalLeft, // Switched to Outline
                        color: Colors.white,
                        size: 20,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
