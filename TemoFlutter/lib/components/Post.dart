import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:heroicons_flutter/heroicons_flutter.dart';
import 'package:intl/intl.dart';
import 'package:temo/Colors/AppColors.dart';
import 'package:temo/components/VideoPlayerWidget.dart';
import 'package:temo/models/Media/MediaItem.dart';
import 'package:temo/models/Product/Product.dart';
import 'package:temo/models/User/ChatPartner.dart';
import 'package:temo/screens/Message/ChatScreen.dart';
import 'package:temo/screens/Product/ProductDetail.dart';
import 'package:temo/screens/Profile/UserProfileScreen.dart';
import 'package:temo/utils/constants.dart';
import 'package:temo/app_router.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:temo/utils/string_utils.dart';
import 'package:temo/services/product_service.dart';
import 'package:temo/utils/storage.dart';
import 'package:geolocator/geolocator.dart';
import 'package:temo/services/review_service.dart';

class Post extends StatefulWidget {
  final Product product;
  const Post({super.key, required this.product});

  @override
  State<StatefulWidget> createState() => _PostState();
}

class _PostState extends State<Post> with SingleTickerProviderStateMixin {
  late List<MediaItem> _mediaItems;
  final PageController _pageController = PageController();
  final ProductService _productService = ProductService();
  int _currentMediaIndex = 0;
  bool isExpanded = false;
  String? _distanceText;

  // Flip Animation Variables
  late AnimationController _flipController;
  late Animation<double> _flipAnimation;
  bool _isFlipped = false;

  // Rating state
  static final Map<String, double> _ratingCache = {};
  final ReviewService _reviewService = ReviewService();
  double? _rating;
  bool _isFetchingRating = false;

