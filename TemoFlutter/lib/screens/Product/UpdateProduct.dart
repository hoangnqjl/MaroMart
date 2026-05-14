import 'dart:convert';
import 'dart:io';
import 'dart:ui';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:temo/components/FloatingHeader.dart';
import 'package:temo/components/ModernLoader.dart';
import 'package:heroicons_flutter/heroicons_flutter.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:temo/Colors/AppColors.dart';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:http/http.dart' as http;
import 'package:temo/utils/UIHelper.dart';
import 'package:temo/services/user_service.dart';
import '../../services/product_service.dart';
import 'package:temo/models/Product/Product.dart';
import 'package:intl/intl.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:temo/utils/ui_helpers.dart';
import 'package:temo/utils/constants.dart';
import 'package:shared_preferences/shared_preferences.dart';

// --- HELPER CLASS CHO ATTRIBUTE ---
class AttributeItem {
  TextEditingController nameController = TextEditingController();
  TextEditingController valueController = TextEditingController();

  AttributeItem({String? name, String? value}) {
    if (name != null) nameController.text = name;
    if (value != null) valueController.text = value;
  }

  void dispose() {
    nameController.dispose();
    valueController.dispose();
  }
}

class UpdateProduct extends StatefulWidget {
  final Product product;
  const UpdateProduct({super.key, required this.product});

  @override
  State<UpdateProduct> createState() => _UpdateProductState();
}

class _UpdateProductState extends State<UpdateProduct> {
  final ProductService _productService = ProductService();

  // --- CONTROLLERS ---
  final _titleController = TextEditingController();
  final _priceController = TextEditingController();
  final _descController = TextEditingController();
  final _conditionController = TextEditingController();
  final _brandController = TextEditingController();
  final _policyController = TextEditingController();
  final _originController = TextEditingController();
  final _addressDetailController = TextEditingController();

  // --- STATE ---
  String? _selectedCategory;
  bool _isAiLoading = false;
  bool _isAiValidated = false; 
  bool _contentAlreadyValidated = false; 

  List<String> _oldMediaUrls = [];
  List<XFile> _selectedImages = [];
  List<XFile> _selectedVideos = [];

  List<AttributeItem> _attributes = [];

  // --- ADDRESS ---
  List<dynamic> _provinces = [];
  List<dynamic> _wards = [];
  String? _selectedProvinceName;
  String? _selectedWardName;

  // --- WIZARD STATE ---
  int _currentStep = 0;
  final PageController _pageController = PageController();

  @override
  void initState() {
    super.initState();
    _initData();
    _fetchProvinces();
    _fetchCategoriesFromApi();
  }

  void _initData() {
    final p = widget.product;
    _titleController.text = p.productName;
    _priceController.text = _formatCurrency(p.productPrice.toString());
    _descController.text = p.productDescription;
    _conditionController.text = p.productCondition;
    _brandController.text = p.productBrand;
    _policyController.text = p.productWP;
    _originController.text = p.productOrigin;
    _selectedCategory = p.productCategory;
    _oldMediaUrls = List<String>.from(p.productMedia);

    if (p.productAddress != null) {
      _selectedProvinceName = p.productAddress!.province;
      _selectedWardName = p.productAddress!.commute;
      _addressDetailController.text = p.productAddress!.detail;
    }

    _priceController.addListener(_onFieldChanged);
    _titleController.addListener(_onFieldChanged);
    _descController.addListener(_onFieldChanged);
    _conditionController.addListener(_onFieldChanged);
    _brandController.addListener(_onFieldChanged);
    _policyController.addListener(_onFieldChanged);
    _originController.addListener(_onFieldChanged);
    _addressDetailController.addListener(_onFieldChanged);

    // Mặc định cho là đã duyệt nếu chưa sửa gì
    _isAiValidated = true;
    _contentAlreadyValidated = true;
  }

  void _onFieldChanged() {
    if (mounted) {
      setState(() {
        _contentAlreadyValidated = false;
      });
    }
  }

  @override
  void dispose() {
    for (var attr in _attributes) attr.dispose();
    _titleController.dispose();
    _priceController.dispose();
    _descController.dispose();
    _conditionController.dispose();
    _brandController.dispose();
    _policyController.dispose();
    _originController.dispose();
    _addressDetailController.dispose();
    _pageController.dispose();
    super.dispose();
  }

