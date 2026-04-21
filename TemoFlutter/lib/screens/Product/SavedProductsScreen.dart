import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:temo/components/ModernLoader.dart';
import 'package:temo/components/ProductGridItem.dart';
import 'package:temo/Colors/AppColors.dart';
import 'package:heroicons_flutter/heroicons_flutter.dart';
import 'package:temo/models/Product/Product.dart';
import 'package:temo/services/api_service.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'package:temo/components/Skeletons/ProductCardSkeleton.dart';

class SavedProductsScreen extends StatefulWidget {
  const SavedProductsScreen({super.key});

  @override
  State<SavedProductsScreen> createState() => _SavedProductsScreenState();
}

class _SavedProductsScreenState extends State<SavedProductsScreen> {
  bool _isLoading = true;
  List<Product> _savedProducts = [];

  @override
  void initState() {
    super.initState();
    _fetchSavedProducts();
  }

  Future<void> _fetchSavedProducts() async {
    try {
      setState(() => _isLoading = true);
      final response = await ApiService().get(endpoint: '/products/user/saved', needAuth: true);
      if (response != null && response is List) {
        setState(() {
          _savedProducts = response.map((e) => Product.fromJson(e)).toList();
        });
      }
    } catch (e) {
      print("Lỗi lấy sản phẩm đã lưu: $e");
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Stack(
        children: [
          Column(
            children: [
              const SizedBox(height: 120),
              Expanded(
                child: _isLoading
                    ? SliverPadding(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        sliver: SliverMasonryGrid.count(
                          crossAxisCount: 2,
                          mainAxisSpacing: 10,
                          crossAxisSpacing: 10,
                          childCount: 6,
                          itemBuilder: (context, index) => const ProductCardSkeleton(),
                        ),
                      )
                    : _savedProducts.isEmpty
                        ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(HeroiconsOutline.heart, size: 64, color: Colors.grey[300]),
                                const SizedBox(height: 16),
                                Text(
                                  "Chưa có sản phẩm nào được lưu",
                                  style: GoogleFonts.roboto(
                                      color: Colors.grey[400],
                                      fontSize: 15,
                                      fontWeight: FontWeight.w500),
                                ),
                              ],
                            ),
                          )
                        : MasonryGridView.count(
                            padding: const EdgeInsets.symmetric(horizontal: 12),
                            crossAxisCount: 2,
                            mainAxisSpacing: 10,
                            crossAxisSpacing: 10,
                            itemCount: _savedProducts.length,
                            itemBuilder: (context, index) {
                              return ProductGridItem(product: _savedProducts[index]);
                            },
                          ),
              ),
            ],
          ),
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: _buildCustomHeader(context),
          ),
        ],
      ),
    );
  }

  Widget _buildCustomHeader(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.black.withOpacity(0.08), width: 0.5),
                      boxShadow: [
                        BoxShadow(
                            color: Colors.black.withOpacity(0.05),
                            blurRadius: 10,
                            offset: const Offset(0, 4))
                      ],
                    ),
                    child: const Icon(HeroiconsOutline.chevronLeft, color: Color(0xFF4B5563), size: 24),
                  ),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(100),
                    border: Border.all(color: Colors.black.withOpacity(0.08), width: 0.5),
                    boxShadow: [
                      BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 10,
                          offset: const Offset(0, 4))
                    ],
                  ),
                  child: Text(
                    "Đã Lưu",
                    style: GoogleFonts.roboto(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF4B5563),
                    ),
                  ),
                ),
                const Spacer(),
                const SizedBox(width: 44), // Cân bằng không gian
              ],
            ),
          ],
        ),
      ),
    );
  }
}