  @override
  void initState() {
    super.initState();
    _mediaItems = _parseProductMedia(widget.product.productMedia);

    _flipController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _flipAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _flipController, curve: Curves.easeInOutBack),
    );


    _productService.fetchSavedProductsIfNeeded();
    _calculateDistance();
    _loadRating();
  }

  Future<void> _loadRating() async {
    final userId = widget.product.userId;
    if (userId.isEmpty) return;

    if (_ratingCache.containsKey(userId)) {
      if (mounted) setState(() => _rating = _ratingCache[userId]);
      return;
    }

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

  Future<void> _calculateDistance() async {
    try {
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) return;
      
      final pos = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.low
      );
      
      final product = widget.product;
      if (product.latitude != null && product.longitude != null) {
        double distanceInMeters = Geolocator.distanceBetween(
          pos.latitude, pos.longitude, 
          product.latitude!, product.longitude!
        );

        if (mounted) {
          setState(() {
            if (distanceInMeters < 1000) {
              _distanceText = "Rất gần bạn";
            } else if (distanceInMeters < 10000) {
              _distanceText = "Gần bạn";
            } else {
              _distanceText = "~${NumberFormat('#,###.#').format(distanceInMeters / 1000)} km";
            }
          });
        }
      }
    } catch (e) {
      debugPrint("Lỗi tính khoảng cách: $e");
    }
  }

  @override
  void dispose() {
    _flipController.dispose();
    _pageController.dispose();
    super.dispose();
  }

  void _toggleFlip() {
    if (_isFlipped) _flipController.reverse();
    else _flipController.forward();
    _isFlipped = !_isFlipped;
  }

  void _toggleExpanded() => setState(() => isExpanded = !isExpanded);



  List<MediaItem> _parseProductMedia(List<String> rawMedia) {
    return rawMedia.map((mediaString) {
      String cleanUrl = mediaString;
      if (mediaString.toLowerCase().startsWith('video:')) {
        cleanUrl = mediaString.substring(6).trim();
        return MediaItem(type: MediaType.video, url: StringUtils.normalizeUrl(cleanUrl));
      } else {
        if (mediaString.toLowerCase().startsWith('image:')) {
          cleanUrl = mediaString.substring(6).trim();
        }
        return MediaItem(type: MediaType.image, url: StringUtils.normalizeUrl(cleanUrl));
      }
    }).toList();
  }

  String _formatPrice(int price) => NumberFormat('#,###', 'vi_VN').format(price) + ' đ';

  void _makeCall(String? phone) async {
    if (phone == null || phone.isEmpty) return;
    final uri = Uri.parse("tel:$phone");
    if (await canLaunchUrl(uri)) await launchUrl(uri);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: double.infinity,
      margin: const EdgeInsets.only(bottom: 12),
      color: Colors.transparent,
      child: GestureDetector(
        onDoubleTap: _toggleFlip,
        child: AnimatedBuilder(
          animation: _flipAnimation,
          builder: (context, child) {
            final double angle = _flipAnimation.value * 3.14159265;
            final bool isBack = angle >= 3.14159265 / 2;

            return Transform(
              alignment: Alignment.center,
              transform: Matrix4.identity()
                ..setEntry(3, 2, 0.001)
                ..rotateY(angle),
              child: isBack
                  ? Transform(
                alignment: Alignment.center,
                transform: Matrix4.identity()..rotateY(3.14159265),
                child: _buildBackSide(),
              )
                  : _buildFrontSide(context),
            );
          },
        ),
      ),
    );
  }

  Widget _buildFrontSide(BuildContext context) {
    final product = widget.product;
    final seller = product.userInfo;

    return Container(
      clipBehavior: Clip.hardEdge,
      decoration: BoxDecoration(
        color: AppColors.E2Color,
        borderRadius: BorderRadius.circular(30),
      ),
      child: Stack(
        children: [
          GestureDetector(
            onTap: () => smoothPush(context, ProductDetail(productId: product.productId)),
            onHorizontalDragEnd: (details) {
              if (details.primaryVelocity! < -300) { if (!isExpanded) _toggleExpanded(); }
              else if (details.primaryVelocity! > 300) { if (isExpanded) _toggleExpanded(); }
            },
            child: PageView.builder(
              controller: _pageController,
              itemCount: _mediaItems.length,
              onPageChanged: (index) {
                setState(() {
                  _currentMediaIndex = index;
                });
              },
              itemBuilder: (context, index) => _buildMediaContent(_mediaItems[index]),
            ),
          ),

          // Price Tag removed from top left as it's now at the bottom
          
          // Image Indicator (Top Right)
          if (_mediaItems.length > 1)
            Positioned(
              top: 15, right: 15,
              child: _buildBlurTag('${_currentMediaIndex + 1}/${_mediaItems.length}'),
            ),

          // Rating Badge (Top Left - Glassmorphism)
          Positioned(
            top: 15, left: 15,
            child: ClipRRect(
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
                  child: Row(
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
            ),
          ),


          // --- Progressive Blur: Overlapping strips, each adds sigma 5 ---
          // Bottom gets all 8 layers stacked = very blurry
          // Top gets only 1 layer = slightly blurry
          // Smooth transition because each layer only adds a tiny amount
          ...[140, 128, 116, 104, 92, 80, 68, 56, 44, 32].map((h) => Positioned(
            bottom: 0, left: 0, right: 0, height: h.toDouble(),
            child: ClipRect(
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 1.5, sigmaY: 1.5),
                child: Container(color: Colors.black.withOpacity(0.002)),
              ),
            ),
          )),
          
          // --- Content Overlay ---
          Positioned(
            bottom: 0, left: 0, right: 0,
            child: Container(
              padding: const EdgeInsets.fromLTRB(20, 50, 20, 25),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    product.productName,
                    style: const TextStyle(
                      color: Colors.white, 
                      fontWeight: FontWeight.bold, 
                      fontSize: 19, 
                      fontFamily: 'QuickSand',
                      shadows: [Shadow(blurRadius: 10, color: Colors.black38, offset: Offset(0, 2))]
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _formatPrice(product.productPrice),
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w900, 
                      fontSize: 22, 
                      fontFamily: 'QuickSand',
                      shadows: [Shadow(blurRadius: 8, color: Colors.black26, offset: Offset(0, 2))]
                    ),
                  ),
                  const SizedBox(height: 15),
                  Row(
                    children: [
                      _buildConditionTag(product.productCondition),
                      const SizedBox(width: 8),
                      _buildLocationTag(_distanceText ?? StringUtils.simplifyAddress(product.productAddress?.province ?? "")),
                    ],
                  )
                ],
              ),
            ),
          ),

          // Sidebar Action Bar (Moved to the end of Stack to stay above progressive blur)
          if (widget.product.userId != StorageHelper.getUserId())
            AnimatedPositioned(
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeOutCubic,
              top: 60, bottom: 80,
              right: isExpanded ? 16 : -85,
              child: Row(
              children: [
                GestureDetector(
                  onTap: _toggleExpanded,
                  child: Container(
                    width: 25, height: 60,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: const BorderRadius.only(topLeft: Radius.circular(15), bottomLeft: Radius.circular(15)),
                    ),
                    child: Center(
                      child: Container(width: 4, height: 30, decoration: BoxDecoration(color: Colors.white70, borderRadius: BorderRadius.circular(2))),
                    ),
                  ),
                ),
                ClipRRect(
                  borderRadius: BorderRadius.circular(50),
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
                    child: Container(
                      width: 80,
                      padding: const EdgeInsets.symmetric(vertical: 15),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.85),
                        border: Border.all(color: Colors.white.withOpacity(0.9), width: 1.5),
                        borderRadius: BorderRadius.circular(50),
                        boxShadow: [
                          BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 10, offset: const Offset(-5, 0))
                        ],
                      ),
                      child: SingleChildScrollView(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            _buildAction(HeroiconsSolid.user, "Hồ sơ", isAvatar: true, avatarUrl: seller?.avatarUrl, onTap: () {
                              smoothPush(context, UserProfileScreen(userId: widget.product.userId));
                            }),
                            const SizedBox(height: 16),
                            _buildAction(HeroiconsSolid.chatBubbleOvalLeft, "Chat", onTap: () {
                              if (seller != null) {
                                final partner = ChatPartner(userId: seller.userId, fullName: seller.fullName, avatarUrl: seller.avatarUrl);
                                smoothPush(context, ChatScreen(conversationId: "", partnerUser: partner, product: widget.product));
                              }
                            }),
                            const SizedBox(height: 18),
                            _buildAction(HeroiconsSolid.phone, "Call", onTap: () => _makeCall(seller?.phoneNumber.toString())),
                            const SizedBox(height: 18),
                            _buildMoreAction(), // Nút More chứa Save bên trong
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMoreAction() {
    return PopupMenuButton<String>(
      offset: const Offset(-150, 0),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(color: AppColors.primary.withOpacity(0.1), shape: BoxShape.circle),
            child: const Icon(HeroiconsSolid.ellipsisHorizontal, color: AppColors.primary, size: 24),
          ),
          const SizedBox(height: 4),
          const Text("More", style: TextStyle(color: Colors.black87, fontSize: 11, fontWeight: FontWeight.bold, fontFamily: 'QuickSand')),
        ],
      ),
      onSelected: (value) {
        if (value == 'save') {
          _toggleSave();
        }
      },
      itemBuilder: (context) => [
        PopupMenuItem(
          value: 'save',
          child: ValueListenableBuilder<Set<String>>(
            valueListenable: ProductService.savedProductIdsNotifier,
            builder: (context, savedIds, _) {
              final isSaved = savedIds.contains(widget.product.productId);
              return Row(
                children: [
                  Icon(
                    isSaved ? HeroiconsSolid.bookmark : HeroiconsOutline.bookmark,
                    color: isSaved ? AppColors.primary : Colors.black87,
                  ),
                  const SizedBox(width: 10),
                  Text(
                    isSaved ? "Bỏ lưu tin" : "Lưu tin",
                    style: const TextStyle(fontFamily: 'QuickSand'),
                  ),
                ],
              );
            },
          ),
        ),
        const PopupMenuItem(
          value: 'report',
          child: Row(children: [Icon(HeroiconsOutline.exclamationTriangle, color: Colors.red), SizedBox(width: 10), Text("Báo cáo", style: TextStyle(fontFamily: 'QuickSand', color: Colors.red))]),
        ),
      ],
    );
  }

  Widget _buildConditionTag(String condition) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.15), 
        borderRadius: BorderRadius.circular(50), 
        border: Border.all(color: Colors.white.withOpacity(0.25))
      ),
      child: Text(condition.isNotEmpty ? condition : "Mới/Cũ", style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600, fontFamily: 'QuickSand')),
    );
  }

  Widget _buildLocationTag(String location) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.15), 
        borderRadius: BorderRadius.circular(50), 
        border: Border.all(color: Colors.white.withOpacity(0.25))
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(HeroiconsOutline.mapPin, color: Colors.white, size: 12),
          const SizedBox(width: 4),
          Text(
            location,
            style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600, fontFamily: 'QuickSand'),
          ),
        ],
      ),
    );
  }

  Widget _buildBackSide() {
    final seller = widget.product.userInfo;
    String bgUrl = _mediaItems.isNotEmpty ? _mediaItems[0].url : '';
    
    return Container(
      clipBehavior: Clip.hardEdge,
      decoration: BoxDecoration(borderRadius: BorderRadius.circular(30), color: Colors.black),
      child: Stack(
        fit: StackFit.expand,
        children: [
          // Blurred background image
           if (bgUrl.isNotEmpty)
             CachedNetworkImage(
                imageUrl: bgUrl,
                fit: BoxFit.cover,
                maxWidthDiskCache: 1920,
                maxHeightDiskCache: 1080,
                errorWidget: (context, url, err) => Container(color: Colors.grey[800]),
             ),
           // Glassmorphism overlay
           BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 30, sigmaY: 30),
              child: Container(color: Colors.black.withOpacity(0.6)),
           ),
           
           // Content
           Padding(
             padding: const EdgeInsets.all(24),
             child: Column(
               crossAxisAlignment: CrossAxisAlignment.start,
               children: [
                 GestureDetector(
                   onTap: () {
                     smoothPush(context, UserProfileScreen(userId: widget.product.userId));
                   },
                   child: Row(
                     children: [
                       CircleAvatar(
                         radius: 20,
                         backgroundColor: Colors.white24,
                         backgroundImage: (seller?.avatarUrl != null && seller!.avatarUrl.isNotEmpty)
                             ? CachedNetworkImageProvider(StringUtils.normalizeUrl(seller.avatarUrl))
                             : null,
                         child: (seller?.avatarUrl == null || seller!.avatarUrl.isEmpty) 
                            ? const Icon(Icons.person, color: Colors.white) : null,
                       ),
                       const SizedBox(width: 12),
                       Expanded(
                         child: Column(
                           crossAxisAlignment: CrossAxisAlignment.start,
                           children: [
                             Text(seller?.fullName ?? "Người dùng ẩn danh", style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                             const Text("Người bán", style: TextStyle(color: Colors.white54, fontSize: 12)),
                           ],
                         ),
                       ),
                     ],
                   ),
                 ),
                 
                 const SizedBox(height: 20),
                 const Text("CHI TIẾT MÔ TẢ", style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.white54, letterSpacing: 1.2)),
                 const Divider(height: 24, color: Colors.white24),
                 
                 Expanded(
                   child: SingleChildScrollView(
                     physics: const BouncingScrollPhysics(), 
                     child: Text(widget.product.productDescription, style: const TextStyle(fontSize: 15, height: 1.6, color: Colors.white, fontFamily: 'QuickSand'))
                   )
                 ),
                 
                 const SizedBox(height: 10),
                 Center(
                   child: Container(
                     padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                     decoration: BoxDecoration(color: Colors.white12, borderRadius: BorderRadius.circular(20)),
                     child: const Text("Nhấn đúp để quay lại ảnh", style: TextStyle(color: Colors.white70, fontSize: 12, fontFamily: 'QuickSand')),
                   )
                 ),
               ],
             ),
           ),
        ],
      )
    );
  }

  Widget _buildBlurTag(String text) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
          decoration: BoxDecoration(color: Colors.black.withOpacity(0.3), borderRadius: BorderRadius.circular(20), border: Border.all(color: Colors.white.withOpacity(0.2))),
          child: Text(text, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13, fontFamily: 'QuickSand')),
        ),
      ),
    );
  }

  Widget _buildMediaContent(MediaItem item) {
    if (item.type == MediaType.image) return CachedNetworkImage(imageUrl: item.url, fit: BoxFit.cover, width: double.infinity, maxWidthDiskCache: 1920, maxHeightDiskCache: 1080, placeholder: (context, url) => Container(color: Colors.grey[200]));
    return VideoPlayerWidget(videoUrl: item.url);
  }

  Widget _buildAction(IconData icon, String label, {VoidCallback? onTap, bool isAvatar = false, String? avatarUrl}) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          if (isAvatar)
            Container(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 1.5),
              ),
              child: CircleAvatar(
                radius: 22,
                backgroundColor: Colors.white24,
                backgroundImage: (avatarUrl != null && avatarUrl.isNotEmpty) ? CachedNetworkImageProvider(StringUtils.normalizeUrl(avatarUrl)) : null,
                child: (avatarUrl == null || avatarUrl.isEmpty) ? Icon(icon, color: Colors.white, size: 24) : null,
              ),
            )
          else
            Container(
              padding: const EdgeInsets.all(10), 
              decoration: BoxDecoration(color: AppColors.primary.withOpacity(0.1), shape: BoxShape.circle), 
              child: Icon(icon, color: AppColors.primary, size: 24)
            ),
          const SizedBox(height: 4),
          Text(label, style: const TextStyle(color: Colors.black87, fontSize: 11, fontWeight: FontWeight.bold, fontFamily: 'QuickSand')),
        ],
      ),
    );
  }

  Future<void> _toggleSave() async {
    if (StorageHelper.getToken() == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Vui lòng đăng nhập để lưu sản phẩm")),
      );
      return;
    }

    try {
      await _productService.toggleSave(widget.product.productId);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Lỗi: ${e.toString().replaceAll("Exception: ", "")}")),
      );
    }
  }
}