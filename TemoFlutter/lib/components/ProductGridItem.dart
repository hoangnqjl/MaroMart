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
import 'package:temo/services/review_service.dart';
import 'package:temo/Colors/AppColors.dart';

class ProductGridItem extends StatefulWidget {
  final Product product;
  const ProductGridItem({super.key, required this.product});

  @override
  State<ProductGridItem> createState() => _ProductGridItemState();
}

class _ProductGridItemState extends State<ProductGridItem> {
  // Static cache to avoid redundant rating fetches across the app session
  static final Map<String, double> _ratingCache = {};
  
  final ReviewService _reviewService = ReviewService();
  double? _rating;
  bool _isFetchingRating = false;

  @override
  void initState() {
    super.initState();
    _loadRating();
  }

  Future<void> _loadRating() async {
    final userId = widget.product.userId;
    if (userId.isEmpty) return;

    // Check cache first
    if (_ratingCache.containsKey(userId)) {
      if (mounted) {
        setState(() {
          _rating = _ratingCache[userId];
        });
      }
      return;
    }

    // Fetch from service
    if (mounted) setState(() => _isFetchingRating = true);
    try {
      final summary = await _reviewService.getRatingSummary(userId);
      final avg = (summary['averageRating'] as num).toDouble();
      _ratingCache[userId] = avg;
      if (mounted) {
        setState(() {
          _rating = avg;
          _isFetchingRating = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isFetchingRating = false);
    }
  }

  // --- UI Helpers ---
  final Color titleColor = const Color(0xFF3F3F46);
  final Color locationColor = const Color(0x803F3F46); // 50% opacity
  final Color chatBtnColor = const Color(0xFFFFB86A);
  final Color pricePillColor = const Color(0xFFEAEAEA);

  String _formatPrice(int price) {
    if (price >= 1000000000) {
      double t = price / 1000000000;
      return 'đ ${t % 1 == 0 ? t.toInt() : t.toStringAsFixed(1).replaceAll('.', ',')} tỷ';
    } else if (price >= 10000000) {
      double m = price / 1000000;
      return 'đ ${m % 1 == 0 ? m.toInt() : m.toStringAsFixed(1).replaceAll('.', ',')} tr';
    }
    final formatter = NumberFormat('#,###', 'vi_VN');
    return 'đ ${formatter.format(price).replaceAll(',', '.')}';
  }

  @override
  Widget build(BuildContext context) {
    final product = widget.product;
    String imageUrl = product.productMedia.isNotEmpty ? product.productMedia[0] : '';
    if (imageUrl.startsWith('image:')) imageUrl = imageUrl.substring(6).trim();

    String locationText = StringUtils.simplifyAddress(
      product.productAddress?.province ?? "Đà Nẵng",
    );
    final commune = product.productAddress?.commute;
    if (commune != null && commune.isNotEmpty) {
      locationText = "${StringUtils.simplifyAddress(commune)}, $locationText";
    }

    String displayTitle = product.productName;
    if (product.productCondition.isNotEmpty) {
      displayTitle += " (${product.productCondition.toLowerCase()})";
    }

    return GestureDetector(
      onTap: () => smoothPush(context, ProductDetail(productId: product.productId)),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(25),
          border: Border.all(
            color: const Color(0x26000000), // 15% black stroke
            width: 0.2,
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              // Image Section with Glassmorphism Rating Badge
              AspectRatio(
                aspectRatio: 1.0, 
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(20),
                  child: Stack(
                    children: [
                      CachedNetworkImage(
                        imageUrl: imageUrl,
                        width: double.infinity,
                        height: double.infinity,
                        fit: BoxFit.cover,
                        placeholder: (context, url) => Container(color: const Color(0xFFF3F4F6)),
                        errorWidget: (_, __, ___) => Container(
                          color: const Color(0xFFF3F4F6),
                          child: const Icon(Icons.image, color: Colors.grey),
                        ),
                      ),
                      
                      // GROWTH ICON (Top Left)
                      if (product.pushExpiry != null)
                        const Positioned(
                          top: 8,
                          left: 8,
                          child: Icon(
                            HeroiconsSolid.arrowTrendingUp,
                            color: Colors.white,
                            size: 14,
                            shadows: [Shadow(color: Colors.black45, blurRadius: 4, offset: Offset(0, 1))],
                          ),
                        ),

                      // RATING BADGE (Top Right - Glassmorphism)
                      Positioned(
                        top: 8,
                        right: 8,
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(25),
                          child: BackdropFilter(
                            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.65),
                                borderRadius: BorderRadius.circular(25),
                                border: Border.all(color: Colors.white.withOpacity(0.2), width: 0.5),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  ClipOval(
                                    child: CachedNetworkImage(
                                      imageUrl: product.userInfo?.avatarUrl ?? '',
                                      width: 20,
                                      height: 20,
                                      fit: BoxFit.cover,
                                      errorWidget: (_, __, ___) => Container(
                                        color: const Color(0xFFFFB86A),
                                        child: const Icon(Icons.person, size: 12, color: Colors.white),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    _rating != null ? _rating!.toStringAsFixed(1) : "...",
                                    style: const TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                      color: Color(0xFF3F3F46),
                                      fontFamily: 'Quicksand',
                                    ),
                                  ),
                                  const SizedBox(width: 4),
                                  const Icon(Icons.star_rate_rounded, color: Color(0xFFFFB86A), size: 14),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 12),

              // Title with Condition
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 2),
                child: Text(
                  displayTitle,
                  style: const TextStyle(
                    fontFamily: 'Quicksand',
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                    color: Color(0xFF3F3F46),
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),

              const SizedBox(height: 6),

              // Location Row
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 2),
                child: Row(
                  children: [
                    const Icon(HeroiconsOutline.mapPin, size: 14, color: Color(0x803F3F46)),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        locationText,
                        style: const TextStyle(
                          fontFamily: 'Quicksand',
                          color: Color(0x803F3F46),
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // Bottom Row: Price Pill & Bookmark
              Padding(
                padding: const EdgeInsets.only(left: 2, right: 2, bottom: 4),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: const Color(0xFFEAEAEA),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        _formatPrice(product.productPrice),
                        style: const TextStyle(
                          fontFamily: 'Quicksand',
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                          color: Color(0xCC3F3F46),
                        ),
                      ),
                    ),
                    const Icon(HeroiconsOutline.bookmark, color: Color(0xFF3F3F46), size: 20),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
