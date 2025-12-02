import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:heroicons_flutter/heroicons_flutter.dart';
import 'package:intl/intl.dart';
import 'package:maromart/Colors/AppColors.dart';
import 'package:maromart/components/VideoPlayerWidget.dart';
import 'package:maromart/models/Media/MediaItem.dart';
import 'package:maromart/models/Product/Product.dart';
import 'package:maromart/models/User/ChatPartner.dart';
import 'package:maromart/models/User/User.dart';
import 'package:maromart/screens/Message/ChatScreen.dart';
import 'package:maromart/screens/Product/ProductDetail.dart';
import 'package:maromart/utils/storage.dart';

class Post extends StatefulWidget {
  final Product product;
  const Post({super.key, required this.product});

  @override
  State<StatefulWidget> createState() => _PostState();
}

class _PostState extends State<Post> {
  late List<MediaItem> _mediaItems;
  bool isExpanded = false;
  final PageController _pageController = PageController();

  @override
  void initState() {
    super.initState();
    _mediaItems = _parseProductMedia(widget.product.productMedia);
  }

  List<MediaItem> _parseProductMedia(List<String> rawMedia) {
    return rawMedia.map((mediaString) {
      if (mediaString.toLowerCase().startsWith('video:')) {
        return MediaItem(
          type: MediaType.video,
          url: mediaString.substring(6).trim(),
        );
      } else {
        String url = mediaString;
        if (mediaString.toLowerCase().startsWith('image:')) {
          url = mediaString.substring(6).trim();
        }
        return MediaItem(type: MediaType.image, url: url);
      }
    }).toList();
  }

  String _formatPrice(int price) {
    final formatter = NumberFormat('#,###', 'vi_VN');
    return '${formatter.format(price)} đ';
  }

  void _toggleExpanded() {
    setState(() => isExpanded = !isExpanded);
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final product = widget.product;

    final String sellerName = product.userInfo?.fullName ?? 'Người dùng ẩn danh';
    final String sellerAvatar = product.userInfo?.avatarUrl ?? '';
    final currentUserId = StorageHelper.getUserId();
    final sellerId = product.userInfo?.userId;
    final bool isOwner = currentUserId != null && sellerId != null && currentUserId == sellerId;

    return Container(
      height: screenWidth * 1.2,
      width: double.infinity,
      clipBehavior: Clip.hardEdge,
      decoration: BoxDecoration(
        color: AppColors.E2Color,
        border: Border.all(color: Colors.grey.shade300, width: 0.5),
        borderRadius: BorderRadius.circular(30),
      ),
      child: Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.centerRight,
        children: [
          // MEDIA VIEWER
          GestureDetector(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => ProductDetail(
                    productId: product.productId,
                )
                ),
              );
            },
            onHorizontalDragEnd: (details) {
              if (details.primaryVelocity! < -500) {
                if (!isExpanded) _toggleExpanded();
              }
              else if (details.primaryVelocity! > 500) {
                if (isExpanded) _toggleExpanded();
              }
            },
            child: PageView.builder(
              controller: _pageController,
              itemCount: _mediaItems.length,
              itemBuilder: (context, index) => _buildMediaItem(_mediaItems[index]),
            ),
          ),

