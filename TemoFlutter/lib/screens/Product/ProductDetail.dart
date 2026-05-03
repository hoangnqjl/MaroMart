import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';
import 'package:heroicons_flutter/heroicons_flutter.dart';
import 'package:temo/Colors/AppColors.dart';
import 'package:temo/screens/Common/BugReportScreen.dart';
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
import '../../services/review_service.dart';
import '../Message/ChatScreen.dart';
import 'package:temo/components/ModernLoader.dart';
import 'package:temo/components/Skeletons/ProductDetailSkeleton.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:ui';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:temo/utils/string_utils.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:temo/services/order_service.dart';
import 'package:temo/services/chat_service.dart';
import 'package:temo/services/api_service.dart';
import 'package:temo/utils/storage.dart';
import 'package:temo/models/User/User.dart' as model_user;
import 'package:temo/utils/UIHelper.dart';
import 'package:temo/utils/ui_helpers.dart';
import 'package:temo/services/user_service.dart';
import 'package:temo/utils/constants.dart';
import 'package:temo/screens/Setting/AppImprovementScreen.dart';
import 'ProductManager.dart';

class ProductDetail extends StatefulWidget {
  final String productId;

  const ProductDetail({super.key, required this.productId});

  @override
  State<StatefulWidget> createState() => ProductDetailState();
}

class ProductDetailState extends State<ProductDetail> {
  final ProductService _productService = ProductService();
  final LocationService _locationService = LocationService();
  final ReviewService _reviewService = ReviewService();
  final model_user.User? currentUser = StorageHelper.getUser();

  Product? _product;
  bool _isLoading = true;
  double _sellerRating = 0.0;
  int _totalReviews = 0;
  int currentPage = 0;
  late PageController _pageController;

  List<MediaItem> _mediaItems = [];
  List<Product> _relatedProducts = [];
  bool _isLoadingRelated = false;
  String? _distanceText;
  Position? _currentPosition;
  String? _currentUserId;
  final MapController _mapController = MapController();
  final ScrollController _scrollController = ScrollController();
  double _headerOpacity = 1.0;
  
