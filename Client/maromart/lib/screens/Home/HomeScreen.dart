import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:heroicons_flutter/heroicons_flutter.dart';
import 'package:maromart/Colors/AppColors.dart';
import 'package:maromart/utils/constants.dart';
import 'package:maromart/screens/Setting/Setting.dart';
import 'package:maromart/services/auth_service.dart';
import 'package:maromart/components/Post.dart';
import 'package:maromart/components/ProductGridItem.dart';
import 'package:maromart/components/Filter.dart';
import 'package:maromart/models/Product/Product.dart';
import 'package:maromart/services/product_service.dart';
import 'package:maromart/services/location_service.dart';
import 'package:maromart/components/AppDrawer.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart'; // Add import
import 'package:maromart/components/ModernLoader.dart';
import '../Search/SearchResult.dart';
import 'dart:async';
import 'package:maromart/models/User/User.dart';
import 'package:maromart/screens/Notification/NotificationScreen.dart';
import 'package:maromart/screens/Home/CategoryProductsScreen.dart';

class HomeScreen extends StatefulWidget {
  final User? user;
  const HomeScreen({Key? key, this.user}) : super(key: key);

  @override
  State<StatefulWidget> createState() => HomeScreenState();
}

class HomeScreenState extends State<HomeScreen> {
  final ProductService _productService = ProductService();
  final LocationService _locationService = LocationService();
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  late final FilterOverlay _filterOverlay = FilterOverlay(
    onFilterApplied: (categoryId, province, ward) =>
        updateFilter(categoryId: categoryId, province: province, ward: ward),
  );

  final List<Product> _products = [];
  bool _isInitialLoading = true;
  bool _isLoadingMore = false;
  bool _hasMore = true;
  int _currentPage = 1;
  final int _limit = 10;
  bool _isFlashCardMode = false;

  final PageController _bannerController = PageController();
  Timer? _bannerTimer;
  int _currentBannerIndex = 0;

  final List<String> _searchHints = [
    "Bạn muốn tìm gì hôm nay?",
    "Tìm kiếm voucher...",
    "Tìm kiếm vé tham quan...",
    "Tìm kiếm sản phẩm..."
  ];
  int _currentHintIndex = 0;
  Timer? _hintTimer;

  String? _filterCategoryId;
  String? _filterProvince;
  String? _filterWard;
  String _currentLocation = "đang tải...";
  String _activeQuickFilter = "Dành cho bạn";

  final List<Map<String, dynamic>> _quickCategories = [
    {
      'id': 'auto',
      'name': 'Xe cộ',
      'image': 'assets/images/xeco.png',
    },
    {
      'id': 'furniture',
      'name': 'Nội thất',
      'image': 'assets/images/noithat.png',
    },
    {
      'id': 'technology',
      'name': 'Công nghệ',
      'image': 'assets/images/congnghe.png',
    },
    {
      'id': 'style',
      'name': 'Thời trang',
      'image': 'assets/images/thoitrang.png',
    },
    {
      'id': 'service',
      'name': 'Dịch vụ',
      'image': 'assets/images/dichvu.png',
    },
    {
      'id': 'hobby',
      'name': 'Sở thích',
      'image': 'assets/images/sothich.png',
    },
    {
      'id': 'kids',
      'name': 'Mẹ & Bé',
      'image': 'assets/images/mevabe.png',
    },
  ];

  final List<String> _trendingKeywords = [
    '#laptop',
    '#điện thoại',
    '#ô tô',
    '#đồ chơi',
  ];

