import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:heroicons_flutter/heroicons_flutter.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'package:maromart/Colors/AppColors.dart';
import 'package:maromart/components/TopBarSecond.dart';
import 'package:maromart/services/user_service.dart';
import '../../services/product_service.dart';

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

class AddProduct extends StatefulWidget {
  const AddProduct({super.key});

  @override
  State<StatefulWidget> createState() => _AddProductState();
}

class _AddProductState extends State<AddProduct> {
  final ProductService _productService = ProductService();
  final UserService _userService = UserService();

  // --- CONTROLLERS ---
  final _titleController = TextEditingController();
  final _priceController = TextEditingController();
  final _descController = TextEditingController();
  final _conditionController = TextEditingController();
  final _brandController = TextEditingController();
  final _policyController = TextEditingController();
  final _originController = TextEditingController();
  final _addressDetailController = TextEditingController();

  String? _selectedCategory;

  // --- STATE ĐỊA CHỈ ---
  List<dynamic> _provinces = [];
  List<dynamic> _wards = [];

  String? _selectedProvinceCode;
  String? _selectedProvinceName;

  String? _selectedWardCode;
  String? _selectedWardName;

  // Template Attribute
  final Map<String, List<String>> _attributeTemplates = {
    "auto": ["brand", "model", "year", "fuel_type", "transmission", "mileage", "condition", "color", "warranty"],
    "furniture": ["material", "color", "dimensions", "style", "brand", "warranty"],
    "technology": ["brand", "model", "cpu", "ram", "storage", "screen", "battery", "os", "warranty"],
    "office": ["material", "dimensions", "color", "brand", "type"],
    "style": ["size", "color", "material", "gender", "brand", "style", "origin"],
    "service": ["service_type", "duration", "provider", "area", "warranty"],
    "hobby": ["category", "skill_level", "material","age_range","weight", "brand", "size"],
    "kids": ["age_range", "material", "size", "color", "brand", "weight"]
  };

  List<AttributeItem> _attributes = [];

  // --- MEDIA ---
  final ImagePicker _picker = ImagePicker();
  List<XFile> _selectedImages = [];
  List<XFile> _selectedVideos = [];

  @override
  void initState() {
    super.initState();
    _fetchProvinces();
  }

  Future<void> _fetchProvinces() async {
    try {
      final response = await http.get(Uri.parse('https://34tinhthanh.com/api/provinces'));
      if (response.statusCode == 200) {
        setState(() {
          _provinces = jsonDecode(response.body);
        });
      }
    } catch (e) {
      print("Lỗi tải tỉnh thành: $e");
    }
  }

  Future<void> _fetchWards(String provinceCode) async {
    setState(() {
      _wards = [];
      _selectedWardCode = null;
      _selectedWardName = null;
    });

    try {
      final response = await http.get(Uri.parse('https://34tinhthanh.com/api/wards?province_code=$provinceCode'));
      if (response.statusCode == 200) {
        setState(() {
          _wards = jsonDecode(response.body);
        });
      }
    } catch (e) {
      print("Lỗi tải phường xã: $e");
    }
  }

  void _onCategoryChanged(String? newCategory) {
    setState(() {
      _selectedCategory = newCategory;
      for (var attr in _attributes) attr.dispose();
      _attributes.clear();

      if (newCategory != null && _attributeTemplates.containsKey(newCategory)) {
        List<String> templates = _attributeTemplates[newCategory]!;
        for (String key in templates) {
          _attributes.add(AttributeItem(name: key, value: ""));
        }
      }
    });
  }

  Future<void> _pickImages() async {
    final List<XFile> images = await _picker.pickMultiImage();
    if (images.isNotEmpty) setState(() => _selectedImages.addAll(images));
  }

  Future<void> _pickVideo() async {
    final XFile? video = await _picker.pickVideo(source: ImageSource.gallery);
    if (video != null) setState(() => _selectedVideos.add(video));
  }

  void _removeImage(int index) => setState(() => _selectedImages.removeAt(index));
  void _removeVideo(int index) => setState(() => _selectedVideos.removeAt(index));

