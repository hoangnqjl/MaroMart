import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:maromart/models/Product/Product.dart';
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

  final Color primaryColor = const Color(0xFF3F4045);

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

    return GestureDetector(
      onTap: () => smoothPush(context, ProductDetail(productId: product.productId)),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 8, offset: const Offset(0, 4))
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ẢNH SẢN PHẨM
            Expanded(
              flex: 3,
              child: ClipRRect(
                borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
                child: CachedNetworkImage(
                  imageUrl: imageUrl,
                  width: double.infinity,
                  fit: BoxFit.cover,
                  errorWidget: (context, url, error) => Container(color: Colors.grey[200], child: const Icon(Icons.image)),
                ),
              ),
            ),

            // THÔNG TIN VÀ NÚT BẤM
            Padding(
              padding: const EdgeInsets.all(10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    product.productName,
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _formatPrice(product.productPrice),
                    style: TextStyle(color: primaryColor, fontWeight: FontWeight.w800, fontSize: 13),
                  ),
                  const SizedBox(height: 8),

                  // HÀNG NÚT BẤM (CHAT & CALL)
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Nút Chat
                      _buildSmallActionBtn(
                        icon: HeroiconsOutline.chatBubbleLeftRight,
                        onTap: () {
                          if (product.userInfo != null) {
                            final partner = ChatPartner(
                              userId: product.userInfo!.userId,
                              fullName: product.userInfo!.fullName,
                              avatarUrl: product.userInfo!.avatarUrl,
                            );
                            smoothPush(context, ChatScreen(conversationId: "", partnerUser: partner));
                          }
                        },
                      ),
                      const SizedBox(width: 8),
                      // Nút Call
                      _buildSmallActionBtn(
                        icon: HeroiconsOutline.phone,
                        onTap: () => _makeCall(product.userInfo?.phoneNumber),
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

  Widget _buildSmallActionBtn({required IconData icon, required VoidCallback onTap}) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 6),
          decoration: BoxDecoration(
            color: primaryColor.withOpacity(0.08),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, size: 16, color: primaryColor),
        ),
      ),
    );
  }
}