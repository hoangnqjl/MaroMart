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
import 'package:maromart/utils/constants.dart';
import 'package:maromart/app_router.dart';
import 'package:url_launcher/url_launcher.dart';

class Post extends StatefulWidget {
  final Product product;
  const Post({super.key, required this.product});

  @override
  State<StatefulWidget> createState() => _PostState();
}

class _PostState extends State<Post> with SingleTickerProviderStateMixin {
  late List<MediaItem> _mediaItems;
  final PageController _pageController = PageController();
  bool isExpanded = false;

  // Flip Animation Variables
  late AnimationController _flipController;
  late Animation<double> _flipAnimation;
  bool _isFlipped = false;

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
              itemBuilder: (context, index) => _buildMediaContent(_mediaItems[index]),
            ),
          ),

          Positioned(
            top: 15, left: 15,
            child: _buildBlurTag(_formatPrice(product.productPrice)),
          ),

          // Sidebar Action Bar
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
                        color: Colors.white.withOpacity(0.4),
                        border: Border.all(color: Colors.white.withOpacity(0.5), width: 1.5),
                        borderRadius: BorderRadius.circular(50),
                      ),
                      child: SingleChildScrollView(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            _buildAction(HeroiconsSolid.chatBubbleOvalLeftEllipsis, "Chat", onTap: () {
                              if (seller != null) {
                                final partner = ChatPartner(userId: seller.userId, fullName: seller.fullName, avatarUrl: seller.avatarUrl);
                                smoothPush(context, ChatScreen(conversationId: "", partnerUser: partner));
                              }
                            }),
                            const SizedBox(height: 15),
                            _buildAction(HeroiconsSolid.phone, "Call", onTap: () => _makeCall(seller?.phoneNumber.toString())),
                            const SizedBox(height: 15),
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

          Positioned(
            bottom: 0, left: 0, right: 0,
            child: Container(
              padding: const EdgeInsets.fromLTRB(20, 60, 20, 25),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.bottomCenter,
                  end: Alignment.topCenter,
                  colors: [Colors.black.withOpacity(0.9), Colors.black.withOpacity(0.6), Colors.transparent],
                  stops: const [0.0, 0.6, 1.0],
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    product.productName,
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18, fontFamily: 'QuickSand', shadows: [Shadow(offset: Offset(0, 1), blurRadius: 3.0, color: Colors.black)]),
                  ),
                  const SizedBox(height: 6),
                  _buildConditionTag(product.productCondition),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMoreAction() {
    return PopupMenuButton<String>(
      offset: const Offset(-85, 0),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      icon: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: Colors.white.withOpacity(0.3), shape: BoxShape.circle),
            child: const Icon(HeroiconsSolid.ellipsisHorizontal, color: Colors.white, size: 26),
          ),
          const SizedBox(height: 6),
          const Text("More", style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600, fontFamily: 'QuickSand')),
        ],
      ),
      onSelected: (value) {
        if (value == 'save') {
          // Logic Save của bạn ở đây
        }
      },
      itemBuilder: (context) => [
        const PopupMenuItem(
          value: 'save',
          child: Row(children: [Icon(HeroiconsOutline.bookmark, color: Colors.black87), SizedBox(width: 10), Text("Lưu tin", style: TextStyle(fontFamily: 'QuickSand'))]),
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
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), borderRadius: BorderRadius.circular(8), border: Border.all(color: Colors.white.withOpacity(0.3))),
      child: Text(condition.isNotEmpty ? condition : "Mới/Cũ", style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600, fontFamily: 'QuickSand')),
    );
  }

  Widget _buildBackSide() {
    return Container(
      width: double.infinity, height: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(color: const Color(0xFFF0F1F5), borderRadius: BorderRadius.circular(30)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text("Chi tiết sản phẩm", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.black87, fontFamily: 'QuickSand')),
          const Divider(height: 30),
          Expanded(child: SingleChildScrollView(physics: const BouncingScrollPhysics(), child: Text(widget.product.productDescription, style: const TextStyle(fontSize: 15, height: 1.6, color: Colors.black87, fontFamily: 'QuickSand')))),
          const SizedBox(height: 10),
          const Center(child: Text("Nhấn 2 lần để quay lại", style: TextStyle(color: Colors.grey, fontSize: 12, fontFamily: 'QuickSand', fontStyle: FontStyle.italic))),
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
          decoration: BoxDecoration(color: Colors.black.withOpacity(0.3), borderRadius: BorderRadius.circular(20), border: Border.all(color: Colors.white.withOpacity(0.2))),
          child: Text(text, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13, fontFamily: 'QuickSand')),
        ),
      ),
    );
  }

  Widget _buildMediaContent(MediaItem item) {
    if (item.type == MediaType.image) return CachedNetworkImage(imageUrl: item.url, fit: BoxFit.cover, width: double.infinity, placeholder: (context, url) => Container(color: Colors.grey[200]));
    return VideoPlayerWidget(videoUrl: item.url);
  }

  Widget _buildAction(IconData icon, String label, {VoidCallback? onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: Colors.white.withOpacity(0.3), shape: BoxShape.circle), child: Icon(icon, color: Colors.white, size: 26)),
          const SizedBox(height: 6),
          Text(label, style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600, fontFamily: 'QuickSand')),
        ],
      ),
    );
  }
}