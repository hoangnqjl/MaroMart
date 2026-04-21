import 'package:flutter/material.dart';
import 'package:temo/Colors/AppColors.dart';
import 'package:heroicons_flutter/heroicons_flutter.dart';
import 'package:intl/intl.dart';
import 'package:temo/Colors/AppColors.dart';
import 'package:temo/models/Product/Product.dart';
import 'package:temo/screens/Product/UpdateProduct.dart';
import 'package:temo/screens/Product/AddProduct.dart'; // Add this import
import 'package:temo/screens/Product/ProductDetail.dart';
import 'package:temo/services/product_service.dart';
import 'package:temo/services/user_service.dart';
import 'package:temo/utils/constants.dart';
import 'package:temo/app_router.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:temo/components/ModernLoader.dart'; // Import
import 'package:temo/components/CommonAppBar.dart';

import 'package:temo/components/TerminalButton.dart';

class ProductManager extends StatefulWidget {
  final VoidCallback? onMenuTap;
  const ProductManager({super.key, this.onMenuTap});

  @override
  State<ProductManager> createState() => ProductManagerState(); // Public State
}

class ProductManagerState extends State<ProductManager> with SingleTickerProviderStateMixin { // Rename
  late TabController _tabController;
  final List<String> _tabs = ['Đang bán', 'Bản nháp', 'Chờ duyệt'];
  final ProductService _productService = ProductService();
  final UserService _userService = UserService();
  final Color primaryThemeColor = AppColors.primary;

  List<Product> _products = [];
  bool _isLoading = true;

  // Search & Filter State
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();
  String _searchQuery = "";
  int _selectedFilter = 0; // 0: All, 1: Newest, 2: Price Low-High, 3: Price High-Low
  int _selectedStatusIndex = 0; // 0: Đang bán (active), 1: Bản nháp (draft), 2: Chờ duyệt (pending)

  @override
  void initState() {
    super.initState();
    _fetchUserProducts();
    
    _searchFocusNode.addListener(() {
      if (mounted) setState(() {});
    });
    _searchController.addListener(() {
      setState(() => _searchQuery = _searchController.text.toLowerCase());
    });
  }
  
