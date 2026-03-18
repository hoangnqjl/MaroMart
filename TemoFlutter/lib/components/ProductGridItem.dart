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

class ProductGridItem extends StatelessWidget {
  final Product product;
  const ProductGridItem({super.key, required this.product});

  final Color baseColor = const Color(0xFF3F3F46);

  String _formatPrice(int price) {
    return NumberFormat.currency(locale: 'vi_VN', symbol: 'đ', decimalDigits: 0).format(price);
  }

  @override
  Widget build(BuildContext context) {
    String imageUrl = product.productMedia.isNotEmpty ? product.productMedia[0] : '';
    if (imageUrl.startsWith('image:')) imageUrl = imageUrl.substring(6).trim();

    // Sửa lỗi ward/commute tùy theo model của bạn
    String locationText = product.productAddress?.province ?? "Đà Nẵng";
    final commune = product.productAddress?.commute;
    if (commune != null && commune.isNotEmpty) {
      locationText = "$commune, $locationText";
    }

    return GestureDetector(
      onTap: () => smoothPush(context, ProductDetail(productId: product.productId)),
      child: Container(
        width: 173,
        height: 251,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(30),
          border: Border.all(
            color: const Color(0x26000000), // Đen 15%
            width: 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. Ảnh hình vuông (1:1)
            Padding(
              padding: const EdgeInsets.all(6.0),
              child: AspectRatio(
                aspectRatio: 1,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(25),
                  child: CachedNetworkImage(
                    imageUrl: imageUrl,
                    fit: BoxFit.cover,
                    placeholder: (context, url) => Container(color: Colors.grey[100]),
                    errorWidget: (_, __, ___) => Container(
                        color: Colors.grey[200],
                        child: const Icon(Icons.image, color: Colors.grey)
                    ),
                  ),
                ),
              ),
            ),

            // 2. Nội dung với địa chỉ 2 hàng
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(14, 0, 14, 10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: [
                    const SizedBox(height: 4),
                    // Tên sản phẩm: Size 12
                    Text(
                      product.productName,
                      style: TextStyle(
                        fontFamily: 'Quicksand',
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                        color: baseColor,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),

                    const SizedBox(height: 2), // Khoảng cách hẹp để tên và địa chỉ đi liền nhau

                    // Địa chỉ: Size 10, Màu 50%, hiển thị 2 hàng
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: BackdropFilter(
                        filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.grey.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start, // Căn icon theo dòng đầu của text
                            children: [
                              Padding(
                                padding: const EdgeInsets.only(top: 2),
                                child: Icon(HeroiconsOutline.mapPin, size: 10, color: baseColor.withOpacity(0.5)),
                              ),
                              const SizedBox(width: 4),
                              Expanded(
                                child: Text(
                                  locationText,
                                  style: TextStyle(
                                    fontFamily: 'Quicksand',
                                    color: baseColor.withOpacity(0.5),
                                    fontSize: 10,
                                    fontWeight: FontWeight.w500,
                                    height: 1.2, // Chỉnh khoảng cách dòng cho địa chỉ
                                  ),
                                  maxLines: 2, // SỬA: Cho phép hiển thị 2 hàng
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),

                    const Spacer(), // Đẩy phần giá xuống đáy card

                    // Giá tiền: Size 10
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Flexible(
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF2F2F2),
                              borderRadius: BorderRadius.circular(15),
                            ),
                            child: Text(
                              _formatPrice(product.productPrice),
                              style: TextStyle(
                                fontFamily: 'Quicksand',
                                fontWeight: FontWeight.bold,
                                fontSize: 10,
                                color: baseColor,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ),
                        // Nút Chat MaroMart
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
                              smoothPush(context, ChatScreen(conversationId: "", partnerUser: partner));
                            } else {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Không tìm thấy thông tin người bán')),
                              );
                            }
                          },
                          child: ClipOval(
                            child: BackdropFilter(
                              filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
                              child: Container(
                                width: 32,
                                height: 32,
                                color: const Color(0xFFFFB86A).withOpacity(0.9), // Added slight transparency for blur
                                child: const Icon(
                                  HeroiconsSolid.chatBubbleOvalLeft,
                                  color: Colors.white,
                                  size: 16,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}