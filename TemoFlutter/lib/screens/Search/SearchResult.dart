import 'package:flutter/material.dart';
import 'package:heroicons_flutter/heroicons_flutter.dart';
import 'package:temo/components/Post.dart';
import 'package:temo/models/Product/Product.dart';
import 'package:temo/services/product_service.dart';
import 'package:temo/components/Skeletons/ProductCardSkeleton.dart';

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
  bool _isAISearch = false;
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
      _isAISearch = false;
    });

    try {
      final results = await _productService.searchProducts(widget.keyword);

      if (mounted) {
        if (results.length < 2) {
          // Nếu kết quả quá ít hoặc không có, gọi AI để bổ sung
          _doAISearch();
        } else {
          setState(() {
            _products = results;
            _isLoading = false;
          });
        }
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

  Future<void> _doAISearch() async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
      _isAISearch = true;
    });

    try {
      final results = await _productService.semanticSearch(widget.keyword);

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
          _errorMessage = "Lỗi AI Search: ${e.toString()}";
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
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Search Results",
              style: TextStyle(color: Colors.black, fontSize: 12, fontWeight: FontWeight.w400),
            ),
            Text(
              '"${widget.keyword}"',
              style: const TextStyle(color: Colors.black, fontSize: 16, fontWeight: FontWeight.bold),
            ),
          ],
        ),
        centerTitle: false,
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return GridView.builder(
        padding: const EdgeInsets.all(16),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          mainAxisExtent: 305,
        ),
        itemCount: 6,
        itemBuilder: (context, index) => const ProductCardSkeleton(),
      );
    }

    if (_errorMessage.isNotEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(HeroiconsOutline.exclamationTriangle, size: 48, color: Colors.orange),
            const SizedBox(height: 10),
            Text("Error: $_errorMessage", style: const TextStyle(color: Colors.grey)),
            TextButton(onPressed: _doSearch, child: const Text("Try Again"))
          ],
        ),
      );
    }

    final double screenWidth = MediaQuery.of(context).size.width;

    return Column(
      children: [
        if (_products.isEmpty)
           Expanded(
             child: Center(
               child: Column(
                 mainAxisAlignment: MainAxisAlignment.center,
                 children: [
                   const Icon(HeroiconsOutline.magnifyingGlass, size: 60, color: Colors.grey),
                   const SizedBox(height: 16),
                   Text(
                     'No products found for "${widget.keyword}"',
                     style: const TextStyle(color: Colors.grey, fontSize: 16),
                   ),
                 ],
               ),
             ),
           )
        else
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 100),
              itemCount: _products.length,
              itemBuilder: (context, index) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 20),
                  child: SizedBox(
                    height: screenWidth * 1.4,
                    child: Post(product: _products[index]),
                  ),
                );
              },
            ),
          ),
      ],
    );
  }
}
