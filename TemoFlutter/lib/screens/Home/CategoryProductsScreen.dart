import 'package:flutter/material.dart';
import 'dart:ui';
import 'package:temo/Colors/AppColors.dart';
import 'package:heroicons_flutter/heroicons_flutter.dart';
import 'package:temo/components/Post.dart';
import 'package:temo/models/Product/Product.dart';
import 'package:temo/services/product_service.dart';
import 'package:temo/components/ModernLoader.dart';
import 'package:temo/components/FloatingHeader.dart';
import 'package:temo/utils/UIHelper.dart';
import 'package:google_fonts/google_fonts.dart';

class CategoryProductsScreen extends StatefulWidget {
  final Map<String, dynamic> category;
  final bool showRecommendedOnly;

  const CategoryProductsScreen({
    Key? key, 
    required this.category,
    this.showRecommendedOnly = false,
  }) : super(key: key);

  @override
  State<CategoryProductsScreen> createState() => _CategoryProductsScreenState();
}

class _CategoryProductsScreenState extends State<CategoryProductsScreen> {
  final ProductService _productService = ProductService();
  List<Product> _products = [];
  List<dynamic> _categories = [];
  bool _isLoading = true;
  bool _isCategoriesLoading = true;
  String _errorMessage = '';
  String _selectedCategoryId = '';
  bool _showRecommended = false;

  String get _currentTitle {
    if (_showRecommended) return "Gợi ý cho bạn";
    if (_selectedCategoryId == 'all') return "Tất cả sản phẩm";
    try {
      final cat = _categories.firstWhere(
        (c) => (c['categoryId'] ?? c['id']).toString() == _selectedCategoryId,
        orElse: () => null,
      );
      return cat != null ? (cat['categoryName'] ?? cat['name']).toString() : "Sản phẩm";
    } catch (e) {
      return "Sản phẩm";
    }
  }

  @override
  void initState() {
    super.initState();
    _showRecommended = widget.showRecommendedOnly;
    _selectedCategoryId = widget.category['categoryId']?.toString() ?? widget.category['id']?.toString() ?? 'all';
    _fetchCategories();
    _fetchProducts();
  }

  Future<void> _fetchCategories() async {
    setState(() => _isCategoriesLoading = true);
    try {
      final cats = await _productService.getCategories();
      // Add "All" category if not exists
      if (!cats.any((c) => (c['categoryId'] ?? c['id']) == 'all')) {
        cats.insert(0, {'categoryId': 'all', 'categoryName': 'Tất cả'});
      }
      
      cats.sort((a, b) {
        final String idA = (a['categoryId'] ?? a['id'] ?? '').toString();
        if (idA == 'all') return -1;
        final String idB = (b['categoryId'] ?? b['id'] ?? '').toString();
        if (idB == 'all') return 1;
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

  Future<void> _fetchProducts() async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      List<Product> results;
      if (_showRecommended) {
        results = await _productService.getRecommendedProducts(limit: 50);
      } else {
        results = await _productService.getProductsByCategory(
            categoryId: _selectedCategoryId == 'all' ? null : _selectedCategoryId
        );
      }

      if (mounted) {
        setState(() {
          _products = results;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage = e.toString().replaceAll("Exception: ", "");
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          // Background list
          Positioned.fill(child: _buildBody()),
          
          // Floating Header (Copied from SavedProductsScreen style)
          Positioned(
            top: 0, left: 0, right: 0,
            child: Container(
              color: Colors.white,
              child: SafeArea(
                bottom: false,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const SizedBox(height: 10),
                    FloatingHeader(
                      title: _currentTitle,
                      hasBackground: false,
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 0),
                      actions: [
                        FloatingHeader.buildActionBubble(
                          icon: HeroiconsSolid.ellipsisVertical,
                          onTap: () => UIHelper.showOptionsMenu(context, screenName: _currentTitle),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    _buildCategoryFilter(),
                    const SizedBox(height: 15),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryFilter() {
    if (_isCategoriesLoading) return const SizedBox(height: 40);

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: _categories.map((cat) {
          final String id = (cat['categoryId'] ?? cat['id'] ?? '').toString();
          final String label = (cat['categoryName'] ?? cat['name'] ?? '').toString();
          bool isSelected = !_showRecommended && _selectedCategoryId == id;

          return GestureDetector(
            onTap: () {
              setState(() {
                _selectedCategoryId = id;
                _showRecommended = false;
              });
              _fetchProducts();
            },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              margin: const EdgeInsets.only(right: 8),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: isSelected ? AppColors.primary : const Color(0xFFF3F4F6),
                borderRadius: BorderRadius.circular(25),
              ),
              child: Text(
                label,
                style: GoogleFonts.quicksand(
                  fontSize: 13,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                  color: isSelected ? Colors.white : const Color(0xFF6B7280),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return Center(child: ModernLoader());
    }

    if (_errorMessage.isNotEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(HeroiconsOutline.exclamationTriangle, size: 48, color: Colors.orange),
            const SizedBox(height: 10),
            Text("Lỗi: $_errorMessage", style: const TextStyle(color: Colors.grey, fontFamily: 'Quicksand')),
            TextButton(onPressed: _fetchProducts, child: const Text("Thử lại", style: TextStyle(fontFamily: 'Quicksand')))
          ],
        ),
      );
    }

    if (_products.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(HeroiconsOutline.archiveBoxXMark, size: 60, color: Colors.grey),
            const SizedBox(height: 16),
            Text(
              'Không có sản phẩm nào',
              style: const TextStyle(color: Colors.grey, fontSize: 16, fontFamily: 'Quicksand'),
            ),
          ],
        ),
      );
    }

    final double screenWidth = MediaQuery.of(context).size.width;

    return ListView.builder(
      padding: EdgeInsets.fromLTRB(16, MediaQuery.of(context).padding.top + 150, 16, 40),
      itemCount: _products.length,
      itemBuilder: (context, index) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 20),
          child: SizedBox(
            height: screenWidth * 1.4,
            child: Post(product: _products[index]),
          ),
        );
      },
    );
  }
}
