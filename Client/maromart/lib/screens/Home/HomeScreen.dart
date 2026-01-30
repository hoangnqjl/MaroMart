import 'package:flutter/material.dart';
import 'package:heroicons_flutter/heroicons_flutter.dart';
import 'package:maromart/Colors/AppColors.dart';
import 'package:maromart/components/Post.dart';
import 'package:maromart/components/ProductGridItem.dart';
import 'package:maromart/components/Filter.dart';
import 'package:maromart/models/Product/Product.dart';
import 'package:maromart/services/product_service.dart';
import 'package:maromart/services/location_service.dart'; // 1. Import LocationService
import 'package:maromart/components/ModernLoader.dart';
import '../Search/SearchResult.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  State<StatefulWidget> createState() => HomeScreenState();
}

class HomeScreenState extends State<HomeScreen> {
  final ProductService _productService = ProductService();
  final LocationService _locationService = LocationService(); // 2. Khởi tạo Service

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

  // 3. Biến lưu địa điểm (Mặc định là "bạn" hoặc địa danh mẫu)
  String _currentLocation = "bạn";

  final List<Map<String, dynamic>> _quickCategories = [
    {'id': '', 'name': 'All', 'icon': HeroiconsOutline.squares2x2, 'color': Colors.blue},
    {'id': 'auto', 'name': 'Auto', 'icon': HeroiconsOutline.truck, 'color': Colors.orange},
    {'id': 'furniture', 'name': 'Furniture', 'icon': HeroiconsOutline.home, 'color': Colors.brown},
    {'id': 'technology', 'name': 'Tech', 'icon': HeroiconsOutline.computerDesktop, 'color': Colors.purple},
    {'id': 'fashion', 'name': 'Fashion', 'icon': HeroiconsOutline.shoppingBag, 'color': Colors.pink},
    {'id': 'service', 'name': 'Service', 'icon': HeroiconsOutline.wrenchScrewdriver, 'color': Colors.teal},
    {'id': 'hobby', 'name': 'Hobby', 'icon': HeroiconsOutline.puzzlePiece, 'color': Colors.red},
    {'id': 'kids', 'name': 'Kids', 'icon': HeroiconsOutline.faceSmile, 'color': Colors.yellow},
  ];

  @override
  void initState() {
    super.initState();
    _fetchLocation(); // 4. Gọi hàm lấy vị trí ngay khi mở màn hình
    _loadProducts(isRefresh: true);
    _productService.productChangeNotifier.addListener(_onProductChanged);
  }

  // 5. Hàm xử lý lấy và rút gọn địa chỉ
  Future<void> _fetchLocation() async {
    final location = await _locationService.getCurrentAddress();
    if (mounted && location != null && location.isNotEmpty) {
      // Chỉ lấy phần đầu tiên của địa chỉ (VD: "An Khê, Đà Nẵng" -> "An Khê")
      // để hiển thị ngắn gọn, đẹp mắt trên Header
      String shortLocation = location.split(',')[0].trim();
      setState(() {
        _currentLocation = shortLocation;
      });
    }
  }

  @override
  void dispose() {
    _productService.productChangeNotifier.removeListener(_onProductChanged);
    super.dispose();
  }