  // --- SUBMIT ---
  Future<void> _submitProduct() async {
    // 1. Validate cơ bản ở Client
    if (_titleController.text.isEmpty || _priceController.text.isEmpty || _selectedCategory == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Please enter Name, Price and select a Category!")));
      return;
    }

    if (_selectedProvinceName == null || _selectedWardName == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Please select Province and Ward!")));
      return;
    }

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator()),
    );

    try {
      Map<String, dynamic> attributesMap = {};
      for (var item in _attributes) {
        String key = item.nameController.text.trim();
        String value = item.valueController.text.trim();
        if (key.isNotEmpty && value.isNotEmpty) {
          attributesMap[key] = value;
        }
      }

      String? userId = _userService.getCurrentUserId();
      if (userId == null) {
        Navigator.pop(context);
        return;
      }

      Map<String, String> addressMap = {
        "province": _selectedProvinceName!,
        "commune": _selectedWardName!,
        "detail": _addressDetailController.text.trim(),
      };

      Map<String, String> fields = {
        "productName": _titleController.text,
        "productPrice": _priceController.text,
        "productDescription": _descController.text,
        "categoryId": _selectedCategory!,
        "productCategory": _selectedCategory!,
        "productOrigin": _originController.text.isNotEmpty ? _originController.text : "Vietnam",
        "productCondition": _conditionController.text.isNotEmpty ? _conditionController.text : "New",
        "productBrand": _brandController.text.isNotEmpty ? _brandController.text : "No Brand",
        "productWP": _policyController.text.isNotEmpty ? _policyController.text : "No Warranty",
        "userId": userId,
        "productAttribute": jsonEncode(attributesMap),
        "productAddress": jsonEncode(addressMap),
      };

      List<XFile> allFiles = [..._selectedImages, ..._selectedVideos];

      await _productService.createProduct(fields: fields, files: allFiles);

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Success! Product created."), backgroundColor: Colors.green));
        Navigator.pop(context);
      }

    } catch (e) {
      if (mounted) {
        Navigator.pop(context);

        _showErrorDialog(e.toString().replaceAll("Exception:", "").trim());
      }
    }
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.error_outline, color: Colors.red),
            SizedBox(width: 10),
            Text("Upload Failed"),
          ],
        ),
        content: Text(
          message,
          style: const TextStyle(fontSize: 16),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text("OK", style: TextStyle(color: AppColors.ButtonBlackColor, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
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
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: const TopBarSecond(title: 'Add New Product'),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        physics: const BouncingScrollPhysics(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSectionTitle("Images & Videos"),
            const SizedBox(height: 12),
            _buildHorizontalMediaList(
              label: "Add Image", icon: HeroiconsOutline.photo, items: _selectedImages,
              onAdd: _pickImages, onRemove: _removeImage, isImage: true,
            ),
            const SizedBox(height: 16),
            _buildHorizontalMediaList(
              label: "Add Video", icon: HeroiconsOutline.videoCamera, items: _selectedVideos,
              onAdd: _pickVideo, onRemove: _removeVideo, isImage: false,
            ),

            const SizedBox(height: 24),
            _buildSectionTitle("Basic Information"),
            const SizedBox(height: 12),
            _buildDropdownField(
                hint: "Category",
                value: _selectedCategory,
                items: _attributeTemplates.keys.toList(),
                onChanged: _onCategoryChanged
            ),
            const SizedBox(height: 12),
            _buildTextField(controller: _titleController, hint: "Product Name"),
            const SizedBox(height: 12),
            _buildTextField(controller: _priceController, hint: "Price (VND)", keyboardType: TextInputType.number),
            const SizedBox(height: 12),
            _buildTextField(controller: _descController, hint: "Detailed description...", maxLines: 4),

            const SizedBox(height: 24),
            _buildSectionTitle("Address"),
            const SizedBox(height: 12),

            _buildDynamicDropdown(
              hint: "Province / City",
              value: _selectedProvinceCode,
              items: _provinces,
              itemValueMapper: (item) => item['province_code'].toString(),
              itemLabelMapper: (item) => item['name'],
              onChanged: (val) {
                setState(() {
                  _selectedProvinceCode = val;
                  final selectedItem = _provinces.firstWhere((e) => e['province_code'].toString() == val, orElse: () => null);
                  _selectedProvinceName = selectedItem != null ? selectedItem['name'] : null;
                });
                if (val != null) _fetchWards(val);
              },
            ),

            const SizedBox(height: 12),

            _buildDynamicDropdown(
              hint: "Ward / Commune",
              value: _selectedWardCode,
              items: _wards,
              itemValueMapper: (item) => item['ward_code'].toString(),
              itemLabelMapper: (item) => item['ward_name'],
              onChanged: (val) {
                setState(() {
                  _selectedWardCode = val;
                  final selectedItem = _wards.firstWhere((e) => e['ward_code'].toString() == val, orElse: () => null);
                  _selectedWardName = selectedItem != null ? selectedItem['ward_name'] : null;
                });
              },
            ),

            const SizedBox(height: 12),
            _buildTextField(controller: _addressDetailController, hint: "Detail Address (Street, House No...)"),

            const SizedBox(height: 24),
            _buildSectionTitle("Other Details"),
            const SizedBox(height: 12),
            _buildTextField(controller: _conditionController, hint: "Condition (New/Used)"),
            const SizedBox(height: 12),
            _buildTextField(controller: _brandController, hint: "Brand"),
            const SizedBox(height: 12),
            _buildTextField(controller: _originController, hint: "Origin"),
            const SizedBox(height: 12),
            _buildTextField(controller: _policyController, hint: "Warranty Policy"),

            const SizedBox(height: 32),
            // --- ĐÃ BỎ NÚT THÊM (+) Ở ĐÂY ---
            _buildSectionTitle("Product Attributes"),
            const SizedBox(height: 12),

            _attributes.isEmpty
                ? const Padding(
              padding: EdgeInsets.all(16.0),
              child: Center(child: Text("Select a category to see attributes", style: TextStyle(color: Colors.grey))),
            )
                : ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _attributes.length,
              itemBuilder: (context, index) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: Row(
                    children: [
                      Expanded(
                        flex: 2,
                        child: _buildTextField(
                          controller: _attributes[index].nameController,
                          hint: "Name",
                          readOnly: true, // Tên thuộc tính fix cứng, không sửa
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        flex: 3,
                        child: _buildTextField(
                          controller: _attributes[index].valueController,
                          hint: "Enter value...",
                        ),
                      ),
                      // --- ĐÃ BỎ NÚT XÓA (x) Ở ĐÂY ---
                    ],
                  ),
                );
              },
            ),

            const SizedBox(height: 40),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _submitProduct,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.ButtonBlackColor,
                  foregroundColor: Colors.white,
                  shape: const StadiumBorder(),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                child: const Text("Upload Product"),
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  // ... Các Widget Helper giữ nguyên ...
  Widget _buildSectionTitle(String title) {
    return Text(title, style: TextStyle(fontSize: 14, color: Colors.grey[600], fontWeight: FontWeight.w500));
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String hint,
    TextInputType keyboardType = TextInputType.text,
    int maxLines = 1,
    bool readOnly = false,
  }) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      maxLines: maxLines,
      readOnly: readOnly,
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(color: Colors.grey[400], fontSize: 13),
        filled: true,
        fillColor: readOnly ? Colors.grey[200] : const Color(0xFFF2F2F2),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(30), borderSide: BorderSide.none),
      ),
    );
  }

  Widget _buildDropdownField({
    required String hint, required String? value, required List<String> items, required ValueChanged<String?> onChanged,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(color: const Color(0xFFF2F2F2), borderRadius: BorderRadius.circular(30)),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: value,
          hint: Text(hint, style: TextStyle(color: Colors.grey[400], fontSize: 13)),
          isExpanded: true,
          items: items.map((e) => DropdownMenuItem(value: e, child: Text(e, style: const TextStyle(fontSize: 14)))).toList(),
          onChanged: onChanged,
        ),
      ),
    );
  }

  Widget _buildDynamicDropdown({
    required String hint,
    required String? value,
    required List<dynamic> items,
    required String Function(dynamic) itemValueMapper,
    required String Function(dynamic) itemLabelMapper,
    required ValueChanged<String?> onChanged,
  }) {
    final uniqueValues = <String>{};
    final dropdownItems = <DropdownMenuItem<String>>[];

    for (var item in items) {
      final val = itemValueMapper(item);
      if (!uniqueValues.contains(val)) {
        uniqueValues.add(val);
        dropdownItems.add(
          DropdownMenuItem<String>(
            value: val,
            child: Text(itemLabelMapper(item), style: const TextStyle(fontSize: 14), overflow: TextOverflow.ellipsis),
          ),
        );
      }
    }
    final safeValue = uniqueValues.contains(value) ? value : null;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(color: const Color(0xFFF2F2F2), borderRadius: BorderRadius.circular(30)),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: safeValue,
          hint: Text(hint, style: TextStyle(color: Colors.grey[400], fontSize: 13)),
          isExpanded: true,
          menuMaxHeight: 300,
          items: dropdownItems,
          onChanged: onChanged,
        ),
      ),
    );
  }

  Widget _buildHorizontalMediaList({
    required String label, required IconData icon, required List<XFile> items,
    required VoidCallback onAdd, required Function(int) onRemove, required bool isImage,
  }) {
    return SizedBox(
      height: 100,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: items.length + 1,
        itemBuilder: (context, index) {
          if (index == 0) {
            return GestureDetector(
              onTap: onAdd,
              child: Container(
                width: 100, margin: const EdgeInsets.only(right: 12),
                decoration: BoxDecoration(
                  color: Colors.white, borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.black, width: 1),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(icon, size: 24, color: Colors.black),
                    const SizedBox(height: 4),
                    Text(label, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold))
                  ],
                ),
              ),
            );
          }
          final file = items[index - 1];
          return Stack(
            children: [
              Container(
                width: 100, margin: const EdgeInsets.only(right: 12),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16), color: Colors.grey[200],
                  image: isImage
                      ? DecorationImage(
                      image: kIsWeb ? NetworkImage(file.path) : FileImage(File(file.path)) as ImageProvider,
                      fit: BoxFit.cover
                  )
                      : null,
                ),
                child: !isImage ? const Center(child: Icon(Icons.play_circle_fill, size: 30, color: Colors.white)) : null,
              ),
              Positioned(
                top: 4, right: 16,
                child: GestureDetector(
                  onTap: () => onRemove(index - 1),
                  child: Container(
                    padding: const EdgeInsets.all(2),
                    decoration: const BoxDecoration(color: Colors.black54, shape: BoxShape.circle),
                    child: const Icon(Icons.close, size: 14, color: Colors.white),
                  ),
                ),
              )
            ],
          );
        },
      ),
    );
  }
}