          // PRICE TAG
          Positioned(
            top: 20,
            left: 20,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 10.0, sigmaY: 10.0),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.black26.withOpacity(0.5),
                  ),
                  child: Text(
                    _formatPrice(product.productPrice),
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 13,
                        fontWeight: FontWeight.bold
                    ),
                  ),
                ),
              ),
            ),
          ),

          // ACTION MENU SIDEBAR
          AnimatedPositioned(
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOut,
            top: screenWidth * 0.20,
            right: isExpanded ? 0 : -60,
            child: GestureDetector(
              onHorizontalDragEnd: (details) {
                if (details.primaryVelocity! > 300) {
                  if (isExpanded) _toggleExpanded();
                } else if (details.primaryVelocity! < -300) {
                  if (!isExpanded) _toggleExpanded();
                }
              },
              onTap: () {
                if (!isExpanded) _toggleExpanded();
              },
              child: ClipRRect(
                borderRadius: const BorderRadius.only(
                    bottomLeft: Radius.circular(30),
                    topLeft: Radius.circular(30)
                ),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 15.0, sigmaY: 15.0),
                  child: Container(
                    width: 90,
                    height: screenWidth * 0.8,
                    decoration: BoxDecoration(color: Colors.black.withOpacity(0.3)),
                    padding: const EdgeInsets.only(right: 10, top: 14, bottom: 14, left: 10),
                    child: Row(
                      children: [
                        GestureDetector(
                          onTap: _toggleExpanded,
                          child: Container(
                            width: 10,
                            height: 50,
                            decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.9),
                                borderRadius: BorderRadius.circular(10)
                            ),
                            // Thêm icon để rõ ràng hơn
                            // child: Center(
                            //   child: Icon(
                            //     isExpanded ? Icons.chevron_right : Icons.chevron_left,
                            //     color: Colors.black54,
                            //     size: 16,
                            //   ),
                            // ),
                          ),
                        ),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            children: [
                              _buildActionButton(HeroiconsSolid.heart, "Like"),
                              if (!isOwner)
                                _buildActionButton(
                                  HeroiconsSolid.chatBubbleOvalLeftEllipsis,
                                  "Chat",
                                  onTap: () {
                                    if (widget.product.userInfo != null) {
                                      final partner = ChatPartner(
                                        userId: widget.product.userInfo!.userId,
                                        fullName: widget.product.userInfo!.fullName,
                                        avatarUrl: widget.product.userInfo!.avatarUrl,
                                        email: widget.product.userInfo!.email,
                                      );
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (context) => ChatScreen(
                                            conversationId: "",
                                            partnerUser: partner,
                                          ),
                                        ),
                                      );
                                    }
                                  },
                                ),
                              if (!isOwner)
                                _buildActionButton(HeroiconsSolid.phone, "Call"),

                              _buildActionButton(HeroiconsSolid.ellipsisHorizontal, "More"),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),

          // PRODUCT INFO OVERLAY
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              padding: const EdgeInsets.fromLTRB(20, 40, 20, 20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.bottomCenter,
                  end: Alignment.topCenter,
                  colors: [Colors.black.withOpacity(0.7), Colors.transparent],
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 1.5),
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(100),
                          child: SizedBox(
                            width: 32,
                            height: 32,
                            child: _buildSafeAvatar(sellerAvatar),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          sellerName,
                          style: const TextStyle(
                            fontSize: 13,
                            color: Colors.white,
                            fontFamily: 'QuickSand',
                            fontWeight: FontWeight.w700,
                            shadows: [Shadow(blurRadius: 4, color: Colors.black)],
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    product.productDescription,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.w400,
                      shadows: [Shadow(blurRadius: 2, color: Colors.black)],
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSafeAvatar(String url) {
    if (url.isEmpty) {
      return Image.asset('lib/images/avt.webp', fit: BoxFit.cover);
    }
    return Image.network(
      url,
      fit: BoxFit.cover,
      errorBuilder: (context, error, stackTrace) {
        return Image.asset('lib/images/avt.webp', fit: BoxFit.cover);
      },
    );
  }

  Widget _buildMediaItem(MediaItem item) {
    if (item.type == MediaType.image) {
      return Image.network(
        item.url,
        fit: BoxFit.cover,
        width: double.infinity,
        height: double.infinity,
        errorBuilder: (context, error, stackTrace) => Container(
            color: Colors.grey[300],
            child: const Center(child: Icon(Icons.image_not_supported, color: Colors.grey))
        ),
      );
    } else {
      return VideoPlayerWidget(videoUrl: item.url);
    }
  }

  Widget _buildActionButton(IconData icon, String label, {VoidCallback? onTap}) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.25),
            shape: BoxShape.circle,
          ),
          child: IconButton(
            padding: EdgeInsets.zero,
            icon: Icon(icon, color: Colors.white, size: 22),
            onPressed: onTap ?? () {},
          ),
        ),
        const SizedBox(height: 4),
        Text(
            label,
            style: const TextStyle(
                fontSize: 10,
                color: Colors.white,
                fontWeight: FontWeight.w600,
                shadows: [Shadow(blurRadius: 2, color: Colors.black)]
            )
        ),
      ],
    );
  }
}