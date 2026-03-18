import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:heroicons_flutter/heroicons_flutter.dart';
import 'package:temo/Colors/AppColors.dart';
import 'package:temo/utils/constants.dart';
import 'package:temo/screens/Setting/Setting.dart';
import 'package:temo/services/auth_service.dart';
import 'package:temo/components/Post.dart';
import 'package:temo/components/ProductGridItem.dart';
import 'package:temo/components/Filter.dart';
import 'package:temo/models/Product/Product.dart';
import 'package:temo/services/product_service.dart';
import 'package:temo/services/location_service.dart';
import 'package:temo/components/AppDrawer.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'dart:async';
import 'package:temo/components/ModernLoader.dart';
import '../Search/SearchResult.dart';
import 'package:temo/models/User/User.dart';
import 'package:temo/screens/Notification/NotificationScreen.dart';
import 'package:temo/screens/Home/CategoryProductsScreen.dart';
import 'package:intl/intl.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:temo/models/User/ChatPartner.dart';
import 'package:temo/screens/Message/ChatScreen.dart';
import 'package:temo/app_router.dart';

class HomeScreen extends StatefulWidget {
  final User? user;
  final VoidCallback? onMenuTap;
  const HomeScreen({Key? key, this.user, this.onMenuTap}) : super(key: key);

  @override
  State<StatefulWidget> createState() => HomeScreenState();
}

class HomeScreenState extends State<HomeScreen> {
  final ProductService _productService = ProductService();
  final LocationService _locationService = LocationService();

  final List<Product> _products = [];
  bool _isInitialLoading = true;
  bool _isLoadingMore = false;
  bool _hasMore = true;
  int _currentPage = 1;
  final int _limit = 10;

  final PageController _bannerController = PageController();
  Timer? _bannerTimer;
  int _currentBannerIndex = 0;

  final List<String> _searchHints = [
    "What are you looking for today?",
    "Search for vouchers...",
    "Search for tickets...",
    "Search for products...",
  ];
  int _currentHintIndex = 0;
  Timer? _hintTimer;

  String? _filterCategoryId;
  String? _filterProvince;
  String? _filterWard;

  final List<Map<String, dynamic>> _quickCategories = [
    {'id': 'auto', 'name': 'Autos', 'image': 'assets/images/auto.png'},
    {'id': 'furniture', 'name': 'Appliances', 'image': 'assets/images/appliances.png'},
    {'id': 'technology', 'name': 'Electronics', 'image': 'assets/images/electronics.png'},
    {'id': 'style', 'name': 'Fashion', 'image': 'assets/images/fashion.png'},
    {'id': 'service', 'name': 'Services', 'image': 'assets/images/service.png'},
    {'id': 'hobby', 'name': 'Hobbies', 'image': 'assets/images/hobbies.png'},
    {'id': 'kids', 'name': 'Kids', 'image': 'assets/images/kids.png'},
  ];

  late final FilterOverlay _filterOverlay = FilterOverlay(
    onFilterApplied: (categoryId, province, ward) =>
        updateFilter(categoryId: categoryId, province: province, ward: ward),
  );

  @override
  void initState() {
    super.initState();
    _fetchLocation();
    _loadProducts(isRefresh: true);
    _productService.productChangeNotifier.addListener(_onProductChanged);

    _bannerTimer = Timer.periodic(const Duration(seconds: 3), (Timer timer) {
      if (_bannerController.hasClients) {
        _currentBannerIndex = (_currentBannerIndex + 1) % 4;
        _bannerController.animateToPage(
          _currentBannerIndex,
          duration: const Duration(milliseconds: 350),
          curve: Curves.easeIn,
        );
      }
    });

    _hintTimer = Timer.periodic(const Duration(seconds: 3), (Timer timer) {
      if (mounted) {
        setState(() {
          _currentHintIndex = (_currentHintIndex + 1) % _searchHints.length;
        });
      }
    });
  }

  Future<void> _fetchLocation() async {
    try {
      await _locationService.getCurrentAddress();
    } catch (e) {
      debugPrint("Location error: $e");
    }
  }

