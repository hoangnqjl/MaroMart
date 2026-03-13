import 'package:flutter/material.dart';
import 'package:heroicons_flutter/heroicons_flutter.dart';
import 'package:maromart/components/Post.dart';
import 'package:maromart/models/Product/Product.dart';
import 'package:maromart/services/product_service.dart';
import 'package:maromart/components/ModernLoader.dart';

class CategoryProductsScreen extends StatefulWidget {
  final Map<String, dynamic> category;

  const CategoryProductsScreen({Key? key, required this.category}) : super(key: key);

  @override
  State<CategoryProductsScreen> createState() => _CategoryProductsScreenState();
}

class _CategoryProductsScreenState extends State<CategoryProductsScreen> {
  final ProductService _productService = ProductService();
  List<Product> _products = [];
  bool _isLoading = true;
  String _errorMessage = '';

  @override
  void initState() {
    super.initState();
    _fetchProducts();
  }

  Future<void> _fetchProducts() async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      final results = await _productService.getProductsByCategory(
          categoryId: widget.category['id']
      );

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
      appBar: AppBar(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(HeroiconsOutline.arrowLeft, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          widget.category['name'],
          style: const TextStyle(color: Colors.black, fontSize: 18, fontWeight: FontWeight.bold),
        ),
        centerTitle: false,
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return Center(child: ModernLoader());
    }

    if (_errorMessage.isNotEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(HeroiconsOutline.exclamationTriangle, size: 48, color: Colors.orange),
            const SizedBox(height: 10),
            Text("Lỗi: $_errorMessage", style: const TextStyle(color: Colors.grey)),
            TextButton(onPressed: _fetchProducts, child: const Text("Thử lại"))
          ],
        ),
      );
    }

    if (_products.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(HeroiconsOutline.archiveBoxXMark, size: 60, color: Colors.grey),
            const SizedBox(height: 16),
            Text(
              'Không có sản phẩm nào cho danh mục "${widget.category['name']}"',
              style: const TextStyle(color: Colors.grey, fontSize: 16),
            ),
          ],
        ),
      );
    }

    final double screenWidth = MediaQuery.of(context).size.width;

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 100),
      itemCount: _products.length,
      itemBuilder: (context, index) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 20),
          child: SizedBox(
            height: screenWidth * 1.05,
            child: Post(product: _products[index]),
          ),
        );
      },
    );
  }
}
