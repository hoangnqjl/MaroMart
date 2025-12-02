import 'package:flutter/material.dart';
import 'package:maromart/Colors/AppColors.dart';
import 'package:maromart/components/Post.dart';
import 'package:maromart/models/Product/Product.dart';
import 'package:maromart/models/User/User.dart';
import 'package:maromart/services/user_service.dart';
import 'package:maromart/services/product_service.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  State<StatefulWidget> createState() => HomeScreenState();
}

class HomeScreenState extends State<HomeScreen> {
  final UserService _userService = UserService();
  final ProductService _productService = ProductService();

  final ScrollController _scrollController = ScrollController();

  User? _currentUser;
  final List<Product> _products = [];

  bool _isInitialLoading = true;
  bool _isLoadingMore = false;
  bool _hasMore = true;
  int _currentPage = 1;
  final int _limit = 5;

  String? _filterCategoryId;
  String? _filterProvince;
  String? _filterWard;

  @override
  void initState() {
    super.initState();
    _fetchCurrentUser();
    _loadProducts(isRefresh: true);

    // Lắng nghe scroll để load more
    _scrollController.addListener(() {
      if (_scrollController.position.pixels >= _scrollController.position.maxScrollExtent - 200) {
        _loadProducts(isRefresh: false);
      }
    });

    // --- THÊM MỚI: Lắng nghe thay đổi từ ProductService ---
    _productService.productChangeNotifier.addListener(_onProductChanged);
  }

  @override
  void dispose() {
    // --- THÊM MỚI: Hủy lắng nghe ---
    _productService.productChangeNotifier.removeListener(_onProductChanged);
    _scrollController.dispose();
    super.dispose();
  }

  // --- THÊM MỚI: Hàm xử lý khi có thay đổi ---
  void _onProductChanged() {
    if (mounted) {
      print("Data changed, reloading...");
      _loadProducts(isRefresh: true);
    }
  }

  // Hàm này được gọi từ TopBar
  void updateFilter({String? categoryId, String? province, String? ward}) {
    print("Filter: Cat=$categoryId, Prov=$province, Ward=$ward");
    setState(() {
      _filterCategoryId = categoryId;
      _filterProvince = province;
      _filterWard = ward;
    });
    // Khi có bộ lọc mới, reset về trang 1 và tải lại
    _loadProducts(isRefresh: true);
  }

  Future<void> _loadProducts({required bool isRefresh}) async {
    // Nếu đang tải thêm hoặc hết dữ liệu (và không phải refresh) thì dừng
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

      // KIỂM TRA: Đang lọc hay đang xem tất cả?
      bool isFiltering = _filterCategoryId != null || _filterProvince != null || _filterWard != null;

      if (isFiltering) {
        newProducts = await _productService.getProductsByFilter(
          categoryId: _filterCategoryId,
          province: _filterProvince,
          ward: _filterWard,
        );
        // Giả sử filter trả về hết 1 lần -> hasMore = false
        _hasMore = false;
      } else {
        // GỌI API GET ALL (Phân trang)
        newProducts = await _productService.getProducts(
          page: _currentPage,
          limit: _limit,
        );
      }

      if (mounted) {
        setState(() {
          if (newProducts.isEmpty) {
            if (!isFiltering) _hasMore = false; // Hết dữ liệu phân trang
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
      print('Lỗi tải sản phẩm: $e');
    }
  }

  Future<void> _fetchCurrentUser() async {
    try {
      final user = await _userService.getCurrentUser();
      if (mounted) setState(() => _currentUser = user);
    } catch (_) {}
  }

  String get greetingName => _currentUser?.fullName ?? 'Friend';

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.only(top: 10, left: 16, right: 16),
      child: RefreshIndicator(
        onRefresh: () async => _loadProducts(isRefresh: true),
        child: ListView(
          controller: _scrollController,
          physics: const AlwaysScrollableScrollPhysics(),
          children: [
            // HEADER
            _buildHeader(),

            // PRODUCT LIST
            if (_isInitialLoading && _products.isEmpty)
              const Padding(padding: EdgeInsets.all(32.0), child: Center(child: CircularProgressIndicator()))
            else if (_products.isEmpty)
              const Padding(padding: EdgeInsets.only(top: 40), child: Center(child: Text('Không tìm thấy sản phẩm nào.', style: TextStyle(color: Colors.grey))))
            else
              Column(
                children: [
                  ..._products.map((p) => Padding(
                    padding: const EdgeInsets.only(bottom: 20.0),
                    child: Post(product: p),
                  )).toList(),

                  if (_isLoadingMore)
                    const Padding(padding: EdgeInsets.all(16.0), child: Center(child: CircularProgressIndicator(strokeWidth: 2))),

                  if (!_hasMore && !_isInitialLoading)
                    _buildEndOfListMessage(),
                ],
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 6),
      decoration: BoxDecoration(color: AppColors.E2Color, borderRadius: BorderRadius.circular(30)),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 10),
                Text('Hi $greetingName!', style: const TextStyle(fontSize: 12, fontFamily: 'QuickSand', fontWeight: FontWeight.w600)),
                const SizedBox(height: 10),
                const Text('Turn your stuff into cash it only takes a minute to post', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w200)),
                const SizedBox(height: 10),
                GestureDetector(
                  onTap: () => Navigator.pushNamed(context, '/add_product'),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 8),
                    decoration: BoxDecoration(color: AppColors.ButtonBlackColor, borderRadius: BorderRadius.circular(30)),
                    child: const Text('Sell now', style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w600)),
                  ),
                )
              ],
            ),
          ),
          Image.asset('lib/images/twomen.png', width: 120, fit: BoxFit.contain)
        ],
      ),
    );
  }

  Widget _buildEndOfListMessage() {
    return Padding(
      padding: const EdgeInsets.only(top: 20.0, bottom: 100),
      child: Center(
        child: Column(
          children: [
            Icon(Icons.check_circle_outline, color: Colors.grey[300], size: 40),
            const SizedBox(height: 8),
            const Text("You're all caught up!", style: TextStyle(color: Colors.grey)),
          ],
        ),
      ),
    );
  }
}