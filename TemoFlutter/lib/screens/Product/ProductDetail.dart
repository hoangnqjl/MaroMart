import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:heroicons_flutter/heroicons_flutter.dart';
import 'package:maromart/Colors/AppColors.dart';
import 'package:maromart/components/VideoPlayerWidget.dart';
import 'package:maromart/models/Media/MediaItem.dart';
import 'package:maromart/models/Product/Product.dart';
import 'package:maromart/services/product_service.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../models/User/ChatPartner.dart';
import '../Message/ChatScreen.dart';
import 'package:maromart/app_router.dart';
import 'package:maromart/services/user_service.dart';
import 'package:maromart/components/ModernLoader.dart';

class ProductDetail extends StatefulWidget {
  final String productId;

  const ProductDetail({super.key, required this.productId});

  @override
  State<StatefulWidget> createState() => ProductDetailState();
}

class ProductDetailState extends State<ProductDetail> {
  final ProductService _productService = ProductService();
  Product? _product;
  bool _isLoading = true;
  bool isDescription = true;
  int currentPage = 0;
  late PageController _pageController;

  List<MediaItem> _mediaItems = [];

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
    _fetchProductDetail();
  }

  Future<void> _fetchProductDetail() async {
    try {
      final product = await _productService.getProductById(widget.productId);
      if (mounted) {
        setState(() {
          _product = product;
          _mediaItems = _parseProductMedia(product.productMedia);
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Không thể tải chi tiết sản phẩm: ${e.toString()}')),
        );
      }
      print('Lỗi tải chi tiết sản phẩm: $e');
    }
  }

  List<MediaItem> _parseProductMedia(List<String> rawMedia) {
    return rawMedia.map((mediaString) {
      final parts = mediaString.split(':');
      final type = parts.first.toLowerCase();
      final url = parts.length > 1 ? parts.sublist(1).join(':').trim() : mediaString.trim();

      if (type == 'video') {
        return MediaItem(type: MediaType.video, url: url);
      } else {
        return MediaItem(type: MediaType.image, url: url);
      }
    }).toList();
  }

  String _formatPrice(int price) {
    final formatter = NumberFormat('#,###', 'vi_VN');
    return '${formatter.format(price)} VND';
  }

  // --- DIALOG CALL ---
  void _showCallDialog() {
    final phoneNumber = _product?.userInfo?.phoneNumber.toString() ?? '';
    final sellerName = _product?.userInfo?.fullName ?? 'Người bán';

    if (phoneNumber.isEmpty || phoneNumber == '0') {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Người bán chưa cập nhật số điện thoại')),
      );
      return;
    }

    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 60, height: 60,
                decoration: BoxDecoration(color: Colors.green.shade50, shape: BoxShape.circle),
                child: Icon(HeroiconsSolid.phone, size: 30, color: Colors.green.shade600),
              ),
              const SizedBox(height: 16),
              Text(sellerName, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700, fontFamily: 'QuickSand'), textAlign: TextAlign.center),
              const SizedBox(height: 8),
              Text(phoneNumber, style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600, color: Colors.blue.shade700, letterSpacing: 1)),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () { Navigator.pop(context); _makePhoneCall(phoneNumber); },
                  icon: const Icon(HeroiconsSolid.phone, size: 20),
                  label: const Text('Call Now', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.green, foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(vertical: 14), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30))),
                ),
              ),
              const SizedBox(height: 12),
              TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel', style: TextStyle(fontSize: 14, color: Colors.grey))),
            ],
          ),
        ),
      ),
    );
  }

  void _makePhoneCall(String phoneNumber) async {
    final Uri phoneUri = Uri(scheme: 'tel', path: phoneNumber);
    if (await canLaunchUrl(phoneUri)) {
      await launchUrl(phoneUri);
    } else {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Không thể thực hiện cuộc gọi')));
    }
  }

  // --- DIALOG LOCATION ---
  void _showLocationDialog() {
    final address = _product?.productAddress;
    if (address == null || (address.province.isEmpty && address.commute.isEmpty && address.detail.isEmpty)) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Sản phẩm không có thông tin địa chỉ')));
      return;
    }

    final fullAddress = address.fullAddress;

    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 60, height: 60,
                decoration: BoxDecoration(color: Colors.red.shade50, shape: BoxShape.circle),
                child: Icon(HeroiconsSolid.mapPin, size: 30, color: Colors.red.shade600),
              ),
              const SizedBox(height: 16),
              const Text("Product Location", style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, fontFamily: 'QuickSand'), textAlign: TextAlign.center),
              const SizedBox(height: 8),
              Text(fullAddress, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: Colors.grey.shade700), textAlign: TextAlign.center),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () { Navigator.pop(context); _openMap(fullAddress); },
                  icon: const Icon(Icons.map, size: 20),
                  label: const Text('Open Google Maps', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(vertical: 14), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30))),
                ),
              ),
              const SizedBox(height: 12),
              TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel', style: TextStyle(fontSize: 14, color: Colors.grey))),
            ],
          ),
        ),
      ),
    );
  }

  void _openMap(String address) async {
    final query = Uri.encodeComponent(address);
    final googleMapUrl = Uri.parse("https://www.google.com/maps/search/?api=1&query=$query");

    if (await canLaunchUrl(googleMapUrl)) {
      await launchUrl(googleMapUrl, mode: LaunchMode.externalApplication);
    } else {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Không thể mở Google Maps')));
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) return Scaffold(body: Center(child: ModernLoader()));
    if (_product == null) return Scaffold(appBar: AppBar(title: const Text('Lỗi')), body: const Center(child: Text('Không tìm thấy thông tin sản phẩm.')));

    final product = _product!;

    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // MEDIA SLIDER
                SizedBox(
                  height: MediaQuery.of(context).size.height * 0.66,
                  child: Stack(
                    children: [
                      PageView.builder(
                        controller: _pageController,
                        onPageChanged: (index) => setState(() => currentPage = index),
                        itemCount: _mediaItems.length,
                        itemBuilder: (context, index) => _buildMediaItem(_mediaItems[index]),
                      ),
                      Positioned(
                        bottom: 16, left: 0, right: 0,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: List.generate(
                            _mediaItems.length,
                                (index) => Container(
                              margin: const EdgeInsets.symmetric(horizontal: 4),
                              width: currentPage == index ? 24 : 8, height: 8,
                              decoration: BoxDecoration(color: currentPage == index ? Colors.white : Colors.white.withOpacity(0.5), borderRadius: BorderRadius.circular(4)),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(product.productCategory.toUpperCase(), style: const TextStyle(fontWeight: FontWeight.w100, fontSize: 8, color: Colors.black54)),
                              const SizedBox(height: 2),
                              Text(product.productName, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12, color: Colors.black)),
                            ],
                          ),
                          Text(_formatPrice(product.productPrice), style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12, color: Colors.black)),
                        ],
                      ),
                      const SizedBox(height: 14),

                      Row(
                        children: [
                          Expanded(
                            child: _buildTabToggle(),
                          ),

                          const SizedBox(width: 10),

                          GestureDetector(
                            onTap: _showLocationDialog,
                            child: Container(
                              height: 42,
                              padding: const EdgeInsets.symmetric(horizontal: 16),
                              decoration: BoxDecoration(
                                color: AppColors.E2Color,
                                borderRadius: BorderRadius.circular(30),
                              ),
                              child: Row(
                                children: const [
                                  Icon(HeroiconsOutline.mapPin, size: 18, color: Colors.black),
                                  SizedBox(width: 6),
                                  Text(
                                    "Location",
                                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.black),
                                  )
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 16),

                      // CONTENT
                      AnimatedSwitcher(
                        duration: const Duration(milliseconds: 300),
                        switchInCurve: Curves.easeIn,
                        switchOutCurve: Curves.easeOut,
                        child: isDescription ? _buildDescriptionContent(product.productDescription) : _buildViewDetailContent(product.productAttribute, product),
                      ),

                      // BOTTOM ACTIONS (Chat + Call)
                      _buildActionButtons(),
                      const SizedBox(height: 20),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // BACK BUTTON
          Positioned(
            top: 0, left: 0, right: 0,
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(decoration: BoxDecoration(color: Colors.black.withOpacity(0.3), shape: BoxShape.circle), child: IconButton(icon: const Icon(HeroiconsOutline.arrowLeft, color: Colors.white, size: 20), onPressed: () => Navigator.pop(context))),
                    Container(decoration: BoxDecoration(color: Colors.black.withOpacity(0.3), shape: BoxShape.circle), child: IconButton(icon: const Icon(HeroiconsSolid.heart, color: Colors.red, size: 20), onPressed: () {})),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTabToggle() {
    return LayoutBuilder(builder: (context, constraints) {
      final double totalWidth = constraints.maxWidth;
      final double tabWidth = (totalWidth - 4) / 2;
      return Container(
        height: 42,
        width: double.infinity,
        padding: const EdgeInsets.all(2),
        decoration: BoxDecoration(borderRadius: BorderRadius.circular(30), color: AppColors.E2Color),
        child: Stack(
          children: [
            AnimatedAlign(
              duration: const Duration(milliseconds: 300), curve: Curves.easeInOut,
              alignment: isDescription ? Alignment.centerLeft : Alignment.centerRight,
              child: Container(width: tabWidth, height: 38, decoration: BoxDecoration(color: Colors.black, borderRadius: BorderRadius.circular(30))),
            ),
            Row(children: [
              _buildTabItem(title: 'Description', isSelected: isDescription, onTap: () => setState(() => isDescription = true)),
              _buildTabItem(title: 'View Detail', isSelected: !isDescription, onTap: () => setState(() => isDescription = false))
            ]),
          ],
        ),
      );
    });
  }

  Widget _buildTabItem({required String title, required bool isSelected, required VoidCallback onTap}) {
    return Expanded(child: GestureDetector(onTap: onTap, behavior: HitTestBehavior.translucent, child: Container(alignment: Alignment.center, child: Text(title, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: isSelected ? Colors.white : Colors.black)))));
  }

  Widget _buildActionButtons() {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(top: 16),
      child: Row(
        children: [
          // CHAT BUTTON
          Expanded(
            child: GestureDetector(
              onTap: () {
                if (_product?.userInfo != null) {
                  final userInfo = _product!.userInfo!;
                  final partner = ChatPartner(userId: userInfo.userId, fullName: userInfo.fullName, avatarUrl: userInfo.avatarUrl, email: userInfo.email);
                  smoothPush(context, ChatScreen(conversationId: "", partnerUser: partner));
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Không tìm thấy thông tin người bán')));
                }
              },
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.black),
                  borderRadius: BorderRadius.circular(30),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: const [
                    Icon(HeroiconsOutline.chatBubbleOvalLeft, size: 18, color: Colors.black),
                    SizedBox(width: 8),
                    Text('Chat', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600))
                  ],
                ),
              ),
            ),
          ),

          const SizedBox(width: 12),

          // CALL BUTTON
          Expanded(
            child: GestureDetector(
              onTap: () => _showCallDialog(),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(color: Colors.black, borderRadius: BorderRadius.circular(30)),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: const [
                    Icon(HeroiconsSolid.phone, size: 18, color: Colors.white),
                    SizedBox(width: 8),
                    Text('Call now', style: TextStyle(fontSize: 14, color: Colors.white, fontWeight: FontWeight.w600))
                  ],
                ),
              ),
            ),
          )
        ],
      ),
    );
  }

  Widget _buildMediaItem(MediaItem item) {
    if (item.type == MediaType.image) {
      return Image.network(item.url, fit: BoxFit.cover, width: double.infinity, height: double.infinity,
          loadingBuilder: (context, child, loadingProgress) {
            if (loadingProgress == null) return child;
            return const Center(child: ModernLoader(size: 30));
          },
          errorBuilder: (context, error, stackTrace) => Container(color: Colors.grey[300], child: const Center(child: Icon(Icons.broken_image, color: Colors.grey, size: 60))));
    } else {
      return VideoPlayerWidget(videoUrl: item.url);
    }
  }

  Widget _buildDescriptionContent(String description) {
    return Container(key: const ValueKey('description'), width: double.infinity, child: Text(description, style: const TextStyle(fontSize: 12, color: Colors.black54)));
  }

  Widget _buildViewDetailContent(dynamic attributesInput, Product product) {
    final List<Map<String, String>> displayList = [
      {'label': 'Thương hiệu', 'value': product.productBrand},
      {'label': 'Tình trạng', 'value': product.productCondition},
      {'label': 'Xuất xứ', 'value': product.productOrigin},
      {'label': 'Bảo hành', 'value': product.productWP},
    ];
    if (attributesInput != null) {
      Map<String, dynamic> attrMap = {};
      try {
        if (attributesInput is String) attrMap = jsonDecode(attributesInput);
        else if (attributesInput is Map) attrMap = Map<String, dynamic>.from(attributesInput);
      } catch (e) { print("Lỗi parse attribute: $e"); }
      attrMap.forEach((key, value) { if (value.toString().isNotEmpty) displayList.add({'label': key, 'value': value.toString()}); });
    }

    return Container(
        key: const ValueKey('detail'),
        padding: const EdgeInsets.all(16),
        width: double.infinity,
        decoration: BoxDecoration(color: Colors.grey[100], borderRadius: BorderRadius.circular(12)),
        child: Column(
          children: displayList.map((detail) => Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(detail['label']!, style: const TextStyle(color: Colors.black54, fontSize: 10, fontWeight: FontWeight.w200)),
                Text(detail['value']!, style: const TextStyle(color: Colors.black54, fontSize: 10, fontWeight: FontWeight.w500))
              ],
            ),
          )).toList(),
        )
    );
  }
}