import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:heroicons_flutter/heroicons_flutter.dart';
import 'package:temo/components/ProductGridItem.dart';
import 'package:temo/models/Product/Product.dart';
import 'package:temo/services/product_service.dart';
import 'package:temo/components/Skeletons/ProductCardSkeleton.dart';
import 'package:temo/components/FloatingHeader.dart';
import 'package:temo/utils/UIHelper.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';

class SearchResultScreen extends StatefulWidget {
  final String keyword;

  const SearchResultScreen({super.key, required this.keyword});

  @override
  State<SearchResultScreen> createState() => _SearchResultScreenState();
}

class _SearchResultScreenState extends State<SearchResultScreen> {
  final ProductService _productService = ProductService();
  List<Product> _products = [];
  bool _isLoading = true;
  String _errorMessage = '';

  @override
  void initState() {
    super.initState();
    _doSearch();
  }

  Future<void> _doSearch() async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      final results = await _productService.searchProducts(widget.keyword);
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
          // 1. Search Results Content
          RefreshIndicator(
            onRefresh: _doSearch,
            color: const Color(0xFFFFB86B),
            child: CustomScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              slivers: [
                // Top spacing for floating header (Safe Area + FloatingHeader height)
                SliverToBoxAdapter(
                  child: SizedBox(
                    height: MediaQuery.of(context).padding.top + 80,
                  ),
                ),

                if (_isLoading)
                  SliverPadding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    sliver: SliverGrid(
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        crossAxisSpacing: 12,
                        mainAxisSpacing: 12,
                        mainAxisExtent: 315,
                      ),
                      delegate: SliverChildBuilderDelegate(
                        (context, index) => const ProductCardSkeleton(),
                        childCount: 6,
                      ),
                    ),
                  )
                else if (_errorMessage.isNotEmpty)
                  SliverFillRemaining(
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(HeroiconsOutline.exclamationTriangle,
                              size: 48, color: Colors.orange),
                          const SizedBox(height: 10),
                          Text("Lỗi: $_errorMessage",
                              style: const TextStyle(
                                  color: Colors.grey, fontFamily: 'Quicksand')),
                          TextButton(
                              onPressed: _doSearch,
                              child: const Text("Thử lại",
                                  style: TextStyle(color: Color(0xFFFFB86B))))
                        ],
                      ),
                    ),
                  )
                else if (_products.isEmpty)
                  SliverFillRemaining(
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(HeroiconsOutline.magnifyingGlass,
                              size: 64, color: Colors.grey),
                          const SizedBox(height: 16),
                          Text(
                            'Không tìm thấy sản phẩm nào cho "${widget.keyword}"',
                            style: const TextStyle(
                              color: Colors.grey,
                              fontSize: 16,
                              fontFamily: 'Quicksand',
                            ),
                            textAlign: TextAlign.center,
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
                      itemBuilder: (context, index) {
                        return ProductGridItem(product: _products[index]);
                      },
                      childCount: _products.length,
                    ),
                  ),

                const SliverToBoxAdapter(child: SizedBox(height: 100)),
              ],
            ),
          ),

          // 2. Floating Header (Consistent with All Products page)
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: ClipRRect(
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                child: Container(
                  color: Colors.white.withOpacity(0.8),
                  child: SafeArea(
                    bottom: false,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const SizedBox(height: 10),
                        FloatingHeader(
                          title: widget.keyword,
                          hasBackground: false,
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 0),
                          actions: [
                            FloatingHeader.buildActionBubble(
                              icon: HeroiconsSolid.ellipsisVertical,
                              onTap: () => UIHelper.showOptionsMenu(context,
                                  screenName: "Tìm kiếm: ${widget.keyword}"),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