  @override
  void dispose() {
    _bannerTimer?.cancel();
    _bannerController.dispose();
    _hintTimer?.cancel();
    _productService.productChangeNotifier.removeListener(_onProductChanged);
    super.dispose();
  }

  void reload() {
    _loadProducts(isRefresh: true);
    _fetchLocation();
  }

  void _onProductChanged() => _loadProducts(isRefresh: true);

  void updateFilter({String? categoryId, String? province, String? ward}) {
    setState(() {
      _filterCategoryId = categoryId;
      _filterProvince = province;
      _filterWard = ward;
    });
    _loadProducts(isRefresh: true);
  }

  Future<void> _loadProducts({required bool isRefresh}) async {
    if (!isRefresh && (_isLoadingMore || !_hasMore)) return;
    setState(() {
      if (isRefresh) {
        _isInitialLoading = true;
        _products.clear();
        _currentPage = 1;
        _hasMore = true;
      } else {
        _isLoadingMore = true;
      }
    });

    try {
      List<Product> newProducts;
      bool isFiltering = _filterCategoryId != null || _filterProvince != null || _filterWard != null;
      if (isFiltering) {
        newProducts = await _productService.getProductsByFilter(
          categoryId: _filterCategoryId == '' ? null : _filterCategoryId,
          province: _filterProvince,
          ward: _filterWard,
        );
        _hasMore = false;
      } else {
        newProducts = await _productService.getProducts(page: _currentPage, limit: _limit);
      }

      if (mounted) {
        setState(() {
          if (newProducts.isEmpty) {
            if (!isFiltering) _hasMore = false;
          } else {
            _products.addAll(newProducts);
            if (!isFiltering) {
              _currentPage++;
              if (newProducts.length < _limit) _hasMore = false;
            }
          }
          _isInitialLoading = false;
          _isLoadingMore = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isInitialLoading = _isLoadingMore = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () async {
            _fetchLocation();
            await _loadProducts(isRefresh: true);
          },
          child: CustomScrollView(
            slivers: [
              SliverToBoxAdapter(
                child: Column(
                  children: [
                    Stack(
                      children: [
                        Positioned.fill(child: Container(color: Colors.white)),
                        // Gradient & Fade giữ nguyên
                        Positioned.fill(
                          child: Container(
                            decoration: const BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.centerLeft,
                                end: Alignment.centerRight,
                                colors: [Color(0xFFFFB86A), Color(0xFFFFAD86), Color(0xFFFFA2A2), Color(0xFFFFA2A2)],
                                stops: [0.0, 0.39, 0.77, 1.0],
                              ),
                            ),
                          ),
                        ),
                        Positioned.fill(
                          child: Container(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                                colors: [Colors.white.withOpacity(0.0), Colors.white.withOpacity(0.0), Colors.white.withOpacity(0.6), Colors.white, Colors.white],
                                stops: const [0.0, 0.15, 0.40, 0.70, 1.0],
                              ),
                            ),
                          ),
                        ),
                        Column(
                          children: [
                            // 1. Top Bar
                            Padding(
                              padding: const EdgeInsets.only(left: 14, right: 14, top: 10, bottom: 0),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  GestureDetector(
                                    onTap: () => widget.onMenuTap?.call(),
                                    child: SvgPicture.asset('assets/images/Iconmenu.svg', width: 30, height: 30, fit: BoxFit.contain),
                                  ),
                                  Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      _buildCircleIcon('assets/images/Iconluu.svg'),
                                      const SizedBox(width: 12),
                                      GestureDetector(
                                        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const NotificationScreen())),
                                        child: _buildCircleIcon('assets/images/Iconbell.svg'),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 20),

                            // 2. Search Bar
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 20),
                              child: Container(
                                height: 50,
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.95),
                                  borderRadius: BorderRadius.circular(25),
                                  boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4))],
                                ),
                                child: Row(
                                  children: [
                                    const SizedBox(width: 16),
                                    const Icon(HeroiconsOutline.magnifyingGlass, color: Colors.grey, size: 22),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: TextField(
                                        textInputAction: TextInputAction.search,
                                        onSubmitted: (value) {
                                          if (value.trim().isNotEmpty) {
                                            smoothPush(context, SearchResultScreen(keyword: value.trim()));
                                          }
                                        },
                                        decoration: InputDecoration(
                                          hintText: _searchHints[_currentHintIndex],
                                          border: InputBorder.none,
                                          hintStyle: const TextStyle(
                                            color: Color(0x66000000), // Đen 40%
                                            fontSize: 14,
                                            fontFamily: 'Roboto',
                                          ),
                                        ),
                                      ),
                                    ),
                                    // Filter Button
                                    GestureDetector(
                                      onTap: () => _filterOverlay.toggle(context),
                                      child: Container(
                                        width: 44, height: 44, margin: const EdgeInsets.only(right: 3),
                                        decoration: const BoxDecoration(color: Color(0xFFFFB86A), shape: BoxShape.circle),
                                        child: const Icon(HeroiconsOutline.adjustmentsHorizontal, color: Colors.white, size: 20),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),

                            const SizedBox(height: 10),

                            // 3. Categories List
                            Container(
                              height: 90,
                              child: ListView.builder(
                                scrollDirection: Axis.horizontal,
                                padding: const EdgeInsets.symmetric(horizontal: 10),
                                itemCount: _quickCategories.length,
                                itemBuilder: (context, index) {
                                  final cat = _quickCategories[index];
                                  return GestureDetector(
                                    onTap: () {
                                      smoothPush(
                                        context,
                                        CategoryProductsScreen(
                                          category: cat,
                                        ),
                                      );
                                    },
                                    child: Container(
                                      width: 72, margin: const EdgeInsets.only(right: 6),
                                      child: Column(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: [
                                          Image.asset(cat['image'], width: 44, height: 44, fit: BoxFit.contain),
                                          const SizedBox(height: 6),
                                          Text(
                                            cat['name'],
                                            style: const TextStyle(
                                                fontSize: 10,
                                                color: Color(0x99000000), // Đen 60%
                                                fontFamily: 'Roboto',
                                                fontWeight: FontWeight.bold
                                            ),
                                            maxLines: 1, overflow: TextOverflow.ellipsis,
                                          ),
                                        ],
                                      ),
                                    ),
                                  );
                                },
                              ),
                            ),

                            const SizedBox(height: 10),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              if (_products.isNotEmpty)
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.only(left: 20, right: 20, top: 0, bottom: 10),
                    child: const Text(
                        "Recommended",
                        style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                            color: Color(0xB3000000),
                            fontFamily: 'Roboto'
                        )
                    ),
                  ),
                ),

              if (_products.isNotEmpty)
                SliverToBoxAdapter(
                  child: Container(
                    height: 328, margin: const EdgeInsets.only(bottom: 20),
                    child: ListView.separated(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      scrollDirection: Axis.horizontal,
                      itemCount: _products.take(6).length,
                      separatorBuilder: (_, __) => const SizedBox(width: 16),

                      itemBuilder: (context, index) {
                        final product = _products[index];
                        String imageUrl = product.productMedia.isNotEmpty ? product.productMedia[0] : '';
                        if (imageUrl.startsWith('image:')) imageUrl = imageUrl.substring(6).trim();

                        final String formattedPrice = NumberFormat.currency(
                            locale: 'vi_VN',
                            symbol: 'đ',
                            decimalDigits: 0
                        ).format(product.productPrice);

                        return GestureDetector(
                          onTap: () => Navigator.pushNamed(context, '/product_detail', arguments: product.productId),
                          child: SizedBox(
                            width: 245,
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(26),
                              child: Stack(
                                fit: StackFit.expand,
                                children: [
                                  // Background Image
                                  CachedNetworkImage(
                                    imageUrl: imageUrl,
                                    fit: BoxFit.cover,
                                    placeholder: (context, url) => Container(color: Colors.white),
                                    errorWidget: (context, url, error) => Container(
                                        color: Colors.grey[200],
                                        child: const Icon(Icons.image)
                                    ),
                                  ),
                                  // Dark Overlay
                                  Container(color: Colors.black.withOpacity(0.3)),

                                  // Content
                                  Padding(
                                    padding: const EdgeInsets.all(16.0),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        // Product Name & Price
                                        Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                                product.productName,
                                                style: const TextStyle(
                                                    fontFamily: 'Quicksand', // Font Quicksand
                                                    color: Colors.white,      // Trắng 100%
                                                    fontSize: 18,             // Size 18
                                                    fontWeight: FontWeight.bold
                                                ),
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis
                                            ),
                                            const SizedBox(height: 4),
                                            Text(
                                                formattedPrice,
                                                style: const TextStyle(
                                                    fontFamily: 'Quicksand', // Font Quicksand
                                                    color: Colors.white,
                                                    fontSize: 14,             // Size 14
                                                    fontWeight: FontWeight.w700
                                                )
                                            ),
                                          ],
                                        ),
                                        // Bottom Location and Message Pill
                                        Row(
                                          children: [
                                            Expanded(
                                              child: ClipRRect(
                                                borderRadius: BorderRadius.circular(20),
                                                child: BackdropFilter(
                                                  filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
                                                  child: Container(
                                                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                                    decoration: BoxDecoration(
                                                        color: Colors.white.withOpacity(0.4),
                                                        borderRadius: BorderRadius.circular(20)
                                                    ),
                                                    child: Row(
                                                      children: [
                                                        const Icon(HeroiconsOutline.mapPin, color: Colors.white, size: 14),
                                                        const SizedBox(width: 4),
                                                        Expanded(
                                                            child: Text(
                                                                product.productAddress?.province ?? 'Location unknown',
                                                                style: const TextStyle(
                                                                    fontFamily: 'Quicksand', // Font Quicksand
                                                                    color: Colors.white,
                                                                    fontSize: 12,             // Size 12
                                                                    fontWeight: FontWeight.w700
                                                                ),
                                                                maxLines: 1,
                                                                overflow: TextOverflow.ellipsis
                                                            )
                                                        ),
                                                      ],
                                                    ),
                                                  ),
                                                ),
                                              ),
                                            ),
                                            const SizedBox(width: 8),
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
                                                      width: 36,
                                                      height: 36,
                                                      decoration: BoxDecoration(
                                                          color: Colors.white.withOpacity(0.4),
                                                          shape: BoxShape.circle
                                                      ),
                                                      alignment: Alignment.center,
                                                      child: const Icon(HeroiconsOutline.chatBubbleOvalLeft, color: Colors.white, size: 18)
                                                  ),
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  )
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),

              if (_products.isNotEmpty)
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.only(left: 20, right: 20, top: 10, bottom: 10),
                    child: const Text(
                      "Explore more",
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                        color: Color(0xB3000000), // Black 70%
                        fontFamily: 'Roboto',
                      ),
                    ),
                  ),
                ),

              _products.isEmpty && !_isInitialLoading
                  ? SliverToBoxAdapter(child: Center(child: Padding(padding: const EdgeInsets.only(top: 50), child: Text("No products found.", style: TextStyle(color: Colors.grey)))))
                  : SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                sliver: SliverMasonryGrid.count(
                  crossAxisCount: 2, mainAxisSpacing: 16, crossAxisSpacing: 16,
                  childCount: _products.length + (_hasMore ? 1 : 0),
                  itemBuilder: (context, index) {
                    if (index == _products.length && _hasMore) {
                      WidgetsBinding.instance.addPostFrameCallback((_) => _loadProducts(isRefresh: false));
                      return const SizedBox();
                    }
                    if (index >= _products.length) return const SizedBox();
                    return ProductGridItem(product: _products[index]);
                  },
                ),
              ),

              if (_isLoadingMore)
                const SliverToBoxAdapter(child: Padding(padding: EdgeInsets.all(20), child: Center(child: ModernLoader()))),

              const SliverToBoxAdapter(child: SizedBox(height: 80)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCircleIcon(String assetPath) {
    return Container(
      width: 40, height: 40,
      decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
      alignment: Alignment.center,
      child: SvgPicture.asset(assetPath, width: 20, height: 20, color: Colors.black87),
    );
  }
}