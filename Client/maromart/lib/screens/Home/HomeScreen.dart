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

  // Khởi tạo Overlay an toàn
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
      if (_scrollController.position.pixels >= _scrollController.position.maxScrollExtent - 200) {
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
      bool isFiltering = _filterCategoryId != null || _filterProvince != null || _filterWard != null;
      if (isFiltering) {
        newProducts = await _productService.getProductsByFilter(
          categoryId: _filterCategoryId,
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
    return Container(
      color: Colors.white,
      child: Column(
        children: [
          // Thêm Padding Top để không bị sát mép TopBar
          const SizedBox(height: 10),
          _buildSearchAndFilter(),
          _buildForYouHeader(),
          Expanded(
            child: RefreshIndicator(
              onRefresh: () async => _loadProducts(isRefresh: true),
              child: Padding(
                // Cắt bớt Padding ngang của list để Post tràn ra đẹp hơn nhưng không lỗi
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

  Widget _buildSearchAndFilter() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
      child: Row(
        children: [
          Expanded(
            child: Container(
              height: 50,
              padding: const EdgeInsets.symmetric(horizontal: 20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(30),
                boxShadow: [
                  BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 5))
                ],
              ),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      textInputAction: TextInputAction.search, // Hiển thị nút Search trên bàn phím
                      onSubmitted: (value) {
                        if (value.trim().isNotEmpty) {
                          // Gọi trang kết quả tìm kiếm
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => SearchResultScreen(keyword: value.trim()),
                            ),
                          );
                        }
                      },
                      decoration: InputDecoration(
                        hintText: 'Search...',
                        hintStyle: TextStyle(color: Colors.grey[400], fontSize: 15),
                        border: InputBorder.none,
                      ),
                    ),
                  ),
                  Icon(HeroiconsOutline.camera, color: Colors.grey[400], size: 22),
                ],
              ),
            ),
          ),
          const SizedBox(width: 12),
          CompositedTransformTarget(
            link: _filterOverlay.layerLink,
            child: GestureDetector(
              onTap: () => _filterOverlay.toggle(context),
              child: Container(
                width: 50, height: 50,
                decoration: BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 5))
                  ],
                ),
                child: const Icon(HeroiconsOutline.adjustmentsHorizontal, color: Colors.black87, size: 22),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildForYouHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Text("For You", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          Row(
            children: [
              IconButton(
                icon: Icon(Icons.view_agenda, color: _isFlashCardMode ? Colors.black : Colors.grey),
                onPressed: () => setState(() => _isFlashCardMode = true),
              ),
              IconButton(
                icon: Icon(Icons.grid_view, color: !_isFlashCardMode ? Colors.black : Colors.grey),
                onPressed: () => setState(() => _isFlashCardMode = false),
              ),
            ],
          )
        ],
      ),
    );
  }

  Widget _buildProductList() {
    if (_isFlashCardMode) {
      return PageView.builder(
        scrollDirection: Axis.vertical,
        controller: PageController(viewportFraction: 1.0),
        itemCount: _products.length,
        itemBuilder: (context, index) {
          if (index == _products.length - 1 && _hasMore) _loadProducts(isRefresh: false);
          return Padding(
            // Tạo khoảng trống giữa các Post để không dính lẹo
            padding: const EdgeInsets.only(bottom: 16),
            child: Post(product: _products[index]),
          );
        },
      );
    } else {
      return GridView.builder(
        // Grid giữ nguyên Padding
        padding: const EdgeInsets.only(top: 10, bottom: 100),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          childAspectRatio: 0.68,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
        ),
        itemCount: _products.length,
        itemBuilder: (context, index) => ProductGridItem(product: _products[index]),
      );
    }
  }
}