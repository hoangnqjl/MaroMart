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
  bool _showManualBackup = false; 
  
  // AI Data
  String? _visualDetails;
  String? _aiCondition;

  List<AttributeItem> _attributes = [];

  // --- TEMPLATES ---
  final Map<String, List<String>> _attributeTemplates = {
    "auto": ["brand", "model", "year", "fuel_type", "transmission", "mileage", "condition", "color", "accessories_type", "warranty"],
    "furniture": ["material", "color", "dimensions", "style", "room_type", "weight", "brand", "warranty", "assembly_required"],
    "technology": ["brand", "model", "cpu", "ram", "storage", "screen_size", "battery_capacity", "os", "connectivity", "warranty"],
    "appliances": ["brand", "type", "capacity", "power_usage", "dimensions", "warranty", "color", "material"], // Fridge, Fan, etc.
    "office": ["material", "dimensions", "color", "brand", "quantity", "type", "weight"],
    "style": ["size", "color", "material", "gender", "brand", "season", "pattern", "style", "origin"],
    "service": ["service_type", "duration", "price_type", "provider", "area", "availability", "warranty"],
    "hobby": ["category", "skill_level", "material", "brand", "age_range", "weight", "size"],
    "kids": ["age_range", "material", "size", "color", "brand", "education_type", "certification", "weight"],
    "books": ["author", "genre", "language", "publisher", "publication_year", "page_count", "condition"],
    "pets": ["species", "breed", "age", "gender", "color", "health_status", "vaccination"],
    "other": ["brand", "material", "color", "dimensions", "weight", "condition"]
  };
  
  // AI Config
  String _selectedStyle = "Professional";
  String _selectedLength = "Medium";
  final List<String> _styles = ["Professional", "Casual", "Funny", "Technical"];
  final List<String> _lengths = ["Short", "Medium", "Detailed"];

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

  // --- WIZARD STATE ---
  int _currentStep = 0;
  final PageController _pageController = PageController();

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
    _pageController.dispose();
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
      // 1. Capture current values into a map
      Map<String, String> currentValues = {};
      for (var attr in _attributes) {
        if (attr.valueController.text.isNotEmpty) {
          currentValues[attr.nameController.text.toLowerCase()] = attr.valueController.text;
        }
      }

      _selectedCategory = newCategory;
      
      // 2. Dispose old controllers
      for (var attr in _attributes) attr.dispose();
      _attributes.clear();

      // 3. Rebuild based on new template
      if (newCategory != null && _attributeTemplates.containsKey(newCategory)) {
        List<String> templates = _attributeTemplates[newCategory]!;
        for (String key in templates) {
          // 4. Restore value if matched (fuzzy match key)
          String initialValue = currentValues[key.toLowerCase()] ?? "";
          _attributes.add(AttributeItem(name: key, value: initialValue));
        }
      }
    });
  }

  // --- LOGIC AI SUGGESTION ---
  // --- LOGIC AI HANDLERS ---
  
  // STEP 1: VALIDATE MEDIA
  Future<bool> _handleValidateMedia() async {
    if (_selectedImages.isEmpty) {
      _showErrorDialog("Vui lòng đăng tải ít nhất 1 hình ảnh sản phẩm (ảnh chụp thật).");
      return false;
    }
    if (_titleController.text.trim().isEmpty) {
        _showErrorDialog("Vui lòng nhập tên sản phẩm.");
        return false;
    }

    setState(() => _isAiLoading = true);
    try {
      final result = await _productService.validateMedia(_selectedImages);
      // result: { is_stock, reason, visual_details, condition }
      
      if (result['is_stock'] == true) {
        _showErrorDialog("Lỗi ảnh: ${result['reason'] ?? 'Ảnh trông giống ảnh mạng/stock.'}\nVui lòng dùng ảnh chụp thật.");
        return false;
      }
      
      setState(() {
        _visualDetails = result['visual_details'];
        if (result['condition'] != null) _conditionController.text = result['condition'];
      });
      
      return true;
    } catch (e) {
      // Fail open or closed? User asked for strict check. 
      // But if API fail (network), maybe warn?
      _showErrorDialog("Không thể kiểm tra ảnh: ${e.toString()}");
      return false; // Prevent proceed if check fails? Or allow with warning? User said "bắt buộc phải là ảnh chụp thật".
    } finally {
      setState(() => _isAiLoading = false);
    }
  }

  // STEP 2: GENERATE DETAILS
  Future<void> _handleGenerateDetails() async {
    setState(() => _isAiLoading = true);
    try {
      final result = await _productService.generateDetails(
        productName: _titleController.text,
        visualDetails: _visualDetails ?? "",
        style: _selectedStyle,
        length: _selectedLength
      );

      // 1. Check Moderation (Safety)
      if (result['is_safe'] == false) {
         _showErrorDialog("Vi phạm tiêu chuẩn cộng đồng: ${result['violation_reason'] ?? 'Nội dung không phù hợp.'}");
         return;
      }

      // 2. Check Consistency
      if (result['is_consistent'] == false) {
        bool continueAnyway = await showDialog(
          context: context,
          builder: (c) => AlertDialog(
            title: const Text("Cảnh báo AI"),
            content: Text("AI phát hiện mâu thuẫn: ${result['inconsistency_reason']}\nBạn có muốn sửa lại Tên/Ảnh không?"),
            actions: [
              TextButton(onPressed: () => Navigator.pop(c, false), child: const Text("Quay lại sửa")),
              TextButton(onPressed: () => Navigator.pop(c, true), child: const Text("Vẫn tiếp tục", style: TextStyle(color: Colors.red))),
            ],
          )
        ) ?? false;

        if (!continueAnyway) {
           _prevStep(); // Go back to Step 1
           return;
        }
      }

      setState(() {
        // 3. Auto-fill Description
        _descController.text = result['description'] ?? "";
        
        // 4. Auto-select Category
        String? predictedCategory = result['category'];
        if (predictedCategory != null && _attributeTemplates.containsKey(predictedCategory.toLowerCase())) {
             _onCategoryChanged(predictedCategory.toLowerCase());
        }

        // 5. Auto-fill Attributes (Dynamic Expansion)
        // We iterate through ALL keys returned by AI.
        // If key exists in list -> Update value.
        // If key does NOT exist -> Add new AttributeItem.
        Map<String, dynamic> aiAttrs = result['attributes'] ?? {};
        
        // Handle standard fields first
        if (aiAttrs.containsKey('brand')) _brandController.text = aiAttrs['brand'].toString();
        if (aiAttrs.containsKey('origin')) _originController.text = aiAttrs['origin'].toString();

        aiAttrs.forEach((key, value) {
            String cleanKey = key.toString().toLowerCase().trim();
            String cleanValue = value.toString().trim();

            if (cleanKey == 'brand' || cleanKey == 'origin') return; // Skip standard fields

            // Check if attribute already exists in current list
            int existingIndex = _attributes.indexWhere((attr) => attr.nameController.text.toLowerCase().trim() == cleanKey);

            if (existingIndex != -1) {
                // Update existing
                _attributes[existingIndex].valueController.text = cleanValue;
            } else {
                // Add NEW dynamic attribute
                _attributes.add(AttributeItem(name: _formatKey(cleanKey), value: cleanValue));
            }
        });
      });
      
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Đã tự động điền đầy đủ thông tin!"), backgroundColor: Colors.green));

    } catch (e) {
      _showErrorDialog("Lỗi tạo nội dung: $e");
    } finally {
      setState(() => _isAiLoading = false);
    }
  }
  
  String _formatKey(String key) {
     // Optional: format "power_usage" -> "Power Usage"
     return key.replaceAll("_", " ").split(" ").map((str) => str.isNotEmpty ? '${str[0].toUpperCase()}${str.substring(1)}' : '').join(" ");
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
    // Show Loading: "AI đang phân tích sản phẩm..."
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        content: Row(
          children: const [
            CircularProgressIndicator(),
            SizedBox(width: 20),
            Expanded(child: Text("AI đang phân tích sản phẩm...\nQuá trình này mất khoảng 5-8 giây.", style: TextStyle(fontSize: 14))),
          ],
        ),
      )
    );

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
        Navigator.pop(context); // Close Loading
        // Replace AddProduct screen with SuccessPostScreen
        Navigator.pushReplacementNamed(context, '/success_post');
      }
    } catch (e) {
      if (mounted) {
        Navigator.pop(context); // Close Loading
        String errorMsg = e.toString().replaceAll("Exception:", "").trim();
        _showErrorDialog(errorMsg);
      }
    }
  }

  void _showErrorDialog(String message) {
    showDialog(context: context, builder: (ctx) => AlertDialog(title: const Text("Error"), content: Text(message), actions: [TextButton(onPressed: () => Navigator.of(ctx).pop(), child: const Text("OK"))]));
  }

  // --- VALIDATION ---
  Future<bool> _validateCurrentStep() async {
    switch (_currentStep) {
      case 0: // Step 1: Media + Info
        if (_selectedImages.isEmpty) {
            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Cần ít nhất 1 hình ảnh.")));
            return false;
        }
        if (_titleController.text.isEmpty || _priceController.text.isEmpty) {
             ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Vui lòng nhập Tên và Giá.")));
             return false;
        }
        // Gọi AI check Media
        bool isMediaValid = await _handleValidateMedia();
        return isMediaValid;

      case 1: // Step 2: Details & Attributes
        if (_descController.text.isEmpty) {
            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Vui lòng nhập Mô tả sản phẩm.")));
            return false;
        }
        if (_selectedCategory == null) {
            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Vui lòng chọn Danh mục sản phẩm.")));
            return false;
        }
        return true;

      case 2: // Step 3: Review -> Submit called directly
        return true;
      default:
        return false;
    }
  }

  void _nextStep() async {
    bool valid = await _validateCurrentStep();
    if (valid) {
      if (_currentStep < 2) { // 0 -> 1 -> 2
        setState(() => _currentStep++);
        _pageController.nextPage(duration: const Duration(milliseconds: 300), curve: Curves.easeInOut);
      } else {
        _submitProduct();
      }
    }
  }

  void _prevStep() {
    if (_currentStep > 0) {
      setState(() => _currentStep--);
      _pageController.previousPage(duration: const Duration(milliseconds: 300), curve: Curves.easeInOut);
    }
  }

  // --- UI BUILDING BLOCKS ---

  // STEP 1: MEDIA & INFO
  Widget _buildStep1Media() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text("Bước 1: Hình ảnh & Thông tin", style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
          const Text("Đăng tải ảnh thật (AI sẽ kiểm tra stock/mạng).", style: TextStyle(color: Colors.grey)),
          const SizedBox(height: 20),
          
          _buildSectionTitle("Hình ảnh (Bắt buộc ảnh thật)"),
          const SizedBox(height: 12),
          _buildHorizontalMediaList(label: "Thêm Ảnh", icon: HeroiconsOutline.photo, items: _selectedImages, onAdd: _pickImages, onRemove: _removeImage, isImage: true),
          if (_selectedImages.length > 0)
            const Padding(padding: EdgeInsets.only(top: 8), child: Text("Đã chọn ảnh. Nhấn 'Next' để AI kiểm tra Stock.", style: TextStyle(color: Colors.blue, fontSize: 12))),
            
          const SizedBox(height: 24),
          _buildSectionTitle("Video (Tùy chọn)"),
          const SizedBox(height: 12),
          _buildHorizontalMediaList(label: "Thêm Video", icon: HeroiconsOutline.videoCamera, items: _selectedVideos, onAdd: _pickVideo, onRemove: _removeVideo, isImage: false),

           const SizedBox(height: 24),
           _buildSectionTitle("Tên sản phẩm"),
           const SizedBox(height: 8),
           _buildTextField(controller: _titleController, hint: "VD: Laptop Dell XPS 15 9500"),

           const SizedBox(height: 16),
           _buildSectionTitle("Giá mong muốn (VND)"),
           const SizedBox(height: 8),
           _buildTextField(controller: _priceController, hint: "VD: 25000000", keyboardType: TextInputType.number),
        ],
      ),
    );
  }

  // STEP 2: ESSENTIALS
  Widget _buildStep2Essentials() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text("The Basics", style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
          const Text("Detailed information about your product.", style: TextStyle(color: Colors.grey)),
          const SizedBox(height: 20),

          // --- CONDITION ---
          _buildSectionTitle("Condition"),
          const SizedBox(height: 8),
          _buildTextField(controller: _conditionController, hint: "e.g. New, Like New, Used"),

          const SizedBox(height: 20),

          // --- STYLE & LENGTH ---
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildSectionTitle("Style"),
                    const SizedBox(height: 8),
                     DropdownButtonFormField<String>(
                      value: _selectedStyle,
                      decoration: InputDecoration(
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 0),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        filled: true,
                        fillColor: const Color(0xFFF2F2F2),
                      ),
                      items: _styles.map((s) => DropdownMenuItem(value: s, child: Text(s, style: const TextStyle(fontSize: 13)))).toList(),
                      onChanged: (val) => setState(() => _selectedStyle = val!),
                    )
                  ],
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                     _buildSectionTitle("Length"),
                     const SizedBox(height: 8),
                     DropdownButtonFormField<String>(
                      value: _selectedLength,
                      decoration: InputDecoration(
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 0),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        filled: true,
                         fillColor: const Color(0xFFF2F2F2),
                      ),
                      items: _lengths.map((s) => DropdownMenuItem(value: s, child: Text(s, style: const TextStyle(fontSize: 13)))).toList(),
                      onChanged: (val) => setState(() => _selectedLength = val!),
                    )
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 20),

          // --- DESCRIPTION ---
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildSectionTitle("Description"),
              TextButton.icon(
                onPressed: _isAiLoading ? null : _handleGenerateDetails,
                icon: _isAiLoading 
                    ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2)) 
                    : const Icon(HeroiconsSolid.sparkles, size: 16, color: Colors.purple),
                label: Text(_isAiLoading ? "Processing..." : "✨ AI Generate & Fill", style: const TextStyle(color: Colors.purple, fontSize: 13, fontWeight: FontWeight.bold)),
                style: TextButton.styleFrom(backgroundColor: Colors.purple.shade50, padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8)),
              )
            ],
          ),
          const SizedBox(height: 8),
          _buildTextField(controller: _descController, hint: "Describe your product...", maxLines: 5),

          const SizedBox(height: 20),

          // --- CATEGORY ---
          _buildSectionTitle("Category"),
          const SizedBox(height: 8),
          _buildDropdownField(
            hint: "Select Category", 
            value: _selectedCategory, 
            items: _attributeTemplates.keys.toList(), 
            onChanged: _onCategoryChanged
          ),

          // --- ATTRIBUTES ---
          if (_attributes.isNotEmpty) ...[
             const SizedBox(height: 20),
             const Divider(),
             const SizedBox(height: 10),
             const Text("Attributes", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
             const SizedBox(height: 10),
             ListView.builder(
               shrinkWrap: true,
               physics: const NeverScrollableScrollPhysics(),
               itemCount: _attributes.length,
               itemBuilder: (context, index) {
                 final attr = _attributes[index];
                 return Padding(
                   padding: const EdgeInsets.only(bottom: 12),
                   child: Column(
                     crossAxisAlignment: CrossAxisAlignment.start,
                     children: [
                       Text(attr.nameController.text.toUpperCase(), style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey)),
                       const SizedBox(height: 6),
                       _buildTextField(controller: attr.valueController, hint: "Enter ${attr.nameController.text}"),
                     ],
                   ),
                 );
               },
             )
          ]
        ],
      ),
    );
  }

  // STEP 3: REVIEW & FINALIZE (Merged old Step 3 & 4)
  Widget _buildStep3Finalize() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text("Bước 3: Kiểm tra & Đăng", style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
          const Text("Đảm bảo thông tin chính xác trước khi đăng bán.", style: TextStyle(color: Colors.grey)),
          const SizedBox(height: 20),
          
          _buildSectionTitle("Địa chỉ giao dịch"),
          const SizedBox(height: 8),
          _buildDynamicDropdown(
                hint: "Tỉnh / Thành phố", value: _selectedProvinceCode, items: _provinces,
                itemValueMapper: (item) => item['province_code'].toString(), itemLabelMapper: (item) => item['name'],
                onChanged: (val) { setState(() { _selectedProvinceCode = val; final s = _provinces.firstWhere((e) => e['province_code'].toString() == val, orElse: () => null); _selectedProvinceName = s != null ? s['name'] : null; }); if (val != null) _fetchWards(val); }
            ),
            const SizedBox(height: 8),
            _buildDynamicDropdown(
                hint: "Phường / Xã", value: _selectedWardCode, items: _wards,
                itemValueMapper: (item) => item['ward_code'].toString(), itemLabelMapper: (item) => item['ward_name'],
                onChanged: (val) { setState(() { _selectedWardCode = val; final s = _wards.firstWhere((e) => e['ward_code'].toString() == val, orElse: () => null); _selectedWardName = s != null ? s['ward_name'] : null; }); }
            ),
            const SizedBox(height: 8),
            _buildTextField(controller: _addressDetailController, hint: "Số nhà, tên đường..."),
            
            const SizedBox(height: 20),
            
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: Colors.grey.shade200)),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                     const Text("Review nhanh:", style: TextStyle(fontWeight: FontWeight.bold)),
                     const SizedBox(height: 10),
                     Row(children: [
                        if (_selectedImages.isNotEmpty) Image.file(File(_selectedImages.first.path), width: 50, height: 50, fit: BoxFit.cover),
                        const SizedBox(width: 10),
                        Expanded(child: Text(_titleController.text, style: const TextStyle(fontWeight: FontWeight.bold)))
                     ]),
                     const SizedBox(height: 5),
                     Text("Giá: ${_priceController.text} VND"),
                     Text("Tình trạng: ${_conditionController.text}"),
                     Text("Danh mục: ${_selectedCategory ?? 'Chưa chọn'}"),
                ]
              )
            )
        ]
      )
    );
  }

  // STEP 4: REVIEW
  Widget _buildStep4Review() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text("Review & Submit", style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
          const Text("Double check everything before listing.", style: TextStyle(color: Colors.grey)),
          const SizedBox(height: 30),

           Container(
             padding: const EdgeInsets.all(16),
             decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: Colors.grey.shade200), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4))]),
             child: Column(
               crossAxisAlignment: CrossAxisAlignment.start,
               children: [
                 Row(
                   children: [
                     Container(
                       width: 60, height: 60,
                       decoration: BoxDecoration(borderRadius: BorderRadius.circular(8), color: Colors.grey[100], image: _selectedImages.isNotEmpty ? DecorationImage(image: FileImage(File(_selectedImages.first.path)), fit: BoxFit.cover) : null),
                     ),
                     const SizedBox(width: 16),
                     Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                       Text(_titleController.text, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                       Text("${_priceController.text} VND", style: const TextStyle(color: Colors.blue, fontWeight: FontWeight.bold)),
                     ]))
                   ],
                 ),
                 const Divider(height: 30),
                 _buildReviewRow("Category", _selectedCategory?.toUpperCase() ?? "N/A"),
                 _buildReviewRow("Condition", _conditionController.text),
                 _buildReviewRow("Brand", _brandController.text),
                 _buildReviewRow("Origin", _originController.text),
                 _buildReviewRow("Warranty", _policyController.text),
                 const SizedBox(height: 10),
                 const Text("Description:", style: TextStyle(color: Colors.grey, fontSize: 12)),
                 Text(_descController.text, maxLines: 3, overflow: TextOverflow.ellipsis),
                 const SizedBox(height: 10),
                 const Text("Address:", style: TextStyle(color: Colors.grey, fontSize: 12)),
                 Text("${_addressDetailController.text}, ${_selectedWardName ?? ''}, ${_selectedProvinceName ?? ''}"),
               ],
             ),
           )
        ],
      ),
    );
  }

  Widget _buildReviewRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: Colors.grey)),
          Text(value, style: const TextStyle(fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: const TopBarSecond(title: 'Add New Product'),
      body: Column(
        children: [
          // CUSTOM STEPPER
          Container(
            padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 40),
            color: Colors.white,
            child: Row(
              children: [
                _buildStepIndicator(0, "Media & Info"),
                _buildStepLine(0),
                _buildStepIndicator(1, "AI Auto"),
                _buildStepLine(1),
                _buildStepIndicator(2, "Review & Post"),
              ],
            ),
          ),
          const Divider(height: 1),

          Expanded(
            child: PageView(
              controller: _pageController,
              physics: const NeverScrollableScrollPhysics(), // Disable swipe
              children: [
                _buildStep1Media(),
                _buildStep2Essentials(),
                _buildStep3Finalize(),
              ],
            ),
          ),
        ],
      ),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.all(16),
         decoration: BoxDecoration(color: Colors.white, border: Border(top: BorderSide(color: Colors.grey.shade200))),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
             if (_currentStep > 0)
                TextButton(onPressed: _prevStep, child: const Text("Back", style: TextStyle(color: Colors.grey)))
             else
                const SizedBox.shrink(),

             ElevatedButton(
                onPressed: _nextStep,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.ButtonBlackColor,
                  foregroundColor: Colors.white,
                  shape: const StadiumBorder(),
                  padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                ),
                child: _isAiLoading 
                    ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                    : Text(_currentStep == 2 ? "Upload Product" : "Next"),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildStepIndicator(int step, String label) {
    bool isActive = _currentStep >= step;
    return Column(
      children: [
        Container(
          width: 30, height: 30,
          decoration: BoxDecoration(
            color: isActive ? Colors.black : Colors.grey[200],
            shape: BoxShape.circle,
          ),
          child: Center(
            child: isActive
              ? const Icon(Icons.check, color: Colors.white, size: 16)
              : Text((step + 1).toString(), style: const TextStyle(color: Colors.grey, fontWeight: FontWeight.bold)),
          ),
        ),
        const SizedBox(height: 4),
        Text(label, style: TextStyle(fontSize: 10, color: isActive ? Colors.black : Colors.grey, fontWeight: FontWeight.bold))
      ],
    );
  }

  Widget _buildStepLine(int step) {
    return Expanded(
      child: Container(
        height: 2,
        color: _currentStep > step ? Colors.black : Colors.grey[200],
        margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 15), // align with circle center roughly
        // remove vertical margin if it looks off, alignment is key
      ),
    );
  }

  // --- HELPERS (Reused) ---
  Widget _buildSectionTitle(String title) => Text(title, style: TextStyle(fontSize: 14, color: Colors.grey[800], fontWeight: FontWeight.bold));

  Widget _buildTextField({required TextEditingController controller, required String hint, TextInputType keyboardType = TextInputType.text, int maxLines = 1, bool readOnly = false}) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      maxLines: maxLines,
      readOnly: readOnly,
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
            Container(
                width: 100, margin: const EdgeInsets.only(right: 12),
                decoration: BoxDecoration(borderRadius: BorderRadius.circular(16), color: Colors.grey[200], image: isImage ? DecorationImage(image: FileImage(File(file.path)), fit: BoxFit.cover) : null),
                child: !isImage ? const Center(child: Icon(Icons.play_circle_fill, size: 30, color: Colors.white)) : null
            ),
            Positioned(top: 4, right: 16, child: GestureDetector(onTap: () => onRemove(index - 1), child: Container(padding: const EdgeInsets.all(2), decoration: const BoxDecoration(color: Colors.black54, shape: BoxShape.circle), child: const Icon(Icons.close, size: 14, color: Colors.white))))
          ]);
        },
      ),
    );
  }
}