  @override
  void initState() {
    super.initState();
    _fetchLocation();
    _loadProducts(isRefresh: true);
    _productService.productChangeNotifier.addListener(_onProductChanged);
    
    _bannerTimer = Timer.periodic(const Duration(seconds: 3), (Timer timer) {
      if (_bannerController.hasClients) {
        _currentBannerIndex++;
        if (_currentBannerIndex >= 4) { // Assuming 4 banners
          _currentBannerIndex = 0;
        }
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
      final loc = await _locationService.getCurrentAddress();
      if (mounted) setState(() => _currentLocation = loc ?? "Không xác định");
    } catch (e) {
      print("Location error: $e");
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

  void _showTestingFeature() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text(
          "Tính năng đang thử nghiệm",
          style: TextStyle(fontFamily: 'QuickSand'),
        ),
        backgroundColor: Colors.grey[800],
        duration: const Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  void _handleLogout() async {
    await AuthService().logout();
    if (mounted) {
      Navigator.of(
        context,
      ).pushNamedAndRemoveUntil('/signin', (route) => false);
    }
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
      bool isFiltering =
          _filterCategoryId != null ||
          _filterProvince != null ||
          _filterWard != null;
      if (isFiltering) {
        newProducts = await _productService.getProductsByFilter(
          categoryId: _filterCategoryId == '' ? null : _filterCategoryId,
          province: _filterProvince,
          ward: _filterWard,
        );
        _hasMore = false;
      } else {
        newProducts = await _productService.getProducts(
          page: _currentPage,
          limit: _limit,
        );
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
            
            // Xử lý Quick Filters
            if (!isFiltering) {
               if (_activeQuickFilter == "Mới nhất") {
                 _products.sort((a, b) => b.createdAt.compareTo(a.createdAt));
               } else if (_activeQuickFilter == "Dành cho bạn") {
                 _products.shuffle();
               }
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
      backgroundColor: Colors.grey[50], // Slightly darker background
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () async {
            _fetchLocation();
            await _loadProducts(isRefresh: true);
          },
          child: CustomScrollView(
            slivers: [
              // 1. Top Bar (AppBar)
              SliverAppBar(
                pinned: true,
                floating: true,
                backgroundColor: Colors.white,
                elevation: 0,
                titleSpacing: 16,
                automaticallyImplyLeading: false,
                title: Container(
                  height: 40,
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: AppColors.primary, width: 1.5),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        HeroiconsOutline.magnifyingGlass,
                        color: AppColors.primary,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: TextField(
                          onSubmitted: (value) {
                            if (value.trim().isNotEmpty) {
                              setState(() {
                                final keyword = '#\${value.trim()}';
                                if (!_trendingKeywords.contains(keyword)) {
                                  _trendingKeywords.insert(0, keyword);
                                }
                              });
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) =>
                                      SearchResultScreen(keyword: value.trim()),
                                ),
                              );
                            }
                          },
                          decoration: InputDecoration(
                            hintText: _searchHints[_currentHintIndex],
                            border: InputBorder.none,
                            hintStyle: const TextStyle(
                              color: Colors.grey, // Updated color here
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                            ),
                            contentPadding: const EdgeInsets.only(bottom: 12),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                actions: [
                  IconButton(
                    icon: const Icon(
                      HeroiconsOutline.bell,
                      color: Colors.black87,
                      size: 26,
                    ),
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const NotificationScreen(),
                        ),
                      );
                    },
                  ),
                  const SizedBox(width: 4),
                  GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const Setting(),
                        ),
                      );
                    },
                    child: CircleAvatar(
                      radius: 16,
                      backgroundColor: Colors.grey[200],
                      backgroundImage: widget.user?.avatarUrl != null
                          ? NetworkImage(widget.user!.avatarUrl!)
                          : null,
                      child: widget.user?.avatarUrl == null
                          ? const Icon(HeroiconsOutline.user, size: 20, color: Colors.black54) 
                          : null,
                    ),
                  ),
                  const SizedBox(width: 16),
                ],
              ),

              // 2. Horizontal Image List (Banners)
              SliverToBoxAdapter(
                child: Container(
                  height: 180, // Increased banner height
                  child: PageView.builder(
                    controller: _bannerController,
                    onPageChanged: (int index) {
                      setState(() {
                         _currentBannerIndex = index;
                      });
                    },
                    itemCount: 4,
                    itemBuilder: (context, index) {
                      return Container(
                        width: MediaQuery.of(context).size.width,
                        decoration: BoxDecoration(
                          image: DecorationImage(
                            image: AssetImage("assets/images/banner${index + 1}.png"),
                            fit: BoxFit.cover,
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),

              // 3. Horizontal Categories
              SliverToBoxAdapter(
                child: Container(
                  height: 90, // Set fixed height for the horizontal list
                  margin: EdgeInsets.zero,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        AppColors.primary.withOpacity(0.15),
                        Colors.white,
                      ],
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      stops: const [0.0, 1.0],
                    ),
                  ),
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 10),
                    itemCount: _quickCategories.length,
                    itemBuilder: (context, index) {
                      final cat = _quickCategories[index];
                      final isSelected = _filterCategoryId == cat['id'];
                      return GestureDetector(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => CategoryProductsScreen(category: cat),
                            ),
                          );
                        },
                        child: Container(
                          width: 72, // Reduced width for tighter spacing
                          margin: const EdgeInsets.only(right: 6), // Reduced margin
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                                Image.asset(
                                  cat['image'],
                                  width: 44,
                                  height: 44,
                                  fit: BoxFit.contain,
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  cat['name'],
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: isSelected ? AppColors.primary : Colors.black87,
                                    fontWeight: isSelected ? FontWeight.w900 : FontWeight.bold, // Bolder text
                                  ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),

              // 3.5 Trending Keywords
              if (_trendingKeywords.isNotEmpty)
                SliverToBoxAdapter(
                  child: Container(
                    height: 52, // height 36 + padding 8 * 2
                    margin: const EdgeInsets.only(bottom: 20),
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    decoration: BoxDecoration(
                      border: Border(
                        top: BorderSide(color: Colors.grey[200]!, width: 1),
                        bottom: BorderSide(color: Colors.grey[200]!, width: 1),
                      ),
                    ),
                    child: ListView.separated(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      scrollDirection: Axis.horizontal,
                      itemCount: _trendingKeywords.length,
                      separatorBuilder: (_, __) => const SizedBox(width: 8),
                      itemBuilder: (context, index) {
                        return GestureDetector(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => SearchResultScreen(
                                  keyword: _trendingKeywords[index].replaceAll('#', ''),
                                ),
                              ),
                            );
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            decoration: BoxDecoration(
                              color: Colors.black87,
                              borderRadius: BorderRadius.circular(18),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  _trendingKeywords[index],
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                const SizedBox(width: 4),
                                const Icon(
                                  Icons.arrow_right_alt,
                                  color: Colors.white,
                                  size: 14,
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),

              // 4. Top Rated Sellers Header
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.only(
                    left: 20,
                    right: 20,
                    top: 0,
                    bottom: 10,
                  ),
                  child: Text(
                    "Người bán được đánh giá cao",
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                  ),
                ),
              ),

              // 5. Top Rated Sellers List
              SliverToBoxAdapter(
                child: Container(
                  height: 150,
                  margin: const EdgeInsets.only(bottom: 20),
                  child: ListView.separated(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    scrollDirection: Axis.horizontal,
                    itemCount: 5,
                    separatorBuilder: (_, __) => const SizedBox(width: 16),
                    itemBuilder: (context, index) {
                      return Container(
                        width: 140,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.grey[200]!),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: ClipRRect(
                                borderRadius: const BorderRadius.only(
                                  topLeft: Radius.circular(12),
                                  topRight: Radius.circular(12),
                                ),
                                child: Image.asset(
                                  'assets/images/background.jpg',
                                  fit: BoxFit.cover,
                                  width: double.infinity,
                                ),
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 8.0),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: [
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        const Text(
                                          "L'FEMME",
                                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                        const SizedBox(height: 2),
                                        Text(
                                          "Thương hiệu xuất sắc 2024",
                                          style: TextStyle(color: Colors.red[300], fontSize: 10),
                                          maxLines: 2,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  const CircleAvatar(
                                    radius: 18,
                                    backgroundColor: Colors.black,
                                    child: Text(
                                      "ESTHER",
                                      style: TextStyle(color: Colors.white, fontSize: 7, fontWeight: FontWeight.bold),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
              ),

              // 5.5 + 6 Combined: Quick Filters and View Toggle
              SliverToBoxAdapter(
                child: Container(
                  height: 40,
                  margin: const EdgeInsets.only(bottom: 10, top: 10),
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Row(
                    children: [
                      // Quick Filters (Single Button Toggle)
                      Expanded(
                        child: Row(
                          children: [
                            GestureDetector(
                              onTap: () {
                                setState(() {
                                  _activeQuickFilter = _activeQuickFilter == "Dành cho bạn" ? "Mới nhất" : "Dành cho bạn";
                                });
                                _loadProducts(isRefresh: true);
                              },
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                decoration: BoxDecoration(
                                  color: AppColors.primary.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(color: AppColors.primary, width: 1),
                                ),
                                child: Row(
                                  children: [
                                    Text(
                                      _activeQuickFilter,
                                      style: const TextStyle(color: AppColors.primary, fontSize: 13, fontWeight: FontWeight.w600),
                                    ),
                                    const SizedBox(width: 4),
                                    const Icon(
                                      HeroiconsOutline.chevronUpDown,
                                      color: AppColors.primary,
                                      size: 16,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      
                      // View Toggle & Filter
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          GestureDetector(
                            onTap: () => _filterOverlay.toggle(context),
                            child: CompositedTransformTarget(
                              link: _filterOverlay.layerLink,
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(
                                  color: AppColors.primary.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Row(
                                  children: [
                                    const Text("Lọc", style: TextStyle(color: AppColors.primary, fontSize: 13)),
                                    const SizedBox(width: 4),
                                    const Icon(HeroiconsOutline.adjustmentsHorizontal, color: AppColors.primary, size: 16),
                                  ],
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          GestureDetector(
                            onTap: () => setState(
                              () => _isFlashCardMode = !_isFlashCardMode,
                            ),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: AppColors.primary.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Row(
                                children: [
                                  Text(
                                    _isFlashCardMode ? "Lưới" : "Thẻ",
                                    style: const TextStyle(color: AppColors.primary, fontSize: 13),
                                  ),
                                  const SizedBox(width: 4),
                                  Icon(
                                    _isFlashCardMode
                                        ? Icons.grid_view_rounded
                                        : Icons.view_agenda_rounded,
                                    color: AppColors.primary,
                                    size: 16,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),

              // 7. Product List (Grid/List)
              _products.isEmpty && !_isInitialLoading
                  ? SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.only(top: 50),
                        child: Center(
                          child: Column(
                            children: [
                              Icon(
                                HeroiconsOutline.faceFrown,
                                size: 48,
                                color: Colors.grey[300],
                              ),
                              const SizedBox(height: 10),
                              const Text(
                                "Không tìm thấy sản phẩm nào.",
                                style: TextStyle(color: Colors.grey),
                              ),
                            ],
                          ),
                        ),
                      ),
                    )
                  : _buildSliverProductList(),

              if (_isLoadingMore)
                const SliverToBoxAdapter(
                  child: Padding(
                    padding: EdgeInsets.all(20),
                    child: Center(child: ModernLoader()),
                  ),
                ),

              const SliverToBoxAdapter(child: SizedBox(height: 80)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDrawerItem(
    IconData icon,
    String title,
    VoidCallback onTap, {
    bool isDestructive = false,
  }) {
    return ListTile(
      leading: Icon(icon, color: isDestructive ? Colors.red : Colors.black87),
      title: Text(
        title,
        style: TextStyle(
          color: isDestructive ? Colors.red : Colors.black87,
          fontWeight: FontWeight.w600,
        ),
      ),
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 4),
    );
  }

  Widget _buildSliverProductList() {
    if (_isFlashCardMode) {
      return SliverList(
        delegate: SliverChildBuilderDelegate((context, index) {
          if (index == _products.length && _hasMore) {
            WidgetsBinding.instance.addPostFrameCallback(
              (_) => _loadProducts(isRefresh: false),
            );
            return const SizedBox();
          }
          if (index >= _products.length) return null;
          // Simplified FlashCard Height logic
          final double cardHeight =
              MediaQuery.of(context).size.height *
              0.6; // Approximate nice height
          return Padding(
            padding: const EdgeInsets.only(bottom: 20, left: 20, right: 20),
            child: SizedBox(
              height: cardHeight,
              child: Post(product: _products[index]),
            ),
          );
        }, childCount: _products.length + (_hasMore ? 1 : 0)),
      );
    } else {
      return SliverPadding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        sliver: SliverMasonryGrid.count(
          crossAxisCount: 2,
          mainAxisSpacing: 16,
          crossAxisSpacing: 16,
          childCount: _products.length + (_hasMore ? 1 : 0),
          itemBuilder: (context, index) {
            if (index == _products.length && _hasMore) {
              WidgetsBinding.instance.addPostFrameCallback(
                (_) => _loadProducts(isRefresh: false),
              );
              return const SizedBox();
            }
            if (index >= _products.length) return const SizedBox();
            return ProductGridItem(product: _products[index]);
          },
        ),
      );
    }
  }
}

class _StickySearchBarDelegate extends SliverPersistentHeaderDelegate {
  final double minHeight;
  final double maxHeight;
  final Widget child;

  _StickySearchBarDelegate({
    required this.minHeight,
    required this.maxHeight,
    required this.child,
  });

  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) => SizedBox.expand(child: child);

  @override
  double get maxExtent => maxHeight;
  @override
  double get minExtent => minHeight;
  @override
  bool shouldRebuild(covariant _StickySearchBarDelegate oldDelegate) => false;
}
