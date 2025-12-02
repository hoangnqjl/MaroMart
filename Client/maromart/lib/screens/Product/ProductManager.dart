import 'package:flutter/material.dart';
import 'package:heroicons_flutter/heroicons_flutter.dart';
import 'package:intl/intl.dart'; // Cần import intl trong pubspec.yaml để format ngày/giá
import 'package:maromart/Colors/AppColors.dart';
import 'package:maromart/components/TopBarSecond.dart';
import 'package:maromart/models/Product/Product.dart';
import 'package:maromart/screens/Product/UpdateProduct.dart';
import 'package:maromart/services/product_service.dart';
import 'package:maromart/services/user_service.dart';
import 'package:maromart/utils/constants.dart';

class ProductManager extends StatefulWidget {
  const ProductManager({super.key});

  @override
  State<ProductManager> createState() => _ProductManager();
}

class _ProductManager extends State<ProductManager> {
  final List<String> _tabs = ['Posted', 'Pending', 'Rejected', 'Removed'];

  // Services
  final ProductService _productService = ProductService();
  final UserService _userService = UserService();

  // State
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
      print("Lỗi tải sản phẩm quản lý: $e");
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  // Helper xử lý URL ảnh
  String _getThumbnailUrl(List<String> media) {
    if (media.isEmpty) return '';
    String url = media[0];

    // Xử lý nếu backend lưu dạng "image:url" hoặc "video:url"
    if (url.contains(':') && !url.startsWith('http')) {
      final parts = url.split(':');
      if (parts.length > 1) url = parts.sublist(1).join(':');
    }

    if (url.startsWith('http')) return url;
    return '${ApiConstants.baseUrl}$url';
  }

  // Helper format tiền tệ
  String _formatCurrency(int price) {
    return NumberFormat.currency(locale: 'vi_VN', symbol: '', decimalDigits: 0).format(price).trim();
  }

  void _confirmDelete(Product product) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Delete Product"),
        content: const Text("Are you sure you want to delete this product? This action cannot be undone."),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text("Cancel", style: TextStyle(color: Colors.grey)),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx); // Đóng dialog xác nhận
              _deleteProduct(product.productId); // Gọi API
            },
            child: const Text("Delete", style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteProduct(String productId) async {
    // Hiển thị loading
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
          const SnackBar(content: Text("Product deleted successfully"), backgroundColor: Colors.green),
        );
      }
    } catch (e) {
      if (mounted) {
        Navigator.pop(context); // Tắt loading
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Failed to delete: $e"), backgroundColor: Colors.red),
        );
      }
    }
  }

  // Helper format ngày giờ
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
          padding: const EdgeInsets.all(20),
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(25),
              topRight: Radius.circular(25),
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 20),
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
                  Navigator.pop(ctx); // Đóng Modal trước

                  final result = await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => UpdateProduct(productId: product.productId),
                    ),
                  );

                  if (result == true) {
                    _fetchUserProducts();
                  }
                },
              ),

              const SizedBox(height: 12),

              // Nút DELETE (Màu đỏ nhạt)
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
        appBar: const TopBarSecond(title: 'Product Manager'),
        body: Column(
          children: [
            const SizedBox(height: 16),
            Container(
              height: 45,
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
                labelPadding: const EdgeInsets.symmetric(horizontal: 20),
                indicator: BoxDecoration(
                  color: AppColors.ButtonBlackColor,
                  borderRadius: BorderRadius.circular(25),
                ),
                dividerColor: Colors.transparent,
                labelColor: Colors.white,
                unselectedLabelColor: Colors.grey[600],
                labelStyle: const TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 13,
                  fontFamily: 'QuickSand',
                ),
                tabs: _tabs.map((name) => Tab(text: name)).toList(),
              ),
            ),

            const SizedBox(height: 16),

            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : TabBarView(
                children: [
                  _buildPostedList(), // Tab Posted (Dữ liệu thật)
                  _buildPlaceholderList("No pending products"), // Pending
                  _buildPlaceholderList("No rejected products"), // Rejected
                  _buildPlaceholderList("No removed products"), // Removed
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Tab Posted: Hiển thị dữ liệu từ API
  Widget _buildPostedList() {
    if (_postedProducts.isEmpty) {
      return _buildPlaceholderList("You haven't posted any products yet");
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: _postedProducts.length,
      itemBuilder: (context, index) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 16.0),
          child: _buildProductCard(_postedProducts[index]),
        );
      },
    );
  }

  // Widget hiển thị danh sách trống cho các tab khác
  Widget _buildPlaceholderList(String message) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(HeroiconsOutline.archiveBox, size: 40, color: Colors.grey[300]),
          const SizedBox(height: 8),
          Text(message, style: TextStyle(color: Colors.grey[400])),
        ],
      ),
    );
  }

  // Trong _ProductManager State

  Widget _buildProductCard(Product product) {
    final imageUrl = _getThumbnailUrl(product.productMedia);

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.F6Color,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ẢNH SẢN PHẨM (Giữ nguyên)
          ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: imageUrl.isNotEmpty
                ? Image.network(
              imageUrl,
              width: 90,
              height: 90,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => Container(
                width: 90, height: 90, color: Colors.grey[300],
                child: const Icon(Icons.broken_image, color: Colors.grey),
              ),
            )
                : Container(
              width: 90, height: 90, color: Colors.grey[300],
              child: const Icon(Icons.image, color: Colors.grey),
            ),
          ),

          const SizedBox(width: 14),

          // THÔNG TIN CHÍNH (Giữ nguyên)
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  product.productName,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    fontFamily: 'QuickSand',
                    color: Colors.black,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  product.productCategory.toUpperCase(),
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[500],
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    _buildStatTag(
                      icon: HeroiconsOutline.eye,
                      text: '0',
                      bgColor: const Color(0xFFFFF0E3),
                      textColor: const Color(0xFFFF9C54),
                    ),
                    const SizedBox(width: 8),
                    _buildStatTag(
                      icon: HeroiconsOutline.currencyDollar,
                      text: _formatCurrency(product.productPrice),
                      bgColor: const Color(0xFFFCEEEB),
                      textColor: const Color(0xFFE55858),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // MENU & NGÀY GIỜ
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () {
                  _showProductOptions(context, product);
                },
                child: const Icon(HeroiconsOutline.ellipsisHorizontal, color: Colors.black, size: 22),
              ),
              const SizedBox(height: 35),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  const Text(
                    'Date',
                    style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.black),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    _formatDate(product.createdAt, 'dd MMM yyyy'),
                    style: TextStyle(fontSize: 10, color: Colors.grey[500]),
                  ),
                  Text(
                    _formatDate(product.createdAt, 'hh:mm a'),
                    style: TextStyle(fontSize: 10, color: Colors.grey[500]),
                  ),
                ],
              )
            ],
          )
        ],
      ),
    );
  }

  Widget _buildStatTag({
    required IconData icon,
    required String text,
    required Color bgColor,
    required Color textColor
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Icon(icon, size: 12, color: textColor),
          const SizedBox(width: 4),
          Text(
            text,
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.bold,
              color: textColor,
            ),
          ),
        ],
      ),
    );
  }
  Widget _buildOptionButton({
    required IconData icon,
    required String label,
    required Color iconColor,
    required Color bgColor,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(30),
          border: Border.all(color: Colors.grey.shade200), // Viền nhẹ
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
            )
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: bgColor, // Màu nền icon
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: iconColor, size: 20),
            ),
            const SizedBox(width: 16),
            Text(
              label,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
            ),
          ],
        ),
      ),
    );
  }
}