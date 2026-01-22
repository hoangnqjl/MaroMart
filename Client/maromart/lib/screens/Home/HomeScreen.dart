import 'package:flutter/material.dart';
import 'package:maromart/Colors/AppColors.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import 'package:maromart/components/Post.dart';
import 'package:maromart/models/Product/Product.dart';
import 'package:maromart/components/ProductFlashCard.dart' as import_ProductFlashCard;
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

  bool _isFlashCardMode = true; // Default to immersive mode

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white,
      child: Column(
        children: [
          // CUSTOM HEADER with Toggle
          _buildHeader(),
          
          // TOGGLE BAR (Optional, or integrate into Header)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                 const Text("For You", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                 Row(
                   children: [
                     IconButton(
                       icon: Icon(Icons.view_agenda, color: _isFlashCardMode ? Colors.black : Colors.grey),
                       onPressed: () => setState(() => _isFlashCardMode = true),
                     ),
                     IconButton(
                       icon: Icon(Icons.grid_view, color: !_isFlashCardMode ? Colors.black : Colors.grey),
                       onPressed: () => setState(() => _isFlashCardMode = false),
                     ),
                   ],
                 )
              ],
            ),
          ),

          // LIST CONTENT
          Expanded(
            child: RefreshIndicator(
              onRefresh: () async => _loadProducts(isRefresh: true),
              child: _products.isEmpty 
                 ? (_isInitialLoading 
                     ? const Center(child: CircularProgressIndicator()) 
                     : const Center(child: Text("No products found.")))
                 : _buildProductList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProductList() {
    if (_isFlashCardMode) {
      // MODE 1: FLASH CARD (PageView Vertical)
      return PageView.builder(
        scrollDirection: Axis.vertical,
        controller: PageController(viewportFraction: 1.0), // Full screen feel
        itemCount: _products.length,
        itemBuilder: (context, index) {
          if (index == _products.length - 1 && _hasMore) {
             _loadProducts(isRefresh: false); // Lazy load
          }
          return Padding(
            padding: const EdgeInsets.only(bottom: 0), // Full tight layout
            child: import_ProductFlashCard.ProductFlashCard( // Resolving naming conflict if any
              product: _products[index],
              onTap: () {
                 // Navigate to details if needed
              },
            ),
          );
        },
      );
    } else {
      // MODE 2: GRID 2x2
      return GridView.builder(
        padding: const EdgeInsets.all(10),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          childAspectRatio: 0.7,
          crossAxisSpacing: 10,
          mainAxisSpacing: 10,
        ),
        itemCount: _products.length,
        itemBuilder: (context, index) {
           return Post(product: _products[index]); // Use existing Post for grid or create new GridItem
        },
      );
    }
  }

  // Simplified Header
  Widget _buildHeader() {
    return SafeArea(
      bottom: false,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
             Column(
               crossAxisAlignment: CrossAxisAlignment.start,
               children: [
                 Text('Location', style: TextStyle(color: Colors.grey[600], fontSize: 12)),
                 const Row(
                   children: [
                     Icon(Icons.location_on, size: 14, color: Colors.black),
                     SizedBox(width: 4),
                     Text('An Khe, Da Nang', style: TextStyle(fontWeight: FontWeight.bold)),
                   ],
                 )
               ],
             ),
             CircleAvatar(
               backgroundColor: Colors.grey[200],
               backgroundImage: (_currentUser?.avatarUrl?.isNotEmpty == true) 
                   ? NetworkImage(_currentUser!.avatarUrl!) 
                   : null,
               child: (_currentUser?.avatarUrl?.isEmpty ?? true) 
                   ? const Icon(Icons.person) 
                   : null,
             )
          ],
        ),
      ),
    );
  }
}