  void reload() {
    _loadProducts(isRefresh: true);
    _fetchLocation(); // Reload lại cả vị trí nếu cần
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
    final double topPadding = 110.0;
    final double searchBarHeight = 55.0;
    final double categoriesHeight = 90.0;
    final double heroImageHeight = 240.0;
    final double maxHeaderHeight = topPadding + heroImageHeight + categoriesHeight * 0.5;
    final double minHeaderHeight = topPadding + searchBarHeight + 20;

    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: RefreshIndicator(
        onRefresh: () async {
          _fetchLocation(); // Refresh location
          await _loadProducts(isRefresh: true);
        },
        child: CustomScrollView(
          slivers: [
            SliverPersistentHeader(
              pinned: true,
              delegate: _HomeCollapsingDelegate(
                minHeight: minHeaderHeight,
                maxHeight: 400,
                topPadding: topPadding,
                searchBarHeight: searchBarHeight,
                categoriesHeight: categoriesHeight,
                filterLink: _filterOverlay.layerLink,
                onFilterTap: () => _filterOverlay.toggle(context),
                categories: _quickCategories,
                selectedCatId: _filterCategoryId,
                onCategoryTap: (id) => updateFilter(categoryId: id),
                isFlashCardMode: _isFlashCardMode,
                onViewModeTap: () => setState(() => _isFlashCardMode = !_isFlashCardMode),

                // 6. Truyền biến vị trí xuống Delegate
                locationName: _currentLocation,
              ),
            ),

            const SliverToBoxAdapter(child: SizedBox(height: 15)),

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
    );
  }

  Widget _buildSliverProductList() {
    if (_isFlashCardMode) {
      return SliverList(
        delegate: SliverChildBuilderDelegate(
              (context, index) {
            if (index == _products.length && _hasMore) { _loadProducts(isRefresh: false); return const SizedBox(); }
            if (index >= _products.length) return null;
            return Padding(
              padding: const EdgeInsets.only(bottom: 20, left: 16, right: 16),
              child: SizedBox(height: MediaQuery.of(context).size.width * 1.05, child: Post(product: _products[index])),
            );
          },
          childCount: _products.length + (_hasMore ? 1 : 0),
        ),
      );
    } else {
      return SliverPadding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        sliver: SliverGrid(
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 2, childAspectRatio: 0.68, crossAxisSpacing: 12, mainAxisSpacing: 12),
          delegate: SliverChildBuilderDelegate(
                (context, index) {
              if (index == _products.length && _hasMore) { _loadProducts(isRefresh: false); return const SizedBox(); }
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

// --- DELEGATE ---
class _HomeCollapsingDelegate extends SliverPersistentHeaderDelegate {
  final double minHeight;
  final double maxHeight;
  final double topPadding;
  final double searchBarHeight;
  final double categoriesHeight;
  final LayerLink filterLink;
  final VoidCallback onFilterTap;
  final List<Map<String, dynamic>> categories;
  final String? selectedCatId;
  final Function(String?) onCategoryTap;
  final bool isFlashCardMode;
  final VoidCallback onViewModeTap;

  // 7. Nhận biến locationName
  final String locationName;

  _HomeCollapsingDelegate({
    required this.minHeight,
    required this.maxHeight,
    required this.topPadding,
    required this.searchBarHeight,
    required this.categoriesHeight,
    required this.filterLink,
    required this.onFilterTap,
    required this.categories,
    required this.selectedCatId,
    required this.onCategoryTap,
    required this.isFlashCardMode,
    required this.onViewModeTap,
    required this.locationName, // Required
  });

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) {
    final double scrollRange = maxHeight - minHeight;
    final double progress = (shrinkOffset / scrollRange).clamp(0.0, 1.0);
    final double heroOpacity = (1.0 - progress * 2).clamp(0.0, 1.0);
    final double currentCatHeight = (categoriesHeight * (1.0 - progress)).clamp(0.0, categoriesHeight);
    final double catOpacity = (1.0 - progress * 3).clamp(0.0, 1.0);
    final double whiteSheetHeight = searchBarHeight + 20 + currentCatHeight + 10;

    return Container(
      color: Colors.grey[50],
      child: Stack(
        children: [
          Positioned(
            top: 0, left: 0, right: 0,
            bottom: whiteSheetHeight - 30,
            child: Opacity(
              opacity: heroOpacity,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  Image.asset("assets/images/hero.png", fit: BoxFit.cover),
                  Container(decoration: BoxDecoration(gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Colors.black.withOpacity(0.0), Colors.black.withOpacity(0.2)]))),
                  Positioned(
                    top: 100, left: 20, right: 20,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // 8. Hiển thị Text động theo locationName
                        Text(
                          "Tìm đồ gia dụng\ngiá tốt tại $locationName!",
                          style: const TextStyle(
                              color: Colors.white,
                              fontSize: 22,
                              fontWeight: FontWeight.w800,
                              fontFamily: 'QuickSand',
                              height: 1.2,
                              shadows: [Shadow(offset: Offset(0, 1), blurRadius: 4, color: Colors.black45)]
                          ),
                        ),
                        const SizedBox(height: 12),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(color: Colors.orange, borderRadius: BorderRadius.circular(20), boxShadow: [BoxShadow(color: Colors.orange.withOpacity(0.4), blurRadius: 8, offset: const Offset(0, 4))]),
                          child: const Row(mainAxisSize: MainAxisSize.min, children: [Icon(Icons.monetization_on, color: Colors.white, size: 16), SizedBox(width: 5), Text("Deal Hot: 250.000 đ", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12))]),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          Positioned(
            bottom: 0, left: 0, right: 0,
            height: whiteSheetHeight,
            child: Container(
              decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.only(topLeft: Radius.circular(30), topRight: Radius.circular(30)),
                  boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 10, offset: Offset(0, -5))]
              ),
            ),
          ),

          Positioned(
            bottom: currentCatHeight + 10,
            left: 20, right: 20,
            height: searchBarHeight,
            child: Row(
              children: [
                Expanded(
                  child: Container(
                    height: 55,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    decoration: BoxDecoration(
                      color: Colors.grey[100],
                      borderRadius: BorderRadius.circular(30),
                    ),
                    child: Row(
                      children: [
                        const Icon(HeroiconsOutline.magnifyingGlass, color: Colors.grey, size: 22),
                        const SizedBox(width: 10),
                        Expanded(
                          child: TextField(
                            onSubmitted: (value) {
                              if (value.trim().isNotEmpty) {
                                Navigator.push(context, MaterialPageRoute(builder: (context) => SearchResultScreen(keyword: value.trim())));
                              }
                            },
                            decoration: const InputDecoration(hintText: 'Tìm kiếm...', hintStyle: TextStyle(color: Colors.grey, fontSize: 14), border: InputBorder.none),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(width: 12),

                CompositedTransformTarget(
                  link: filterLink,
                  child: GestureDetector(
                    onTap: onFilterTap,
                    child: Container(
                      height: 55, width: 55,
                      decoration: BoxDecoration(
                        color: Colors.grey[100],
                        borderRadius: BorderRadius.circular(30),
                      ),
                      child: Icon(HeroiconsSolid.adjustmentsHorizontal, color: Colors.blue[700], size: 26),
                    ),
                  ),
                ),
              ],
            ),
          ),

          Positioned(
            bottom: 0, left: 0, right: 0,
            height: currentCatHeight,
            child: Opacity(
              opacity: catOpacity,
              child: SingleChildScrollView(
                physics: const NeverScrollableScrollPhysics(),
                child: SizedBox(
                  height: categoriesHeight,
                  child: Row(
                    children: [
                      Expanded(
                        child: ListView.builder(
                          padding: const EdgeInsets.only(left: 10),
                          scrollDirection: Axis.horizontal,
                          itemCount: categories.length,
                          itemBuilder: (context, index) {
                            final cat = categories[index];
                            final isSelected = selectedCatId == cat['id'];
                            return Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 8),
                              child: GestureDetector(
                                onTap: () => onCategoryTap(cat['id']),
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Container(
                                      width: 50, height: 50,
                                      decoration: BoxDecoration(
                                        color: isSelected ? Colors.blue : Colors.grey[100],
                                        borderRadius: BorderRadius.circular(18),
                                        border: isSelected ? null : Border.all(color: Colors.transparent),
                                      ),
                                      child: Icon(cat['icon'], color: isSelected ? Colors.white : cat['color'], size: 24),
                                    ),
                                    const SizedBox(height: 5),
                                    Text(cat['name'], style: TextStyle(fontSize: 11, fontWeight: isSelected ? FontWeight.bold : FontWeight.w500, color: isSelected ? Colors.blue[800] : Colors.black87)),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                      ),

                      Container(width: 1, height: 40, color: Colors.grey[300], margin: const EdgeInsets.symmetric(horizontal: 5)),

                      Padding(
                        padding: const EdgeInsets.only(right: 16, left: 5),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            GestureDetector(
                              onTap: onViewModeTap,
                              child: Container(
                                width: 50, height: 50,
                                decoration: BoxDecoration(color: Colors.grey[200], borderRadius: BorderRadius.circular(18)),
                                child: Icon(isFlashCardMode ? Icons.grid_view_rounded : Icons.view_agenda_rounded, color: Colors.black87),
                              ),
                            ),
                            const SizedBox(height: 5),
                            const Text("View", style: TextStyle(fontSize: 11, fontWeight: FontWeight.w500)),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  double get maxExtent => maxHeight;
  @override
  double get minExtent => minHeight;
  @override
  bool shouldRebuild(covariant _HomeCollapsingDelegate oldDelegate) {
    return maxHeight != oldDelegate.maxExtent ||
        minHeight != oldDelegate.minExtent ||
        isFlashCardMode != oldDelegate.isFlashCardMode ||
        selectedCatId != oldDelegate.selectedCatId ||
        locationName != oldDelegate.locationName;
  }
}