  double? _marketPriceMin;
  double? _marketPriceMax;
  bool _isLoadingMarketPrice = false;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
    _currentUserId = StorageHelper.getUserId();
    _scrollController.addListener(_onScroll);
    _fetchProductDetail();
    _productService.fetchSavedProductsIfNeeded();
  }

  void _onScroll() {
    double offset = _scrollController.offset;
    // Invert logic: 1.0 at top, 0.0 after scrolling 120px
    double opacity = (1.0 - (offset / 120)).clamp(0.0, 1.0);
    if (opacity != _headerOpacity) {
      setState(() => _headerOpacity = opacity);
    }
  }


  Future<void> _toggleSaveProduct() async {
    try {
      await _productService.toggleSave(widget.productId);
    } catch (e) {
      print('Lỗi lưu/ẩn sản phẩm: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Lỗi: ${e.toString().replaceAll("Exception: ", "")}')),
      );
    }
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
              _distanceText = "~${NumberFormat('#,###.#').format(distanceInMeters / 1000)} km";
            }
          });
        }
      }
    } catch (e) {
      debugPrint("Lỗi tính khoảng cách: $e");
    }
  }

  Future<List<LatLng>> _getRoutePoints(LatLng start, LatLng end) async {
    try {
      final String url = 'https://router.project-osrm.org/route/v1/driving/'
          '${start.longitude},${start.latitude};${end.longitude},${end.latitude}'
          '?overview=full&geometries=geojson';
      
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['routes'] != null && data['routes'].isNotEmpty) {
          final List coords = data['routes'][0]['geometry']['coordinates'];
          return coords.map((c) => LatLng(c[1].toDouble(), c[0].toDouble())).toList();
        }
      }
    } catch (e) {
      debugPrint("Lỗi lấy chỉ đường: $e");
    }
    return [];
  }

  @override
  void dispose() {
    _pageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _fetchProductDetail() async {
    try {
      final product = await _productService.getProductById(widget.productId);
      
      // Fetch seller rating summary
      final summary = await _reviewService.getRatingSummary(product.userId);
      
      if (mounted) {
        setState(() {
          _product = product;
          _sellerRating = (summary['averageRating'] as num).toDouble();
          _totalReviews = (summary['totalReviews'] as num).toInt();
          _mediaItems = _parseProductMedia(product.productMedia);
          _isLoading = false;
        });
        _calculateDistance(product);
        _fetchRelatedProducts(product.categoryId);
        _fetchMarketPrice();
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
    }
  }

  Future<void> _fetchMarketPrice() async {
    setState(() => _isLoadingMarketPrice = true);
    try {
      final data = await _productService.getMarketPrice(widget.productId);
      if (data != null && mounted) {
        setState(() {
          _marketPriceMin = (data['minPrice'] as num).toDouble();
          _marketPriceMax = (data['maxPrice'] as num).toDouble();
          _isLoadingMarketPrice = false;
        });
      } else {
        if (mounted) setState(() => _isLoadingMarketPrice = false);
      }
    } catch (e) {
      if (mounted) setState(() => _isLoadingMarketPrice = false);
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
              controller: _scrollController,
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.only(bottom: 120),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildGallery(),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 20),
                        _buildProductHeader(product),
                        const SizedBox(height: 16),
                        _buildTagButtons(product),
                        _buildMarketPriceDiagram(product),
                        const SizedBox(height: 24),
                        _buildSellerInfo(product),
                        const SizedBox(height: 24),
                        _buildSectionTitle("Mô tả chi tiết"),
                        const SizedBox(height: 8),
                        Text(
                          product.productDescription,
                          style: GoogleFonts.inter(
                            fontSize: 14.5,
                            color: const Color(0xFF4B5563),
                            height: 1.65,
                            fontWeight: FontWeight.w400,
                          ),
                        ),
                        const SizedBox(height: 24),
                        _buildSectionTitle("Chi tiết sản phẩm"),
                        const SizedBox(height: 12),
                        _buildTechSpecs(product),
                        const SizedBox(height: 24),
                        
                        // MAP SECTION (Restored to original position)
                        if (product.latitude != null && product.longitude != null) ...[
                          _buildSectionTitle("Vị trí giao dịch"),
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
                              "Sản phẩm tương tự",
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
        ],
      ),
      bottomNavigationBar: _buildBottomBar(),
    );
  }

  Widget _buildTopBar() {
    return Positioned(
      top: 0, left: 0, right: 0,
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildRoundIconButton(
                HeroiconsSolid.chevronLeft, 
                () => Navigator.pop(context),
              ),
              Opacity(
                opacity: _headerOpacity,
                child: Text(
                  "Chi tiết sản phẩm",
                  style: GoogleFonts.roboto(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF111827),
                  ),
                ),
              ),
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(30),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.08),
                      blurRadius: 15,
                      offset: const Offset(0, 5),
                    )
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _buildTopBarAction(HeroiconsSolid.shoppingBag, _requestPurchase),
                    Container(width: 1, height: 20, color: Colors.grey[200]),
                    _buildTopBarAction(HeroiconsSolid.ellipsisVertical, _showMoreOptions),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTopBarAction(IconData icon, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 45,
        height: 45,
        alignment: Alignment.center,
        color: Colors.transparent, // Ensures the entire area is tappable
        child: Icon(icon, color: const Color(0xFF3F3F46), size: 20),
      ),
    );
  }

  Widget _buildRoundIconButton(IconData icon, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 45,
        height: 45,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: Colors.white,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.08),
              blurRadius: 15,
              offset: const Offset(0, 5),
            )
          ],
        ),
        child: Icon(icon, color: const Color(0xFF3F3F46), size: 20),
      ),
    );
  }

  Widget _buildGallery() {
    return Container(
      height: MediaQuery.of(context).size.height * 0.55,
      margin: const EdgeInsets.fromLTRB(16, 95, 16, 0),
      child: Stack(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(40),
            child: PageView.builder(
              controller: _pageController,
              onPageChanged: (index) => setState(() => currentPage = index),
              itemCount: _mediaItems.length,
              itemBuilder: (context, index) => GestureDetector(
                onTap: () => _showFullScreenGallery(index),
                child: _buildMediaItem(_mediaItems[index]),
              ),
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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // MAIN CONTENT (PRICE/TITLE + ANIMATED BOOKMARK)
        Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "₫ ${product.formattedPrice}",
                    style: GoogleFonts.inter(
                      fontSize: 22,
                      fontWeight: FontWeight.w700,
                      color: AppColors.primary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    product.productName,
                    style: GoogleFonts.inter(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFF111827),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            _buildAnimatedBookmarkButton(),
          ],
        ),
        
        // MARKET PRICE INFO moved to tags and diagram
      ],
    );
  }

  Widget _buildSellerInfo(Product product) {
    // Tiền xử lý URL ảnh đại diện
    String avatarUrl = product.userInfo?.avatarUrl ?? '';
    if (avatarUrl.isNotEmpty && !avatarUrl.startsWith('http')) {
      avatarUrl = '${ApiConstants.baseUrl}$avatarUrl';
    }

    return GestureDetector(
      onTap: () => Navigator.pushNamed(context, '/user_profile', arguments: product.userId),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: const Color(0xFFF9FAFB), // Xám cực nhạt để tạo khối
          borderRadius: BorderRadius.circular(30), // Bo cong hoàn toàn (Pill shape)
          border: Border.all(color: const Color(0xFFF3F4F6), width: 1),
        ),
        child: Row(
          children: [
            // Avatar với Placeholder chuyên nghiệp hơn
            Container(
              width: 40,
              height: 40,
              decoration: const BoxDecoration(
                color: Color(0xFFE5E7EB),
                shape: BoxShape.circle,
              ),
              child: ClipOval(
                child: avatarUrl.isNotEmpty
                    ? Image.network(
                        avatarUrl,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => const Icon(Icons.person, color: Colors.white, size: 24),
                      )
                    : const Icon(Icons.person, color: Colors.white, size: 24),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    product.userInfo?.fullName ?? 'Người bán',
                    style: GoogleFonts.inter(
                      fontSize: 15,
                      color: const Color(0xFF111827),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      const Icon(Icons.star_rounded, color: Color(0xFFFBBF24), size: 16),
                      const SizedBox(width: 4),
                      Text(
                        _totalReviews > 0 ? _sellerRating.toStringAsFixed(1) : '0.0',
                        style: GoogleFonts.inter(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFF374151),
                        ),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        "• $_totalReviews đánh giá",
                        style: GoogleFonts.inter(
                          fontSize: 13,
                          color: const Color(0xFF6B7280),
                          fontWeight: FontWeight.w400,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            // Nút "Xem Shop" hoặc "Liên hệ" nhỏ (Optional)
            Icon(Icons.chevron_right_rounded, color: Colors.grey[400]),
          ],
        ),
      ),
    );
  }

  Widget _buildAnimatedBookmarkButton() {
    return ValueListenableBuilder<Set<String>>(
      valueListenable: ProductService.savedProductIdsNotifier,
      builder: (context, savedIds, _) {
        final isSaved = savedIds.contains(widget.productId);
        return _BookmarkButton(
          isSaved: isSaved,
          onTap: _toggleSaveProduct,
        );
      },
    );
  }

  String _translateCondition(String condition) {
    final lower = condition.toLowerCase().trim();
    if (lower == 'used' || lower == 'cũ' || lower == 'đã sử dụng') return 'Đã qua sử dụng';
    if (lower == 'new' || lower == 'mới') return 'Mới';
    if (lower == 'like new' || lower == 'like_new') return 'Như mới';
    if (lower == 'refurbished') return 'Tân trang';
    return condition;
  }

  Widget _buildTagButtons(Product product) {
    final List<Map<String, dynamic>> tags = [];
    if (product.productCondition.isNotEmpty) {
      tags.add({
        'label': _translateCondition(product.productCondition),
        'icon': HeroiconsOutline.tag,
        'color': const Color(0xFF6B7280),
        'bg': const Color(0xFFF3F4F6),
      });
    }
    if (_distanceText != null) {
      tags.add({
        'label': _distanceText!,
        'icon': HeroiconsOutline.mapPin,
        'color': const Color(0xFF6B7280),
        'bg': const Color(0xFFF3F4F6),
      });
    }

    if (_isLoadingMarketPrice) {
      tags.add({
        'label': 'Đang kiểm tra giá...',
        'icon': HeroiconsOutline.currencyDollar,
        'color': const Color(0xFF6B7280),
        'bg': const Color(0xFFF3F4F6),
      });
    } else if (_marketPriceMin != null && _marketPriceMax != null) {
      final price = product.productPrice;
      if (price < _marketPriceMin!) {
        final percent = (((_marketPriceMin! - price) / _marketPriceMin!) * 100).toStringAsFixed(0);
        tags.add({
          'label': 'Rẻ hơn ~$percent%',
          'icon': HeroiconsOutline.arrowTrendingDown,
          'color': const Color(0xFF059669),
          'bg': const Color(0xFFECFDF5),
        });
      } else if (price > _marketPriceMax!) {
        final percent = (((price - _marketPriceMax!) / _marketPriceMax!) * 100).toStringAsFixed(0);
        tags.add({
          'label': 'Cao hơn ~$percent%',
          'icon': HeroiconsOutline.arrowTrendingUp,
          'color': const Color(0xFFDC2626),
          'bg': const Color(0xFFFEF2F2),
        });
      } else {
        tags.add({
          'label': 'Đúng giá',
          'icon': HeroiconsOutline.checkBadge,
          'color': const Color(0xFF2563EB),
          'bg': const Color(0xFFEFF6FF),
        });
      }
    }
    
    if (tags.isEmpty) return const SizedBox.shrink();

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: tags.map((tag) => Padding(
          padding: const EdgeInsets.only(right: 10),
          child: Container(
            height: 34,
            padding: const EdgeInsets.symmetric(horizontal: 14),
            decoration: BoxDecoration(
              color: tag['bg'] as Color,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(tag['icon'] as IconData, size: 13, color: tag['color'] as Color),
                const SizedBox(width: 6),
                Text(
                  tag['label'] as String,
                  style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w500, color: tag['color'] as Color),
                ),
              ],
            ),
          ),
        )).toList(),
      ),
    );
  }

  Widget _buildMarketPriceDiagram(Product product) {
    if (_isLoadingMarketPrice || _marketPriceMin == null || _marketPriceMax == null) {
      return const SizedBox.shrink();
    }

    final minPriceStr = NumberFormat.currency(locale: 'vi_VN', symbol: 'đ', decimalDigits: 0).format(_marketPriceMin);
    final maxPriceStr = NumberFormat.currency(locale: 'vi_VN', symbol: 'đ', decimalDigits: 0).format(_marketPriceMax);

    double percent = 0.5; // default center
    final range = _marketPriceMax! - _marketPriceMin!;
    if (range > 0) {
      percent = (product.productPrice - _marketPriceMin!) / range;
      percent = percent.clamp(-0.2, 1.2); 
    } else {
       if (product.productPrice < _marketPriceMin!) percent = -0.2;
       else if (product.productPrice > _marketPriceMax!) percent = 1.2;
    }

    return Container(
      margin: const EdgeInsets.only(top: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF9FAFB),
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: const Color(0xFFF3F4F6), width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(HeroiconsOutline.chartBar, size: 18, color: AppColors.primary),
              const SizedBox(width: 8),
              Text(
                "Biểu đồ giá thị trường",
                style: GoogleFonts.inter(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF374151),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          LayoutBuilder(
            builder: (context, constraints) {
              final width = constraints.maxWidth;
              
              final markerWidth = 50.0;
              final maxPos = width - markerWidth;
              
              double pos = percent * width;
              pos = pos - (markerWidth / 2);
              pos = pos.clamp(0.0, maxPos);
              
              return Stack(
                clipBehavior: Clip.none,
                children: [
                  Container(
                    margin: const EdgeInsets.only(top: 14),
                    height: 8,
                    width: width,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Colors.green.shade400, Colors.orange.shade400, Colors.red.shade400],
                      ),
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                  Positioned(
                    left: 0,
                    top: 28,
                    child: Text(
                      minPriceStr,
                      style: GoogleFonts.inter(fontSize: 11, color: Colors.grey[600], fontWeight: FontWeight.w500),
                    ),
                  ),
                  Positioned(
                    right: 0,
                    top: 28,
                    child: Text(
                      maxPriceStr,
                      style: GoogleFonts.inter(fontSize: 11, color: Colors.grey[600], fontWeight: FontWeight.w500),
                    ),
                  ),
                  Positioned(
                    left: pos,
                    top: -12,
                    child: Column(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: AppColors.primary,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            "Giá bán",
                            style: GoogleFonts.inter(fontSize: 10, color: Colors.white, fontWeight: FontWeight.bold),
                          ),
                        ),
                        Container(
                          width: 2,
                          height: 10,
                          color: AppColors.primary,
                        ),
                      ],
                    ),
                  ),
                ],
              );
            },
          ),
          const SizedBox(height: 38),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title, {Color? color}) {
    return Text(
      title,
      style: GoogleFonts.inter(
        fontSize: 17,
        fontWeight: FontWeight.w700,
        color: color ?? const Color(0xFF111827),
      ),
    );
  }

  static const Map<String, String> _specLabelMap = {
    'cpu': 'Bộ vi xử lý',
    'processor': 'Bộ vi xử lý',
    'ram': 'Bộ nhớ RAM',
    'memory': 'Bộ nhớ RAM',
    'type': 'Loại thiết bị',
    'device_type': 'Loại thiết bị',
    'model': 'Kiểu máy',
    'storage': 'Dung lượng',
    'capacity': 'Dung lượng',
    'condition': 'Tình trạng',
    'screen': 'Kích thước màn hình',
    'screen_size': 'Kích thước màn hình',
    'display': 'Kích thước màn hình',
    'battery': 'Dung lượng pin',
    'battery_capacity': 'Dung lượng pin',
    'os': 'Hệ điều hành',
    'operating_system': 'Hệ điều hành',
    'brand': 'Thương hiệu',
    'color': 'Màu sắc',
    'weight': 'Trọng lượng',
    'material': 'Chất liệu',
    'warranty': 'Bảo hành',
    'origin': 'Xuất xứ',
    'compatibility': 'Tương thích',
    'tình_trạng': 'Tình trạng',
    'dòng_máy_/_mã': 'Dòng máy / Mã',
    'power_consumption': 'Mức tiêu thụ điện',
    'power': 'Công suất',
    'status': 'Trạng thái',
  };

  String _translateSpecValue(String key, String value) {
    final lowerVal = value.toLowerCase().trim();
    if (lowerVal == 'smartphone') return 'Điện thoại thông minh';
    if (lowerVal == 'tablet') return 'Máy tính bảng';
    if (lowerVal == 'laptop') return 'Máy tính xách tay';
    if (lowerVal == 'used') return 'Cũ';
    if (lowerVal == 'new') return 'Mới';
    if (lowerVal == 'like new') return 'Như mới';
    if (lowerVal == 'refurbished') return 'Tân trang';
    return value;
  }

  String _getVietnameseLabel(String key) {
    return _specLabelMap[key.toLowerCase().trim()] ?? (key[0].toUpperCase() + key.substring(1));
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
      specs = {
        'Cpu': 'Apple A14 Bionic',
        'Ram': '6 GB',
        'Storage': '128 GB',
        'Model': 'iPhone 12 Pro',
        'Battery': '2815 mAh',
      };
    }

    final entries = specs.entries.toList();
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF9FAFB),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFF3F4F6), width: 1),
      ),
      child: Column(
        children: List.generate(entries.length, (index) {
          final entry = entries[index];
          final isLast = index == entries.length - 1;
          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 10),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      _getVietnameseLabel(entry.key),
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        color: const Color(0xFF6B7280),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    Text(
                      _translateSpecValue(entry.key, entry.value),
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        color: const Color(0xFF111827),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              if (!isLast)
                Divider(height: 1, color: Colors.grey[200]),
            ],
          );
        }),
      ),
    );
  }

  Widget _buildMapSection(Product product) {
    final LatLng productPos = LatLng(product.latitude!, product.longitude!);
    final String? avatarUrl = product.userInfo?.avatarUrl;

    LatLng center = productPos;
    if (_currentPosition != null) {
      center = LatLng(
        (productPos.latitude + _currentPosition!.latitude) / 2,
        (productPos.longitude + _currentPosition!.longitude) / 2,
      );
    }

    return Container(
      height: 350, // Đã tăng chiều cao theo yêu cầu của bạn
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
        child: Stack(
          children: [
            FlutterMap(
              mapController: _mapController,
              options: MapOptions(
                initialCenter: center,
                initialZoom: _currentPosition != null ? 12.0 : 14.5, 
                interactionOptions: const InteractionOptions(flags: InteractiveFlag.all), 
              ),
              children: [
                TileLayer(
                  urlTemplate: 'https://mt1.google.com/vt/lyrs=m&x={x}&y={y}&z={z}',
                  userAgentPackageName: 'com.temo.app',
                  retinaMode: true,
                ),
                MarkerLayer(
                  markers: [
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
                                        imageUrl: StringUtils.normalizeUrl(avatarUrl),
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
            // FULLSCREEN TOGGLE BUTTON
            Positioned(
              right: 16,
              bottom: 16,
              child: GestureDetector(
                onTap: () => _showFullScreenMap(product),
                child: Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.15),
                        blurRadius: 8,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: const Icon(Icons.fullscreen_rounded, color: Color(0xFF374151), size: 28),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showFullScreenMap(Product product) {
    final LatLng productPos = LatLng(product.latitude!, product.longitude!);
    final String? avatarUrl = product.userInfo?.avatarUrl;
    List<LatLng> routePoints = [];
    bool isLoadingRoute = true;
    final MapController mapController = MapController();

    showGeneralDialog(
      context: context,
      barrierDismissible: false,
      barrierLabel: "Map",
      transitionDuration: const Duration(milliseconds: 300),
      pageBuilder: (context, animation, secondaryAnimation) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            // Fetch route on first build
            if (isLoadingRoute && _currentPosition != null) {
              _getRoutePoints(
                LatLng(_currentPosition!.latitude, _currentPosition!.longitude),
                productPos,
              ).then((points) {
                if (context.mounted) {
                  setModalState(() {
                    routePoints = points;
                    isLoadingRoute = false;
                  });
                }
              });
            } else if (isLoadingRoute) {
              isLoadingRoute = false; // No current position, skip routing
            }

            return Scaffold(
              body: Stack(
                children: [
                  FlutterMap(
                    mapController: mapController,
                    options: MapOptions(
                      initialCenter: productPos,
                      initialZoom: 15.0,
                      interactionOptions: const InteractionOptions(flags: InteractiveFlag.all),
                    ),
                    children: [
                      TileLayer(
                        urlTemplate: 'https://mt1.google.com/vt/lyrs=m&x={x}&y={y}&z={z}',
                        userAgentPackageName: 'com.temo.app',
                        retinaMode: true,
                      ),
                      if (routePoints.isNotEmpty)
                        PolylineLayer(
                          polylines: [
                            Polyline(
                              points: routePoints,
                              color: AppColors.primary,
                              strokeWidth: 5,
                              borderColor: AppColors.primary.withOpacity(0.3),
                              borderStrokeWidth: 2,
                            ),
                          ],
                        ),
                      MarkerLayer(
                        markers: [
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
                                              imageUrl: StringUtils.normalizeUrl(avatarUrl),
                                              fit: BoxFit.cover,
                                              errorWidget: (context, url, e) => Image.asset('assets/images/logo.png'),
                                            )
                                          : Image.asset('assets/images/logo.png', fit: BoxFit.cover),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          if (_currentPosition != null)
                            Marker(
                              point: LatLng(_currentPosition!.latitude, _currentPosition!.longitude),
                              width: 30,
                              height: 30,
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
                  // BACK BUTTON
                  Positioned(
                    top: MediaQuery.of(context).padding.top + 16,
                    left: 16,
                    child: GestureDetector(
                      onTap: () => Navigator.pop(context),
                      child: Container(
                        padding: const EdgeInsets.all(10),
                        decoration: const BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                          boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 10)],
                        ),
                        child: const Icon(Icons.close_rounded, color: Colors.black87),
                      ),
                    ),
                  ),
                  
                  // ZOOM HUD
                  Positioned(
                    right: 16,
                    top: MediaQuery.of(context).padding.top + 16,
                    child: Column(
                      children: [
                        _buildMapControl(
                          icon: Icons.add_rounded,
                          onTap: () => mapController.move(mapController.camera.center, mapController.camera.zoom + 1),
                        ),
                        const SizedBox(height: 12),
                        _buildMapControl(
                          icon: Icons.remove_rounded,
                          onTap: () => mapController.move(mapController.camera.center, mapController.camera.zoom - 1),
                        ),
                        const SizedBox(height: 12),
                        if (_currentPosition != null)
                          _buildMapControl(
                            icon: Icons.my_location_rounded,
                            onTap: () => mapController.move(LatLng(_currentPosition!.latitude, _currentPosition!.longitude), 15.0),
                          ),
                      ],
                    ),
                  ),

                  // INFO PANEL
                  Positioned(
                    bottom: 24,
                    left: 16,
                    right: 16,
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 20)],
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(
                                "Vị trí giao dịch",
                                style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 16),
                              ),
                              const Spacer(),
                              if (isLoadingRoute)
                                const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.blue)),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            product.productAddress?.fullAddress ?? "Khu vực người bán",
                            style: GoogleFonts.inter(fontSize: 14, color: Colors.grey[600]),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildMapControl({required IconData icon, required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: Colors.white,
          shape: BoxShape.circle,
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 8, offset: const Offset(0, 4))],
        ),
        child: Icon(icon, color: const Color(0xFF374151), size: 24),
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
        margin: const EdgeInsets.only(right: 12),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(26),
          child: Stack(
            fit: StackFit.expand,
            children: [
              CachedNetworkImage(
                imageUrl: StringUtils.normalizeUrl(imageUrl),
                fit: BoxFit.cover,
                maxWidthDiskCache: 1080,
                maxHeightDiskCache: 1080,
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

  final OrderService _orderService = OrderService();

  Future<void> _requestPurchase() async {
    if (_product == null) return;
    
    setState(() => _isLoading = true);
    try {
      final response = await _orderService.createPurchaseRequest(_product!.productId, _product!.userId);
      
      // Sau khi tạo order thành công, gửi tin nhắn vào chat
      if (response['orderId'] != null) {
        final orderId = response['orderId'];
        final chatService = ChatService();
        
        final orderData = {
          "orderId": orderId,
          "productId": _product!.productId,
          "productName": _product!.productName,
          "price": _product!.productPrice,
        };
        
        final content = "[[ORDER_REQUEST:${jsonEncode(orderData)}]]";
        
        await chatService.sendMessage(
          receiverId: _product!.userId,
          content: content,
        );
        
        if (mounted) {
          UIHelpers.showSuccessDialog(
            context,
            title: "Đã gửi yêu cầu!",
            message: "Yêu cầu mua hàng của bạn đã được gửi trực tiếp trong tin nhắn đến người bán.",
          );
        }
      }
    } catch (e) {
      if (mounted) {
        UIHelpers.showErrorSnackBar(context, e.toString());
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _confirmDelete() async {
    final confirmed = await UIHelpers.confirmDialog(
      context,
      title: "Xác nhận xóa",
      message: "Bạn có chắc chắn muốn xóa sản phẩm này? Hành động này không thể hoàn tác.",
      confirmText: "Xóa ngay",
      confirmColor: Colors.red,
      icon: HeroiconsOutline.trash,
    );
    if (confirmed == true) {
      _handleDelete();
    }
  }


  void _showReportProductDialog() {
    final List<Map<String, dynamic>> reasons = [
      {'label': 'Hàng giả / Nhái', 'icon': HeroiconsOutline.archiveBox},
      {'label': 'Lừa đảo', 'icon': HeroiconsOutline.exclamationCircle},
      {'label': 'Sản phẩm cấm', 'icon': HeroiconsOutline.noSymbol},
      {'label': 'Nội dung phản cảm', 'icon': HeroiconsOutline.eyeSlash},
      {'label': 'Khác', 'icon': HeroiconsOutline.ellipsisHorizontal},
    ];

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
        child: SafeArea(
          child: Container(
            margin: const EdgeInsets.fromLTRB(16, 0, 16, 24),
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.95),
              borderRadius: BorderRadius.circular(45),
              boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 20)],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 40, height: 4,
                  margin: const EdgeInsets.only(bottom: 24),
                  decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(2)),
                ),
                const Text("Báo cáo sản phẩm", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 12),
                const Text("Vui lòng chọn lý do bạn muốn báo cáo sản phẩm này.", style: TextStyle(color: Colors.grey, fontSize: 13)),
                const SizedBox(height: 24),
                ...reasons.map((r) => Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: _buildMenuItem(
                    icon: r['icon'] as IconData,
                    iconColor: Colors.red,
                    bgColor: Colors.red.withOpacity(0.1),
                    title: r['label'] as String,
                    onTap: () {
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text("Cảm ơn bạn đã báo cáo. Chúng tôi sẽ xem xét sớm nhất!"), backgroundColor: Colors.green),
                      );
                    },
                  ),
                )).toList(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showMoreOptions() {
    final currentUser = StorageHelper.getUser();
    final bool isOwner = currentUser?.userId == _product?.userId;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
        child: SafeArea(
          child: Container(
            margin: const EdgeInsets.fromLTRB(16, 0, 16, 24),
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.95),
              borderRadius: BorderRadius.circular(45),
              boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 20)],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 40, height: 4,
                  margin: const EdgeInsets.only(bottom: 24),
                  decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(2)),
                ),
                if (isOwner) ...[
                  _buildMenuItem(
                    icon: HeroiconsOutline.arrowTrendingUp,
                    iconColor: Colors.orange,
                    bgColor: const Color(0xFFFFF7ED),
                    title: "Đẩy tin sản phẩm",
                    onTap: () { Navigator.pop(context); _showPushPromotionDialog(); },
                  ),
                  const SizedBox(height: 12),
                  _buildMenuItem(
                    icon: HeroiconsOutline.pencilSquare,
                    iconColor: AppColors.primary,
                    bgColor: AppColors.primary.withOpacity(0.1),
                    title: "Chỉnh sửa sản phẩm",
                    onTap: () { Navigator.pop(context); /* logic chỉnh sửa */ },
                  ),
                  const SizedBox(height: 12),
                  _buildMenuItem(
                    icon: HeroiconsOutline.trash,
                    iconColor: Colors.red,
                    bgColor: const Color(0xFFFEF2F2),
                    title: "Xóa sản phẩm",
                    onTap: () { Navigator.pop(context); _confirmDelete(); },
                  ),
                ]
                else ...[
                  _buildMenuItem(
                    icon: HeroiconsOutline.shoppingBag,
                    iconColor: AppColors.success,
                    bgColor: AppColors.success.withOpacity(0.1),
                    title: "Gửi yêu cầu mua",
                    onTap: () { Navigator.pop(context); _requestPurchase(); },
                  ),
                  const SizedBox(height: 12),
                  _buildMenuItem(
                    icon: HeroiconsOutline.flag,
                    iconColor: Colors.red,
                    bgColor: Colors.red.withOpacity(0.1),
                    title: "Báo cáo sản phẩm",
                    onTap: () {
                      Navigator.pop(context);
                      _showReportProductDialog();
                    },
                  ),
                  const SizedBox(height: 12),
                  _buildMenuItem(
                    icon: HeroiconsOutline.share,
                    iconColor: AppColors.warning,
                    bgColor: AppColors.warning.withOpacity(0.1),
                    title: "Chia sẻ",
                    onTap: () => Navigator.pop(context),
                  ),
                ],
                const SizedBox(height: 12),
                _buildMenuItem(
                  icon: HeroiconsOutline.sparkles,
                  iconColor: AppColors.primary,
                  bgColor: AppColors.primary.withOpacity(0.1),
                  title: "Cải tiến ứng dụng",
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => AppImprovementScreen(),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 10),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMenuItem({
    required IconData icon,
    required Color iconColor,
    required Color bgColor,
    required String title,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(45),
          border: Border.all(color: Colors.grey.shade100),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(color: bgColor, shape: BoxShape.circle),
              child: Icon(icon, color: iconColor, size: 20),
            ),
            const SizedBox(width: 16),
            Text(
              title,
              style: GoogleFonts.roboto(fontSize: 15, fontWeight: FontWeight.w700, color: const Color(0xFF1F2937)),
            ),
            const Spacer(),
            const Icon(Icons.chevron_right_rounded, color: Colors.grey, size: 18),
          ],
        ),
      ),
    );
  }

  Widget _buildDivider() => Divider(height: 1, indent: 70, color: Colors.grey[100]);

  Future<void> _handleDelete() async {
    setState(() => _isLoading = true);
    try {
      await _productService.deleteProduct(_product!.productId);
      if (mounted) {
        Navigator.pop(context); // Quay về trang trước
        UIHelpers.showSuccessSnackBar(context, "Sản phẩm đã được xóa thành công");
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        UIHelpers.showErrorSnackBar(context, "Lỗi khi xóa: $e");
      }
    }
  }

  void _showPushPromotionDialog() {
    final packages = [
      {'days': 3, 'cost': 2},
      {'days': 7, 'cost': 4},
      {'days': 15, 'cost': 7},
      {'days': 30, 'cost': 10},
    ];

    UIHelpers.showModernDialog(
      context,
      icon: HeroiconsOutline.megaphone,
      iconColor: AppColors.primary,
      bgColor: AppColors.primary.withOpacity(0.1),
      title: "Promote Product",
      description: "Your product will appear in the recommended section, reaching more customers.",
      content: Column(
        children: packages.map((pkg) => Container(
          margin: const EdgeInsets.only(bottom: 12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.grey[100]!),
          ),
          child: ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 16),
            leading: const Icon(HeroiconsOutline.clock, color: Colors.amber, size: 20),
            title: Text("${pkg['days']} Days", style: GoogleFonts.roboto(fontWeight: FontWeight.bold)),
            subtitle: Text("${pkg['cost']} coins", style: const TextStyle(fontSize: 12)),
            trailing: const Icon(Icons.arrow_forward_ios, size: 12),
            onTap: () { Navigator.pop(context); _handlePush(pkg['days'] as int); },
          ),
        )).toList(),
      ),
      primaryButtonText: "Cancel",
    );
  }

  Future<void> _handlePush(int days) async {
    setState(() => _isLoading = true);
    try {
      await _productService.pushProduct(_product!.productId, days);
      if (mounted) {
        UIHelpers.showSuccessSnackBar(context, "Promotion successful! Your product will be featured in the recommended section soon.");
        _fetchProductDetail(); // Reload state
      }
    } catch (e) {
      if (mounted) {
        UIHelpers.showErrorDialog(
          context,
          title: "Đẩy tin thất bại",
          message: e.toString().replaceAll("Exception:", ""),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }


  Widget _buildBottomBar() {
    final bool isOwner = _currentUserId != null && _product != null && _currentUserId == _product!.userId;

    return Container(
      padding: EdgeInsets.fromLTRB(16, 12, 16, MediaQuery.of(context).padding.bottom + 12),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Colors.grey[200]!, width: 1)),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, -5))
        ],
      ),
      child: isOwner
          ? _buildBottomButton(
              icon: HeroiconsSolid.pencilSquare,
              label: "Quản lý sản phẩm",
              onTap: () => smoothPush(context, const ProductManager()),
              isSolid: true,
            )
          : Row(
              children: [
                Expanded(
                  child: _buildBottomButton(
                    icon: HeroiconsSolid.phone,
                    label: "Gọi ngay",
                    onTap: _showCallDialog,
                    isSolid: false,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildBottomButton(
                    icon: HeroiconsSolid.chatBubbleOvalLeft,
                    label: "Nhắn tin",
                    onTap: () {
                      if (_product?.userInfo != null) {
                        final userInfo = _product!.userInfo!;
                        final partner = ChatPartner(userId: userInfo.userId, fullName: userInfo.fullName, avatarUrl: userInfo.avatarUrl, email: userInfo.email);
                        smoothPush(context, ChatScreen(conversationId: "", partnerUser: partner, product: _product));
                      }
                    },
                    isSolid: true,
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildBottomButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    required bool isSolid,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 52,
        decoration: BoxDecoration(
          color: isSolid ? AppColors.primary : const Color(0xFFFFF7ED),
          borderRadius: BorderRadius.circular(50),
          border: Border.all(
            color: isSolid ? AppColors.primary : const Color(0xFFFFF7ED),
            width: 1.5,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: isSolid ? Colors.white : AppColors.primary, size: 20),
            const SizedBox(width: 8),
            Text(
              label,
              style: GoogleFonts.inter(
                color: isSolid ? Colors.white : AppColors.primary,
                fontSize: 16,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showCallDialog() {
    final phoneNumber = _product?.userInfo?.phoneNumber.toString() ?? '';
    final sellerName = _product?.userInfo?.fullName ?? 'Người bán';
    if (phoneNumber.isEmpty || phoneNumber == '0') return;

    UIHelpers.showModernDialog(
      context,
      icon: HeroiconsOutline.phone,
      iconColor: AppColors.primary,
      bgColor: AppColors.primary.withOpacity(0.1),
      title: "Gọi cho $sellerName",
      description: "Bạn có muốn gọi cho người bán tại số $phoneNumber?",
      content: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          minimumSize: const Size(double.infinity, 50),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
        ),
        onPressed: () {
          Navigator.pop(context);
          _makePhoneCall(phoneNumber);
        },
        child: const Text("Gọi ngay", style: TextStyle(fontWeight: FontWeight.bold)),
      ),
      primaryButtonText: "Hủy",
    );
  }

  void _makePhoneCall(String phoneNumber) async {
    final Uri phoneUri = Uri(scheme: 'tel', path: phoneNumber);
    if (await canLaunchUrl(phoneUri)) await launchUrl(phoneUri);
  }


  Widget _buildMediaItem(MediaItem item) {
    if (item.type == MediaType.image) {
      return CachedNetworkImage(
        imageUrl: StringUtils.normalizeUrl(item.url),
        fit: BoxFit.cover,
        width: double.infinity,
        height: double.infinity,
        maxWidthDiskCache: 1920,
        maxHeightDiskCache: 1080,
        placeholder: (context, url) => const Center(child: ModernLoader(size: 30)),
        errorWidget: (context, url, error) => Container(
          color: Colors.grey[300],
          child: const Center(child: Icon(Icons.broken_image, color: Colors.grey, size: 60)),
        ),
      );
    } else {
      return VideoPlayerWidget(
        videoUrl: item.url,
        onFullscreen: () => _showFullScreenGallery(_mediaItems.indexOf(item)),
      );
    }
  }

  void _showFullScreenGallery(int initialIndex) {
    int tempCurrentPage = initialIndex;
    final PageController galleryController = PageController(initialPage: initialIndex);

    showGeneralDialog(
      context: context,
      barrierColor: Colors.black,
      barrierDismissible: false,
      barrierLabel: "Gallery",
      transitionDuration: const Duration(milliseconds: 300),
      pageBuilder: (context, animation, secondaryAnimation) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Scaffold(
              backgroundColor: Colors.black,
              body: Stack(
                children: [
                  PageView.builder(
                    controller: galleryController,
                    itemCount: _mediaItems.length,
                    onPageChanged: (index) => setModalState(() => tempCurrentPage = index),
                    itemBuilder: (context, index) {
                      final item = _mediaItems[index];
                      if (item.type == MediaType.image) {
                        return InteractiveViewer(
                          minScale: 1.0,
                          maxScale: 5.0,
                          child: Center(
                            child: CachedNetworkImage(
                              imageUrl: StringUtils.normalizeUrl(item.url),
                              fit: BoxFit.contain,
                              placeholder: (context, url) => const ModernLoader(size: 30),
                              errorWidget: (context, url, error) => const Icon(Icons.broken_image, color: Colors.white, size: 50),
                            ),
                          ),
                        );
                      } else {
                        return Center(child: VideoPlayerWidget(videoUrl: item.url));
                      }
                    },
                  ),
                  // TOP BAR
                  Positioned(
                    top: MediaQuery.of(context).padding.top + 10,
                    left: 0,
                    right: 0,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          // Close Button
                          Align(
                            alignment: Alignment.centerRight,
                            child: GestureDetector(
                              onTap: () {
                                _pageController.jumpToPage(tempCurrentPage);
                                Navigator.pop(context);
                              },
                              child: Container(
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color: Colors.black54,
                                  shape: BoxShape.circle,
                                  border: Border.all(color: Colors.white24),
                                ),
                                child: const Icon(Icons.close_rounded, color: Colors.white, size: 24),
                              ),
                            ),
                          ),
                          // Index Indicator
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: Colors.black.withOpacity(0.5),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              "${tempCurrentPage + 1} / ${_mediaItems.length}",
                              style: GoogleFonts.inter(
                                color: Colors.white,
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}
class _BookmarkButton extends StatefulWidget {
  final bool isSaved;
  final VoidCallback onTap;

  const _BookmarkButton({required this.isSaved, required this.onTap});

  @override
  State<_BookmarkButton> createState() => _BookmarkButtonState();
}

class _BookmarkButtonState extends State<_BookmarkButton> {
  double _scale = 1.0;

  void _handleTap() {
    setState(() => _scale = 1.15);
    Future.delayed(const Duration(milliseconds: 150), () {
      if (mounted) setState(() => _scale = 1.0);
    });
    widget.onTap();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _handleTap,
      child: AnimatedScale(
        scale: _scale,
        duration: const Duration(milliseconds: 150),
        curve: Curves.easeOutBack,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: widget.isSaved ? AppColors.primary : Colors.white,
            shape: BoxShape.circle,
            border: Border.all(
              color: widget.isSaved ? AppColors.primary : const Color(0xFFE5E7EB),
              width: 1,
            ),
            boxShadow: [
              if (widget.isSaved)
                BoxShadow(
                  color: AppColors.primary.withOpacity(0.25),
                  blurRadius: 12,
                  offset: const Offset(0, 5),
                ),
            ],
          ),
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 250),
            transitionBuilder: (child, animation) => FadeTransition(
              opacity: animation,
              child: ScaleTransition(scale: animation, child: child),
            ),
            child: Icon(
              widget.isSaved ? HeroiconsSolid.bookmark : HeroiconsOutline.bookmark,
              key: ValueKey<bool>(widget.isSaved),
              color: widget.isSaved ? Colors.white : const Color(0xFF4B5563),
              size: 22,
            ),
          ),
        ),
      ),
    );
  }
}
