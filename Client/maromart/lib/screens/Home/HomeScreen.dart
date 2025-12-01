import 'package:flutter/cupertino.dart';
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

  User? _currentUser;
  List<Product> _products = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchCurrentUser();
    _fetchProducts();
  }

  void updateFilter({String? categoryId, String? province, String? ward}) {
    print("HomeScreen applying filter: Cat=$categoryId, Prov=$province, Ward=$ward");
    _fetchProducts(categoryId: categoryId, province: province, ward: ward);
  }

  Future<void> _fetchCurrentUser() async {
    final userFromStorage = _userService.getCurrentUserFromStorage();

    if (userFromStorage != null) {
      setState(() {
        _currentUser = userFromStorage;
      });
    }
    try {
      final user = await _userService.getCurrentUser();
      if (mounted) {
        setState(() {
          _currentUser = user;
        });
      }
    } catch (e) {
      if (mounted) {
        print('Lỗi khi lấy thông tin user: $e');
      }
    }
  }

  Future<void> _fetchProducts({String? categoryId, String? province, String? ward}) async {
    setState(() {
      _isLoading = true;
    });
    try {
      final products = await _productService.getProductsByFilter(
          categoryId: categoryId,
          province: province,
          ward: ward
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
      print('Lỗi khi lấy danh sách sản phẩm: $e');
    }
  }

  String get greetingName {
    if (_isLoading) {
      return 'Guest';
    }
    return _currentUser?.displayName ?? 'Friend';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.only(top: 10, left: 16, right: 16),
      child: ListView(
        children: [
          Container(
            margin: const EdgeInsets.only(bottom: 20, top: 0),
            padding: const EdgeInsets.only(
                top: 10, right: 16, left: 16, bottom: 6),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(30),
              color: AppColors.E2Color,
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 10),
                      Text(
                        'Hi $greetingName!',
                        style: const TextStyle(
                          fontSize: 12,
                          fontFamily: 'QuickSand',
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 10),
                      const Text(
                        'Turn your stuff into cash it only takes a minute to post',
                        style: TextStyle(fontSize: 12, fontWeight: FontWeight.w200),
                        softWrap: true,
                      ),
                      const SizedBox(height: 10),
                      GestureDetector(
                        onTap: () {
                          // Điều hướng sang màn hình bán hàng nếu cần
                          Navigator.pushNamed(context, '/add_product');
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 28, vertical: 8),
                          decoration: BoxDecoration(
                            color: AppColors.ButtonBlackColor,
                            borderRadius: BorderRadius.circular(30),
                          ),
                          child: const Text(
                            'Sell now',
                            style: TextStyle(
                                color: Colors.white,
                                fontSize: 11,
                                fontWeight: FontWeight.w600),
                          ),
                        ),
                      )
                    ],
                  ),
                ),
                Container(
                  child: Image.asset(
                    'lib/images/twomen.png',
                    width: 120,
                    fit: BoxFit.contain,
                  ),
                )
              ],
            ),
          ),

          // --- PRODUCT LIST SECTION ---
          _isLoading
              ? const Center(child: Padding(
            padding: EdgeInsets.all(32.0),
            child: CircularProgressIndicator(),
          ))
              : _products.isEmpty
              ? const Center(
            child: Padding(
              padding: EdgeInsets.only(top: 20),
              child: Text('Không tìm thấy sản phẩm nào.', style: TextStyle(color: Colors.grey)),
            ),
          )
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
                padding: const EdgeInsets.only(top: 30.0, bottom : 100),
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
}