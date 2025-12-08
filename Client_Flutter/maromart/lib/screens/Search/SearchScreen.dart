import 'package:flutter/material.dart';
import 'package:maromart/Colors/AppColors.dart';
import 'package:maromart/components/Post.dart';
import 'package:maromart/models/Product/Product.dart';
import 'package:maromart/services/product_service.dart';

class SearchScreen extends StatefulWidget {
  @override
  State<StatefulWidget> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final ProductService _productService = ProductService();
  List<Product> _products = [];
  bool _isLoading = true;

  String? _selectedCategoryId;

  final List<CategoryItem> categories = [
    CategoryItem(icon: '', label: 'All', id: ''),
    CategoryItem(icon: 'lib/images/Automotive.png', label: 'Auto', id: 'auto'),
    CategoryItem(icon: 'lib/images/Furniture Household.png', label: 'Furniture', id: 'furniture'),
    CategoryItem(icon: 'lib/images/Computer & Accessory.png', label: 'Tech', id: 'technology'), // Sửa ID cho khớp với backend nếu cần
    CategoryItem(icon: 'lib/images/Office Stationary.png', label: 'Office', id: 'office'),
    CategoryItem(icon: 'lib/images/Men Fashion.png', label: 'Style', id: 'style'),
    CategoryItem(icon: 'lib/images/Hijab.png', label: 'Service', id: 'service'),
    CategoryItem(icon: 'lib/images/Sport.png', label: 'Hobby', id: 'hobby'),
    CategoryItem(icon: 'lib/images/Baby.png', label: 'Kids', id: 'kids'),
  ];

  @override
  void initState() {
    super.initState();
    _fetchFilteredProducts('');
  }

  Future<void> _fetchFilteredProducts(String? categoryId) async {
    setState(() {
      _isLoading = true;
      _selectedCategoryId = (categoryId == null || categoryId.isEmpty) ? null : categoryId;
    });

    try {
      final products = await _productService.getProductsByCategory(
          categoryId: _selectedCategoryId
      );

      if (mounted) {
        setState(() {
          _products = products;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _products = [];
          _isLoading = false;
        });
      }
      print('Lỗi khi lọc sản phẩm: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.only(top: 10, left: 16, right: 16),
      child: ListView(
        children: [
          SizedBox(
            height: 85,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: categories.length,
              physics: const BouncingScrollPhysics(),
              itemBuilder: (context, index) {
                return _buildCategoryItem(categories[index]);
              },
            ),
          ),

          const SizedBox(height: 20),

          _isLoading
              ? const Center(
              child: Padding(
                padding: EdgeInsets.all(32.0),
                child: CircularProgressIndicator(),
              ))
              : _products.isEmpty
              ? const Center(
              child: Padding(
                padding: EdgeInsets.all(32.0),
                child: Text('Không tìm thấy sản phẩm nào.'),
              ))
              : Column(
            children: [
              ...List.generate(
                _products.length,
                    (index) => Padding(
                  padding: const EdgeInsets.only(bottom: 20.0),
                  child: Post(product: _products[index]),
                ),
              ),

              Padding(
                padding: const EdgeInsets.only(top: 30.0, bottom: 150.0),
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                          Icons.check_circle_outline,
                          color: Colors.grey[300],
                          size: 40
                      ),
                      const SizedBox(height: 8),
                      Text(
                        "You're all caught up!",
                        style: TextStyle(
                          color: Colors.grey[400],
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          fontFamily: 'QuickSand',
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        "You've seen all the listings for now.",
                        style: TextStyle(
                          color: Colors.grey[400],
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryItem(CategoryItem item) {
    final isSelected = _selectedCategoryId == item.id ||
        (_selectedCategoryId == null && item.id == '');

    return GestureDetector(
      onTap: () {
        print('Lọc theo: ${item.label} (ID: ${item.id})');
        _fetchFilteredProducts(item.id);
      },
      child: Container(
        width: 85,
        height: 85,
        margin: const EdgeInsets.only(right: 10),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          color: isSelected ? Colors.black : AppColors.E2Color,
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset(
              item.icon,
              width: 28,
              height: 28,
              fit: BoxFit.contain,
              color: isSelected ? Colors.white : null,
              errorBuilder: (context, error, stackTrace) {
                return Icon(
                    Icons.grid_view,
                    size: 24,
                    color: isSelected ? Colors.white : Colors.grey
                );
              },
            ),
            const SizedBox(height: 8),
            Text(
              item.label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: isSelected ? Colors.white : Colors.black,
              ),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}

class CategoryItem {
  final String icon;
  final String label;
  final String id;

  CategoryItem({
    required this.icon,
    required this.label,
    required this.id
  });
}