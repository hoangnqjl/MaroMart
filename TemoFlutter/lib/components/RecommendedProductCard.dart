import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:heroicons_flutter/heroicons_flutter.dart';
import 'package:intl/intl.dart';
import 'package:temo/models/Product/Product.dart';
import 'package:temo/utils/string_utils.dart';
import 'package:temo/services/review_service.dart';
import 'package:temo/Colors/AppColors.dart';
import 'package:temo/models/User/ChatPartner.dart';
import 'package:temo/screens/Message/ChatScreen.dart';
import 'package:temo/app_router.dart';
import 'package:geolocator/geolocator.dart';

class RecommendedProductCard extends StatefulWidget {
  final Product product;
  final Position? currentPosition;

  const RecommendedProductCard({
    Key? key,
    required this.product,
    this.currentPosition,
  }) : super(key: key);

  @override
  State<RecommendedProductCard> createState() => _RecommendedProductCardState();
}

class _RecommendedProductCardState extends State<RecommendedProductCard> {
  static final Map<String, double> _ratingCache = {};
  final ReviewService _reviewService = ReviewService();
  double? _rating;

  @override
  void initState() {
    super.initState();
    _loadRating();
  }

  Future<void> _loadRating() async {
    final userId = widget.product.userId;
    if (userId.isEmpty) return;

    if (_ratingCache.containsKey(userId)) {
      if (mounted) setState(() => _rating = _ratingCache[userId]);
      return;
    }

    try {
      final summary = await _reviewService.getRatingSummary(userId);
      final avg = (summary['averageRating'] as num).toDouble();
      _ratingCache[userId] = avg;
      if (mounted) setState(() => _rating = avg);
    } catch (e) {
      debugPrint("Error loading rating: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    final product = widget.product;
    String imageUrl = product.productMedia.isNotEmpty ? product.productMedia[0] : '';
    if (imageUrl.startsWith('image:')) imageUrl = imageUrl.substring(6).trim();

    final String formattedPrice = NumberFormat.currency(
      locale: 'vi_VN',
      symbol: 'đ',
      decimalDigits: 0,
    ).format(product.productPrice);

    Widget? discountTag;
    if (product.marketPrice != null && product.marketPrice! > 0 && product.marketPrice! > product.productPrice) {
      int percent = ((product.marketPrice! - product.productPrice) / product.marketPrice! * 100).round();
      if (percent > 0) {
        discountTag = Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: const Color(0xFFECFDF5).withOpacity(0.95),
            borderRadius: BorderRadius.circular(20),
            boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 4, offset: Offset(0, 2))],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(HeroiconsOutline.arrowTrendingDown, color: Color(0xFF059669), size: 10),
              const SizedBox(width: 2),
              Text(
                "$percent%",
                style: const TextStyle(
                  fontFamily: 'Quicksand',
                  color: Color(0xFF059669),
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        );
      }
    }

    return GestureDetector(
      onTap: () => Navigator.pushNamed(context, '/product_detail', arguments: product.productId),
      child: Container(
        width: 250,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(30),
          boxShadow: [
            BoxShadow(
              color: const Color(0x26000000),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(30),
          child: Stack(
            fit: StackFit.expand,
            children: [
              CachedNetworkImage(
                imageUrl: StringUtils.normalizeUrl(imageUrl),
                fit: BoxFit.cover,
                maxWidthDiskCache: 1080,
                maxHeightDiskCache: 1080,
                placeholder: (context, url) => Container(color: AppColors.background),
                errorWidget: (context, url, error) => Container(
                  color: Colors.grey[200],
                  child: const Icon(Icons.image),
                ),
              ),
              Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.black.withOpacity(0.4),
                      Colors.transparent,
                      Colors.transparent,
                      Colors.black.withOpacity(0.4),
                    ],
                    stops: const [0.0, 0.25, 0.7, 1.0],
                  ),
                ),
              ),
              
              // Rating Badge (Top Right - Glassmorphism)
              Positioned(
                top: 12, right: 12,
                child: _buildGlassBadge(
                  content: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        _rating != null ? _rating!.toStringAsFixed(1) : "...",
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                          fontFamily: 'Quicksand',
                        ),
                      ),
                      const SizedBox(width: 4),
                      const Icon(Icons.star_rate_rounded, color: Color(0xFFFFB86A), size: 14),
                    ],
                  ),
                ),
              ),

              Padding(
                padding: const EdgeInsets.all(12.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          product.productName,
                          style: const TextStyle(
                            fontFamily: 'Quicksand',
                            color: Colors.white,
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            shadows: [Shadow(color: Colors.black45, blurRadius: 8, offset: Offset(0, 4))],
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 6),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Text(
                              formattedPrice,
                              style: const TextStyle(
                                fontFamily: 'Quicksand',
                                color: Colors.white,
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                                shadows: [Shadow(color: Colors.black26, blurRadius: 4, offset: Offset(0, 2))],
                              ),
                            ),
                            if (discountTag != null) ...[
                              const SizedBox(width: 8),
                              discountTag,
                            ],
                          ],
                        ),
                      ],
                    ),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Expanded(
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(20),
                            child: BackdropFilter(
                              filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                              child: Container(
                                height: 44,
                                padding: const EdgeInsets.symmetric(horizontal: 14),
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.2),
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(color: Colors.white.withOpacity(0.2), width: 0.5),
                                ),
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.center,
                                  children: [
                                    const Icon(HeroiconsOutline.mapPin, color: Colors.white, size: 16),
                                    const SizedBox(width: 6),
                                    Expanded(
                                      child: Text(
                                        (() {
                                          if (widget.currentPosition != null && product.latitude != null && product.longitude != null) {
                                            double dist = Geolocator.distanceBetween(
                                              widget.currentPosition!.latitude,
                                              widget.currentPosition!.longitude,
                                              product.latitude!,
                                              product.longitude!,
                                            );
                                            if (dist < 1000) return "Rất gần bạn";
                                            if (dist < 10000) return "Gần bạn";
                                            return "~${NumberFormat('#,###.#').format(dist / 1000)} km";
                                          }
                                          return StringUtils.simplifyAddress(product.productAddress?.province ?? 'Location');
                                        })(),
                                        style: const TextStyle(
                                          fontFamily: 'Quicksand',
                                          color: Colors.white,
                                          fontSize: 13,
                                          fontWeight: FontWeight.w600,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        GestureDetector(
                          onTap: () {
                            if (product.userInfo != null) {
                              final userInfo = product.userInfo!;
                              final partner = ChatPartner(
                                userId: userInfo.userId,
                                fullName: userInfo.fullName,
                                avatarUrl: StringUtils.normalizeUrl(userInfo.avatarUrl),
                                email: userInfo.email,
                              );
                              smoothPush(context, ChatScreen(conversationId: "", partnerUser: partner, product: product));
                            }
                          },
                          child: ClipOval(
                            child: BackdropFilter(
                              filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                              child: Container(
                                width: 44,
                                height: 44,
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.2),
                                  shape: BoxShape.circle,
                                  border: Border.all(color: Colors.white.withOpacity(0.2), width: 0.5),
                                ),
                                alignment: Alignment.center,
                                child: const Icon(HeroiconsOutline.chatBubbleOvalLeft, color: Colors.white, size: 22),
                              ),
                            ),
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
      ),
    );
  }
  Widget _buildGlassBadge({required Widget content}) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: Colors.black.withOpacity(0.3),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.white.withOpacity(0.2), width: 0.5),
          ),
          child: content,
        ),
      ),
    );
  }
}