  // --- COMPARISON LOGIC ---
  bool _isMediaChanged() {
    if (_selectedImages.isNotEmpty || _selectedVideos.isNotEmpty) return true;
    if (_oldMediaUrls.length != widget.product.productMedia.length) return true;
    for (int i = 0; i < _oldMediaUrls.length; i++) {
      if (_oldMediaUrls[i] != widget.product.productMedia[i]) return true;
    }
    return false;
  }

  bool _isContentChanged() {
    if (_titleController.text != widget.product.productName) return true;
    String cleanPrice = _priceController.text.replaceAll('.', '');
    if (cleanPrice != widget.product.productPrice.toString()) return true;
    if (_descController.text != widget.product.productDescription) return true;
    if (_selectedCategory != widget.product.productCategory) return true;
    if (_conditionController.text != widget.product.productCondition) return true;
    if (_brandController.text != widget.product.productBrand) return true;
    if (_originController.text != widget.product.productOrigin) return true;
    if (_policyController.text != widget.product.productWP) return true;
    
    // Check attributes
    Map<String, dynamic> currentAttrs = {};
    for (var attr in _attributes) {
      if (attr.nameController.text.isNotEmpty) currentAttrs[attr.nameController.text] = attr.valueController.text;
    }
    
    Map<String, dynamic> originalAttrs = {};
    if (widget.product.productAttribute != null) {
      if (widget.product.productAttribute is Map) {
        originalAttrs = Map<String, dynamic>.from(widget.product.productAttribute);
      } else if (widget.product.productAttribute is String) {
        try {
          originalAttrs = jsonDecode(widget.product.productAttribute);
        } catch (e) {}
      }
    }

    if (currentAttrs.length != originalAttrs.length) return true;
    for (var key in currentAttrs.keys) {
      if (currentAttrs[key].toString() != originalAttrs[key].toString()) return true;
    }

    return false; 
  }

  bool _isAddressChanged() {
    final p = widget.product.productAddress;
    if (p == null) return _selectedProvinceName != null || _selectedWardName != null || _addressDetailController.text.isNotEmpty;
    
    return _selectedProvinceName != p.province ||
           _selectedWardName != p.commute ||
           _addressDetailController.text != p.detail;
  }

  // --- API DATA ---
  Map<String, List<String>> _attributeTemplates = {};
  Map<String, String> _categoryNames = {};

