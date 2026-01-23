import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:heroicons_flutter/heroicons_flutter.dart';
import 'package:intl/intl.dart';
import 'package:maromart/Colors/AppColors.dart';
import 'package:maromart/components/VideoPlayerWidget.dart';
import 'package:maromart/models/Media/MediaItem.dart';
import 'package:maromart/models/Product/Product.dart';
import 'package:maromart/models/User/ChatPartner.dart';
import 'package:maromart/screens/Message/ChatScreen.dart';
import 'package:maromart/screens/Product/ProductDetail.dart';
import 'package:maromart/utils/storage.dart';
import 'package:maromart/utils/constants.dart';
import 'package:maromart/app_router.dart';
import 'package:url_launcher/url_launcher.dart';

class Post extends StatefulWidget {
  final Product product;
  const Post({super.key, required this.product});

  @override
  State<StatefulWidget> createState() => _PostState();
}

class _PostState extends State<Post> {
  late List<MediaItem> _mediaItems;
  final PageController _pageController = PageController();
  bool isExpanded = false; // Trạng thái đóng/mở thanh trượt

  @override
  void initState() {
    super.initState();
    _mediaItems = _parseProductMedia(widget.product.productMedia);
  }

  String _getFullUrl(String path) {
    if (path.isEmpty) return '';
    if (path.startsWith('http')) return path;
    return '${ApiConstants.baseUrl}$path';
  }

  List<MediaItem> _parseProductMedia(List<String> rawMedia) {
    return rawMedia.map((mediaString) {
      String cleanUrl = mediaString;
      if (mediaString.toLowerCase().startsWith('video:')) {
        cleanUrl = mediaString.substring(6).trim();
        return MediaItem(type: MediaType.video, url: _getFullUrl(cleanUrl));
      } else {
        if (mediaString.toLowerCase().startsWith('image:')) {
          cleanUrl = mediaString.substring(6).trim();
        }
        return MediaItem(type: MediaType.image, url: _getFullUrl(cleanUrl));
      }
    }).toList();
  }

  String _formatPrice(int price) {
    return NumberFormat('#,###', 'vi_VN').format(price) + ' đ';
  }

  void _toggleExpanded() {
    setState(() => isExpanded = !isExpanded);
  }

  void _makeCall(String? phone) async {
    if (phone == null || phone.isEmpty) return;
    final uri = Uri.parse("tel:$phone");
    if (await canLaunchUrl(uri)) await launchUrl(uri);
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final product = widget.product;
    final seller = product.userInfo;

    return Container(
      height: screenWidth * 1.05,
      width: double.infinity,
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
              if (details.primaryVelocity! < -300) {
                if (!isExpanded) _toggleExpanded();
              } else if (details.primaryVelocity! > 300) {
                if (isExpanded) _toggleExpanded();
              }
            },
            child: PageView.builder(
              controller: _pageController,
              itemCount: _mediaItems.length,
              itemBuilder: (context, index) => _buildMediaContent(_mediaItems[index]),
            ),
          ),

          // 2. PRICE TAG
          Positioned(
            top: 15,
            left: 15,
            child: _buildBlurTag(_formatPrice(product.productPrice)),
          ),

          AnimatedPositioned(
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOutCubic,
            top: 40,
            bottom: 60,
            right: isExpanded ? 0 : -85,
            child: Row(
              children: [
                GestureDetector(
                  onTap: _toggleExpanded,
                  child: Container(
                    width: 25,
                    height: 60,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(15),
                        bottomLeft: Radius.circular(15),
                      ),
                    ),
                    child: Center(
                      child: Container(
                        width: 4,
                        height: 30,
                        decoration: BoxDecoration(
                          color: Colors.white70,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                  ),
                ),
                ClipRRect(
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(30),
                    bottomLeft: Radius.circular(30),
                  ),
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
                    child: Container(
                      width: 85,
                      padding: const EdgeInsets.symmetric(vertical: 20),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.3),
                        border: Border.all(color: Colors.white.withOpacity(0.1)),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          _buildAction(HeroiconsSolid.bookmark, "Save"),
                          _buildAction(HeroiconsSolid.chatBubbleOvalLeftEllipsis, "Chat", onTap: () {
                            if (seller != null) {
                              final partner = ChatPartner(userId: seller.userId, fullName: seller.fullName, avatarUrl: seller.avatarUrl);
                              smoothPush(context, ChatScreen(conversationId: "", partnerUser: partner));
                            }
                          }),
                          _buildAction(HeroiconsSolid.phone, "Call", onTap: () => _makeCall(seller?.phoneNumber.toString())),
                          _buildAction(HeroiconsSolid.ellipsisHorizontal, "More"),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          Positioned(
            bottom: 0, left: 0, right: 0,
            child: Container(
              padding: const EdgeInsets.fromLTRB(20, 40, 80, 25),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.bottomCenter,
                  end: Alignment.topCenter,
                  colors: [Colors.black.withOpacity(0.7), Colors.black.withOpacity(0.3), Colors.transparent],
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    product.productName,
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16, fontFamily: 'QuickSand'),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    product.productDescription,
                    style: const TextStyle(color: Colors.white, fontSize: 12, fontFamily: 'QuickSand'),
                    maxLines: 5,
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


  Widget _buildBlurTag(String text) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.2),
            border: Border.all(color: Colors.white.withOpacity(0.1)),
          ),
          child: Text(text, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
        ),
      ),
    );
  }

  Widget _buildMediaContent(MediaItem item) {
    if (item.type == MediaType.image) {
      return CachedNetworkImage(
        imageUrl: item.url,
        fit: BoxFit.cover,
        placeholder: (context, url) => Container(color: Colors.grey[200]),
        errorWidget: (context, url, error) => Container(color: Colors.grey[300], child: const Icon(Icons.broken_image)),
      );
    }
    return VideoPlayerWidget(videoUrl: item.url);
  }

  Widget _buildAction(IconData icon, String label, {VoidCallback? onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(color: Colors.white.withOpacity(0.15), shape: BoxShape.circle),
            child: Icon(icon, color: Colors.white, size: 22),
          ),
          const SizedBox(height: 4),
          Text(label, style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}