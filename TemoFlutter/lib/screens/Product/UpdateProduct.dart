import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:temo/components/FloatingHeader.dart';
import 'package:temo/components/ModernLoader.dart';
import 'package:heroicons_flutter/heroicons_flutter.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:http/http.dart' as http;
import 'package:temo/services/product_service.dart';
import 'package:temo/utils/constants.dart';
import 'package:temo/Colors/AppColors.dart';

import 'package:temo/models/Product/Product.dart';

class UpdateProduct extends StatefulWidget {
  final Product product;
const UpdateProduct({super.key, required this.product});

  @override
  State<UpdateProduct> createState() => _UpdateProductState();
}

class AttributeItem {
  final TextEditingController nameController;
  final TextEditingController valueController;
  AttributeItem({required String name, String value = ""})
      : nameController = TextEditingController(text: name),
        valueController = TextEditingController(text: value);
}

class _UpdateProductState extends State<UpdateProduct> {
  final Map<String, List<String>> _attributeTemplates = {
    "Fashion": ["Material", "Size", "Color", "Style"],
    "Electronics": ["Screen Size", "RAM", "Storage", "Battery"],
    "Furniture": ["Dimension", "Material", "Color"],
    "Others": ["Custom Label"]
  };
  
  final _productService = ProductService();
  final _titleController = TextEditingController();
  final _priceController = TextEditingController();
  final _descController = TextEditingController();
  final _conditionController = TextEditingController();
  final _brandController = TextEditingController();
  final _originController = TextEditingController();
  final _policyController = TextEditingController();
  final _addressDetailController = TextEditingController();

  String? _selectedCategory;
  String? _selectedProvinceCode;
  String? _selectedProvinceName;
  String? _selectedWardCode;
  String? _selectedWardName;

  List<dynamic> _provinces = [];
  List<dynamic> _wards = [];
  List<XFile> _selectedImages = [];
  List<XFile> _selectedVideos = [];
  List<String> _oldMediaUrls = [];

  bool _isLoading = true;
  bool _isUpdating = false;

  List<AttributeItem> _attributes = [];

  @override
  void initState() {
    super.initState();
    _initData();
    _loadProvinces();
  }

  void _initData() {
    final p = widget.product;
    _titleController.text = p.productName;
    _priceController.text = p.productPrice.toString();
    _descController.text = p.productDescription;
    _conditionController.text = p.productCondition;
    _brandController.text = p.productBrand;
    _originController.text = p.productOrigin;
    _policyController.text = p.productWP;
    
    _selectedCategory = p.productCategory;
    _oldMediaUrls = List<String>.from(p.productMedia);
    
    if (p.productAddress != null) {
      _selectedProvinceName = p.productAddress!.province;
      _selectedWardName = p.productAddress!.commute;
      _addressDetailController.text = p.productAddress!.detail;
    }

    if (p.productAttribute != null) {
        if (p.productAttribute is Map) {
            (p.productAttribute as Map<String, dynamic>).forEach((key, value) {
                 _attributes.add(AttributeItem(name: key, value: value.toString()));
            });
        }
    }

    setState(() => _isLoading = false);
  }

  // Load provinces logic... (simplified here, but should match actual service)
  Future<void> _loadProvinces() async {
    // Implementation here...
  }

  Future<void> _loadWards(String provinceCode) async {
    // Implementation here...
  }

  void _pickImages() async {
    final picker = ImagePicker();
    final picked = await picker.pickMultiImage();
    if (picked != null) setState(() => _selectedImages.addAll(picked));
  }

  void _pickVideo() async {
    final picker = ImagePicker();
    final picked = await picker.pickVideo(source: ImageSource.gallery);
    if (picked != null) setState(() => _selectedVideos.add(picked));
  }

  void _removeOldMedia(int index) {
    setState(() => _oldMediaUrls.removeAt(index));
  }

  void _removeNewImage(int index) {
    setState(() => _selectedImages.removeAt(index));
  }

  void _removeNewVideo(int index) {
    setState(() => _selectedVideos.removeAt(index));
  }

  void _onCategoryChanged(String? val, {bool reset = true}) {
    setState(() {
      _selectedCategory = val;
      if (reset) {
        _attributes = (_attributeTemplates[val] ?? [])
            .map((e) => AttributeItem(name: e))
            .toList();
      }
    });
  }

  String _getFullUrl(String url) {
    if (url.startsWith('http')) return url;
    return '${ApiConstants.baseUrl}$url';
  }

  Future<void> _updateProduct() async {
    // Implementation here...
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
          body: Center(child: ModernLoader())
      );
    }

    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            physics: const BouncingScrollPhysics(),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 110),
                _buildSectionTitle("Ảnh và Video hiện tại"),
                const SizedBox(height: 12),
                if (_oldMediaUrls.isNotEmpty)
                  SizedBox(
                    height: 100,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      itemCount: _oldMediaUrls.length,
                      itemBuilder: (context, index) {
                        final url = _getFullUrl(_oldMediaUrls[index]);
                        return Stack(
                          children: [
                            Container(
                              width: 100,
                              margin: const EdgeInsets.only(right: 12),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(16),
                                color: Colors.grey[200],
                                image: DecorationImage(image: NetworkImage(url), fit: BoxFit.cover),
                              ),
                            ),
                            Positioned(
                              top: 4, right: 16,
                              child: GestureDetector(
                                onTap: () => _removeOldMedia(index),
                                child: Container(
                                  padding: const EdgeInsets.all(2),
                                  decoration: const BoxDecoration(color: Colors.red, shape: BoxShape.circle),
                                  child: const Icon(Icons.close, size: 14, color: Colors.white),
                                ),
                              ),
                            )
                          ],
                        );
                      },
                    ),
                  ),
                
                const SizedBox(height: 24),
                _buildSectionTitle("Thông tin cơ bản"),
                const SizedBox(height: 12),
                _buildTextField(controller: _titleController, hint: "Tên sản phẩm"),
                const SizedBox(height: 12),
                _buildTextField(controller: _priceController, hint: "Giá bán", keyboardType: TextInputType.number),
                const SizedBox(height: 12),
                _buildTextField(controller: _descController, hint: "Mô tả chi tiết", maxLines: 4),

                const SizedBox(height: 40),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _updateProduct,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.black,
                      foregroundColor: Colors.white,
                      shape: const StadiumBorder(),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    child: const Text("Cập nhật tin đăng"),
                  ),
                ),
                const SizedBox(height: 100),
              ],
            ),
          ),
          Positioned(
            top: 0, left: 0, right: 0,
            child: const FloatingHeader(title: "Chỉnh sửa tin đăng"),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(title, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold));
  }

  Widget _buildTextField({required TextEditingController controller, required String hint, TextInputType keyboardType = TextInputType.text, int maxLines = 1, bool readOnly = false}) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      maxLines: maxLines,
      readOnly: readOnly,
      decoration: InputDecoration(
        hintText: hint,
        filled: true,
        fillColor: readOnly ? Colors.grey[200] : const Color(0xFFF2F2F2),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(30), borderSide: BorderSide.none),
      ),
    );
  }
}