  Future<void> _fetchCategoriesFromApi() async {
    try {
      final response = await http.get(Uri.parse('${ApiConstants.baseUrl}/categories'));
      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        setState(() {
          for (var cat in data) {
            String catId = cat['categoryId'];
            _categoryNames[catId] = cat['categoryName'];
            List<String> attrs = ["type"];
            if (cat['attributes'] != null) {
              for (var a in cat['attributes']) attrs.add(a['name']);
            }
            _attributeTemplates[catId] = attrs;
          }
          _populateAttributes(widget.product.productAttribute);
        });
      }
    } catch (e) {}
  }

  void _populateAttributes(dynamic attrData) {
    if (_selectedCategory == null) return;
    _attributes.clear();
    
    if (_attributeTemplates.containsKey(_selectedCategory)) {
      for (String key in _attributeTemplates[_selectedCategory]!) {
        _attributes.add(AttributeItem(name: key, value: ""));
      }
    }

    Map<String, dynamic> data = {};
    if (attrData is String) data = jsonDecode(attrData);
    else if (attrData is Map) data = Map<String, dynamic>.from(attrData);

    data.forEach((key, value) {
      int index = _attributes.indexWhere((a) => a.nameController.text.toLowerCase() == key.toLowerCase());
      if (index != -1) {
        _attributes[index].valueController.text = value.toString();
      } else {
        _attributes.add(AttributeItem(name: key, value: value.toString()));
      }
    });
  }

  Future<void> _fetchProvinces() async {
    try {
      final response = await http.get(Uri.parse('https://34tinhthanh.com/api/provinces'));
      if (response.statusCode == 200) setState(() => _provinces = jsonDecode(response.body));
    } catch (e) {}
  }

  Future<void> _fetchWards(String provinceCode) async {
    setState(() => _wards = []);
    try {
      final response = await http.get(Uri.parse('https://34tinhthanh.com/api/wards?province_code=$provinceCode'));
      if (response.statusCode == 200) setState(() => _wards = jsonDecode(response.body));
    } catch (e) {}
  }

  // --- MODERATION HANDLERS ---
  Future<bool> _handleValidateMedia() async {
    // Nếu không thay đổi media HOẶC đã duyệt rồi thì cho qua
    if (!_isMediaChanged()) return true;
    if (_isAiValidated && _selectedImages.isEmpty) return true;

    setState(() => _isAiLoading = true);
    try {
      final result = await _productService.validateMedia(
        _selectedImages,
        _titleController.text,
        remoteUrls: _selectedImages.isEmpty ? _oldMediaUrls : [],
      );

      if (result['is_stock'] == true) {
        _showErrorDialog("Ảnh không hợp lệ (ảnh mạng/quảng cáo). Vui lòng dùng ảnh thật.");
        return false;
      }
      setState(() => _isAiValidated = true);
      return true;
    } catch (e) {
      _showErrorDialog("Lỗi kiểm duyệt ảnh: $e");
      return false;
    } finally {
      setState(() => _isAiLoading = false);
    }
  }

  Future<bool> _handleValidateContent() async {
    // Nếu không thay đổi nội dung HOẶC đã duyệt rồi thì cho qua
    if (!_isContentChanged() || _contentAlreadyValidated) return true;

    setState(() => _isAiLoading = true);
    try {
      Map<String, dynamic> attributesMap = {};
      for (var item in _attributes) {
        attributesMap[item.nameController.text.trim().toLowerCase().replaceAll(' ', '_')] = item.valueController.text.trim();
      }

      final result = await _productService.validateContent(
        productName: _titleController.text,
        productDescription: _descController.text,
        category: _selectedCategory ?? "",
        type: attributesMap['type'] ?? "",
        attributes: attributesMap,
      );

      if (result['is_safe'] == false) {
        _showErrorDialog("Vi phạm tiêu chuẩn cộng đồng: ${result['violation_reason']}");
        return false;
      }
      if (result['is_consistent'] == false) {
        _showErrorDialog("Thông tin không đồng nhất: ${result['inconsistency_reason']}");
        return false;
      }
      setState(() => _contentAlreadyValidated = true);
      return true;
    } catch (e) {
      _showErrorDialog("Lỗi kiểm duyệt nội dung: $e");
      return false;
    } finally {
      setState(() => _isAiLoading = false);
    }
  }

  // --- WIZARD NAVIGATION ---
  void _nextStep() async {
    if (_isAiLoading) return;

    bool isValid = true;
    if (_currentStep == 0) isValid = await _handleValidateMedia();
    else if (_currentStep == 1) isValid = await _handleValidateContent();
    else if (_currentStep == 2) isValid = true; // Địa chỉ

    if (isValid) {
      if (_currentStep < 3) {
        setState(() => _currentStep++);
        _pageController.nextPage(duration: const Duration(milliseconds: 300), curve: Curves.easeInOut);
      } else {
        _submitUpdate();
      }
    }
  }

  void _prevStep() {
    if (_currentStep > 0) {
      setState(() => _currentStep--);
      _pageController.previousPage(duration: const Duration(milliseconds: 300), curve: Curves.easeInOut);
    }
  }

  Future<void> _submitUpdate() async {
    // Kiểm tra xem thực sự có thay đổi gì không
    if (!_isMediaChanged() && !_isContentChanged() && !_isAddressChanged()) {
      print("No changes detected, skipping API call.");
      Navigator.pop(context);
      return;
    }

    setState(() => _isAiLoading = true);
    try {
      Map<String, String> fields = {
        "productName": _titleController.text,
        "productPrice": _priceController.text.replaceAll('.', ''),
        "productDescription": _descController.text,
        "productCategory": _selectedCategory ?? "Khác",
        "productCondition": _conditionController.text,
        "productBrand": _brandController.text,
        "productOrigin": _originController.text,
        "productWP": _policyController.text,
        "province": _selectedProvinceName ?? "",
        "commute": _selectedWardName ?? "",
        "detail": _addressDetailController.text,
      };

      Map<String, dynamic> attrMap = {};
      for (var attr in _attributes) {
        if (attr.nameController.text.isNotEmpty) attrMap[attr.nameController.text] = attr.valueController.text;
      }
      fields["productAttribute"] = jsonEncode(attrMap);
      fields["existingMedia"] = jsonEncode(_oldMediaUrls);

      List<XFile> newFiles = [..._selectedImages, ..._selectedVideos];

      await _productService.updateProductWithMedia(widget.product.productId, fields, newFiles);

      if (mounted) {
        UIHelpers.showSuccessDialog(context, title: "Thành công", message: "Đã cập nhật tin đăng của bạn!");
        Navigator.pop(context, true);
      }
    } catch (e) {
      _showErrorDialog("Lỗi cập nhật: $e");
    } finally {
      setState(() => _isAiLoading = false);
    }
  }

  void _showErrorDialog(String msg) => UIHelpers.showErrorDialog(context, title: "Lỗi", message: msg);

  String _formatCurrency(String value) {
    if (value.isEmpty) return "";
    value = value.replaceAll('.', '');
    final number = int.tryParse(value) ?? 0;
    return NumberFormat.currency(locale: 'vi_VN', symbol: '', decimalDigits: 0).format(number).trim();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          Column(
            children: [
              const SizedBox(height: 95),
              // Stepper
              Container(
                padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
                color: Colors.white,
                child: Row(
                  children: [
                    _buildStepIndicator(0, "Hình ảnh"),
                    _buildStepLine(0),
                    _buildStepIndicator(1, "Thông tin"),
                    _buildStepLine(1),
                    _buildStepIndicator(2, "Địa chỉ"),
                    _buildStepLine(2),
                    _buildStepIndicator(3, "Xem trước"),
                  ],
                ),
              ),
              const Divider(height: 1),
              const SizedBox(height: 4),
              Expanded(
                child: PageView(
                  controller: _pageController,
                  physics: const NeverScrollableScrollPhysics(),
                  children: [
                    _buildStep1Media(),
                    _buildStep2Info(),
                    _buildStep3Address(),
                    _buildStep4Review(),
                  ],
                ),
              ),
            ],
          ),
          Positioned(
            top: 0, left: 0, right: 0,
            child: SafeArea(child: FloatingHeader(title: "Chỉnh sửa tin đăng", hasBackground: false)),
          ),
        ],
      ),
      bottomNavigationBar: SafeArea(
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            border: Border(top: BorderSide(color: Colors.grey.shade200)),
          ),
          child: Row(
            children: [
              if (_currentStep > 0) ...[
                TextButton(onPressed: _prevStep, child: const Text("Quay lại", style: TextStyle(color: Colors.grey))),
                const SizedBox(width: 16),
              ],
              Expanded(
                child: ElevatedButton(
                  onPressed: _nextStep,
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.black, foregroundColor: Colors.white, shape: const StadiumBorder(), minimumSize: const Size(double.infinity, 48)),
                  child: _isAiLoading ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)) : Text(_currentStep == 3 ? "Cập nhật" : "Tiếp theo"),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // --- STEP WIDGETS ---
  Widget _buildStep1Media() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const Text("Hình ảnh sản phẩm", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        const SizedBox(height: 12),
        SizedBox(
          height: 100,
          child: ListView(
            scrollDirection: Axis.horizontal,
            children: [
              GestureDetector(
                onTap: () => UIHelper.showImageSourceSheet(context, allowMultiple: true, onPicked: (files) {
                  if (files != null) setState(() => _selectedImages.addAll(files));
                }),
                child: Container(width: 100, margin: const EdgeInsets.only(right: 12), decoration: BoxDecoration(borderRadius: BorderRadius.circular(16), border: Border.all(color: Colors.grey.shade300)), child: const Icon(Icons.add_a_photo_outlined)),
              ),
              ..._oldMediaUrls.asMap().entries.map((e) => _buildMediaThumb(e.value, () => setState(() => _oldMediaUrls.removeAt(e.key)), isRemote: true)),
              ..._selectedImages.asMap().entries.map((e) => _buildMediaThumb(e.value.path, () => setState(() => _selectedImages.removeAt(e.key)))),
            ],
          ),
        ),
        const SizedBox(height: 24),
        _buildTextField(controller: _titleController, hint: "Tên sản phẩm (ví dụ: iPhone 13 Pro Max)"),
        const SizedBox(height: 12),
        _buildTextField(controller: _priceController, hint: "Giá bán (VNĐ)", keyboardType: TextInputType.number),
      ],
    );
  }

  Widget _buildStep2Info() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _buildDropdownField(
          hint: "Danh mục", 
          value: _selectedCategory, 
          items: _categoryNames.keys.toList(), 
          labelMapper: (k) => _categoryNames[k] ?? k, 
          onChanged: (v) => setState(() => _selectedCategory = v)
        ),
        const SizedBox(height: 12),
        _buildTextField(controller: _descController, hint: "Mô tả chi tiết sản phẩm...", maxLines: 5),
        const SizedBox(height: 12),
        const Text("Thuộc tính bổ sung", style: TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(height: 12),
        ..._attributes.map((attr) => Padding(padding: const EdgeInsets.only(bottom: 8), child: _buildTextField(controller: attr.valueController, hint: attr.nameController.text))),
      ],
    );
  }

  Widget _buildStep3Address() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _buildDropdownField(hint: "Tỉnh / Thành phố", value: _selectedProvinceName, items: _provinces.map((e) => e['name'].toString()).toList(), labelMapper: (v) => v, onChanged: (v) {
          setState(() => _selectedProvinceName = v);
          final match = _provinces.firstWhere((e) => e['name'] == v, orElse: () => null);
          if (match != null) _fetchWards(match['code'].toString());
        }),
        const SizedBox(height: 12),
        _buildDropdownField(hint: "Phường / Xã", value: _selectedWardName, items: _wards.map((e) => e['name'].toString()).toList(), labelMapper: (v) => v, onChanged: (v) => setState(() => _selectedWardName = v)),
        const SizedBox(height: 12),
        _buildTextField(controller: _addressDetailController, hint: "Số nhà, tên đường..."),
      ],
    );
  }

  Widget _buildStep4Review() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text(_titleController.text, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
        Text("${_priceController.text} VNĐ", style: const TextStyle(fontSize: 18, color: Colors.orange, fontWeight: FontWeight.bold)),
        const Divider(),
        Text(_descController.text),
        const Divider(),
        Text("Địa chỉ: ${_addressDetailController.text}, ${_selectedWardName}, ${_selectedProvinceName}"),
      ],
    );
  }

  // --- UI HELPERS ---
  Widget _buildStepIndicator(int step, String label) {
    bool isActive = _currentStep >= step;
    return Column(children: [
      Container(width: 30, height: 30, decoration: BoxDecoration(color: isActive ? AppColors.primary : Colors.grey[200], shape: BoxShape.circle), child: Center(child: Icon(isActive ? Icons.check : Icons.circle, color: isActive ? Colors.white : Colors.grey, size: 16))),
      const SizedBox(height: 4),
      Text(label, style: TextStyle(fontSize: 10, color: isActive ? AppColors.primary : Colors.grey, fontWeight: FontWeight.bold)),
    ]);
  }

  Widget _buildStepLine(int step) => Expanded(child: Container(height: 2, color: _currentStep > step ? AppColors.primary : Colors.grey[200], margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 15)));

  Widget _buildMediaThumb(String path, VoidCallback onRemove, {bool isRemote = false}) {
    return Stack(children: [
      Container(
        width: 100, 
        margin: const EdgeInsets.only(right: 12), 
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16), 
          image: DecorationImage(
            image: isRemote 
              ? NetworkImage(path.startsWith('http') ? path : "${ApiConstants.baseUrl}$path") 
              : (kIsWeb ? NetworkImage(path) : FileImage(File(path)) as ImageProvider), 
            fit: BoxFit.cover
          )
        )
      ),
      Positioned(top: 4, right: 16, child: GestureDetector(onTap: onRemove, child: Container(padding: const EdgeInsets.all(2), decoration: const BoxDecoration(color: Colors.black54, shape: BoxShape.circle), child: const Icon(Icons.close, size: 14, color: Colors.white)))),
    ]);
  }

  Widget _buildTextField({required TextEditingController controller, required String hint, TextInputType keyboardType = TextInputType.text, int maxLines = 1}) {
    return TextField(
      controller: controller, keyboardType: keyboardType, maxLines: maxLines,
      decoration: InputDecoration(hintText: hint, filled: true, fillColor: const Color(0xFFF2F2F2), border: OutlineInputBorder(borderRadius: BorderRadius.circular(30), borderSide: BorderSide.none), contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14)),
    );
  }

  Widget _buildDropdownField({required String hint, required String? value, required List<String> items, required String Function(String) labelMapper, required ValueChanged<String?> onChanged}) {
    return GestureDetector(
      onTap: () {
        showModalBottomSheet(context: context, builder: (ctx) => ListView(children: items.map((e) => ListTile(title: Text(labelMapper(e)), onTap: () { onChanged(e); Navigator.pop(ctx); })).toList()));
      },
      child: Container(padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14), decoration: BoxDecoration(color: const Color(0xFFF2F2F2), borderRadius: BorderRadius.circular(30)), child: Row(children: [Expanded(child: Text(value == null ? hint : labelMapper(value), style: TextStyle(color: value == null ? Colors.grey : Colors.black))), const Icon(Icons.arrow_drop_down)])),
    );
  }
}