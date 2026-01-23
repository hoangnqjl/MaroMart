import 'package:flutter/material.dart';
import 'package:heroicons_flutter/heroicons_flutter.dart';
import 'package:intl/intl.dart';
import 'package:maromart/Colors/AppColors.dart';
import 'package:maromart/models/Product/Product.dart';
import 'package:maromart/screens/Product/UpdateProduct.dart';
import 'package:maromart/screens/Product/ProductDetail.dart';
import 'package:maromart/services/product_service.dart';
import 'package:maromart/services/user_service.dart';
import 'package:maromart/utils/constants.dart';
import 'package:maromart/app_router.dart';

class ProductManager extends StatefulWidget {
  const ProductManager({super.key});

  @override
  State<ProductManager> createState() => _ProductManager();
}

class _ProductManager extends State<ProductManager> {
  final List<String> _tabs = ['Posted', 'Pending', 'Rejected', 'Removed'];
  final ProductService _productService = ProductService();
  final UserService _userService = UserService();
  final Color primaryThemeColor = const Color(0xFF3F4045);

  List<Product> _postedProducts = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchUserProducts();
  }

  Future<void> _fetchUserProducts() async {
    try {
      final userId = _userService.getCurrentUserId();
      if (userId == null) {
        setState(() => _isLoading = false);
        return;
      }
      final products = await _productService.getUserProducts(userId);

      if (mounted) {
        setState(() {
          _postedProducts = products;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  String _getThumbnailUrl(List<String> media) {
    if (media.isEmpty) return '';
    String url = media[0];
    if (url.contains(':') && !url.startsWith('http')) {
      final parts = url.split(':');
      if (parts.length > 1) url = parts.sublist(1).join(':');
    }
    if (url.startsWith('http')) return url;
    return '${ApiConstants.baseUrl}$url';
  }

  String _formatCurrency(int price) {
    return NumberFormat.currency(locale: 'vi_VN', symbol: 'đ', decimalDigits: 0).format(price).trim();
  }

  void _confirmDelete(Product product) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text("Delete Product"),
        content: const Text("Are you sure you want to delete this product? This action cannot be undone."),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text("Cancel", style: TextStyle(color: Colors.grey)),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              _deleteProduct(product.productId);
            },
            child: const Text("Delete", style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteProduct(String productId) async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => const Center(child: CircularProgressIndicator()),
    );

    try {
      await _productService.deleteProduct(productId);
      if (mounted) {
        Navigator.pop(context);
        setState(() {
          _postedProducts.removeWhere((p) => p.productId == productId);
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Product deleted successfully")),
        );
      }
    } catch (e) {
      if (mounted) Navigator.pop(context);
    }
  }

  String _formatDate(String dateString, String format) {
    try {
      final date = DateTime.parse(dateString).toLocal();
      return DateFormat(format).format(date);
    } catch (e) {
      return '';
    }
  }

  void _showProductOptions(BuildContext context, Product product) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (BuildContext ctx) {
        return Container(
          padding: const EdgeInsets.all(24),
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 24),
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              _buildOptionButton(
                icon: HeroiconsOutline.pencilSquare,
                label: 'Edit item',
                iconColor: Colors.orange,
                bgColor: const Color(0xFFFFF4E5),
                onTap: () async {
                  Navigator.pop(ctx);
                  final result = await smoothPush(context, UpdateProduct(productId: product.productId));
                  if (result == true) _fetchUserProducts();
                },
              ),
              const SizedBox(height: 12),
              _buildOptionButton(
                icon: HeroiconsOutline.trash,
                label: 'Delete item',
                iconColor: Colors.red,
                bgColor: const Color(0xFFFCEEEB),
                onTap: () {
                  Navigator.pop(ctx);
                  _confirmDelete(product);
                },
              ),
              const SizedBox(height: 10),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: _tabs.length,
      child: Scaffold(
        backgroundColor: Colors.white,
        body: Column(
          children: [
            const SizedBox(height: 10),
            Container(
              height: 48,
              margin: const EdgeInsets.symmetric(horizontal: 16),
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: AppColors.E2Color,
                borderRadius: BorderRadius.circular(25),
              ),
              child: TabBar(
                indicatorSize: TabBarIndicatorSize.tab,
                isScrollable: true,
                tabAlignment: TabAlignment.start,
                labelPadding: const EdgeInsets.symmetric(horizontal: 24),
                indicator: BoxDecoration(
                  color: primaryThemeColor,
                  borderRadius: BorderRadius.circular(25),
                ),
                dividerColor: Colors.transparent,
                labelColor: Colors.white,
                unselectedLabelColor: Colors.grey[600],
                labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                tabs: _tabs.map((name) => Tab(text: name)).toList(),
              ),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: _isLoading
                  ? Center(child: CircularProgressIndicator(color: primaryThemeColor))
                  : TabBarView(
                children: [
                  _buildPostedList(),
                  _buildPlaceholderList("No pending products"),
                  _buildPlaceholderList("No rejected products"),
                  _buildPlaceholderList("No removed products"),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPostedList() {
    if (_postedProducts.isEmpty) return _buildPlaceholderList("No products posted yet");
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: _postedProducts.length,
      itemBuilder: (context, index) => _buildProductCard(_postedProducts[index]),
    );
  }

  Widget _buildPlaceholderList(String message) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(HeroiconsOutline.archiveBox, size: 40, color: Colors.grey[200]),
          const SizedBox(height: 8),
          Text(message, style: TextStyle(color: Colors.grey[400])),
        ],
      ),
    );
  }

  Widget _buildProductCard(Product product) {
    final imageUrl = _getThumbnailUrl(product.productMedia);
    return GestureDetector(
      onTap: () => smoothPush(context, ProductDetail(productId: product.productId)),
      child: Container(
        padding: const EdgeInsets.all(12),
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: AppColors.F6Color,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: imageUrl.isNotEmpty
                  ? Image.network(imageUrl, width: 85, height: 85, fit: BoxFit.cover)
                  : Container(width: 85, height: 85, color: Colors.grey[200], child: const Icon(Icons.image, color: Colors.grey)),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(product.productName, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold), maxLines: 1, overflow: TextOverflow.ellipsis),
                  const SizedBox(height: 4),
                  Text(product.productCategory.toUpperCase(), style: TextStyle(fontSize: 11, color: Colors.grey[500], fontWeight: FontWeight.w600)),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      _buildStatTag(icon: HeroiconsOutline.eye, text: '0', bgColor: const Color(0xFFF5F5F5), textColor: Colors.grey),
                      const SizedBox(width: 8),
                      _buildStatTag(icon: HeroiconsOutline.banknotes, text: _formatCurrency(product.productPrice), bgColor: const Color(0xFFE8F5E9), textColor: const Color(0xFF2E7D32)),
                    ],
                  ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                GestureDetector(
                  onTap: () => _showProductOptions(context, product),
                  child: const Icon(HeroiconsOutline.ellipsisHorizontal, color: Colors.black, size: 22),
                ),
                const SizedBox(height: 25),
                Text(_formatDate(product.createdAt, 'dd MMM'), style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
                Text(_formatDate(product.createdAt, 'hh:mm a'), style: TextStyle(fontSize: 9, color: Colors.grey[500])),
              ],
            )
          ],
        ),
      ),
    );
  }

  Widget _buildStatTag({required IconData icon, required String text, required Color bgColor, required Color textColor}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(color: bgColor, borderRadius: BorderRadius.circular(8)),
      child: Row(
        children: [
          Icon(icon, size: 10, color: textColor),
          const SizedBox(width: 4),
          Text(text, style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: textColor)),
        ],
      ),
    );
  }

  Widget _buildOptionButton({required IconData icon, required String label, required Color iconColor, required Color bgColor, required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.grey.shade100),
        ),
        child: Row(
          children: [
            Container(padding: const EdgeInsets.all(8), decoration: BoxDecoration(color: bgColor, shape: BoxShape.circle), child: Icon(icon, color: iconColor, size: 20)),
            const SizedBox(width: 16),
            Text(label, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }
}