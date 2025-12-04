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

  // --- STATE ---
  String? _selectedCategory;
  bool _isAiLoading = false;
  bool _showManualBackup = false; // Chỉ hiện khi AI lỗi

  List<AttributeItem> _attributes = [];

  // --- TEMPLATES ---
  final Map<String, List<String>> _attributeTemplates = {
    "auto": ["brand", "model", "year", "fuel_type", "transmission", "mileage", "condition", "color", "accessories_type", "warranty"],
    "furniture": ["material", "color", "dimensions", "style", "room_type", "weight", "brand", "warranty", "assembly_required"],
    "technology": ["brand", "model", "cpu", "ram", "storage", "screen_size", "battery_capacity", "os", "connectivity", "warranty"],
    "office": ["material", "dimensions", "color", "brand", "quantity", "type", "weight"],
    "style": ["size", "color", "material", "gender", "brand", "season", "pattern", "style", "origin"],
    "service": ["service_type", "duration", "price_type", "provider", "area", "availability", "warranty"],
    "hobby": ["category", "skill_level", "material", "brand", "age_range", "weight", "size"],
    "kids": ["age_range", "material", "size", "color", "brand", "education_type", "certification", "weight"]
  };

  // --- ADDRESS & MEDIA ---
  List<dynamic> _provinces = [];
  List<dynamic> _wards = [];
  String? _selectedProvinceCode;
  String? _selectedProvinceName;
  String? _selectedWardCode;
  String? _selectedWardName;

  final ImagePicker _picker = ImagePicker();
  List<XFile> _selectedImages = [];
  List<XFile> _selectedVideos = [];

  @override
  void initState() {
    super.initState();
    _fetchProvinces();
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

  Future<void> _fetchProvinces() async {
    try {
      final response = await http.get(Uri.parse('https://34tinhthanh.com/api/provinces'));
      if (response.statusCode == 200) setState(() => _provinces = jsonDecode(response.body));
    } catch (e) { print("Error provinces: $e"); }
  }

  Future<void> _fetchWards(String provinceCode) async {
    setState(() { _wards = []; _selectedWardCode = null; _selectedWardName = null; });
    try {
      final response = await http.get(Uri.parse('https://34tinhthanh.com/api/wards?province_code=$provinceCode'));
      if (response.statusCode == 200) setState(() => _wards = jsonDecode(response.body));
    } catch (e) { print("Error wards: $e"); }
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

  // --- LOGIC MANUAL CATEGORY ---
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

  // --- LOGIC AI SUGGESTION ---
  Future<void> _handleAISuggestion() async {
    final name = _titleController.text.trim();
    final desc = _descController.text.trim();
    final condition = _conditionController.text.trim();

    if (name.isEmpty || desc.isEmpty || condition.isEmpty) {
      _showErrorDialog("Please enter Product Name, Description, and Condition.");
      return;
    }

    setState(() {
      _isAiLoading = true;
      _showManualBackup = false;
    });

    try {
      final result = await _productService.getAISuggestion(
        productName: name,
        description: desc,
        condition: condition,
      );

      if (result != null) {
        setState(() {
          if (result['category'] != null) _selectedCategory = result['category'];
          for (var attr in _attributes) attr.dispose();
          _attributes.clear();

          if (result['attributes'] != null) {
            Map<String, dynamic> aiAttrs = result['attributes'];
            aiAttrs.forEach((key, value) {
              String valToShow = (value == "no" || value == null) ? "" : value.toString();
              _attributes.add(AttributeItem(name: key, value: valToShow));
            });
          }
        });
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("AI Applied!"), backgroundColor: Colors.green));
      } else {
        _activateBackupMode();
      }
    } catch (e) {
      _activateBackupMode();
    } finally {
      setState(() => _isAiLoading = false);
    }
  }

  void _activateBackupMode() {
    setState(() {
      _showManualBackup = true;
      _selectedCategory = null;
      _attributes.clear();
    });
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("AI Failed. Manual Mode Activated."), backgroundColor: Colors.redAccent));
  }

  // --- SUBMIT ---
  Future<void> _submitProduct() async {
    // Không cần validate ở đây nữa vì nút đã bị disable nếu thiếu thông tin
    showDialog(context: context, barrierDismissible: false, builder: (_) => const Center(child: CircularProgressIndicator()));

    try {
      Map<String, dynamic> attributesMap = {};
      for (var item in _attributes) {
        attributesMap[item.nameController.text.trim()] = item.valueController.text.trim();
      }

      String? userId = _userService.getCurrentUserId();
      if (userId == null) { Navigator.pop(context); return; }

      Map<String, String> addressMap = {
        "province": _selectedProvinceName!,
        "commune": _selectedWardName!,
        "detail": _addressDetailController.text.trim(),
      };

      Map<String, String> fields = {
        "productName": _titleController.text,
        "productPrice": _priceController.text,
        "productDescription": _descController.text,
        "categoryId": _selectedCategory ?? "other",
        "productCategory": _selectedCategory ?? "other",
        "productOrigin": _originController.text,
        "productCondition": _conditionController.text,
        "productBrand": _brandController.text,
        "productWP": _policyController.text,
        "userId": userId,
        "productAttribute": jsonEncode(attributesMap),
        "productAddress": jsonEncode(addressMap),
      };

      List<XFile> allFiles = [..._selectedImages, ..._selectedVideos];
      await _productService.createProduct(fields: fields, files: allFiles);

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Product Created!"), backgroundColor: Colors.green));
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
    showDialog(context: context, builder: (ctx) => AlertDialog(title: const Text("Error"), content: Text(message), actions: [TextButton(onPressed: () => Navigator.of(ctx).pop(), child: const Text("OK"))]));
  }

  // --- HÀM KIỂM TRA VALIDATION TOÀN BỘ FORM ---
  bool _checkAllFieldsFilled() {
    // 1. Basic Info
    if (_titleController.text.isEmpty) return false;
    if (_priceController.text.isEmpty) return false;
    if (_descController.text.isEmpty) return false;

    // 2. Address
    if (_selectedProvinceName == null) return false;
    if (_selectedWardName == null) return false;
    if (_addressDetailController.text.isEmpty) return false;

    // 3. Other Details (Bắt buộc nhập hết theo yêu cầu)
    if (_conditionController.text.isEmpty) return false;
    if (_brandController.text.isEmpty) return false;
    if (_originController.text.isEmpty) return false;
    if (_policyController.text.isEmpty) return false;

    // 4. Attributes (Phải có danh sách VÀ phải điền hết giá trị)
    if (_selectedCategory == null) return false;
    if (_attributes.isEmpty) return false;

    // Kiểm tra từng dòng attribute
    for (var attr in _attributes) {
      if (attr.valueController.text.trim().isEmpty) return false;
    }

    return true; // Tất cả ok
  }

  @override
  Widget build(BuildContext context) {
    // Gọi hàm kiểm tra mỗi lần rebuild
    final bool isFormValid = _checkAllFieldsFilled();

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
            _buildHorizontalMediaList(label: "Add Image", icon: HeroiconsOutline.photo, items: _selectedImages, onAdd: _pickImages, onRemove: _removeImage, isImage: true),
            const SizedBox(height: 16),
            _buildHorizontalMediaList(label: "Add Video", icon: HeroiconsOutline.videoCamera, items: _selectedVideos, onAdd: _pickVideo, onRemove: _removeVideo, isImage: false),

            const SizedBox(height: 24),
            _buildSectionTitle("Basic Information"),
            const SizedBox(height: 12),
            _buildTextField(controller: _titleController, hint: "Product Name"),
            const SizedBox(height: 12),
            _buildTextField(controller: _priceController, hint: "Price (VND)", keyboardType: TextInputType.number),
            const SizedBox(height: 12),
            _buildTextField(controller: _descController, hint: "Description", maxLines: 4),

            const SizedBox(height: 24),
            _buildSectionTitle("Address"),
            const SizedBox(height: 12),
            _buildDynamicDropdown(
                hint: "Province / City", value: _selectedProvinceCode, items: _provinces,
                itemValueMapper: (item) => item['province_code'].toString(), itemLabelMapper: (item) => item['name'],
                onChanged: (val) { setState(() { _selectedProvinceCode = val; final s = _provinces.firstWhere((e) => e['province_code'].toString() == val, orElse: () => null); _selectedProvinceName = s != null ? s['name'] : null; }); if (val != null) _fetchWards(val); }
            ),
            const SizedBox(height: 12),
            _buildDynamicDropdown(
                hint: "Ward / Commune", value: _selectedWardCode, items: _wards,
                itemValueMapper: (item) => item['ward_code'].toString(), itemLabelMapper: (item) => item['ward_name'],
                onChanged: (val) { setState(() { _selectedWardCode = val; final s = _wards.firstWhere((e) => e['ward_code'].toString() == val, orElse: () => null); _selectedWardName = s != null ? s['ward_name'] : null; }); }
            ),
            const SizedBox(height: 12),
            _buildTextField(controller: _addressDetailController, hint: "Detail Address"),

            const SizedBox(height: 24),
            _buildSectionTitle("Other Details"),
            const SizedBox(height: 12),
            _buildTextField(controller: _conditionController, hint: "Condition (Required)"),
            const SizedBox(height: 12),
            _buildTextField(controller: _brandController, hint: "Brand (Required)"),
            const SizedBox(height: 12),
            _buildTextField(controller: _originController, hint: "Origin (Required)"),
            const SizedBox(height: 12),
            _buildTextField(controller: _policyController, hint: "Warranty Policy (Required)"),

            const SizedBox(height: 32),

            _buildSectionTitle("Product details"),
            const SizedBox(height: 12),

            // --- HEADER ROW VỚI GRADIENT TEXT VÀ NÚT ĐEN ---
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // 1. GRADIENT TEXT & ICON
                ShaderMask(
                  shaderCallback: (bounds) => const LinearGradient(
                    colors: [Colors.purple, Colors.blue, Colors.pinkAccent],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ).createShader(bounds),
                  child: Row(
                    children: const [
                      Icon(HeroiconsSolid.sparkles, color: Colors.white, size: 22), // Màu gốc là trắng để ăn màu gradient
                      SizedBox(width: 8),
                      Text("AI Suggestion", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
                    ],
                  ),
                ),

                // 2. NÚT GET MÀU ĐEN
                ElevatedButton(
                  onPressed: _isAiLoading ? null : _handleAISuggestion,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.black,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                    elevation: 5,
                  ),
                  child: _isAiLoading
                      ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                      : const Text("Get", style: TextStyle(fontWeight: FontWeight.bold)),
                )
              ],
            ),

            const SizedBox(height: 16),

            if (_showManualBackup) ...[
              Container(padding: const EdgeInsets.all(8), color: Colors.red.shade50, margin: const EdgeInsets.only(bottom: 8), child: const Text("API Error. Select Category manually:", style: TextStyle(color: Colors.red, fontSize: 12))),
              _buildDropdownField(hint: "Select Category", value: _selectedCategory, items: _attributeTemplates.keys.toList(), onChanged: _onCategoryChanged),
              const SizedBox(height: 16),
            ] else if (_selectedCategory != null && _attributes.isNotEmpty) ...[
              Text("Category: ${_selectedCategory!.toUpperCase()}", style: const TextStyle(fontSize: 12, color: Colors.grey, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
            ],

            if (_attributes.isNotEmpty)
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _attributes.length,
                itemBuilder: (context, index) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: Row(children: [
                      Expanded(flex: 4, child: _buildTextField(controller: _attributes[index].nameController, hint: "Name", readOnly: true)),
                      const SizedBox(width: 8),
                      Expanded(
                        flex: 6,
                        // Truyền onChanged để trigger validate nút Upload ngay khi gõ
                        child: _buildTextField(controller: _attributes[index].valueController, hint: "Value"),
                      ),
                    ]),
                  );
                },
              ),

            if (_attributes.isEmpty && !_isAiLoading)
              const Center(child: Text("Press 'Get' to generate attributes.", style: TextStyle(color: Colors.grey))),

            const SizedBox(height: 30),

            if (!isFormValid)
              Container(
                margin: const EdgeInsets.only(bottom: 10),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(color: Colors.grey[100], borderRadius: BorderRadius.circular(8)),
                child: Row(mainAxisAlignment: MainAxisAlignment.center, children: const [
                  Icon(Icons.lock_outline, color: Colors.grey, size: 18),
                  SizedBox(width: 8),
                  Text("Please fill ALL fields to enable Upload.", style: TextStyle(color: Colors.grey, fontSize: 13, fontWeight: FontWeight.w600)),
                ]),
              ),

            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                // Disable nếu form chưa valid
                onPressed: isFormValid ? _submitProduct : null,

                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.ButtonBlackColor,
                  disabledBackgroundColor: Colors.grey[300], // Màu xám khi disable
                  foregroundColor: Colors.white,
                  shape: const StadiumBorder(),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                child: const Text("Upload Product"),
              ),
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  // --- HELPERS ---
  Widget _buildSectionTitle(String title) => Text(title, style: TextStyle(fontSize: 14, color: Colors.grey[800], fontWeight: FontWeight.bold));

  // Update TextField để hỗ trợ setState khi gõ (Real-time Validation)
  Widget _buildTextField({required TextEditingController controller, required String hint, TextInputType keyboardType = TextInputType.text, int maxLines = 1, bool readOnly = false}) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      maxLines: maxLines,
      readOnly: readOnly,
      // QUAN TRỌNG: Gọi setState mỗi khi gõ để check validation
      onChanged: (_) => setState(() {}),

      decoration: InputDecoration(
        hintText: hint, hintStyle: TextStyle(color: Colors.grey[400], fontSize: 13),
        filled: true, fillColor: readOnly ? Colors.grey[200] : const Color(0xFFF2F2F2),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
      ),
    );
  }

  Widget _buildDropdownField({required String hint, required String? value, required List<String> items, required ValueChanged<String?> onChanged}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(color: const Color(0xFFF2F2F2), borderRadius: BorderRadius.circular(12)),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: value, hint: Text(hint, style: TextStyle(color: Colors.grey[400], fontSize: 13)),
          isExpanded: true, items: items.map((e) => DropdownMenuItem(value: e, child: Text(e, style: const TextStyle(fontSize: 14)))).toList(),
          onChanged: onChanged,
        ),
      ),
    );
  }

  Widget _buildDynamicDropdown({required String hint, required String? value, required List<dynamic> items, required String Function(dynamic) itemValueMapper, required String Function(dynamic) itemLabelMapper, required ValueChanged<String?> onChanged}) {
    final uniqueValues = <String>{};
    final dropdownItems = <DropdownMenuItem<String>>[];
    for (var item in items) {
      final val = itemValueMapper(item);
      if (!uniqueValues.contains(val)) {
        uniqueValues.add(val);
        dropdownItems.add(DropdownMenuItem<String>(value: val, child: Text(itemLabelMapper(item), style: const TextStyle(fontSize: 14), overflow: TextOverflow.ellipsis)));
      }
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(color: const Color(0xFFF2F2F2), borderRadius: BorderRadius.circular(12)),
      child: DropdownButtonHideUnderline(child: DropdownButton<String>(
          value: uniqueValues.contains(value) ? value : null, hint: Text(hint, style: TextStyle(color: Colors.grey[400], fontSize: 13)),
          isExpanded: true, menuMaxHeight: 300, items: dropdownItems, onChanged: onChanged)),
    );
  }

  Widget _buildHorizontalMediaList({required String label, required IconData icon, required List<XFile> items, required VoidCallback onAdd, required Function(int) onRemove, required bool isImage}) {
    return SizedBox(
      height: 100,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: items.length + 1,
        itemBuilder: (context, index) {
          if (index == 0) {
            return GestureDetector(onTap: onAdd, child: Container(
                width: 100, margin: const EdgeInsets.only(right: 12),
                decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: Colors.grey.shade300)),
                child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [Icon(icon, size: 24, color: Colors.black54), const SizedBox(height: 4), Text(label, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold))])));
          }
          final file = items[index - 1];
          return Stack(children: [
            Container(width: 100, margin: const EdgeInsets.only(right: 12), decoration: BoxDecoration(borderRadius: BorderRadius.circular(16), color: Colors.grey[200], image: isImage ? DecorationImage(image: FileImage(File(file.path)), fit: BoxFit.cover) : null), child: !isImage ? const Center(child: Icon(Icons.play_circle_fill, size: 30, color: Colors.white)) : null),
            Positioned(top: 4, right: 16, child: GestureDetector(onTap: () => onRemove(index - 1), child: Container(padding: const EdgeInsets.all(2), decoration: const BoxDecoration(color: Colors.black54, shape: BoxShape.circle), child: const Icon(Icons.close, size: 14, color: Colors.white))))
          ]);
        },
      ),
    );
  }
}