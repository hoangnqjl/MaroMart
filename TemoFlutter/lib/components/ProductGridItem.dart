import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:maromart/models/Product/Product.dart';
import 'package:maromart/Colors/AppColors.dart';
import 'package:maromart/models/User/ChatPartner.dart';
import 'package:maromart/screens/Message/ChatScreen.dart';
import 'package:maromart/screens/Product/ProductDetail.dart';
import 'package:maromart/app_router.dart';
import 'package:intl/intl.dart';
import 'package:heroicons_flutter/heroicons_flutter.dart';
import 'package:url_launcher/url_launcher.dart'; // Để thực hiện cuộc gọi

class ProductGridItem extends StatelessWidget {
  final Product product;
  const ProductGridItem({super.key, required this.product});

  final Color primaryColor = AppColors.primary;

  String _formatPrice(int price) {
    return NumberFormat.currency(locale: 'vi_VN', symbol: 'đ', decimalDigits: 0).format(price);
  }

  void _makeCall(String? phoneNumber) async {
    if (phoneNumber == null || phoneNumber.isEmpty) return;
    final Uri launchUri = Uri(scheme: 'tel', path: phoneNumber);
    if (await canLaunchUrl(launchUri)) {
      await launchUrl(launchUri);
    }
  }

  @override
  Widget build(BuildContext context) {
    String imageUrl = product.productMedia.isNotEmpty ? product.productMedia[0] : '';
    if (imageUrl.startsWith('image:')) imageUrl = imageUrl.substring(6).trim();
    
    // Fallback format for time if needed (Chotot often shows "x hours ago" or similar)
    // Assuming product doesn't have a time/date field explicitly shown here, we might just put a placeholder 
    // or use empty string if we don't have it. We'll omit it or put a simple location.
    
    // Location formatting
    String locationText = product.productAddress?.province ?? "Chưa có địa chỉ";
    if (product.productAddress?.commute != null && product.productAddress!.commute.isNotEmpty) {
      locationText = "${product.productAddress!.commute}, ${locationText}";
    }

    return GestureDetector(
      onTap: () => smoothPush(context, ProductDetail(productId: product.productId)),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8), 
        ),
        clipBehavior: Clip.antiAlias, // Ensures image is clipped to the 8px border radius
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ẢNH SẢN PHẨM (Top)
            AspectRatio(
              aspectRatio: 1.25, // Changed from 1.0 to make height shorter
              child: Stack(
                fit: StackFit.expand,
                children: [
                   CachedNetworkImage(
                    imageUrl: imageUrl,
                    fit: BoxFit.cover,
                    errorWidget: (context, url, error) => Container(color: Colors.grey[200], child: const Icon(Icons.image, color: Colors.grey)),
                    placeholder: (context, url) => Container(color: Colors.grey[100]),
                  ),
                  // Heart icon overlay (top right)
                  Positioned(
                    top: 8,
                    right: 8,
                    child: Icon(HeroiconsOutline.heart, color: Colors.white, size: 24),
                  ),
                  // Image/Video count overlay (bottom right)
                  if (product.productMedia.length > 1)
                     Positioned(
                      bottom: 8,
                      right: 8,
                      child: Row(
                        children: [
                          Text("${product.productMedia.length}", style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
                          const SizedBox(width: 4),
                          const Icon(HeroiconsOutline.photo, color: Colors.white, size: 14),
                        ],
                      ),
                    ),
                ]
              ),
            ),

            // THÔNG TIN SẢN PHẨM (Bottom)
            Container(
              constraints: const BoxConstraints(minHeight: 100),
              padding: const EdgeInsets.fromLTRB(8, 8, 8, 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                    // Tên sản phẩm
                    Text(
                      product.productName,
                      style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14, color: Colors.black87),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    // Giá sản phẩm
                    Text(
                      _formatPrice(product.productPrice),
                      style: const TextStyle(color: Colors.red, fontWeight: FontWeight.bold, fontSize: 15),
                    ),
                    const SizedBox(height: 12),
                    
                    // Vị trí & Thời gian (Optional detail)
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(HeroiconsOutline.mapPin, size: 12, color: Colors.grey),
                        const SizedBox(width: 4),
                         Expanded(
                             child: Text(
                               locationText,
                               style: const TextStyle(color: Colors.grey, fontSize: 11),
                               maxLines: 2,
                               overflow: TextOverflow.ellipsis,
                               textAlign: TextAlign.left,
                             ),
                         ),
                      ],
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}