import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:temo/components/ModernLoader.dart';
import 'package:temo/components/ProductGridItem.dart';
import 'package:temo/Colors/AppColors.dart';
import 'package:heroicons_flutter/heroicons_flutter.dart';
import 'package:temo/models/Product/Product.dart';
import 'package:temo/services/api_service.dart';
import 'package:temo/services/product_service.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'package:temo/components/Skeletons/ProductCardSkeleton.dart';
import 'package:temo/components/FloatingHeader.dart';
import 'package:temo/utils/UIHelper.dart';

class SavedProductsScreen extends StatefulWidget {
  const SavedProductsScreen({super.key});

  @override
  State<SavedProductsScreen> createState() => _SavedProductsScreenState();
}

class _SavedProductsScreenState extends State<SavedProductsScreen> {
  final ProductService _productService = ProductService();
  final TextEditingController _searchController = TextEditingController();
  
  bool _isLoading = true;
  List<Product> _allSavedProducts = [];
  List<Product> _filteredProducts = [];
  List<dynamic> _categories = [];
  String? _selectedCategoryId;

  @override
  void initState() {
    super.initState();
    _fetchData();
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _fetchData() async {
    try {
      setState(() => _isLoading = true);
      
      final responses = await Future.wait([
        ApiService().get(endpoint: '/products/user/saved', needAuth: true),
        _productService.getCategories(),
      ]);

      if (responses[0] != null && responses[0] is List) {
        _allSavedProducts = (responses[0] as List).map((e) => Product.fromJson(e)).toList();
        _filteredProducts = _allSavedProducts;
      }
      _categories = responses[1] as List<dynamic>;

    } catch (e) {
      print("Lỗi lấy dữ liệu: $e");
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _onSearchChanged() {
    _applyFilters();
  }

  void _applyFilters() {
    String query = _searchController.text.toLowerCase();
    setState(() {
      _filteredProducts = _allSavedProducts.where((product) {
        bool matchesSearch = product.productName.toLowerCase().contains(query);
        bool matchesCategory = _selectedCategoryId == null || _selectedCategoryId!.isEmpty || product.categoryId == _selectedCategoryId;
        return matchesSearch && matchesCategory;
      }).toList();
    });
  }

  void _onCategorySelected(String? categoryId) {
    setState(() {
      _selectedCategoryId = categoryId;
      _applyFilters();
    });
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          Column(
            children: [
              const SizedBox(height: 180), // Increased height for 2-row header
              Expanded(
                child: _isLoading
                    ? SliverPadding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        sliver: SliverMasonryGrid.count(
                          crossAxisCount: 2,
                          mainAxisSpacing: 12,
                          crossAxisSpacing: 12,
                          childCount: 6,
                          itemBuilder: (context, index) => const ProductCardSkeleton(),
                        ),
                      )
                    : RefreshIndicator(
                        onRefresh: _fetchData,
                        child: CustomScrollView(
                          slivers: [
                            SliverToBoxAdapter(
                              child: _buildCategoryFilter(),
                            ),
                            if (_filteredProducts.isEmpty)
                              SliverFillRemaining(
                                child: Center(
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(HeroiconsOutline.heart, size: 64, color: Colors.grey[200]),
                                      const SizedBox(height: 16),
                                      Text(
                                        "Không tìm thấy sản phẩm nào",
                                        style: GoogleFonts.roboto(
                                            color: Colors.grey[400],
                                            fontSize: 15,
                                            fontWeight: FontWeight.w500),
                                      ),
                                    ],
                                  ),
                                ),
                              )
                            else
                              SliverPadding(
                                padding: const EdgeInsets.fromLTRB(16, 0, 16, 20),
                                sliver: SliverMasonryGrid.count(
                                  crossAxisCount: 2,
                                  mainAxisSpacing: 12,
                                  crossAxisSpacing: 12,
                                  childCount: _filteredProducts.length,
                                  itemBuilder: (context, index) {
                                    return ProductGridItem(product: _filteredProducts[index]);
                                  },
                                ),
                              ),
                          ],
                        ),
                      ),
              ),
            ],
          ),
          Positioned(
            top: 0, left: 0, right: 0,
            child: Container(
              color: Colors.white,
              child: SafeArea(
                bottom: false,
                child: Column(
                  children: [
                    FloatingHeader(
                      title: "Sản phẩm đã lưu",
                      hasBackground: false,
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 0),
                      actions: [
                        FloatingHeader.buildActionBubble(
                          icon: HeroiconsSolid.ellipsisVertical,
                          onTap: () => UIHelper.showOptionsMenu(context, screenName: "Sản phẩm đã lưu"),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    _buildSearchFilterArea(),
                    const SizedBox(height: 8),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    ),
   );
  }

  Widget _buildSearchFilterArea() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          Expanded(
            child: Container(
              height: 48,
              decoration: BoxDecoration(
                color: const Color(0xFFF3F4F6),
                borderRadius: BorderRadius.circular(40),
              ),
              child: Row(
                children: [
                  const SizedBox(width: 18),
                  Icon(HeroiconsOutline.magnifyingGlass, color: Colors.grey[400], size: 20),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextField(
                      controller: _searchController,
                      style: GoogleFonts.roboto(fontWeight: FontWeight.w600, fontSize: 15),
                      decoration: InputDecoration(
                        hintText: "Tìm trong mục đã lưu...",
                        hintStyle: GoogleFonts.roboto(color: Colors.grey[400], fontSize: 14),
                        border: InputBorder.none,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 8),
          Container(
            width: 48, height: 48,
            decoration: const BoxDecoration(
              color: Color(0xFFF3F4F6),
              shape: BoxShape.circle,
            ),
            child: Icon(HeroiconsOutline.adjustmentsHorizontal, color: const Color(0xFF111827), size: 22),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryFilter() {
    return Container(
      height: 60,
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        children: [
          _buildFilterChip("Tất cả", null),
          ..._categories.map((cat) => _buildFilterChip(cat['categoryName'], cat['categoryId'])),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String label, String? id) {
    bool isSelected = _selectedCategoryId == id;
    return GestureDetector(
      onTap: () => _onCategorySelected(id),
      child: Container(
        margin: const EdgeInsets.only(right: 10),
        padding: const EdgeInsets.symmetric(horizontal: 20),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary : const Color(0xFFF3F4F6),
          borderRadius: BorderRadius.circular(30),
        ),
        child: Text(
          label,
          style: GoogleFonts.roboto(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: isSelected ? Colors.white : const Color(0xFF4B5563),
          ),
        ),
      ),
    );
  }
}
