import 'package:flutter/material.dart';
import 'package:heroicons_flutter/heroicons_flutter.dart';
import 'package:intl/intl.dart';
import 'package:maromart/Colors/AppColors.dart';
import 'package:maromart/models/Product/Product.dart';
import 'package:maromart/screens/Product/UpdateProduct.dart';
import 'package:maromart/screens/Product/AddProduct.dart'; // Add this import
import 'package:maromart/screens/Product/ProductDetail.dart';
import 'package:maromart/services/product_service.dart';
import 'package:maromart/services/user_service.dart';
import 'package:maromart/utils/constants.dart';
import 'package:maromart/app_router.dart';

import 'package:maromart/components/ModernLoader.dart'; // Import

class ProductManager extends StatefulWidget {
  const ProductManager({super.key});

  @override
  State<ProductManager> createState() => ProductManagerState(); // Public State
}

class ProductManagerState extends State<ProductManager> with SingleTickerProviderStateMixin { // Rename
  late TabController _tabController;
  final List<String> _tabs = ['Active', 'Drafts', 'Hidden'];
  final ProductService _productService = ProductService();
  final UserService _userService = UserService();
  final Color primaryThemeColor = const Color(0xFF3F4045);

  List<Product> _products = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _tabs.length, vsync: this);
    _tabController.addListener(_handleTabSelection);
    _fetchUserProducts();
  }
  
  void _handleTabSelection() {
    if (_tabController.indexIsChanging) {
       _fetchUserProducts();
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  // Public Reload
  void reload() => _fetchUserProducts();

  Future<void> _fetchUserProducts() async {
    setState(() => _isLoading = true);
    try {
      final userId = _userService.getCurrentUserId();
      if (userId == null) {
        setState(() => _isLoading = false);
        return;
      }
      
      String status = 'active';
      switch (_tabController.index) {
          case 0: status = 'active'; break;
          case 1: status = 'draft'; break; 
          case 2: status = 'pending'; break; 
      }

      final products = await _productService.getUserProducts(userId, status: status);

      if (mounted) {
        setState(() {
          _products = products;
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
      builder: (ctx) => const Center(child: ModernLoader()),
    );

    try {
      await _productService.deleteProduct(productId);
      if (mounted) {
        Navigator.pop(context);
        setState(() {
          _products.removeWhere((p) => p.productId == productId);
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

  void _showPushSheet(BuildContext context, Product product) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        int selectedOption = 0;
        final List<Map<String, dynamic>> pushOptions = [
          {'days': 3, 'coins': 2, 'label': '3 Ngày'},
          {'days': 7, 'coins': 4, 'label': '7 Ngày'},
          {'days': 15, 'coins': 7, 'label': '15 Ngày'},
          {'days': 30, 'coins': 10, 'label': '30 Ngày'},
        ];

        return StatefulBuilder(
          builder: (context, setSheetState) {
             final user = _userService.userNotifier.value;
             final currentCoins = user?.coins ?? 0;
             final cost = pushOptions[selectedOption]['coins'];
             final canAfford = currentCoins >= cost;

            return Container(
              height: MediaQuery.of(context).size.height * 0.6,
              padding: const EdgeInsets.all(24),
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 40, height: 4,
                      margin: const EdgeInsets.only(bottom: 20),
                      decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(2)),
                    ),
                  ),
                  const Text("Đẩy tin / Quảng cáo", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  Text("Tin của bạn sẽ được ưu tiên hiển thị trên đầu trang.", style: TextStyle(color: Colors.grey[600], fontSize: 14)),
                  
                  const SizedBox(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text("Số dư của bạn:", style: TextStyle(fontWeight: FontWeight.bold)),
                      Text("$currentCoins Coins", style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.amber, fontSize: 16)),
                    ],
                  ),
                  const SizedBox(height: 16),
                  
                  Expanded(
                    child: ListView.separated(
                      itemCount: pushOptions.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 12),
                      itemBuilder: (context, index) {
                        final opt = pushOptions[index];
                        final isSelected = selectedOption == index;
                        return GestureDetector(
                          onTap: () => setSheetState(() => selectedOption = index),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                            decoration: BoxDecoration(
                              color: isSelected ? const Color(0xFFE8F5E9) : Colors.white,
                              border: Border.all(color: isSelected ? Colors.green : Colors.grey.shade300, width: isSelected ? 2 : 1),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(opt['label'], style: TextStyle(fontWeight: FontWeight.bold, color: isSelected ? Colors.green : Colors.black)),
                                Text("${opt['coins']} Coins", style: TextStyle(fontWeight: FontWeight.bold, color: isSelected ? Colors.green : Colors.black)),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: canAfford ? () async {
                        Navigator.pop(ctx);
                        _handlePushProduct(product.productId, pushOptions[selectedOption]['days']);
                      } : () {
                        Navigator.pop(ctx);
                         // Navigate to Coin Manager
                         Navigator.pushNamed(context, '/coin_manager'); 
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: canAfford ? const Color(0xFF3F4045) : Colors.orange,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      ),
                      child: Text(
                        canAfford ? "Thanh toán & Đẩy tin ($cost Coins)" : "Nạp thêm Coins",
                        style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
                      ),
                    ),
                  )
                ],
              ),
            );
          }
        );
      },
    );
  }

  Future<void> _handlePushProduct(String productId, int days) async {
    showDialog(
      context: context, barrierDismissible: false,
      builder: (_) => const Center(child: ModernLoader()),
    );
    try {
      await _productService.pushProduct(productId, days);
      await _userService.getCurrentUser(); // Refresh balance
      if (mounted) {
        Navigator.pop(context); // Close loading
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Đẩy tin thành công!"), backgroundColor: Colors.green));
      }
    } catch (e) {
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString()), backgroundColor: Colors.red));
      }
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
                icon: HeroiconsOutline.rocketLaunch,
                label: 'Boost / Push Product',
                iconColor: Colors.blue,
                bgColor: const Color(0xFFE3F2FD),
                onTap: () {
                  Navigator.pop(ctx);
                  _showPushSheet(context, product);
                },
              ),
              const SizedBox(height: 12),
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
    return Scaffold(
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
                controller: _tabController,
                indicatorSize: TabBarIndicatorSize.tab,
                labelPadding: EdgeInsets.zero,
                indicator: BoxDecoration(
                  color: primaryThemeColor,
                  borderRadius: BorderRadius.circular(25),
                ),
                dividerColor: Colors.transparent,
                labelColor: Colors.white,
                unselectedLabelColor: Colors.grey[600],
                labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                tabs: _tabs.map((name) => Tab(text: name)).toList(),
                onTap: (index) {
                    if (!_tabController.indexIsChanging) {
                        _fetchUserProducts(); // Force refresh on tap if already selected or not changing via anim
                    }
                },
              ),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: _isLoading
                  ? Center(child: ModernLoader(color: primaryThemeColor)) // Use ModernLoader
                  : TabBarView(
                controller: _tabController,
                children: [
                  _buildProductList(), // Active
                  _buildProductList(), // Drafts
                  _buildProductList(), // Hidden
                ],
              ),
            ),
          ],
        ),
    );
  }
  
  Widget _buildProductList() {
    if (_products.isEmpty) {
        String msg = "No products found";
        if (_tabController.index == 1) msg = "No drafts";
        return _buildPlaceholderList(msg);
    }
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: _products.length,
      itemBuilder: (context, index) => _buildProductCard(_products[index]),
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
      onTap: () {
          if (product.status == 'draft') {
              smoothPush(context, AddProduct(draftProduct: product));
          } else {
              smoothPush(context, ProductDetail(productId: product.productId));
          }
      },
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