  void _handleTabSelection() {
    if (_tabController.indexIsChanging) {
       _fetchUserProducts();
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocusNode.dispose();
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
      switch (_selectedStatusIndex) {
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
        title: const Text("Xóa tin đăng"),
        content: const Text("Bạn có chắc chắn muốn xóa sản phẩm này? Hành động này không thể hoàn tác."),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text("Hủy", style: TextStyle(color: Colors.grey)),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              _deleteProduct(product.productId);
            },
            child: const Text("Xóa", style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
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
          const SnackBar(content: Text("Xóa sản phẩm thành công")),
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
                  const Text("Đẩy tin / Ưu tiên hiển thị", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, fontFamily: 'Quicksand')),
                  const SizedBox(height: 8),
                  Text("Sản phẩm của bạn sẽ được ưu tiên hiển thị ở đầu danh sách tìm kiếm.", style: TextStyle(color: Colors.grey[600], fontSize: 14, fontFamily: 'Quicksand')),
                  
                  const SizedBox(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text("Số dư hiện tại:", style: TextStyle(fontWeight: FontWeight.bold, fontFamily: 'Quicksand')),
                      Text("$currentCoins Xu", style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.amber, fontSize: 16, fontFamily: 'Quicksand')),
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
                                Text(opt['label'], style: TextStyle(fontWeight: FontWeight.bold, color: isSelected ? Colors.green : Colors.black, fontFamily: 'Quicksand')),
                                Text("${opt['coins']} Xu", style: TextStyle(fontWeight: FontWeight.bold, color: isSelected ? Colors.green : Colors.black, fontFamily: 'Quicksand')),
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
                        canAfford ? "Thanh toán & Đẩy tin ngay ($cost Xu)" : "Nạp thêm Xu",
                        style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white, fontFamily: 'Quicksand'),
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
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Đã đẩy tin thành công!"), backgroundColor: Colors.green));
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
              Center(
                child: Container(
                  width: 40, height: 4,
                  margin: const EdgeInsets.only(bottom: 24),
                  decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(2)),
                ),
              ),
              _buildOptionButton(
                icon: HeroiconsOutline.arrowTrendingUp,
                label: 'Đẩy tin / Ưu tiên',
                iconColor: Colors.orange,
                bgColor: const Color(0xFFFFF4E5),
                onTap: () {
                  Navigator.pop(ctx);
                  _showPushSheet(context, product);
                },
              ),
              const SizedBox(height: 12),
              _buildOptionButton(
                icon: HeroiconsOutline.pencilSquare,
                label: 'Chỉnh sửa tin',
                iconColor: Colors.blue,
                bgColor: const Color(0xFFE3F2FD),
                onTap: () async {
                  Navigator.pop(ctx);
                  final result = await smoothPush(context, UpdateProduct(product: product));
                  if (result == true) _fetchUserProducts();
                },
              ),
              const SizedBox(height: 12),
              _buildOptionButton(
                icon: HeroiconsOutline.trash,
                label: 'Xóa tin này',
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
        body: Stack(
          children: [
            Column(
              children: [
                const SizedBox(height: 160), 
                Expanded(
                  child: _isLoading
                      ? Center(child: ModernLoader(color: primaryThemeColor))
                      : _buildProductList(),
                ),
              ],
            ),
            Positioned(
              top: 0, left: 0, right: 0,
              child: _buildCustomHeader(),
            ),
          ],
        ),
    );
  }

  Widget _buildCustomHeader() {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                GestureDetector(
                  onTap: widget.onMenuTap,
                  child: Container(
                    width: 44, height: 44,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.95),
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.black.withOpacity(0.08), width: 0.5),
                      boxShadow: [
                        BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4))
                      ],
                    ),
                    child: const Icon(HeroiconsOutline.bars3BottomLeft, color: Color(0xFF4B5563), size: 24),
                  ),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.95),
                    borderRadius: BorderRadius.circular(100),
                    border: Border.all(color: Colors.black.withOpacity(0.08), width: 0.5),
                    boxShadow: [
                      BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4))
                    ],
                  ),
                  child: Text(
                    "Quản lý sản phẩm",
                    style: GoogleFonts.roboto(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF4B5563),
                    ),
                  ),
                ),
                const Spacer(),
                const SizedBox(width: 44),
              ],
            ),
            const SizedBox(height: 12),
            // Row 2: Search & Filter
            Row(
              children: [
                Expanded(
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    height: 48,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(50),
                      color: Colors.white,
                      gradient: _searchFocusNode.hasFocus 
                        ? const LinearGradient(colors: [Color(0xFFFFB86A), Color(0xFFFB7C7F)])
                        : null,
                      border: _searchFocusNode.hasFocus ? null : Border.all(color: const Color(0x1F000000), width: 1.5),
                    ),
                    child: Container(
                      margin: _searchFocusNode.hasFocus ? const EdgeInsets.all(1.5) : EdgeInsets.zero,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(50),
                      ),
                      child: Row(
                        children: [
                          const SizedBox(width: 14),
                          Icon(HeroiconsOutline.magnifyingGlass, color: Colors.grey[400], size: 18),
                          const SizedBox(width: 10),
                          Expanded(
                            child: TextField(
                              controller: _searchController,
                              focusNode: _searchFocusNode,
                              decoration: InputDecoration(
                                hintText: "Tìm sản phẩm...",
                                hintStyle: GoogleFonts.quicksand(color: Colors.grey[400], fontSize: 14, fontWeight: FontWeight.w600),
                                border: InputBorder.none,
                                isDense: true,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Theme(
                  data: Theme.of(context).copyWith(
                    hoverColor: Colors.transparent,
                    splashColor: Colors.transparent,
                    highlightColor: Colors.transparent,
                  ),
                  child: PopupMenuButton<int>(
                    offset: const Offset(0, 52),
                    padding: EdgeInsets.zero,
                    color: Colors.white,
                    elevation: 10,
                    icon: Container(
                      width: 48, height: 48,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                        border: Border.all(color: const Color(0x1F000000), width: 1.5),
                      ),
                      child: Icon(HeroiconsOutline.adjustmentsHorizontal, color: Colors.grey[600], size: 20),
                    ),
                    onSelected: (val) {
                      if (val >= 10) {
                        setState(() => _selectedFilter = val - 10);
                      } else {
                        setState(() {
                          _selectedStatusIndex = val;
                          _fetchUserProducts();
                        });
                      }
                    },
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                    itemBuilder: (context) => [
                      _buildFilterItemHeader("TRẠNG THÁI"),
                      _buildStatusMenuItem(0, "Đang bán", HeroiconsOutline.checkBadge, Colors.orange),
                      _buildStatusMenuItem(1, "Bản nháp", HeroiconsOutline.pencilSquare, Colors.blue),
                      _buildStatusMenuItem(2, "Chờ duyệt", HeroiconsOutline.clock, Colors.purple),
                      const PopupMenuDivider(),
                      _buildFilterItemHeader("SẮP XẾP"),
                      _buildSortMenuItem(10, "Mới nhất", HeroiconsOutline.sparkles, Colors.deepPurple),
                      _buildSortMenuItem(11, "Giá: Thấp -> Cao", HeroiconsOutline.barsArrowUp, Colors.green),
                      _buildSortMenuItem(12, "Giá: Cao -> Thấp", HeroiconsOutline.barsArrowDown, Colors.teal),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  PopupMenuItem<int> _buildFilterItemHeader(String title) {
    return PopupMenuItem<int>(
      enabled: false,
      height: 30,
      child: Text(
        title,
        style: GoogleFonts.quicksand(fontSize: 11, fontWeight: FontWeight.w800, color: Colors.grey[400], letterSpacing: 1.2),
      ),
    );
  }

  PopupMenuItem<int> _buildStatusMenuItem(int value, String label, IconData icon, Color color) {
    final isSelected = _selectedStatusIndex == value;
    return PopupMenuItem(
      value: value,
      height: 52,
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 18, color: color),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              label,
              style: GoogleFonts.quicksand(
                fontSize: 14,
                fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                color: color,
              ),
            ),
          ),
          if (isSelected)
            Icon(HeroiconsOutline.check, size: 18, color: color),
        ],
      ),
    );
  }

  PopupMenuItem<int> _buildSortMenuItem(int value, String label, IconData icon, Color color) {
    final isSelected = _selectedFilter == (value - 10);
    return PopupMenuItem(
      value: value,
      height: 52,
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 18, color: color),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              label,
              style: GoogleFonts.quicksand(
                fontSize: 14,
                fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                color: color,
              ),
            ),
          ),
          if (isSelected)
            Icon(HeroiconsOutline.check, size: 18, color: color),
        ],
      ),
    );
  }
  
  Widget _buildProductList() {
    // 1. Filter by Search Query
    List<Product> filtered = _products;
    if (_searchQuery.isNotEmpty) {
      filtered = filtered.where((p) => p.productName.toLowerCase().contains(_searchQuery)).toList();
    }

    // 2. Filter by Sort Option
    if (_selectedFilter == 0) { // Newest (Default/All)
       // Keep order
    } else if (_selectedFilter == 1) { // Price Low-High
      filtered.sort((a, b) => a.productPrice.compareTo(b.productPrice));
    } else if (_selectedFilter == 2) { // Price High-Low
      filtered.sort((a, b) => b.productPrice.compareTo(a.productPrice));
    }

    if (filtered.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(HeroiconsOutline.shoppingBag, size: 64, color: Colors.grey[200]),
            const SizedBox(height: 16),
            Text(
              _searchQuery.isEmpty ? "Không có sản phẩm nào" : "Không tìm thấy sản phẩm",
              style: GoogleFonts.quicksand(color: Colors.grey[400], fontWeight: FontWeight.bold),
            ),
          ],
        ),
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 40),
      itemCount: filtered.length,
      itemBuilder: (context, index) => _buildProductCard(filtered[index]),
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
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
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
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.03),
              blurRadius: 5,
              offset: const Offset(0, 2),
            ),
          ],
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