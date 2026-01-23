import 'package:flutter/material.dart';
import 'package:heroicons_flutter/heroicons_flutter.dart';
import 'package:maromart/Colors/AppColors.dart';
import 'package:maromart/components/Post.dart';
import 'package:maromart/components/ProductGridItem.dart';
import 'package:maromart/components/Filter.dart';
import 'package:maromart/models/Product/Product.dart';
import 'package:maromart/services/product_service.dart';
import '../Search/SearchResult.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  State<StatefulWidget> createState() => HomeScreenState();
}

class HomeScreenState extends State<HomeScreen> {
  final ProductService _productService = ProductService();
  final ScrollController _scrollController = ScrollController();

  late final FilterOverlay _filterOverlay = FilterOverlay(
    onFilterApplied: (categoryId, province, ward) =>
        updateFilter(
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
  final int _limit = 5;
  bool _isFlashCardMode = true;

  String? _filterCategoryId;
  String? _filterProvince;
  String? _filterWard;

  @override
  void initState() {
    super.initState();
    _loadProducts(isRefresh: true);
    _scrollController.addListener(() {
      if (_scrollController.position.pixels >=
          _scrollController.position.maxScrollExtent - 200) {
        _loadProducts(isRefresh: false);
      }
    });
    _productService.productChangeNotifier.addListener(_onProductChanged);
  }

  @override
  void dispose() {
    _productService.productChangeNotifier.removeListener(_onProductChanged);
    _scrollController.dispose();
    super.dispose();
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
      bool isFiltering = _filterCategoryId != null || _filterProvince != null ||
          _filterWard != null;
      if (isFiltering) {
        newProducts = await _productService.getProductsByFilter(
          categoryId: _filterCategoryId,
          province: _filterProvince,
          ward: _filterWard,
        );
        _hasMore = false;
      } else {
        newProducts =
        await _productService.getProducts(page: _currentPage, limit: _limit);
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
    return Container(
      color: Colors.white,
      child: Column(
        children: [
          const SizedBox(height: 10),
          _buildSearchAndFilterHeader(),
          Expanded(
            child: RefreshIndicator(
              onRefresh: () async => _loadProducts(isRefresh: true),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: _products.isEmpty
                    ? (_isInitialLoading
                    ? const Center(child: CircularProgressIndicator())
                    : const Center(child: Text("No products found.")))
                    : _buildProductList(),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchAndFilterHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 5, 16, 10),
      child: Column(
        children: [
          Row(
            children: [
              // Ô Search
              Expanded(
                child: Container(
                  height: 46,
                  padding: const EdgeInsets.symmetric(horizontal: 15),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(30),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: TextField(
                          textInputAction: TextInputAction.search,
                          onSubmitted: (value) {
                            if (value
                                .trim()
                                .isNotEmpty) {
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
                            hintText: 'Search...',
                            hintStyle: TextStyle(
                                color: Colors.grey[400], fontSize: 14),
                            border: InputBorder.none,
                            isDense: true,
                          ),
                        ),
                      ),
                      Icon(HeroiconsOutline.camera, color: Colors.grey[400],
                          size: 20),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 10),
              // Nút Lọc (Filter)
              CompositedTransformTarget(
                link: _filterOverlay.layerLink,
                child: GestureDetector(
                  onTap: () => _filterOverlay.toggle(context),
                  child: Container(
                    width: 46, height: 46,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade100,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(HeroiconsOutline.adjustmentsHorizontal,
                        color: Colors.black87, size: 20),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                  "For You",
                  style: TextStyle(fontSize: 16,
                      fontWeight: FontWeight.bold,
                      fontFamily: 'QuickSand')
              ),
              Container(
                padding: const EdgeInsets.all(2),
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  children: [
                    _buildViewToggleButton(
                        Icons.view_agenda_outlined, _isFlashCardMode, true),
                    _buildViewToggleButton(
                        Icons.grid_view_outlined, !_isFlashCardMode, false),
                  ],
                ),
              )
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildViewToggleButton(IconData icon, bool isSelected,
      bool isFlashMode) {
    return GestureDetector(
      onTap: () => setState(() => _isFlashCardMode = isFlashMode),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: isSelected ? Colors.white : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
          boxShadow: isSelected ? [
            BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 4)
          ] : [],
        ),
        child: Icon(
            icon, size: 20, color: isSelected ? Colors.black : Colors.grey),
      ),
    );
  }

  Widget _buildProductList() {
    if (_isFlashCardMode) {
      return PageView.builder(
        scrollDirection: Axis.vertical,
        controller: PageController(viewportFraction: 1.0),
        itemCount: _products.length + 1,
        itemBuilder: (context, index) {
          if (index == _products.length) {
            return _buildEndOfListWidget();
          }

          if (index == _products.length - 1 && _hasMore) _loadProducts(isRefresh: false);

          return Padding(
            padding: const EdgeInsets.only(top: 4, bottom: 20),
            child: Post(product: _products[index]),
          );
        },
      );
  }else {
      return GridView.builder(
        padding: const EdgeInsets.only(top: 10, bottom: 120),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          childAspectRatio: 0.68,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
        ),
        itemCount: _products.length + 1,
        itemBuilder: (context, index) {
          if (index == _products.length) {
            return const SizedBox.shrink();
          }
          return ProductGridItem(product: _products[index]);
        },
      );
    }
  }

  Widget _buildEndOfListWidget() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 40),
      alignment: Alignment.center,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(HeroiconsOutline.checkCircle, size: 40, color: Colors.grey[300]),
          const SizedBox(height: 12),
          Text(
            "Bạn đã xem hết sản phẩm rồi!",
            style: TextStyle(
                color: Colors.grey[400],
                fontSize: 14,
                fontWeight: FontWeight.w500,
                fontFamily: 'QuickSand'
            ),
          ),
          const SizedBox(height: 80),
        ],
      ),
    );
  }
}