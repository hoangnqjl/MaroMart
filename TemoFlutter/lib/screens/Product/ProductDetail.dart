import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:heroicons_flutter/heroicons_flutter.dart';
import 'package:temo/Colors/AppColors.dart';
import 'package:temo/components/VideoPlayerWidget.dart';
import 'package:temo/models/Media/MediaItem.dart';
import 'package:temo/models/Product/Product.dart';
import 'package:temo/services/product_service.dart';
import 'package:temo/services/location_service.dart';
import 'package:geolocator/geolocator.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../app_router.dart';
import '../../models/User/ChatPartner.dart';
import '../Message/ChatScreen.dart';
import 'package:temo/components/ModernLoader.dart';
import 'package:temo/components/Skeletons/ProductDetailSkeleton.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:ui';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:temo/utils/string_utils.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

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
  int currentPage = 0;
  late PageController _pageController;

  List<MediaItem> _mediaItems = [];
  List<Product> _relatedProducts = [];
  bool _isLoadingRelated = false;
  String? _distanceText;
  Position? _currentPosition;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
    _fetchProductDetail();
  }

  Future<void> _calculateDistance(Product product) async {
    try {
      // 1. Kiểm tra quyền truy cập vị trí trước khi lấy vị trí
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) return;
      }
      
      if (permission == LocationPermission.deniedForever) return;

      // 2. Lấy vị trí hiện tại của người dùng
      final pos = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.low // Tiết kiệm pin và nhanh hơn
      );
      
      if (product.latitude != null && product.longitude != null) {
        double distanceInMeters = Geolocator.distanceBetween(
          pos.latitude, pos.longitude, 
          product.latitude!, product.longitude!
        );

        if (mounted) {
          setState(() {
            _currentPosition = pos;
            if (distanceInMeters < 1000) {
              _distanceText = "Rất gần bạn";
            } else if (distanceInMeters < 10000) {
              _distanceText = "Gần bạn";
            } else {
              _distanceText = "~${(distanceInMeters / 1000).toStringAsFixed(1)} km";
            }
          });
        }
      }
    } catch (e) {
      debugPrint("Error calculating distance: $e");
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
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
        _calculateDistance(product);
        _fetchRelatedProducts(product.categoryId);
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not load product details: ${e.toString()}')),
        );
      }
    }
  }

  Future<void> _fetchRelatedProducts(String categoryId) async {
    if (categoryId.isEmpty) return;
    setState(() => _isLoadingRelated = true);
    try {
      final related = await _productService.getProductsByCategory(categoryId: categoryId);
      if (mounted) {
        setState(() {
          _relatedProducts = related.where((p) => p.productId != widget.productId).take(5).toList();
          _isLoadingRelated = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoadingRelated = false);
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

  @override
  Widget build(BuildContext context) {
    if (_isLoading) return const ProductDetailSkeleton();
    if (_product == null) return Scaffold(appBar: AppBar(title: const Text('Error')), body: const Center(child: Text('Product not found.')));

    final product = _product!;

    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          Positioned.fill(
            child: SingleChildScrollView(
              padding: const EdgeInsets.only(bottom: 120),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildGallery(),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 20),
                        _buildProductHeader(product),
                        const SizedBox(height: 16),
                        _buildTagButtons(product),
                        const SizedBox(height: 24),
                        _buildSectionTitle("Description"),
                        const SizedBox(height: 8),
                        Text(
                          product.productDescription,
                          style: GoogleFonts.roboto(fontSize: 14, color: const Color(0xFF3F3F46).withOpacity(0.62), height: 1.5),
                        ),
                        const SizedBox(height: 24),
                        _buildSectionTitle("Product details"),
                        const SizedBox(height: 12),
                        _buildTechSpecs(product),
                        const SizedBox(height: 24),
                        
                        // MAP SECTION (Restored to original position)
                        if (product.latitude != null && product.longitude != null) ...[
                          _buildSectionTitle("Location"),
                          const SizedBox(height: 12),
                          _buildMapSection(product),
                          const SizedBox(height: 24),
                        ],

                        if (_relatedProducts.isNotEmpty) ...[
                          ShaderMask(
                            shaderCallback: (bounds) => const LinearGradient(
                              colors: [Color(0xFFFFB86A), Color(0xFFFB7C7F)],
                            ).createShader(Rect.fromLTWH(0, 0, bounds.width, bounds.height)),
                            child: Text(
                              "Related products",
                              style: GoogleFonts.roboto(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: Colors.white, // Required for ShaderMask to work correctly
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),
                          _buildRelatedProducts(),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          // TOP BAR
          _buildTopBar(),

          // BOTTOM BAR
          _buildFloatingActionBar(),
        ],
      ),
    );
  }

  Widget _buildTopBar() {
    return Positioned(
      top: 0, left: 0, right: 0,
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
          child: Stack(
            alignment: Alignment.center,
            children: [
              Align(
                alignment: Alignment.centerLeft,
                child: _buildRoundIconButton(HeroiconsSolid.chevronLeft, () => Navigator.pop(context)),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(30),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Text(
                  "Product View",
                  style: GoogleFonts.roboto(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF3F3F46),
                  ),
                ),
              ),
              Align(
                alignment: Alignment.centerRight,
                child: _buildRoundIconButton(HeroiconsSolid.ellipsisVertical, () {}),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRoundIconButton(IconData icon, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 40,
        height: 40,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: Colors.white,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.12),
              blurRadius: 12,
              offset: const Offset(0, 4),
            )
          ],
        ),
        child: Icon(icon, color: const Color(0xFF3F3F46), size: 24),
      ),
    );
  }

  Widget _buildGallery() {
    return Container(
      height: MediaQuery.of(context).size.height * 0.55,
      margin: const EdgeInsets.fromLTRB(8, 100, 8, 0),
      child: Stack(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(40),
            child: PageView.builder(
              controller: _pageController,
              onPageChanged: (index) => setState(() => currentPage = index),
              itemCount: _mediaItems.length,
              itemBuilder: (context, index) => _buildMediaItem(_mediaItems[index]),
            ),
          ),
          Positioned(
            bottom: 20, left: 0, right: 0,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(
                _mediaItems.length,
                (index) => Container(
                  margin: const EdgeInsets.symmetric(horizontal: 3),
                  width: currentPage == index ? 8 : 6, height: currentPage == index ? 8 : 6,
                  decoration: BoxDecoration(color: currentPage == index ? Colors.white : Colors.white.withOpacity(0.5), shape: BoxShape.circle),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProductHeader(Product product) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "đ ${product.formattedPrice}",
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Color(0xFFFFB86A), fontFamily: 'QuickSand'),
              ),
              const SizedBox(height: 4),
              Text(
                product.productName,
                style: GoogleFonts.inter(fontSize: 22, fontWeight: FontWeight.bold, color: const Color(0xFF3F3F46).withOpacity(0.8)),
              ),
            ],
          ),
        ),
        Container(
          padding: const EdgeInsets.fromLTRB(4, 4, 10, 4),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4))],
          ),
          child: Row(
            children: [
              ClipOval(child: Image.network(product.userInfo?.avatarUrl ?? '', width: 30, height: 30, fit: BoxFit.cover, errorBuilder: (_, __, ___) => const Icon(Icons.person, size: 30))),
              const SizedBox(width: 8),
              Text("4.5", style: GoogleFonts.roboto(fontSize: 16, fontWeight: FontWeight.w600, color: const Color(0xFF3F3F46).withOpacity(0.8))),
              const SizedBox(width: 4),
              const Icon(Icons.star_rounded, color: Color(0xFFFFB86A), size: 16),
            ],
          ),
        ),
        if (product.marketPrice != null && product.marketPrice! > product.productPrice)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: const Color(0xFFE8F5E9),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              "Rẻ hơn ${(product.marketPrice! - product.productPrice).toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]}.')}đ",
              style: GoogleFonts.roboto(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: const Color(0xFF2E7D32),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildTagButtons(Product product) {
    final List<String> tags = [];
    if (product.productCondition.isNotEmpty) tags.add(product.productCondition);
    if (_distanceText != null) tags.add(_distanceText!);
    
    if (tags.isEmpty) return const SizedBox.shrink();

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: tags.map((tag) => Padding(
          padding: const EdgeInsets.only(right: 10),
          child: Material(
            color: const Color(0xFFEAEAEA),
            borderRadius: BorderRadius.circular(20),
            child: Container(
              height: 32,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              alignment: Alignment.center,
              child: Text(
                tag,
                style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.w500, color: const Color(0xFF3F3F46)),
              ),
            ),
          ),
        )).toList(),
      ),
    );
  }

  Widget _buildSectionTitle(String title, {Color? color}) {
    final defaultColor = const Color(0xFF3F3F46).withOpacity(0.8);
    return Text(title, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: color ?? defaultColor, fontFamily: 'QuickSand'));
  }

  Widget _buildTechSpecs(Product product) {
    Map<String, String> specs = {};
    if (product.productAttribute != null) {
      try {
        Map<String, dynamic> attrMap = {};
        if (product.productAttribute is String) attrMap = jsonDecode(product.productAttribute);
        else if (product.productAttribute is Map) attrMap = Map<String, dynamic>.from(product.productAttribute);
        
        attrMap.forEach((key, value) {
          if (value != null && value.toString().isNotEmpty) {
            specs[key] = value.toString();
          }
        });
      } catch (e) {}
    }

    if (specs.isEmpty) {
      specs = {'Ram': '12 GB', 'CPU': 'Intel core i7 12800H', 'Storage': '16 GB', 'OS': 'Android 17 One UI 9.0', 'Battery': '1200 mAh'};
    }

    return Column(
      children: specs.entries.map((entry) => Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              entry.key[0].toUpperCase() + entry.key.substring(1),
              style: GoogleFonts.roboto(fontSize: 14, color: const Color(0xFF3F3F46).withOpacity(0.7), fontWeight: FontWeight.w500),
            ),
            Text(
              entry.value,
              style: GoogleFonts.roboto(fontSize: 14, color: const Color(0xFF3F3F46).withOpacity(0.62), fontWeight: FontWeight.normal),
            ),
          ],
        ),
      )).toList(),
    );
  }

  Widget _buildMapSection(Product product) {
    final LatLng productPos = LatLng(product.latitude!, product.longitude!);
    final String? avatarUrl = product.userInfo?.avatarUrl;

    // Determine initial center: if we have current position, center between them roughly
    LatLng center = productPos;
    if (_currentPosition != null) {
      center = LatLng(
        (productPos.latitude + _currentPosition!.latitude) / 2,
        (productPos.longitude + _currentPosition!.longitude) / 2,
      );
    }

    return Container(
      height: 250, // Slightly taller to fit two points
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.grey[200],
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: FlutterMap(
          options: MapOptions(
            initialCenter: center,
            initialZoom: _currentPosition != null ? 12.0 : 14.5, 
            interactionOptions: const InteractionOptions(flags: InteractiveFlag.all), 
          ),
          children: [
            TileLayer(
              urlTemplate: 'https://{s}.basemaps.cartocdn.com/rastertiles/voyager_labels_under/{z}/{x}/{y}{r}.png',
              subdomains: const ['a', 'b', 'c', 'd'],
              userAgentPackageName: 'com.temo.app',
              retinaMode: MediaQuery.of(context).devicePixelRatio > 1.0,
            ),
            MarkerLayer(
              markers: [
                // SELLER MARKER
                Marker(
                  point: productPos,
                  width: 60,
                  height: 60,
                  child: Stack(
                    alignment: Alignment.bottomCenter,
                    children: [
                      Positioned(
                        bottom: 0,
                        child: Container(
                          width: 12,
                          height: 12,
                          transform: Matrix4.rotationZ(0.785398),
                          decoration: const BoxDecoration(
                            color: Colors.white,
                            boxShadow: [
                              BoxShadow(color: Colors.black26, blurRadius: 4, offset: Offset(2, 2))
                            ],
                          ),
                        ),
                      ),
                      Positioned(
                        top: 0,
                        child: Container(
                          width: 50,
                          height: 50,
                          padding: const EdgeInsets.all(3),
                          decoration: const BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(color: Colors.black26, blurRadius: 8, offset: Offset(0, 4))
                            ],
                          ),
                          child: ClipOval(
                            child: avatarUrl != null && avatarUrl.isNotEmpty
                                ? CachedNetworkImage(
                                    imageUrl: avatarUrl,
                                    fit: BoxFit.cover,
                                    placeholder: (context, url) => Container(color: Colors.grey[300]),
                                    errorWidget: (context, url, e) => Image.asset('assets/images/logo.png'),
                                  )
                                : Image.asset('assets/images/logo.png', fit: BoxFit.cover),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                
                // CURRENT USER MARKER (Buyer)
                if (_currentPosition != null)
                  Marker(
                    point: LatLng(_currentPosition!.latitude, _currentPosition!.longitude),
                    width: 40,
                    height: 40,
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.blue.withOpacity(0.2),
                        shape: BoxShape.circle,
                      ),
                      child: Center(
                        child: Container(
                          width: 14,
                          height: 14,
                          decoration: BoxDecoration(
                            color: Colors.blue,
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white, width: 2),
                            boxShadow: [
                              BoxShadow(color: Colors.blue.withOpacity(0.4), blurRadius: 10, spreadRadius: 5)
                            ],
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
    );
  }

  Widget _buildRelatedProducts() {
    if (_isLoadingRelated) return const SizedBox(height: 200, child: Center(child: ModernLoader(size: 30)));
    return SizedBox(
      height: 335,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: _relatedProducts.length,
        itemBuilder: (context, index) => _buildRelatedProductCard(_relatedProducts[index]),
      ),
    );
  }

  Widget _buildRelatedProductCard(Product product) {
    String imageUrl = product.productMedia.isNotEmpty ? product.productMedia[0] : '';
    if (imageUrl.startsWith('image:')) imageUrl = imageUrl.substring(6).trim();

    final formattedPrice = NumberFormat.currency(
        locale: 'vi_VN',
        symbol: 'đ',
        decimalDigits: 0
    ).format(product.productPrice);

    return GestureDetector(
      onTap: () => smoothPush(context, ProductDetail(productId: product.productId)),
      child: Container(
        width: 245,
        height: 327,
        margin: const EdgeInsets.only(right: 12), // Reduced slightly
        child: ClipRRect(
          borderRadius: BorderRadius.circular(26),
          child: Stack(
            fit: StackFit.expand,
            children: [
              CachedNetworkImage(
                imageUrl: imageUrl,
                fit: BoxFit.cover,
                placeholder: (context, url) => Container(color: Colors.grey[100]),
                errorWidget: (context, url, error) => Container(color: Colors.grey[200], child: const Icon(Icons.image)),
              ),
              Container(color: Colors.black.withOpacity(0.3)),
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          product.productName,
                          style: const TextStyle(fontFamily: 'Quicksand', color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          formattedPrice,
                          style: const TextStyle(fontFamily: 'Quicksand', color: Colors.white, fontSize: 14, fontWeight: FontWeight.w700),
                        ),
                      ],
                    ),
                    Row(
                      children: [
                        Expanded(
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(20),
                            child: BackdropFilter(
                              filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                decoration: BoxDecoration(color: Colors.white.withOpacity(0.4), borderRadius: BorderRadius.circular(20)),
                                child: Row(
                                  children: [
                                    const Icon(HeroiconsOutline.mapPin, color: Colors.white, size: 14),
                                    const SizedBox(width: 4),
                                    Expanded(
                                      child: Text(
                                        StringUtils.simplifyAddress(
                                          product.productAddress?.province ?? 'Location unknown',
                                        ),
                                        style: const TextStyle(fontFamily: 'Quicksand', color: Colors.white, fontSize: 12, fontWeight: FontWeight.w700),
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
                        const SizedBox(width: 8),
                        ClipOval(
                          child: BackdropFilter(
                            filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
                            child: Container(
                              width: 36, height: 36,
                              decoration: BoxDecoration(color: Colors.white.withOpacity(0.4), shape: BoxShape.circle),
                              alignment: Alignment.center,
                              child: const Icon(HeroiconsOutline.chatBubbleOvalLeft, color: Colors.white, size: 18),
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

  Widget _buildFloatingActionBar() {
    return Positioned(
      bottom: 25, left: 0, right: 0,
      child: Center(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(40),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.12),
                blurRadius: 25,
                offset: const Offset(0, 8),
              )
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildActionItem(HeroiconsOutline.phone, "Call", _showCallDialog),
              const SizedBox(width: 8),
              _buildActionItem(HeroiconsOutline.chatBubbleOvalLeft, "Message", () {
                if (_product?.userInfo != null) {
                  final userInfo = _product!.userInfo!;
                  final partner = ChatPartner(userId: userInfo.userId, fullName: userInfo.fullName, avatarUrl: userInfo.avatarUrl, email: userInfo.email);
                  smoothPush(context, ChatScreen(conversationId: "", partnerUser: partner));
                }
              }),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildActionItem(IconData icon, String label, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: SizedBox(
        width: 80, // Đảm bảo không gian căn giữa cho cả Icon và Label
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Icon(icon, color: AppColors.primaryLight, size: 24),
            const SizedBox(height: 4),
            Text(
              label,
              style: GoogleFonts.roboto(
                color: AppColors.primaryLight,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showCallDialog() {
    final phoneNumber = _product?.userInfo?.phoneNumber.toString() ?? '';
    final sellerName = _product?.userInfo?.fullName ?? 'Seller';
    if (phoneNumber.isEmpty || phoneNumber == '0') return;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text("Call $sellerName"),
        content: Text("Phone: $phoneNumber"),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancel")),
          TextButton(onPressed: () { Navigator.pop(context); _makePhoneCall(phoneNumber); }, child: const Text("Call")),
        ],
      ),
    );
  }

  void _makePhoneCall(String phoneNumber) async {
    final Uri phoneUri = Uri(scheme: 'tel', path: phoneNumber);
    if (await canLaunchUrl(phoneUri)) await launchUrl(phoneUri);
  }

  Widget _buildMediaItem(MediaItem item) {
    if (item.type == MediaType.image) {
      return Image.network(item.url, fit: BoxFit.cover, width: double.infinity, height: double.infinity,
          loadingBuilder: (context, child, loadingProgress) => loadingProgress == null ? child : const Center(child: ModernLoader(size: 30)),
          errorBuilder: (context, error, stackTrace) => Container(color: Colors.grey[300], child: const Center(child: Icon(Icons.broken_image, color: Colors.grey, size: 60))));
    } else {
      return VideoPlayerWidget(videoUrl: item.url);
    }
  }
}