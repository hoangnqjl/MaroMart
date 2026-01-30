
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
import 'package:maromart/components/AppDrawer.dart'; // Add import
import 'package:maromart/components/ModernLoader.dart';
import '../Search/SearchResult.dart';
import 'package:maromart/models/User/User.dart';

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
    onFilterApplied: (categoryId, province, ward) => updateFilter(
      categoryId: categoryId,
      province: province,
      ward: ward,
    ),
  );

  final List<Product> _products = [];
  bool _isInitialLoading = true;
  bool _isLoadingMore = false;
  bool _hasMore = true;
  int _currentPage = 1;
  final int _limit = 10;
  bool _isFlashCardMode = true;

  String? _filterCategoryId;
  String? _filterProvince;
  String? _filterWard;
  String _currentLocation = "đang tải...";

  final List<Map<String, dynamic>> _quickCategories = [
    {'id': '', 'name': 'Tất cả', 'icon': HeroiconsOutline.squares2x2, 'color': Colors.blue},
    {'id': 'fashion', 'name': 'Thời trang', 'icon': HeroiconsOutline.shoppingBag, 'color': Colors.pink},
    {'id': 'technology', 'name': 'Công nghệ', 'icon': HeroiconsOutline.computerDesktop, 'color': Colors.purple},
    {'id': 'furniture', 'name': 'Nội thất', 'icon': HeroiconsOutline.home, 'color': Colors.brown},
    {'id': 'service', 'name': 'Dịch vụ', 'icon': HeroiconsOutline.wrenchScrewdriver, 'color': Colors.teal},
    {'id': 'kids', 'name': 'Mẹ & Bé', 'icon': HeroiconsOutline.faceSmile, 'color': Colors.yellow},
  ];

  @override
  void initState() {
    super.initState();
    _fetchLocation();
    _loadProducts(isRefresh: true);
    _productService.productChangeNotifier.addListener(_onProductChanged);
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
    _productService.productChangeNotifier.removeListener(_onProductChanged);
    super.dispose();
  }

  void _showTestingFeature() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text("Tính năng đang thử nghiệm", style: TextStyle(fontFamily: 'QuickSand')),
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
       Navigator.of(context).pushNamedAndRemoveUntil('/signin', (route) => false);
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
      key: _scaffoldKey,
      backgroundColor: Colors.white,
      endDrawer: AppDrawer(user: widget.user),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () async {
            _fetchLocation();
            await _loadProducts(isRefresh: true);
          },
          child: CustomScrollView(
            slivers: [
              // 1. Top Header: Avatar + Notification
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 22,
                        backgroundImage: widget.user != null && (widget.user!.avatarUrl ?? "").isNotEmpty
                            ? NetworkImage(widget.user!.avatarUrl!)
                            : const NetworkImage("https://i.pravatar.cc/150?img=12") as ImageProvider, // Fallback/Demo
                      ),
                      const SizedBox(width: 12),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text("Xin chào 👋", style: TextStyle(color: Colors.grey, fontSize: 13)),
                          Text(
                            widget.user?.fullName ?? "Khách hàng",
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                          ),
                        ],
                      ),
                      const Spacer(),
                      GestureDetector(
                        onTap: () => _scaffoldKey.currentState?.openEndDrawer(),
                        child: Container(
                          padding: const EdgeInsets.all(10),
                          child: const Icon(HeroiconsOutline.bars3, size: 24, color: Colors.black),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // 2. Large Title
              const SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                  child: Text(
                    "Bạn muốn tìm gì\nhôm nay?",
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.w800,
                      height: 1.2,
                      letterSpacing: -0.5,
                      fontFamily: "Outfit", // Request modern font if available, else standard
                    ),
                  ),
                ),
              ),

              // 3. Search Bar (Pinned)
              SliverPersistentHeader(
                pinned: true,
                delegate: _StickySearchBarDelegate(
                  minHeight: 80,
                  maxHeight: 80,
                  child: ClipRRect(
                    child: BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.4),
                          boxShadow: const [], // Force remove shadow
                        ),
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                    child: Row(
                      children: [
                        Expanded(
                          child: Container(
                            height: 50,
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            decoration: BoxDecoration(
                              color: Colors.grey[100],
                              borderRadius: BorderRadius.circular(16),
                              boxShadow: [], // Force remove shadow
                            ),
                            child: Row(
                              children: [
                                const Icon(HeroiconsOutline.magnifyingGlass, color: Colors.grey),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: TextField(
                                    onSubmitted: (value) {
                                      if (value.trim().isNotEmpty) {
                                        Navigator.push(context, MaterialPageRoute(builder: (context) => SearchResultScreen(keyword: value.trim())));
                                      }
                                    },
                                    decoration: const InputDecoration(
                                      hintText: "Tìm kiếm sản phẩm...",
                                      border: InputBorder.none,
                                      hintStyle: TextStyle(color: Colors.grey),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        InkWell(
                          onTap: () => _filterOverlay.toggle(context),
                          child: CompositedTransformTarget(
                            link: _filterOverlay.layerLink,
                            child: Container(
                              height: 50, width: 50,
                                decoration: BoxDecoration(
                                  color: AppColors.primary,
                                  borderRadius: BorderRadius.circular(16),
                                  boxShadow: [], // Force remove shadow
                                ),
                              child: const Icon(HeroiconsOutline.adjustmentsHorizontal, color: Colors.white),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),

              // 4. Banner
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 10, 20, 20),
                  child: Container(
                    height: 180,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(24),
                      image: const DecorationImage(
                        image: AssetImage("assets/images/hero.png"), // Use existing assets
                        fit: BoxFit.cover,
                      ),
                    ),
                    child: Stack(
                      children: [
                        Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(24),
                            gradient: const LinearGradient(
                              begin: Alignment.centerLeft,
                              end: Alignment.centerRight,
                              colors: [Colors.black87, Colors.transparent],
                            ),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.all(24.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Text("Khám phá\nBộ sưu tập mới", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 20)),
                              const SizedBox(height: 12),
                              ElevatedButton(
                                onPressed: () {},
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.white,
                                  foregroundColor: Colors.black,
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                                ),
                                child: const Text("Xem ngay", style: TextStyle(fontWeight: FontWeight.bold)),
                              )
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              // 5. Categories Header + View Toggle
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text("Danh mục", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                      GestureDetector(
                         onTap: () => setState(() => _isFlashCardMode = !_isFlashCardMode),
                         child: Row(
                           children: [
                             Text(_isFlashCardMode ? "Lưới" : "Thẻ", style: const TextStyle(color: AppColors.primary)),
                             const SizedBox(width: 4),
                             Icon(_isFlashCardMode ? Icons.grid_view_rounded : Icons.view_agenda_rounded, color: AppColors.primary, size: 20),
                           ],
                         ),
                      ),
                    ],
                  ),
                ),
              ),

              // 6. Categories List (Horizontal Cards)
              SliverToBoxAdapter(
                child: Container(
                  height: 60,
                  margin: const EdgeInsets.only(bottom: 20),
                  child: ListView.separated(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    scrollDirection: Axis.horizontal,
                    itemCount: _quickCategories.length,
                    separatorBuilder: (_, __) => const SizedBox(width: 12),
                    itemBuilder: (context, index) {
                      final cat = _quickCategories[index];
                      final isSelected = _filterCategoryId == cat['id'];
                      return GestureDetector(
                        onTap: () => updateFilter(categoryId: cat['id']),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          decoration: BoxDecoration(
                            color: isSelected ? AppColors.primary : Colors.white,
                            borderRadius: BorderRadius.circular(30),
                            border: Border.all(color: isSelected ? Colors.transparent : Colors.grey[200]!),
                            boxShadow: isSelected ? [BoxShadow(color: AppColors.primary.withOpacity(0.3), blurRadius: 8, offset: const Offset(0, 4))] : [],
                          ),
                          child: Row(
                            children: [
                              Icon(cat['icon'], color: isSelected ? Colors.white : Colors.grey, size: 20),
                              const SizedBox(width: 8),
                              Text(cat['name'], style: TextStyle(color: isSelected ? Colors.white : Colors.black87, fontWeight: FontWeight.bold)),
                            ],
                          ),
                        ),
                      );
                    },
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
                              Icon(HeroiconsOutline.faceFrown, size: 48, color: Colors.grey[300]),
                              const SizedBox(height: 10),
                              const Text("Không tìm thấy sản phẩm nào.", style: TextStyle(color: Colors.grey)),
                            ],
                          ),
                        ),
                      ),
                    )
                  : _buildSliverProductList(),

               if (_isLoadingMore)
                const SliverToBoxAdapter(child: Padding(padding: EdgeInsets.all(20), child: Center(child: ModernLoader()))),

               const SliverToBoxAdapter(child: SizedBox(height: 80)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDrawerItem(IconData icon, String title, VoidCallback onTap, {bool isDestructive = false}) {
    return ListTile(
      leading: Icon(icon, color: isDestructive ? Colors.red : Colors.black87),
      title: Text(title, style: TextStyle(color: isDestructive ? Colors.red : Colors.black87, fontWeight: FontWeight.w600)),
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 4),
    );
  }

  Widget _buildSliverProductList() {
    if (_isFlashCardMode) {
      return SliverList(
        delegate: SliverChildBuilderDelegate(
          (context, index) {
            if (index == _products.length && _hasMore) {
              WidgetsBinding.instance.addPostFrameCallback((_) => _loadProducts(isRefresh: false));
              return const SizedBox();
            }
            if (index >= _products.length) return null;
            // Simplified FlashCard Height logic
             final double cardHeight = MediaQuery.of(context).size.height * 0.6; // Approximate nice height
            return Padding(
              padding: const EdgeInsets.only(bottom: 20, left: 20, right: 20),
              child: SizedBox(height: cardHeight, child: Post(product: _products[index])),
            );
          },
          childCount: _products.length + (_hasMore ? 1 : 0),
        ),
      );
    } else {
      return SliverPadding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        sliver: SliverGrid(
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            childAspectRatio: 0.7,
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
          ),
          delegate: SliverChildBuilderDelegate(
            (context, index) {
              if (index == _products.length && _hasMore) {
                WidgetsBinding.instance.addPostFrameCallback((_) => _loadProducts(isRefresh: false));
                return const SizedBox();
              }
              if (index >= _products.length) return null;
              return ProductGridItem(product: _products[index]);
            },
            childCount: _products.length + (_hasMore ? 1 : 0),
          ),
        ),
      );
    }
  }
}

class _StickySearchBarDelegate extends SliverPersistentHeaderDelegate {
  final double minHeight;
  final double maxHeight;
  final Widget child;

  _StickySearchBarDelegate({required this.minHeight, required this.maxHeight, required this.child});

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) => SizedBox.expand(child: child);

  @override
  double get maxExtent => maxHeight;
  @override
  double get minExtent => minHeight;
  @override
  bool shouldRebuild(covariant _StickySearchBarDelegate oldDelegate) => false;
}