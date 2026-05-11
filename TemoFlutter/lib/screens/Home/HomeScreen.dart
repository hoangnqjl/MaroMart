import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:heroicons_flutter/heroicons_flutter.dart';
import 'package:temo/Colors/AppColors.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:temo/components/ProductGridItem.dart';
import 'package:temo/components/Filter.dart';
import 'package:temo/models/Product/Product.dart';
import 'package:temo/services/product_service.dart';
import 'package:temo/services/location_service.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'dart:async';
import '../../components/Skeletons/CategorySkeleton.dart';
import '../Search/SearchResult.dart';
import 'package:temo/models/User/User.dart';
import 'package:temo/screens/Notification/NotificationScreen.dart';
import 'package:temo/screens/Home/CategoryProductsScreen.dart';
import 'package:intl/intl.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:temo/models/User/ChatPartner.dart';
import 'package:temo/screens/Message/ChatScreen.dart';
import 'package:temo/components/Skeletons/ProductCardSkeleton.dart';
import 'package:temo/components/Skeletons/RecommendedProductSkeleton.dart';
import 'package:temo/app_router.dart';
import 'package:flutter/services.dart';
import 'package:temo/utils/string_utils.dart';
import 'package:temo/components/Skeleton.dart';
import 'package:temo/utils/constants.dart';
import 'package:temo/services/notification_service.dart';
import 'package:temo/screens/Product/SavedProductsScreen.dart';

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
  final NotificationService _notificationService = NotificationService();

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
    "Search...",
  ];
  int _currentHintIndex = 0;
  Timer? _hintTimer;
  Timer? _debounce;

  final TextEditingController _searchController = TextEditingController();
  List<String> _suggestions = [];

  String? _filterCategoryId;
  String? _filterProvince;
  String? _filterWard;

  List<dynamic> _categories = [];
  bool _isCategoriesLoading = true;
  
  List<Product> _recommendedProducts = [];
  bool _isRecommendedLoading = true;
  Position? _currentPosition;



  final FocusNode _searchFocusNode = FocusNode();

  late final FilterOverlay _filterOverlay = FilterOverlay(
    onFilterApplied: (categoryId, province, ward) =>
        updateFilter(categoryId: categoryId, province: province, ward: ward),
  );

  @override
  void initState() {
    super.initState();
    _searchFocusNode.addListener(() {
      if (mounted) setState(() {});
    });
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    _fetchLocation();
    _loadCategories();
    _loadRecommendedProducts();
    _loadProducts(isRefresh: true);
    _notificationService.fetchUnreadCount();
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
    _debounce?.cancel();
    _searchController.dispose();
    _searchFocusNode.dispose();
    _productService.productChangeNotifier.removeListener(_onProductChanged);
    super.dispose();
  }

  void _onSearchChanged(String query) {
    if (_debounce?.isActive ?? false) _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 300), () async {
      if (query.trim().isEmpty) {
        setState(() => _suggestions = []);
        return;
      }
      final suggestions = await _productService.getAiSuggestions(query);
      if (mounted) {
        setState(() => _suggestions = suggestions);
      }
    });
  }

  void reload() {
    _loadProducts(isRefresh: true);
    _loadRecommendedProducts();
    _fetchLocation();
  }

  void _onProductChanged() => _loadProducts(isRefresh: true);

  Future<void> _loadCategories() async {
    setState(() => _isCategoriesLoading = true);
    try {
      final cats = await _productService.getCategories();
      cats.sort((a, b) {
        final String idA = (a['categoryId'] ?? a['id'] ?? '').toString().toLowerCase();
        final String idB = (b['categoryId'] ?? b['id'] ?? '').toString().toLowerCase();
        
        if (idA == 'other' || idA == 'khac') {
          if (idB == 'other' || idB == 'khac') return 0;
          return 1;
        }
        if (idB == 'other' || idB == 'khac') return -1;
        
        return idA.compareTo(idB);
      });
      if (mounted) {
        setState(() {
          _categories = cats;
          _isCategoriesLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isCategoriesLoading = false);
    }
  }

  Future<void> _loadRecommendedProducts() async {
    setState(() => _isRecommendedLoading = true);
    try {
      final pos = await _locationService.getCurrentPosition();
      final products = await _productService.getRecommendedProducts(
        limit: 15,
        lat: pos?.latitude,
        lng: pos?.longitude,
      );
      if (mounted) {
        setState(() {
          _recommendedProducts = products;
          _isRecommendedLoading = false;
          if (pos != null) _currentPosition = pos;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isRecommendedLoading = false);
    }
  }

  Widget _buildCategoryItem(dynamic cat) {
    final String id = cat['categoryId']?.toString() ?? cat['id']?.toString() ?? '';
    final String name = cat['categoryName']?.toString() ?? cat['name']?.toString() ?? '';
    final String? iconName = cat['categoryIcon']?.toString(); // URL from backend
    
    String? iconUrl;
    if (iconName != null && iconName.isNotEmpty) {
      if (iconName.startsWith('http')) {
        iconUrl = iconName;
      } else {
        iconUrl = '${ApiConstants.baseUrl}/storage/system/category/$iconName';
      }
    }

    return GestureDetector(
      onTap: () {
        smoothPush(
          context,
          CategoryProductsScreen(
            category: cat is Map ? cat : (cat as dynamic).toJson(),
          ),
        );
      },
      child: Container(
        width: 85,
        margin: const EdgeInsets.only(right: 6),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            id == 'all'
                ? Container(
                    width: 54,
                    height: 54,
                    decoration: const BoxDecoration(
                        color: Color(0xFFFFB86A), shape: BoxShape.circle),
                    child: const Icon(Icons.grid_view_rounded,
                        color: Colors.white, size: 24),
                  )
                : iconUrl != null
                    ? CachedNetworkImage(
                        imageUrl: StringUtils.normalizeUrl(iconUrl),
                        width: 54,
                        height: 54,
                        fit: BoxFit.contain,
                        placeholder: (_, __) => const CircleSkeleton(size: 54),
                        errorWidget: (_, __, ___) => Container(
                          width: 54,
                          height: 54,
                          decoration: BoxDecoration(
                            color: Colors.orange.withOpacity(0.2),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.category, color: Colors.orange),
                        ),
                      )
                    : Container(
                        width: 54,
                        height: 54,
                        decoration: BoxDecoration(
                          color: Colors.orange.withOpacity(0.2),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.category, color: Colors.orange),
                      ),
            const SizedBox(height: 8),
            Text(
              name,
              style: const TextStyle(
                  fontSize: 11,
                  color: Color(0xFF666666),
                  fontFamily: 'Quicksand',
                  fontWeight: FontWeight.bold),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

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
            // Lọc bỏ những sản phẩm đã có trong danh sách để tránh trùng lặp
            final existingIds = _products.map((p) => p.productId).toSet();
            final uniqueNewProducts = newProducts.where((p) => !existingIds.contains(p.productId)).toList();
            
            if (uniqueNewProducts.isNotEmpty) {
              _products.addAll(uniqueNewProducts);
            }

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
    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          // 1. DECORATIVE BLOBS (Restored with Heavy Blur like Sample)
          Positioned(
            top: -150,
            right: -100,
            child: ImageFiltered(
              imageFilter: ImageFilter.blur(sigmaX: 80, sigmaY: 80),
              child: Container(
                width: 450,
                height: 450,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      const Color(0xFFFFB86B).withOpacity(0.35),
                      const Color(0xFFFFB86B).withOpacity(0),
                    ],
                  ),
                ),
              ),
            ),
          ),
          Positioned(
            top: 150,
            left: -150,
            child: ImageFiltered(
              imageFilter: ImageFilter.blur(sigmaX: 100, sigmaY: 100),
              child: Container(
                width: 550,
                height: 550,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      const Color(0xFFFB7C7F).withOpacity(0.25),
                      const Color(0xFFFB7C7F).withOpacity(0),
                    ],
                  ),
                ),
              ),
            ),
          ),
          Positioned(
            bottom: 50,
            right: -150,
            child: ImageFiltered(
              imageFilter: ImageFilter.blur(sigmaX: 80, sigmaY: 80),
              child: Container(
                width: 450,
                height: 450,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      const Color(0xFFFFCC80).withOpacity(0.2),
                      const Color(0xFFFFCC80).withOpacity(0),
                    ],
                  ),
                ),
              ),
            ),
          ),

          // 2. SCROLLABLE CONTENT
          RefreshIndicator(
            onRefresh: () async {
              _fetchLocation();
              _loadCategories();
              _loadRecommendedProducts();
              await _loadProducts(isRefresh: true);
            },
            child: CustomScrollView(
              slivers: [
                SliverToBoxAdapter(
                  child: Column(
                    children: [
                      // 1. Top Bar
                      Padding(
                        padding: EdgeInsets.only(
                          left: 20,
                          right: 20,
                          top: MediaQuery.of(context).padding.top + 15,
                          bottom: 0,
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                               children: [
                             GestureDetector(
                               onTap: widget.onMenuTap,
                               child: const Icon(HeroiconsOutline.bars3BottomLeft, color: Colors.black, size: 28),
                             ),
                                 const SizedBox(width: 8),
                                 const Text(
                                   "Temo",
                                   style: TextStyle(
                                     fontSize: 24,
                                     fontWeight: FontWeight.bold,
                                     color: Color(0xFFFFB86B),
                                     fontFamily: 'Quicksand',
                                   ),
                                 ),
                               ],
                            ),
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                GestureDetector(
                                  onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const SavedProductsScreen())),
                                  child: _buildCircleIcon('assets/images/Iconluu.svg'),
                                ),
                                const SizedBox(width: 16),
                                GestureDetector(
                                  onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const NotificationScreen())),
                                  child: ValueListenableBuilder<int>(
                                    valueListenable: NotificationService.unreadCountNotifier,
                                    builder: (context, count, child) {
                                      return Badge(
                                        isLabelVisible: count > 0,
                                        backgroundColor: Colors.red,
                                        smallSize: 8,
                                        largeSize: 8,
                                        padding: EdgeInsets.zero,
                                        child: SvgPicture.asset('assets/images/Iconbell.svg', width: 24, height: 24),
                                      );
                                    },
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),

                      // Search Bar (Strict Figma: Radius 50, Border 1.5, 25% Black)
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          height: 52,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(50),
                            gradient: _searchFocusNode.hasFocus 
                              ? const LinearGradient(colors: [Color(0xFFFFB86A), Color(0xFFFB7C7F)])
                              : null,
                          ),
                          child: Container(
                            margin: _searchFocusNode.hasFocus ? const EdgeInsets.all(1.5) : EdgeInsets.zero,
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(50),
                            ),
                            child: Row(
                              children: [
                                const SizedBox(width: 16),
                                Icon(HeroiconsOutline.magnifyingGlass, color: Colors.grey[500], size: 20),
                                const SizedBox(width: 12),
                                 Expanded(
                                  child: TextField(
                                    controller: _searchController,
                                    focusNode: _searchFocusNode,
                                    onChanged: _onSearchChanged,
                                    onSubmitted: (value) {
                                      setState(() => _suggestions = []);
                                      if (value.trim().isNotEmpty) {
                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (context) => SearchResultScreen(keyword: value.trim()),
                                          ),
                                        );
                                      }
                                    },
                                    decoration: InputDecoration(
                                      hintText: _searchHints[_currentHintIndex],
                                      hintStyle: GoogleFonts.quicksand(
                                        color: Colors.grey[400],
                                        fontSize: 15,
                                        fontWeight: FontWeight.w700,
                                      ),
                                      border: InputBorder.none,
                                      isDense: true,
                                    ),
                                  ),
                                ),
                                IconButton(
                                  icon: Icon(HeroiconsOutline.viewfinderCircle, color: Colors.grey[500], size: 24),
                                  onPressed: () {
                                    // Placeholder for future Camera/Scanner search
                                  },
                                ),
                                const SizedBox(width: 2),
                              ],
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 5),
                      // Suggestions Overlay
                      if (_searchController.text.trim().isNotEmpty && _searchFocusNode.hasFocus)
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 20),
                          child: Container(
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(15),
                              boxShadow: [
                                BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 10, offset: const Offset(0, 5))
                              ],
                            ),
                            child: ListView.builder(
                              shrinkWrap: true,
                              padding: EdgeInsets.zero,
                              itemCount: _suggestions.length + 1, // +1 cho tùy chọn AI
                              itemBuilder: (context, index) {
                                if (index == _suggestions.length) {
                                  // Dòng cuối cùng: Tìm kiếm bằng AI
                                  return ListTile(
                                    dense: true,
                                    leading: const Icon(Icons.auto_awesome, size: 18, color: Color(0xFFFFB86A)),
                                    title: Text("Tìm '${_searchController.text}' bằng AI... ->", 
                                      style: const TextStyle(
                                        fontFamily: 'Quicksand', 
                                        fontSize: 13, 
                                        fontWeight: FontWeight.w800, 
                                        color: Color(0xFFFFB86A)
                                      )),
                                    onTap: () {
                                      final query = _searchController.text;
                                      setState(() => _suggestions = []);
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (context) => SearchResultScreen(keyword: query),
                                        ),
                                      );
                                    },
                                  );
                                }
                                return ListTile(
                                  dense: true,
                                  leading: const Icon(Icons.history, size: 18, color: Colors.grey),
                                  title: Text(_suggestions[index], style: const TextStyle(fontFamily: 'Quicksand', fontSize: 13)),
                                  onTap: () {
                                    final selected = _suggestions[index];
                                    _searchController.text = selected;
                                    setState(() => _suggestions = []);
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) => SearchResultScreen(keyword: selected),
                                      ),
                                    );
                                  },
                                );
                              },
                            ),
                          ),
                        ),
                      const SizedBox(height: 10),

                      // Categories List
                      Container(
                        height: 110,
                        child: _isCategoriesLoading 
                          ? ListView.builder(
                              scrollDirection: Axis.horizontal,
                              padding: const EdgeInsets.symmetric(horizontal: 10),
                              itemCount: 5,
                              itemBuilder: (context, index) => const CategorySkeleton(),
                            )
                          : ListView.builder(
                          scrollDirection: Axis.horizontal,
                          padding: const EdgeInsets.symmetric(horizontal: 10),
                          itemCount: _categories.length + 1,
                          itemBuilder: (context, index) {
                            if (index == _categories.length) {
                              return _buildCategoryItem({
                                'id': 'all',
                                'name': 'Tất cả',
                              });
                            }
                            final cat = _categories[index];
                            return _buildCategoryItem(cat);
                          },
                        ),
                      ),
                      const SizedBox(height: 10),
                    ],
                  ),
                ),

                if (_recommendedProducts.isNotEmpty || _isRecommendedLoading)
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.only(left: 16, right: 16, top: 10, bottom: 12),
                      child: Row(
                        children: [
                          const Text(
                            "Recommended",
                            style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                                color: Color(0xFF333333),
                                fontFamily: 'Quicksand'
                            )
                          ),
                          const SizedBox(width: 8),
                          const Icon(HeroiconsSolid.arrowTrendingUp, color: Color(0xFFFFB86B), size: 18),
                        ],
                      ),
                    ),
                  ),
                if (_recommendedProducts.isNotEmpty || _isRecommendedLoading)
                  SliverToBoxAdapter(
                    child: Container(
                      height: 380, margin: const EdgeInsets.only(bottom: 20, top: 10),
                      child: _isRecommendedLoading
                        ? ListView.separated(
                            padding: const EdgeInsets.symmetric(horizontal: 20),
                            scrollDirection: Axis.horizontal,
                            itemCount: 3,
                            separatorBuilder: (_, __) => const SizedBox(width: 16),
                            itemBuilder: (context, index) => const RecommendedProductSkeleton(),
                          )
                        : ListView.separated(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        scrollDirection: Axis.horizontal,
                        itemCount: _recommendedProducts.length + 1,
                        separatorBuilder: (_, __) => const SizedBox(width: 16),
                        itemBuilder: (context, index) {
                          if (index == _recommendedProducts.length) {
                            return GestureDetector(
                              onTap: () {
                                smoothPush(
                                  context,
                                  CategoryProductsScreen(
                                    category: {'categoryId': 'all', 'categoryName': 'Tất cả'},
                                  ),
                                );
                              },
                              child: Container(
                                width: 140,
                                decoration: BoxDecoration(
                                  color: const Color(0xFFFFF8F1),
                                  borderRadius: BorderRadius.circular(30),
                                  border: Border.all(color: const Color(0xFFFFB86A).withOpacity(0.3)),
                                ),
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Container(
                                      width: 48,
                                      height: 48,
                                      decoration: BoxDecoration(
                                        color: Colors.white,
                                        shape: BoxShape.circle,
                                        boxShadow: [
                                          BoxShadow(
                                            color: const Color(0xFFFFB86A).withOpacity(0.2),
                                            blurRadius: 8,
                                            offset: const Offset(0, 4),
                                          ),
                                        ],
                                      ),
                                      child: const Icon(HeroiconsOutline.arrowRight, color: Color(0xFFFFB86A)),
                                    ),
                                    const SizedBox(height: 12),
                                    const Text(
                                      "Xem tất cả",
                                      style: TextStyle(
                                        fontFamily: 'Quicksand',
                                        fontSize: 15,
                                        fontWeight: FontWeight.bold,
                                        color: Color(0xFFFFB86A),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          }
                          
                          final product = _recommendedProducts[index];
                          String imageUrl = product.productMedia.isNotEmpty ? product.productMedia[0] : '';
                          if (imageUrl.startsWith('image:')) imageUrl = imageUrl.substring(6).trim();

                          final String formattedPrice = NumberFormat.currency(
                              locale: 'vi_VN',
                              symbol: 'đ',
                              decimalDigits: 0
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
                                  boxShadow: const [
                                    BoxShadow(color: Colors.black12, blurRadius: 4, offset: Offset(0, 2))
                                  ],
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  crossAxisAlignment: CrossAxisAlignment.center,
                                  children: [
                                    const Icon(HeroiconsOutline.arrowTrendingDown, color: Color(0xFF059669), size: 10),
                                    const SizedBox(width: 2),
                                    Text(
                                      "$percent%",
                                      style: const TextStyle(
                                        fontFamily: 'Quicksand',
                                        color: Color(0xFF059669),
                                        fontSize: 10,
                                        height: 1.1,
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
                                    color: const Color(0x26000000), // 15% Shadow
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
                                          child: const Icon(Icons.image)
                                      ),
                                     ),
                                    // (Growth icon moved to section title)
                                    // Complex Gradient Overlay for top/bottom readability
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
                                                      shadows: [Shadow(color: Colors.black45, blurRadius: 8, offset: Offset(0, 4))]
                                                  ),
                                                  maxLines: 2,
                                                  overflow: TextOverflow.ellipsis
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
                                                          shadows: [Shadow(color: Colors.black26, blurRadius: 4, offset: Offset(0, 2))]
                                                      )
                                                  ),
                                                  if (discountTag != null) ...[
                                                    const SizedBox(width: 8),
                                                    discountTag!,
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
                                                          border: Border.all(color: Colors.white.withOpacity(0.2), width: 0.5)
                                                      ),
                                                      child: Row(
                                                        crossAxisAlignment: CrossAxisAlignment.center,
                                                        children: [
                                                          const Icon(HeroiconsOutline.mapPin, color: Colors.white, size: 16),
                                                          const SizedBox(width: 6),
                                                          Expanded(
                                                              child: Text(
                                                                   (() {
                                                                     if (_currentPosition != null && product.latitude != null && product.longitude != null) {
                                                                       double dist = Geolocator.distanceBetween(
                                                                         _currentPosition!.latitude, _currentPosition!.longitude,
                                                                         product.latitude!, product.longitude!
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
                                                                      fontWeight: FontWeight.w600
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
                                              const SizedBox(width: 12),
                                              GestureDetector(
                                                onTap: () {
                                                   if (product.userInfo != null) {
                                                    final userInfo = product.userInfo!;
                                                    final partner = ChatPartner(
                                                      userId: userInfo.userId,
                                                      fullName: userInfo.fullName,
                                                      avatarUrl: StringUtils.normalizeUrl(product.userInfo?.avatarUrl ?? ''),
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
                                                            border: Border.all(color: Colors.white.withOpacity(0.2), width: 0.5)
                                                        ),
                                                        alignment: Alignment.center,
                                                        child: const Icon(HeroiconsOutline.chatBubbleOvalLeft, color: Colors.white, size: 22)
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
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            "Explore more",
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                              color: Color(0xFF333333),
                              fontFamily: 'Quicksand',
                            ),
                          ),
                          Row(
                            children: [
                              Text(
                                "For you",
                                style: TextStyle(
                                  color: Colors.grey[600],
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  fontFamily: 'Quicksand',
                                ),
                              ),
                              Icon(Icons.keyboard_arrow_down, size: 18, color: Colors.grey[600]),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),

                _products.isEmpty && !_isInitialLoading
                    ? SliverToBoxAdapter(child: Center(child: Padding(padding: const EdgeInsets.only(top: 50), child: Text("Không tìm thấy sản phẩm nào.", style: TextStyle(color: Colors.grey)))))
                    : SliverPadding(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  sliver: SliverMasonryGrid.count(
                    crossAxisCount: 2, mainAxisSpacing: 10, crossAxisSpacing: 10,
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

                if (_isInitialLoading && _products.isEmpty)
                  SliverPadding(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    sliver: SliverGrid(
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        crossAxisSpacing: 12,
                        mainAxisSpacing: 12,
                        mainAxisExtent: 305,
                      ),
                      delegate: SliverChildBuilderDelegate(
                        (context, index) => const ProductCardSkeleton(),
                        childCount: 6,
                      ),
                    ),
                  ),

                const SliverToBoxAdapter(child: SizedBox(height: 80)),
              ],
            ),
          ),
        ],
      ),
    ),
   );
  }

  Widget _buildCircleIcon(String assetPath) {
    return SvgPicture.asset(
      assetPath,
      width: 24,
      height: 24,
      colorFilter: const ColorFilter.mode(Color(0xFF333333), BlendMode.srcIn),
    );
  }
}
