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
import 'package:temo/components/TopBarSecond.dart';
import 'package:temo/utils/UIHelper.dart';
import 'package:temo/services/user_service.dart';
import '../../services/product_service.dart';
import 'package:temo/models/Product/Product.dart';
import 'package:intl/intl.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart' as latlong;
import 'package:temo/utils/ui_helpers.dart';
import 'package:temo/utils/constants.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:temo/utils/string_utils.dart';
import 'package:temo/components/PremiumImage.dart';
import 'package:temo/Colors/AppColors.dart';

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
  final Product? draftProduct; // Add optional draft
  const AddProduct({super.key, this.draftProduct});

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
  bool _isAiValidated = false; // Trạng thái đã duyệt AI (Media)
  bool _contentAlreadyValidated = false; // Trạng thái đã duyệt nội dung (Step 2)

  // Remote Media (For Drafts)
  List<String> _draftImages = [];
  List<String> _draftVideos = [];
  String? _createdDraftId; // Lưu productId sau lần tạo nháp đầu tiên
  dynamic _freshProductAttribute;

  List<AttributeItem> _attributes = [];

  // --- TEMPLATES ---
  // --- TEMPLATES (Relaxed) ---
  Map<String, List<String>> _attributeTemplates = {};
  Map<String, String> _categoryNames = {};
  Map<String, List<String>> _allowedTypes = {};
  Map<String, List<String>> _apiTypeSpecificAttributes = {};

  // Specific attributes for certain types (Overrides or Extends category defaults)
  final Map<String, List<String>> _typeSpecificAttributes = {
    // Technology
    "Smartphone": [
      "cpu",
      "ram",
      "storage",
      "screen_size",
      "battery_capacity",
      "camera_resolution",
      "color",
    ],
    "Laptop": [
      "cpu",
      "ram",
      "storage",
      "screen_size",
      "battery_capacity",
      "gpu",
      "weight",
    ],
    "Desktop PC": ["cpu", "ram", "storage", "gpu", "psu", "case_type"],
    "Monitor": ["screen_size", "refresh_rate", "panel_type", "resolution"],
    "Mouse": ["sensor_type", "dpi", "connectivity", "buttons"],
    "Keyboard": ["switch_type", "layout", "connectivity", "backlight"],
    "Headphone": ["type", "connectivity", "noise_cancellation", "battery_life"],

    // Appliances
    "Fridge": ["capacity", "door_style", "power_usage", "inverter"],
    "Washing Machine": ["load_capacity", "machine_type", "spin_speed"],
    "Air Conditioner": ["cooling_capacity", "type", "inverter", "gas_type"],
    "Fan": ["power", "fan_speed", "blade_diameter"],
    "Car": [
      "year",
      "fuel_type",
      "transmission",
      "mileage",
      "seats",
      "engine_capacity",
    ],
    "Motorbike": ["year", "fuel_type", "engine_capacity", "mileage"],
  };

  bool get _hasAnyImages =>
      _selectedImages.isNotEmpty || _draftImages.isNotEmpty;
  bool get _hasAnyVideos =>
      _selectedVideos.isNotEmpty || _draftVideos.isNotEmpty;

  // AI Config
  String _selectedStyle = "Chuyên nghiệp";
  String _selectedLength = "Trung bình";
  bool _isAiModerationEnabled = true; // Mặc định bật kiểm duyệt AI
  final List<String> _styles = [
    "Chuyên nghiệp",
    "Gần gũi",
    "Hài hước",
    "Kỹ thuật",
  ];
  final List<String> _lengths = ["Ngắn", "Trung bình", "Chi tiết"];

  // --- ADDRESS & MEDIA ---
  List<dynamic> _provinces = [];
  List<dynamic> _wards = [];
  String? _selectedProvinceCode;
  String? _selectedProvinceName;
  String? _selectedWardCode;
  String? _selectedWardName;
  latlong.LatLng? _mapCenter;

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
    _fetchCategoriesFromApi();
    _initSocketListeners();
    _loadAIConfig(); // Tải cấu hình AI đã lưu

    // Load Draft if available
    if (widget.draftProduct != null) {
      final p = widget.draftProduct!;
      _titleController.text = p.productName;
      _priceController.text = _formatCurrency(p.productPrice.toString());
      _descController.text = p.productDescription;
      _conditionController.text = p.productCondition;
      _brandController.text = p.productBrand;
      _policyController.text = p.productWP;
      _originController.text = p.productOrigin;
      _selectedCategory = p.productCategory;
      _isAiValidated = p.isAiValidated;
      _currentStep = p.lastCompletedStep;

      // Async: Load FRESH data from the server directly to override stale local data!
      Future.delayed(Duration.zero, () async {
        try {
          final freshProduct = await _productService.getProductById(p.productId);
          if (mounted) {
            setState(() {
              _titleController.text = freshProduct.productName;
              _priceController.text = _formatCurrency(freshProduct.productPrice.toString());
              _descController.text = freshProduct.productDescription;
              _conditionController.text = freshProduct.productCondition;
              _brandController.text = freshProduct.productBrand;
              _policyController.text = freshProduct.productWP;
              _originController.text = freshProduct.productOrigin;
              _selectedCategory = freshProduct.productCategory;
              _isAiValidated = freshProduct.isAiValidated;
              _currentStep = freshProduct.lastCompletedStep;

              _draftImages = freshProduct.productMedia
                  .where((m) => !m.contains('.mp4') && !m.contains('.mov'))
                  .toList();
              _draftVideos = freshProduct.productMedia
                  .where((m) => m.contains('.mp4') || m.contains('.mov'))
                  .toList();
              
              _freshProductAttribute = freshProduct.productAttribute;
              _populateAttributes(_freshProductAttribute);
            });
          }
        } catch (e) {
          print("Error loading fresh draft: $e");
        }
      });

      // Load Remote Media
      _draftImages = p.productMedia
          .where((m) => !m.contains('.mp4') && !m.contains('.mov'))
          .toList();
      _draftVideos = p.productMedia
          .where((m) => m.contains('.mp4') || m.contains('.mov'))
          .toList();

      // Load Address
      if (p.productAddress != null) {
        _selectedProvinceName = p.productAddress!.province;
        _selectedWardName = p.productAddress!.commute;
        _addressDetailController.text = p.productAddress!.detail;

        // Note: Province/Ward codes are not easily recoverable without a reverse lookup,
        // but the names are enough for display and re-saving.
      }

      // Reconstruct Visual Details for AI memory
      if (_isAiValidated) {
        _visualDetails =
            "Resumed session. Verified Category: ${_selectedCategory}. Attributes: ${p.productAttribute.toString()}";
      }

      // Jump to last step
      if (_currentStep > 0) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _pageController.jumpToPage(_currentStep);
        });
      }


    }

    _priceController.addListener(() {
      final text = _priceController.text;
      if (text.isEmpty) return;

      // Remove dots to check raw value
      String clean = text.replaceAll('.', '');

      // Avoid infinite loop if no change in value
      if (clean == text && !text.contains('.')) {
        // It's raw number, format it
        final formatted = _formatCurrency(clean);
        if (formatted != text) {
          _priceController.value = TextEditingValue(
            text: formatted,
            selection: TextSelection.collapsed(offset: formatted.length),
          );
        }
      } else {
        // It might have dots. Check if cursor position maintenance is needed or simple re-format.
        // Simple re-format:
        String newFormatted = _formatCurrency(clean);
        if (newFormatted != text) {
          _priceController.value = TextEditingValue(
            text: newFormatted,
            selection: TextSelection.collapsed(offset: newFormatted.length),
          );
        }
      }
    });
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

  Future<void> _loadAIConfig() async {
    final prefs = await SharedPreferences.getInstance();
    if (mounted) {
      setState(() {
        _selectedStyle = prefs.getString('ai_style') ?? "Chuyên nghiệp";
        _selectedLength = prefs.getString('ai_length') ?? "Trung bình";
        _isAiModerationEnabled = prefs.getBool('ai_moderation') ?? true;
      });
    }
  }

  Future<void> _saveAIConfig() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('ai_style', _selectedStyle);
    await prefs.setString('ai_length', _selectedLength);
    await prefs.setBool('ai_moderation', _isAiModerationEnabled);
  }

  void _initSocketListeners() {
    // Socket initialization
  }

  // --- CURRENCY FORMATTER ---
  String _formatCurrency(String value) {
    if (value.isEmpty) return "";
    value = value.replaceAll('.', ''); // Remove existing dots
    if (value.isEmpty) return "";
    final number = int.parse(value);
    return NumberFormat.currency(
      locale: 'vi_VN',
      symbol: '',
      decimalDigits: 0,
    ).format(number).trim();
  }

  Future<void> _fetchCategoriesFromApi() async {
    try {
      final response = await http.get(Uri.parse('${ApiConstants.baseUrl}/categories'));
      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        setState(() {
          _attributeTemplates.clear();
          _categoryNames.clear();
          _allowedTypes.clear();
          _apiTypeSpecificAttributes.clear();
          
          for (var cat in data) {
            String catId = cat['categoryId'];
            String catName = cat['categoryName'];
            _categoryNames[catId] = catName;
            
            List<String> types = [];
            Set<String> uniqueTypes = {};
            if (cat['productTypes'] != null) {
              for (var t in cat['productTypes']) {
                if (!uniqueTypes.contains(t['typeName'])) {
                  uniqueTypes.add(t['typeName']);
                  types.add(t['typeName']);
                  List<String> typeAttrs = [];
                  if (t['attributes'] != null) {
                    for (var ta in t['attributes']) {
                      typeAttrs.add(ta['name']);
                    }
                  }
                  _apiTypeSpecificAttributes[t['typeName']] = typeAttrs;
                }
              }
            }
            _allowedTypes[catId] = types;
            
            List<String> attrs = ["type"];
            if (cat['attributes'] != null) {
              for (var a in cat['attributes']) {
                attrs.add(a['name']);
              }
            }
            _attributeTemplates[catId] = attrs;
          }
          
          if (widget.draftProduct != null && _selectedCategory != null) {
            _populateAttributes(_freshProductAttribute ?? widget.draftProduct!.productAttribute);
          }
        });
      }
    } catch (e) {
      print("Error fetching dynamic categories: $e");
    }
  }

  void _populateAttributes(dynamic attrData) {
    if (_selectedCategory == null) return;
    if (attrData == null) return;

    if (_attributeTemplates.containsKey(_selectedCategory)) {
      _attributes.clear();
      for (String key in _attributeTemplates[_selectedCategory]!) {
        _attributes.add(AttributeItem(name: key, value: ""));
      }
    }

    Map<String, dynamic> draftAttrs = {};
    try {
      if (attrData is String) {
        draftAttrs = jsonDecode(attrData);
      } else if (attrData is Map) {
        draftAttrs = Map<String, dynamic>.from(attrData);
      }
    } catch (e) {
      print("Error parsing attributes: $e");
    }

    draftAttrs.forEach((key, value) {
      String cleanKey = key.toString().toLowerCase().replaceAll(' ', '_');
      int index = _attributes.indexWhere(
        (attr) => attr.nameController.text.toLowerCase().replaceAll(' ', '_') == cleanKey
      );

      if (index != -1) {
        _attributes[index].valueController.text = value.toString();
      } else {
        _attributes.add(AttributeItem(name: _formatKey(key.toString()), value: value.toString()));
      }
    });
  }

  Future<void> _fetchProvinces() async {
    try {
      final response = await http.get(
        Uri.parse('https://34tinhthanh.com/api/provinces'),
      );
      if (response.statusCode == 200)
        setState(() => _provinces = jsonDecode(response.body));
    } catch (e) {
      print("Error provinces: $e");
    }
  }

  Future<void> _fetchWards(String provinceCode) async {
    setState(() {
      _wards = [];
      _selectedWardCode = null;
      _selectedWardName = null;
    });
    try {
      final response = await http.get(
        Uri.parse(
          'https://34tinhthanh.com/api/wards?province_code=$provinceCode',
        ),
      );
      if (response.statusCode == 200)
        setState(() => _wards = jsonDecode(response.body));
    } catch (e) {
      print("Error wards: $e");
    }
  }

  Future<void> _pickImages() async {
    UIHelper.showImageSourceSheet(
      context,
      isVideo: false,
      allowMultiple: true,
      onPicked: (images) {
        if (images != null) setState(() => _selectedImages.addAll(images));
      },
    );
  }

  Future<void> _pickVideo() async {
    UIHelper.showImageSourceSheet(
      context,
      isVideo: true,
      onPicked: (videos) {
        if (videos != null && videos.isNotEmpty) {
          setState(() => _selectedVideos.add(videos.first));
        }
      },
    );
  }

  void _showPermissionDialog() {
    UIHelpers.showModernDialog(
      context,
      icon: HeroiconsOutline.lockClosed,
      iconColor: AppColors.primary,
      bgColor: AppColors.primary.withOpacity(0.1),
      title: "Yêu cầu quyền truy cập",
      description:
          "Vui lòng cấp quyền truy cập máy ảnh trong Cài đặt để sử dụng tính năng này.",
      primaryButtonText: "Mở Cài đặt",
      onPrimaryPressed: () {
        Navigator.pop(context);
        openAppSettings();
      },
      secondaryButtonText: "Hủy",
    );
  }

  void _removeImage(int index, bool isRemote) {
    setState(() {
      if (isRemote) {
        _draftImages.removeAt(index);
      } else {
        _selectedImages.removeAt(index);
      }
      _isAiValidated =
          false; // Khi xóa ảnh thì phải duyệt lại (nếu thêm ảnh mới)
    });
  }

  void _removeVideo(int index, bool isRemote) {
    setState(() {
      if (isRemote) {
        _draftVideos.removeAt(index);
      } else {
        _selectedVideos.removeAt(index);
      }
    });
  }

  // --- LOGIC MANUAL CATEGORY ---
  void _onCategoryChanged(String? newCategory) {
    if (_selectedCategory == newCategory) return;
    
    setState(() {
      // 1. Capture current values
      Map<String, String> currentValues = {};
      for (var attr in _attributes) {
        if (attr.valueController.text.isNotEmpty) {
          currentValues[attr.nameController.text.toLowerCase().trim()] =
              attr.valueController.text;
        }
      }

      _selectedCategory = newCategory;

      // 2. Rebuild attributes based on template
      _rebuildAttributeList(preservedValues: currentValues);
    });
  }

  void _rebuildAttributeList({Map<String, String>? preservedValues, String? forcedType}) {
    // Note: Call this inside setState if needed
    
    // 1. Dispose old
    for (var attr in _attributes) attr.dispose();
    _attributes.clear();

    Set<String> addedKeys = {};
    Map<String, String> values = preservedValues ?? {};

    // A. Category Common Attributes
    if (_selectedCategory != null && _attributeTemplates.containsKey(_selectedCategory)) {
      for (String key in _attributeTemplates[_selectedCategory]!) {
        String cleanKey = key.toLowerCase().trim();
        _attributes.add(AttributeItem(name: key, value: values[cleanKey] ?? ""));
        addedKeys.add(cleanKey);
      }
    }

    // B. Type-Specific Attributes
    String? currentType = forcedType;
    if (currentType == null) {
      // Find current type value from preserved or existing attributes
      currentType = values["type"];
      if (currentType == null || currentType.isEmpty) {
        var typeAttr = _attributes.firstWhere((a) => a.nameController.text.toLowerCase() == "type", orElse: () => AttributeItem());
        currentType = typeAttr.valueController.text;
      }
    }

    if (currentType != null && currentType.isNotEmpty) {
      String? matchedKey;
      String cleanType = currentType.toLowerCase().trim().replaceAll(' ', '');
      for (String k in _apiTypeSpecificAttributes.keys) {
        String cleanK = k.toLowerCase().trim().replaceAll(' ', '');
        if (cleanK == cleanType || cleanK.contains(cleanType) || cleanType.contains(cleanK)) {
          matchedKey = k;
          break;
        }
      }

      List<String>? typeAttrs = matchedKey != null ? _apiTypeSpecificAttributes[matchedKey] : _typeSpecificAttributes[currentType];
      if (typeAttrs != null) {
        for (String key in typeAttrs) {
          String cleanKey = key.toLowerCase().trim();
          if (!addedKeys.contains(cleanKey)) {
            _attributes.add(AttributeItem(name: key, value: values[cleanKey] ?? ""));
            addedKeys.add(cleanKey);
          }
        }
      }
    }

    // Ensure type is present
    if (!addedKeys.contains("type")) {
      _attributes.add(AttributeItem(name: "type", value: currentType ?? ""));
    }

    // C. Always add Warranty at end
    if (!addedKeys.contains("warranty")) {
      _attributes.add(AttributeItem(name: "warranty", value: values["warranty"] ?? ""));
    }
  }

  void _fillAttributesFromMap(Map<String, dynamic> data, {bool overwrite = false}) {
    data.forEach((key, value) {
      if (value == null) return;
      String cleanKey = key.toString().toLowerCase().trim();
      String valStr = value.toString().trim();
      if (valStr.isEmpty || valStr.toUpperCase() == "N/A" || valStr.toUpperCase() == "UNKNOWN") return;

      // Handle root fields (Database structure)
      if (cleanKey == "brand" || cleanKey == "productbrand") {
        if (overwrite || _brandController.text.isEmpty) _brandController.text = valStr;
        // Don't return, let it also fill the dynamic list below
      }
      if (cleanKey == "origin" || cleanKey == "productorigin") {
        if (overwrite || _originController.text.isEmpty) _originController.text = valStr;
        // Don't return
      }
      if (cleanKey == "condition" || cleanKey == "productcondition") {
        if (overwrite || _conditionController.text.isEmpty) _conditionController.text = valStr;
      }

      // Handle template attributes (UI Display)
      String normalize(String s) => s.toLowerCase().trim().replaceAll(' ', '_').replaceAll('-', '_');
      String normKey = normalize(cleanKey);

      for (var attr in _attributes) {
        String attrName = attr.nameController.text.toLowerCase().trim();
        String normAttrName = normalize(attrName);
        
        bool isMatch = (normAttrName == normKey);
        
        // Smart Mapping for common Vietnamese labels
        if (!isMatch) {
          if ((normKey == "brand" || normKey == "productbrand") && 
              (attrName == "thương hiệu" || attrName == "hãng" || attrName == "nhãn hiệu")) isMatch = true;
          if ((normKey == "origin" || normKey == "productorigin") && 
              (attrName == "xuất xứ" || attrName == "nơi sản xuất")) isMatch = true;
        }

        if (isMatch) {
          if (overwrite || attr.valueController.text.isEmpty || attr.valueController.text.toUpperCase() == "N/A") {
            attr.valueController.text = valStr;
          }
          break;
        }
      }
    });
  }

  // --- LOGIC MANUAL TYPE ---
  Future<void> _onTypeChanged(String newType, {bool fetchSuggestions = true}) async {
    setState(() {
      Map<String, String> preserved = {};
      for (var a in _attributes) {
        if (a.valueController.text.isNotEmpty) preserved[a.nameController.text.toLowerCase().trim()] = a.valueController.text;
      }
      preserved["type"] = newType;
      _rebuildAttributeList(preservedValues: preserved, forcedType: newType);
    });

    if (fetchSuggestions && _isAiModerationEnabled) {
      await _fetchAttributesFromN8N(newType);
    }
  }

  // Gọi n8n để điền giá trị attribute tự động sau khi chọn Type
  Future<void> _fetchAttributesFromN8N(String productType) async {
    if (_selectedCategory == null || _titleController.text.trim().isEmpty) return;

    setState(() => _isAiLoading = true);
    try {
      final result = await _productService.getAISuggestion(
        productName: _titleController.text.trim(),
        description: _descController.text.trim(),
        condition: _conditionController.text.trim(),
        category: _selectedCategory,
        productType: productType,
      );

      print("[AI-ATTR] Raw result: $result");

      if (result == null) return;

      // --- PARSE ATTRIBUTES TỪ NHIỀU DẠNG RESPONSE KHÁC NHAU ---
      Map<String, dynamic> aiAttrs = {};

      // Case 1: { "output": "{ \"attributes\": {...} }" } — n8n AI Agent wrap trong string
      if (result['output'] != null) {
        try {
          String cleaned = result['output']
              .toString()
              .replaceAll('```json', '')
              .replaceAll('```', '')
              .trim();
          final parsed = jsonDecode(cleaned);
          if (parsed is Map) {
            if (parsed['attributes'] is Map) {
              aiAttrs = Map<String, dynamic>.from(parsed['attributes']);
            } else {
              aiAttrs = Map<String, dynamic>.from(parsed);
            }
          }
        } catch (e) {
          print("[AI-ATTR] Failed to parse output string: $e");
        }
      }

      // Case 2: { "attributes": { "brand": "Apple", ... } } — đúng format
      if (aiAttrs.isEmpty && result['attributes'] is Map) {
        aiAttrs = Map<String, dynamic>.from(result['attributes']);
      }

      // Case 3: flat object { "brand": "Apple", "ram": "8GB" } — không có wrapper
      if (aiAttrs.isEmpty && result.isNotEmpty) {
        aiAttrs = Map<String, dynamic>.from(result);
      }

      print("[AI-ATTR] Extracted attributes: $aiAttrs");

      if (aiAttrs.isEmpty) return;

      setState(() {
        print("[AI-ATTR] Filling attributes with overwrite: false");
        _fillAttributesFromMap(aiAttrs, overwrite: false); // Chỉ điền vào các ô còn trống
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("✨ AI đã gợi ý thông số kỹ thuật!"),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      print("[AI-ATTR] n8n suggestion failed: $e");
      // Không hiện lỗi to — để user tự điền
    } finally {
      if (mounted) setState(() => _isAiLoading = false);
    }
  }


  // --- LOGIC AI SUGGESTION ---
  // --- LOGIC AI HANDLERS ---

  // STEP 1: VALIDATE MEDIA
  Future<bool> _handleValidateMedia() async {
    // 1. Kiểm tra nếu không có bất kỳ ảnh nào
    if (!_hasAnyImages) {
      _showErrorDialog(
        "Vui lòng tải lên ít nhất 1 hình ảnh sản phẩm (ảnh thật).",
      );
      return false;
    }

    // 2. Nếu ĐÃ duyệt AI và KHÔNG CÓ ảnh mới -> Cho qua ngay
    if (_isAiValidated && _selectedImages.isEmpty) {
      return true;
    }

    // 3. Nếu chưa duyệt AI HOẶC có ảnh mới -> Bắt buộc phải quét AI
    setState(() => _isAiLoading = true);
    try {
      final result = await _productService.validateMedia(
        _selectedImages,
        _titleController.text,
        remoteUrls: _selectedImages.isEmpty ? _draftImages : [], // Nếu có ảnh mới, chỉ kiểm duyệt ảnh mới để tăng tốc
      );

      print("AI Check Result: ${result.toString()}");

      if (result['is_stock'] == true) {
        _showErrorDialog(
          "Ảnh của bạn không hợp lệ! Hệ thống nhận diện đây là ảnh mạng hoặc ảnh quảng cáo. Vui lòng chụp ảnh thật của sản phẩm để tiếp tục.",
        );
        return false;
      }

      // Extract Info
      String? detectedCategory = result['category'];
      String? detectedType;
      Map<String, dynamic> attrs = result['attributes'] ?? {};
      attrs.forEach((k, v) {
        if (k.toString().toLowerCase() == 'type') detectedType = v.toString().trim();
      });

      setState(() {
        if (result['condition'] != null) _conditionController.text = result['condition'];

        // A. Update Category Selection (don't call _onCategoryChanged as it rebuilds prematurely)
        if (detectedCategory != null && _attributeTemplates.containsKey(detectedCategory.toLowerCase())) {
          _selectedCategory = detectedCategory.toLowerCase();
        }

        // B. Group all values (Current + AI detected)
        Map<String, String> valuesToPreserve = {};
        for (var attr in _attributes) {
          if (attr.valueController.text.isNotEmpty) {
            valuesToPreserve[attr.nameController.text.toLowerCase().trim()] = attr.valueController.text;
          }
        }
        // Overlay AI detected values
        attrs.forEach((key, value) {
          valuesToPreserve[key.toString().toLowerCase().trim()] = value.toString().trim();
        });

        // C. Single Rebuild of the list based on templates
        _rebuildAttributeList(preservedValues: valuesToPreserve, forcedType: detectedType);

        // D. Final fill (for root fields like Brand)
        _fillAttributesFromMap(attrs, overwrite: true);

        _visualDetails = "Detected Info from Image:\n"
            "Category: ${result['category'] ?? 'Unknown'}\n"
            "Condition: ${result['condition'] ?? 'Unknown'}\n"
            "Attributes: ${attrs.toString()}";
        _isAiValidated = true;

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("✨ AI đã trích xuất thông tin từ hình ảnh!"),
            backgroundColor: Colors.green,
          ),
        );
      });

      return true;
    } catch (e) {
      _showErrorDialog("Lỗi hệ thống AI: $e");
      return false;
    } finally {
      setState(() => _isAiLoading = false);
    }
  }

  // STEP 2: GENERATE DETAILS
  Future<void> _handleGenerateDetails() async {
    setState(() => _isAiLoading = true);
    try {
      Set<String> expectedKeys = {};
      if (_selectedCategory != null && _attributeTemplates.containsKey(_selectedCategory)) {
        expectedKeys.addAll(
          _attributeTemplates[_selectedCategory]!
            .where((e) => e != "condition")
            .map((e) => e.toLowerCase().trim())
        );
      }
      
      String? currentType;
      try {
        var typeAttr = _attributes.firstWhere(
          (a) => a.nameController.text.toLowerCase() == 'type',
          orElse: () => AttributeItem(name: "", value: ""),
        );
        if (typeAttr.nameController.text.isNotEmpty) {
          currentType = typeAttr.valueController.text;
        }
      } catch (e) {}

      if (currentType != null) {
        String? matchedKey;
        String cleanType = currentType.toLowerCase().trim().replaceAll(' ', '');
        for (String k in _apiTypeSpecificAttributes.keys) {
          String cleanK = k.toLowerCase().trim().replaceAll(' ', '');
          if (cleanK == cleanType || cleanK.contains(cleanType) || cleanType.contains(cleanK)) {
            matchedKey = k;
            break;
          }
        }

        if (matchedKey != null) {
          expectedKeys.addAll(_apiTypeSpecificAttributes[matchedKey]!.map((e) => e.toLowerCase().trim()));
        } else if (_typeSpecificAttributes.containsKey(currentType)) {
          expectedKeys.addAll(_typeSpecificAttributes[currentType]!.map((e) => e.toLowerCase().trim()));
        }
      }

      Set<String> emptyKeys = {};
      for (var key in expectedKeys) {
        bool isFilled = false;
        try {
          var attrItem = _attributes.firstWhere(
            (a) => a.nameController.text.toLowerCase().trim() == key.toLowerCase().trim(),
            orElse: () => AttributeItem(name: "", value: ""),
          );
          if (attrItem.nameController.text.isNotEmpty && 
              attrItem.valueController.text.trim().isNotEmpty &&
              attrItem.valueController.text.trim() != "N/A") {
            isFilled = true;
          }
        } catch (e) {}
        if (!isFilled) {
          emptyKeys.add(key);
        }
      }

      // Parallelize Description Generation and N8N Attribute Fetching
      List<Future> parallelTasks = [];

      // 1. Task: Generate Details (Description, Category, initial attrs)
      if (_descController.text.trim().isEmpty) {
        print("[AI-GEN] Description is empty, preparing generation task...");
        parallelTasks.add(_generateDescriptionTask(emptyKeys));
      } else {
        print("[AI-GEN] Description already exists, skipping generation task.");
      }

      // 2. Task: Fetch Attributes from N8N
      if (currentType != null && currentType.isNotEmpty) {
        print("[AI-GEN] Fetching attributes from N8N in parallel...");
        parallelTasks.add(_fetchAttributesFromN8N(currentType));
      }

      // Execute all tasks in parallel
      if (parallelTasks.isNotEmpty) {
        await Future.wait(parallelTasks);
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("✨ AI đã hoàn tất việc chuẩn bị thông tin!"),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      print("[AI-ERROR] $e");
      setState(() => _isAiValidated = false);
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("AI đang bận hoặc gặp sự cố. Bạn hãy tự điền thông tin và tin đăng sẽ được Admin duyệt thủ công nhé!"),
          backgroundColor: Colors.orange,
          duration: Duration(seconds: 5),
        ),
      );
    } finally {
      setState(() => _isAiLoading = false);
    }
  }

  // Helper task for parallel execution
  Future<void> _generateDescriptionTask(Set<String> emptyKeys) async {
    final result = await _productService.generateDetails(
      productName: _titleController.text,
      visualDetails: _visualDetails ?? "User uploaded verified images.",
      style: _selectedStyle,
      length: _selectedLength,
      allowedAttributes: emptyKeys.toList(),
      selectedCondition: _conditionController.text,
    );

    // 1. Check Moderation (Safety)
    if (result['is_safe'] == false) {
      _showErrorDialog(
        "Community standard violation: ${result['violation_reason'] ?? 'Inappropriate content.'}",
      );
      return;
    }

    // 2. Check Consistency
    if (result['is_consistent'] == false) {
      bool continueAnyway = await UIHelpers.confirmDialog(
        context,
        title: "Cảnh báo từ AI",
        message: "AI phát hiện thông tin không đồng nhất: ${result['inconsistency_reason']}\nBạn có muốn quay lại để chỉnh sửa Tên/Ảnh không?",
        confirmText: "Tiếp tục",
        cancelText: "Quay lại",
        confirmColor: Colors.red,
        icon: HeroiconsOutline.exclamationTriangle,
      ) ?? false;

      if (!continueAnyway) {
        _prevStep();
        return;
      }
    }

    if (mounted) {
      setState(() {
        _descController.text = result['description'] ?? "";
        String? predictedCategory = result['category'];
        if (predictedCategory != null && _attributeTemplates.containsKey(predictedCategory.toLowerCase())) {
          _onCategoryChanged(predictedCategory.toLowerCase());
        }
        Map<String, dynamic> aiAttrs = result['attributes'] ?? {};
        _fillAttributesFromMap(aiAttrs, overwrite: false);
        _isAiValidated = true;
        _contentAlreadyValidated = true;
      });
    }
  }

  // STEP 2 END: VALIDATE CONTENT
  Future<bool> _handleValidateContent() async {
    if (_contentAlreadyValidated) return true;
    setState(() => _isAiLoading = true);
    try {
      // Prepare data (Convert Display Keys to Snake Case for Backend)
      Map<String, dynamic> attributesMap = {};
      for (var item in _attributes) {
        String keysnake = item.nameController.text
            .trim()
            .toLowerCase()
            .replaceAll(' ', '_');
        attributesMap[keysnake] = item.valueController.text.trim();
      }

      // Validate mandatory common attributes
      if (_selectedCategory != null && _attributeTemplates.containsKey(_selectedCategory)) {
        for (String commonKey in _attributeTemplates[_selectedCategory]!) {
          String cleanCommonKey = commonKey.toLowerCase().trim().replaceAll(' ', '_');
          if (!attributesMap.containsKey(cleanCommonKey) || attributesMap[cleanCommonKey].toString().isEmpty) {
            String displayName = _formatKey(commonKey);
            _showErrorDialog("Vui lòng điền thuộc tính chung bắt buộc: $displayName");
            return false;
          }
        }
      }

      String typeVal = "";
      try {
        var typeAttr = _attributes.firstWhere(
          (a) => a.nameController.text.toLowerCase() == 'type',
          orElse: () => AttributeItem(name: "", value: ""),
        );
        if (typeAttr.nameController.text.isNotEmpty)
          typeVal = typeAttr.valueController.text;
      } catch (e) {}

      final result = await _productService.validateContent(
        productName: _titleController.text,
        productDescription: _descController.text,
        category: _selectedCategory ?? "",
        type: typeVal,
        attributes: attributesMap,
      );

      if (result['is_safe'] == false) {
        _showErrorDialog(
          "Community standard violation: ${result['violation_reason']}",
        );
        return false;
      }

      if (result['is_consistent'] == false) {
        _showErrorDialog(
          "Inconsistent information: ${result['inconsistency_reason']}\n- Name: ${_titleController.text}\n- Description/Attributes do not match.",
        );
        return false;
      }

      if (result['suggestions'] != null &&
          result['suggestions'].toString().isNotEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Gợi ý: ${result['suggestions']}"),
            duration: const Duration(seconds: 3),
          ),
        );
      }

      return true;
    } catch (e) {
      _showErrorDialog("Content verification error: $e");
      return false;
    } finally {
      setState(() => _isAiLoading = false);
    }
  }

  String _formatKey(String key) {
    final Map<String, String> vnKeys = {
      "type": "Loại sản phẩm",
      "brand": "Thương hiệu",
      "model": "Dòng máy / Mã",
      "condition": "Tình trạng",
      "warranty": "Bảo hành",
      "material": "Chất liệu",
      "color": "Màu sắc",
      "dimensions": "Kích thước",
      "weight": "Trọng lượng",
      "power": "Công suất",
      "capacity": "Dung tích / Sức chứa",
      "ram": "Bộ nhớ RAM",
      "storage": "Bộ nhớ lưu trữ",
      "processor": "Bộ vi xử lý (CPU)",
      "battery": "Dung lượng pin",
      "screen_size": "Kích thước màn hình",
      "gpu": "Card đồ họa (GPU)",
      "author": "Tác giả",
      "publisher": "Nhà xuất bản",
      "breed": "Giống loài",
      "gender": "Giới tính",
      "size": "Kích cỡ",
      "origin": "Xuất xứ",
      "dpi": "Độ nhạy chuột (DPI)",
      "buttons": "Số lượng phím bấm",
      "connectivity": "Kiểu kết nối",
      "sensor_type": "Mắt đọc cảm biến",
    };

    String cleanKey = key.toLowerCase().trim();
    if (vnKeys.containsKey(cleanKey)) return vnKeys[cleanKey]!;

    // Fallback to title case
    return cleanKey
        .replaceAll("_", " ")
        .split(" ")
        .map(
          (str) => str.isNotEmpty
              ? '${str[0].toUpperCase()}${str.substring(1)}'
              : '',
        )
        .join(" ");
  }

  void _activateBackupMode() {
    setState(() {
      _showManualBackup = true;
      _selectedCategory = null;
      for (var attr in _attributes) attr.dispose();
      _attributes.clear();
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text("AI không thể xử lý. Đã chuyển sang chế độ thủ công."),
        backgroundColor: Colors.redAccent,
      ),
    );
  }

  // --- SUBMIT ---
  Future<void> _submitProduct() async {
    // Show Loading: Clean ModernLoader
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(
        child: ModernLoader(
          showText: true,
          color: AppColors.primary,
        ),
      ),
    );

    try {
      final existingId = widget.draftProduct?.productId ?? _createdDraftId;
      Map<String, dynamic> attributesMap = {};
      for (var item in _attributes) {
        String keysnake = item.nameController.text
            .trim()
            .toLowerCase()
            .replaceAll(' ', '_');
        attributesMap[keysnake] = item.valueController.text.trim();
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

      // Mặc định dùng toggle, nhưng nếu AI chưa được xác thực (lỗi) thì ép sang Admin duyệt
      String finalStatus = _isAiModerationEnabled && _isAiValidated ? "active" : "pending";

      Map<String, String> fields = {
        "productName": _titleController.text,
        "productPrice": _priceController.text.replaceAll('.', ''),
        "productDescription": _descController.text,
        "categoryId": _selectedCategory ?? "other",
        "productCategory": _selectedCategory ?? "other",
        "productOrigin": _originController.text,
        "productCondition": _conditionController.text,
        "productBrand": _brandController.text,
        "productWP": _policyController.text,
        "userId": userId,
        "status": finalStatus,
        "productAttribute": jsonEncode(attributesMap),
        "productAddress": jsonEncode(addressMap),
      };

      // --- ADD LATITUDE & LONGITUDE ---
      try {
        Position position = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high,
        );
        fields["latitude"] = position.latitude.toString();
        fields["longitude"] = position.longitude.toString();
        print("Captured Location: ${position.latitude}, ${position.longitude}");
      } catch (e) {
        print("Could not capture location for new post: $e");
        // We continue without coordinates if GPS fails
      }

      fields["lastCompletedStep"] = "3";
      fields["isAiValidated"] = "true";
      fields["existingMedia"] = jsonEncode([..._draftImages, ..._draftVideos]);

      List<XFile> newFiles = [..._selectedImages, ..._selectedVideos];

      if (existingId != null) {
        await _productService.updateProductWithMedia(
          existingId,
          fields,
          newFiles,
        );
      } else {
        await _productService.createProduct(fields: fields, files: newFiles);
      }

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
    UIHelpers.showErrorDialog(context, title: "Lỗi", message: message);
  }

  void _showSavePresetDialog() {
    final nameController = TextEditingController();
    UIHelpers.showModernDialog(
      context,
      icon: HeroiconsOutline.bookmark,
      iconColor: Colors.orange,
      bgColor: Colors.orange.withOpacity(0.1),
      title: "Lưu thành mẫu",
      description: "Nhập tên cho mẫu thông tin này:",
      primaryButtonText: "Lưu",
      onPrimaryPressed: () async {
        if (nameController.text.trim().isEmpty) return;
        Navigator.pop(context); // Close dialog
        
        // Prepare attributes map
        Map<String, dynamic> attrMap = {};
        for (var attr in _attributes) {
          if (attr.nameController.text.isNotEmpty && attr.valueController.text.isNotEmpty) {
            attrMap[attr.nameController.text] = attr.valueController.text;
          }
        }
        
        String? currentType;
        try {
          var typeAttr = _attributes.firstWhere(
            (a) => a.nameController.text.toLowerCase() == 'type' || a.nameController.text.toLowerCase() == 'loại',
            orElse: () => AttributeItem(name: "", value: ""),
          );
          if (typeAttr.nameController.text.isNotEmpty) {
            currentType = typeAttr.valueController.text;
          }
        } catch (e) {}

        try {
          await _productService.createPreset(
            presetName: nameController.text.trim(),
            productName: _titleController.text,
            categoryId: _selectedCategory ?? "",
            productType: currentType,
            productAttribute: attrMap,
          );
          
          if (mounted) {
            UIHelpers.showSuccessSnackBar(context, "Đã lưu mẫu thông tin!");
          }
        } catch (e) {
          _showErrorDialog("Lỗi lưu mẫu: $e");
        }
      },
      secondaryButtonText: "Hủy",
      content: Padding(
        padding: const EdgeInsets.only(top: 16),
        child: TextField(
          controller: nameController,
          decoration: InputDecoration(
            hintText: "VD: Mẫu Chuột Inphic",
            filled: true,
            fillColor: Colors.grey[100],
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(15),
              borderSide: BorderSide.none,
            ),
          ),
        ),
      ),
    );
  }

  void _showPresetsSheet() async {
    setState(() => _isAiLoading = true);
    List<dynamic> presets = [];
    try {
      presets = await _productService.getPresets();
    } catch (e) {
      print("Error fetching presets: $e");
    } finally {
      setState(() => _isAiLoading = false);
    }

    if (!mounted) return;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => StatefulBuilder(
        builder: (context, setSheetState) {
          return Container(
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(context).size.height * 0.7,
            ),
            margin: const EdgeInsets.fromLTRB(16, 0, 16, 24),
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(35),
              boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 20)],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 24),
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const Text(
                  "Chọn mẫu thông tin",
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),
                if (presets.isEmpty)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 20),
                    child: Text("Chưa có mẫu nào được lưu.", style: TextStyle(color: Colors.grey)),
                  )
                else
                  Flexible(
                    child: ListView.builder(
                      shrinkWrap: true,
                      itemCount: presets.length,
                      itemBuilder: (context, index) {
                        final preset = presets[index];
                        return ListTile(
                          title: Text(preset['presetName'] ?? 'Không tên', style: const TextStyle(fontWeight: FontWeight.bold)),
                          subtitle: Text(preset['productName'] ?? ''),
                          trailing: IconButton(
                            icon: const Icon(Icons.delete_outline, color: Colors.red),
                            onPressed: () async {
                              final confirm = await UIHelpers.confirmDialog(
                                context,
                                title: "Xóa mẫu",
                                message: "Bạn có chắc chắn muốn xóa mẫu này?",
                              );
                              if (confirm == true) {
                                try {
                                  await _productService.deletePreset(preset['id']);
                                  presets.removeAt(index);
                                  setSheetState(() {});
                                } catch (e) {
                                  print("Error deleting preset: $e");
                                }
                              }
                            },
                          ),
                          onTap: () {
                            Navigator.pop(context);
                            _applyPreset(preset);
                          },
                        );
                      },
                    ),
                  ),
              ],
            ),
          );
        }
      ),
    );
  }

  void _applyPreset(dynamic preset) {
    setState(() {
      if (preset['productName'] != null) {
        _titleController.text = preset['productName'];
      }
      if (preset['categoryId'] != null) {
        _selectedCategory = preset['categoryId'];
      }
      
      // Populate attributes
      if (preset['productAttribute'] != null) {
        _populateAttributes(preset['productAttribute']);
      }
    });
  }

  void _showAISettingsSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => StatefulBuilder(
        builder: (context, setSheetState) {
          return SafeArea(
          child: Container(
            margin: const EdgeInsets.fromLTRB(16, 0, 16, 24),
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.95),
              borderRadius: BorderRadius.circular(45),
              boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 20)],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 24),
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const Text(
                  "Cài đặt đăng tin",
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                const Text(
                  "Tùy chỉnh cách AI hỗ trợ đăng tin của bạn.",
                  style: TextStyle(color: Colors.grey, fontSize: 13),
                ),
                const SizedBox(height: 24),

                _buildAISettingItem(
                  icon: HeroiconsOutline.checkBadge,
                  iconColor: Colors.blue,
                  bgColor: Colors.blue.withOpacity(0.1),
                  title: "Tính năng hỗ trợ AI",
                  value: _isAiModerationEnabled ? "Bật các tính năng thông minh" : "Tắt toàn bộ tính năng AI",
                  trailing: Switch(
                    value: _isAiModerationEnabled,
                    activeColor: AppColors.primary,
                    onChanged: (val) {
                      setState(() => _isAiModerationEnabled = val);
                      _saveAIConfig();
                      setSheetState(() {});
                    },
                  ),
                  onTap: () {
                    setState(() => _isAiModerationEnabled = !_isAiModerationEnabled);
                    _saveAIConfig();
                    setSheetState(() {});
                  },
                ),
                const SizedBox(height: 12),

                _buildAISettingItem(
                  icon: HeroiconsOutline.sparkles,
                  iconColor: AppColors.primary,
                  bgColor: AppColors.primary.withOpacity(0.1),
                  title: "Phong cách viết",
                  value: _selectedStyle,
                    onTap: () => _showSelectionSheet(
                      "Chọn phong cách",
                      _styles,
                      _selectedStyle,
                      (val) {
                        setState(() => _selectedStyle = val);
                        _saveAIConfig();
                        setSheetState(() {}); // Refresh sheet
                      },
                    ),
                ),
                const SizedBox(height: 12),
                _buildAISettingItem(
                  icon: HeroiconsOutline.bars3BottomLeft,
                  iconColor: Colors.amber,
                  bgColor: Colors.amber.withOpacity(0.1),
                  title: "Độ dài nội dung",
                  value: _selectedLength,
                    onTap: () => _showSelectionSheet(
                      "Chọn độ dài",
                      _lengths,
                      _selectedLength,
                      (val) {
                        setState(() => _selectedLength = val);
                        _saveAIConfig();
                        setSheetState(() {}); // Refresh sheet
                      },
                    ),
                ),
                const SizedBox(height: 12),
                if (_currentStep == 1) ...[
                  const SizedBox(height: 12),
                  const Divider(),
                  const SizedBox(height: 12),
                  _buildAISettingItem(
                    icon: HeroiconsOutline.bookmark,
                    iconColor: AppColors.primary,
                    bgColor: AppColors.primary.withOpacity(0.1),
                    title: "Lưu thành mẫu",
                    value: "", // Bỏ chữ phụ rườm rà
                    onTap: () {
                      Navigator.pop(context);
                      _showSavePresetDialog();
                    },
                  ),
                  const SizedBox(height: 12),
                  _buildAISettingItem(
                    icon: HeroiconsOutline.arrowPath,
                    iconColor: AppColors.primary,
                    bgColor: AppColors.primary.withOpacity(0.1),
                    title: "Sử dụng mẫu",
                    value: "", // Bỏ chữ phụ rườm rà
                    onTap: () {
                      Navigator.pop(context);
                      _showPresetsSheet();
                    },
                  ),
                ],
                const SizedBox(height: 12),
                const Divider(),
                const SizedBox(height: 12),
                _buildAISettingItem(
                  icon: HeroiconsOutline.bookmark,
                  iconColor: Colors.redAccent,
                  bgColor: Colors.redAccent.withOpacity(0.1),
                  title: "Lưu bản nháp",
                  value: "", // Bỏ chữ phụ rườm rà
                  onTap: () {
                    Navigator.pop(context);
                    _saveDraft();
                  },
                ),
                const SizedBox(height: 12),
              ],
            ),
          ),
          );
        },
      ),
    );
  }

  Widget _buildAISettingItem({
    required IconData icon,
    required Color iconColor,
    required Color bgColor,
    required String title,
    required String value,
    required VoidCallback onTap,
    Widget? trailing,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(30), // Tăng độ bo cong
          border: Border.all(color: Colors.grey[100]!),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: bgColor,
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: iconColor, size: 22),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                    ),
                  ),
                  if (value.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      value,
                      style: TextStyle(
                        fontSize: 13,
                        color: AppColors.primary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            if (trailing != null)
              trailing
            else
              const Icon(
                Icons.chevron_right_rounded,
                color: Colors.grey,
                size: 18,
              ),
          ],
        ),
      ),
    );
  }

  void _showSelectionSheet(
    String title,
    List<String> options,
    String current,
    Function(String) onSelected,
  ) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => Container(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.7,
        ),
        margin: const EdgeInsets.fromLTRB(16, 0, 16, 24),
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 10),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(35),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 20,
              spreadRadius: 5,
            )
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Text(
              title,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 10),
            Flexible(
              child: ListView(
                shrinkWrap: true,
                padding: EdgeInsets.zero,
                children: options
                    .map(
                      (opt) => ListTile(
                        contentPadding: const EdgeInsets.symmetric(horizontal: 10),
                        title: Text(
                          opt,
                          style: TextStyle(
                            fontWeight: opt == current
                                ? FontWeight.bold
                                : FontWeight.normal,
                            color: opt == current
                                ? AppColors.primary
                                : Colors.black87,
                          ),
                        ),
                        trailing: opt == current
                            ? const Icon(
                                Icons.check_circle_rounded,
                                color: AppColors.primary,
                              )
                            : null,
                        onTap: () {
                          onSelected(opt);
                          Navigator.pop(context);
                        },
                      ),
                    )
                    .toList(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // --- VALIDATION ---
  Future<bool> _validateCurrentStep() async {
    if (_currentStep == 0) {
      // Step 1: Media & Info
      if (_titleController.text.trim().isEmpty ||
          _priceController.text.trim().isEmpty) {
        if (!_hasAnyImages) {
          _showErrorDialog(
            "Vui lòng nhập tên sản phẩm, giá bán và tải lên ít nhất 1 hình ảnh.",
          );
        } else {
          _showErrorDialog("Vui lòng nhập đầy đủ tên sản phẩm và giá bán.");
        }
        return false;
      } else if (!_hasAnyImages) {
        _showErrorDialog(
          "Vui lòng tải lên ít nhất 1 hình ảnh sản phẩm (ảnh thật).",
        );
        return false;
      }
      if (!_isAiModerationEnabled) {
        _isAiValidated = false; // Đánh dấu là chưa qua AI duyệt
        return true; // Cho qua luôn
      }
      return await _handleValidateMedia();
    } else if (_currentStep == 1) {
      // Step 2: Info
      if (_selectedCategory == null) {
        _showErrorDialog("Vui lòng chọn danh mục sản phẩm.");
        return false;
      }
      if (_priceController.text.isEmpty) {
        _showErrorDialog("Vui lòng nhập giá bán.");
        return false;
      }
      if (_descController.text.length < 10) {
        _showErrorDialog("Mô tả sản phẩm quá ngắn (tối thiểu 10 ký tự).");
        return false;
      }

      // Final Check for content safety & consistency
      // This ensures Step 3 is clean.
      if (!_isAiModerationEnabled) {
        _contentAlreadyValidated = true; 
        return true; 
      }
      return await _handleValidateContent();
    } else if (_currentStep == 2) {
      // Step 3: Address Transaction
      if (_selectedProvinceName == null ||
          _selectedWardName == null ||
          _addressDetailController.text.trim().isEmpty) {
        _showErrorDialog("Vui lòng nhập đầy đủ địa chỉ giao dịch.");
        return false;
      }
      return true;
    }
    return true;
  }

  // --- SAVE DRAFT ---
  Future<void> _saveDraft({bool silent = false}) async {
    // Allow saving with minimal info
    if (_titleController.text.isEmpty) {
      if (!silent) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Vui lòng nhập ít nhất tên sản phẩm để lưu bản nháp."),
          ),
        );
      }
      return;
    }

    try {
      String? userId = _userService.getCurrentUserId();
      if (userId == null) return;

      Map<String, dynamic> attributesMap = {};
      for (var item in _attributes) {
        String keysnake = item.nameController.text
            .trim()
            .toLowerCase()
            .replaceAll(' ', '_');
        attributesMap[keysnake] = item.valueController.text.trim();
      }

      Map<String, String> addressMap = {
        "province": _selectedProvinceName ?? "",
        "commune": _selectedWardName ?? "",
        "detail": _addressDetailController.text.trim(),
      };

      Map<String, String> fields = {
        "productName": _titleController.text,
        "productPrice": _priceController.text.replaceAll('.', ''),
        "productDescription": _descController.text.isNotEmpty
            ? _descController.text
            : " ",
        "categoryId": _selectedCategory ?? "other",
        "productCategory": _selectedCategory ?? "other",
        "productOrigin": _originController.text,
        "productCondition": _conditionController.text,
        "productBrand": _brandController.text,
        "productWP": _policyController.text,
        "userId": userId,
        "status": "draft",
        "lastCompletedStep": _currentStep.toString(),
        "isAiValidated": _isAiValidated.toString(),
        "productAttribute": jsonEncode(attributesMap),
        "productAddress": jsonEncode(addressMap),
        "existingMedia": jsonEncode([..._draftImages, ..._draftVideos]),
      };

      List<XFile> newFiles = [..._selectedImages, ..._selectedVideos];

      if (!silent) {
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (ctx) => Center(child: ModernLoader()),
        );
      }

      final existingId = widget.draftProduct?.productId ?? _createdDraftId;
      if (existingId != null) {
        // Đã có nháp rồi → cập nhật
        await _productService.updateProductWithMedia(
          existingId,
          fields,
          newFiles,
        );
      } else {
        // Lần đầu → tạo mới và lưu lại ID
        final created = await _productService.createProduct(fields: fields, files: newFiles);
        _createdDraftId = created.productId;
      }

      if (mounted) {
        if (!silent) {
          Navigator.pop(context); // Close loading
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text("Đã lưu bản nháp!"),
              backgroundColor: Colors.green,
            ),
          );
          Navigator.pop(context); // Close Screen
        }
      }
    } catch (e) {
      if (mounted && !silent) {
        Navigator.pop(context);
        _showErrorDialog("Error saving draft: $e");
      }
    }
  }

  void _nextStep() async {
    // Logic riêng cho Bước 2 (Thông tin chi tiết) - Kiểm tra thuộc tính trống
    if (_currentStep == 1) {
      bool hasEmptyAttribute = _attributes.any((attr) => 
        attr.nameController.text.isNotEmpty && attr.valueController.text.trim().isEmpty
      );

      if (hasEmptyAttribute) {
        bool? proceed = await UIHelpers.confirmDialog(
          context,
          title: "Thiếu thuộc tính",
          message: "Bạn nên nhập đầy đủ các thuộc tính để người mua dễ dàng tìm thấy sản phẩm của bạn hơn.",
          confirmText: "Bỏ qua",
          cancelText: "Nhập tiếp",
          confirmColor: Colors.orange,
          icon: HeroiconsOutline.informationCircle,
        );

        if (proceed != true) return; // Nếu chọn "Nhập tiếp" thì dừng lại
      }
    }

    bool valid = await _validateCurrentStep();
    if (valid) {
      if (_currentStep < 3) {
        // 0 -> 1 -> 2 -> 3
        setState(() => _currentStep++);
        _pageController.nextPage(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
        );
        
        if (_currentStep == 2) {
          _loadAddressFromProfile();
        }

        // Tự động lưu bản nháp để cập nhật lastCompletedStep lên server (silent)
        _saveDraft(silent: true);
      } else {
        _submitProduct();
      }
    }
  }

  void _prevStep() {
    if (_currentStep > 0) {
      setState(() => _currentStep--);
      _pageController.previousPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
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
          const Text(
            "Bước 1: Hình ảnh & Thông tin",
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          const Text(
            "Chọn ảnh thật của sản phẩm (AI sẽ kiểm tra ảnh mạng/stock).",
            style: TextStyle(color: Colors.grey),
          ),
          const SizedBox(height: 20),

          _buildSectionTitle("Ảnh sản phẩm (Bắt buộc ảnh thật)"),
          const SizedBox(height: 12),
          _buildHorizontalMediaList(
            label: "Thêm Ảnh",
            icon: HeroiconsOutline.photo,
            items: _selectedImages,
            remoteItems: _draftImages,
            onAdd: _pickImages,
            onRemove: _removeImage,
            isImage: true,
          ),
          if (_hasAnyImages)
            const Padding(
              padding: EdgeInsets.only(top: 8),
              child: Text(
                "Đã có ảnh. Nhấn 'Tiếp theo' để tiếp tục.",
                style: TextStyle(color: AppColors.primary, fontSize: 12),
              ),
            ),

          const SizedBox(height: 24),
          _buildSectionTitle("Video (Không bắt buộc)"),
          const SizedBox(height: 12),
          _buildHorizontalMediaList(
            label: "Thêm Video",
            icon: HeroiconsOutline.videoCamera,
            items: _selectedVideos,
            remoteItems: _draftVideos,
            onAdd: _pickVideo,
            onRemove: _removeVideo,
            isImage: false,
          ),

          const SizedBox(height: 24),
          _buildSectionTitle(
            "Tên sản phẩm",
            subtitle: "(tên sản phẩm càng chính xác thì thuộc tính điền càng chính xác)",
          ),
          const SizedBox(height: 8),
          _buildTextField(
            controller: _titleController,
            hint: "VD: Laptop Dell XPS 15 9500",
          ),

          const SizedBox(height: 16),
          _buildSectionTitle("Giá muốn bán (VNĐ)"),
          const SizedBox(height: 8),
          _buildTextField(
            controller: _priceController,
            hint: "VD: 25000000",
            keyboardType: TextInputType.number,
          ),

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
          _buildSectionTitle("Danh mục"),
          const SizedBox(height: 8),
          _buildDynamicDropdown(
            hint: "Chọn danh mục",
            value: _selectedCategory,
            items: _categoryNames.keys.toList(),
            itemValueMapper: (key) => key.toString(),
            itemLabelMapper: (key) => _categoryNames[key.toString()] ?? key.toString(),
            onChanged: _onCategoryChanged,
          ),
          
          if (_selectedCategory != null && _allowedTypes.containsKey(_selectedCategory)) ...[
            const SizedBox(height: 16),
            _buildSectionTitle("Loại sản phẩm"),
            const SizedBox(height: 8),
            _buildDynamicDropdown(
              hint: "Chọn loại sản phẩm",
              value: (() {
                try {
                  var typeAttr = _attributes.firstWhere(
                    (a) => a.nameController.text.toLowerCase() == 'type',
                    orElse: () => AttributeItem(name: "", value: ""),
                  );
                  return typeAttr.valueController.text.isNotEmpty ? typeAttr.valueController.text : null;
                } catch (e) {
                  return null;
                }
              })(),
              items: _allowedTypes[_selectedCategory]!,
              itemValueMapper: (item) => item.toString(),
              itemLabelMapper: (item) => item.toString(),
              onChanged: (val) {
                if (val != null) {
                  try {
                    var typeAttr = _attributes.firstWhere(
                      (a) => a.nameController.text.toLowerCase() == 'type',
                    );
                    setState(() {
                      typeAttr.valueController.text = val;
                    });
                  } catch (e) {
                    setState(() {
                      _attributes.insert(0, AttributeItem(name: "type", value: val));
                    });
                  }
                  _onTypeChanged(val);
                }
              },
            ),
          ],
          
          const SizedBox(height: 16),
          // --- CONDITION ---
          _buildSectionTitle("Tình trạng sản phẩm"),
          const SizedBox(height: 8),
          _buildDropdownField(
            hint: "Chọn tình trạng",
            value:
                ["New", "Like New", "Old"].contains(_conditionController.text)
                ? _conditionController.text
                : null,
            items: ["New", "Like New", "Old"],
            onChanged: (val) =>
                setState(() => _conditionController.text = val ?? ""),
          ),

          const SizedBox(height: 16),

          // --- DESCRIPTION ---
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildSectionTitle("Mô tả sản phẩm"),
              if (_isAiModerationEnabled)
                ElevatedButton(
                  onPressed: _isAiLoading ? null : _handleGenerateDetails,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.warning.withOpacity(0.15),
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(50),
                    ),
                  ),
                  child: _isAiLoading
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: ModernLoader(size: 16, color: AppColors.warning, showText: false),
                        )
                      : Row(
                          mainAxisSize: MainAxisSize.min,
                          children: const [
                            Icon(
                              HeroiconsSolid.sparkles,
                              size: 16,
                              color: AppColors.warning,
                            ),
                            SizedBox(width: 6),
                            Text(
                              "Tạo ND & Lấy thông số",
                              style: TextStyle(
                                color: AppColors.warning,
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                ),
            ],
          ),
          const SizedBox(height: 8),
          _buildTextField(
            controller: _descController,
            hint: "Nhập mô tả sản phẩm của bạn...",
            minLines: 5,
            maxLines: null,
            borderRadius: 20, // Bo nhẹ hơn một chút cho ô mô tả
          ),

          const SizedBox(height: 16),

          // --- ATTRIBUTES ---
          if (_attributes.isNotEmpty) ...[
            const SizedBox(height: 16),
            const Divider(),
            const SizedBox(height: 8),
            const Text(
              "Thông số chi tiết",
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const SizedBox(height: 6),
            ListView.builder(
              shrinkWrap: true,
              padding: EdgeInsets.zero,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _attributes.length,
              itemBuilder: (context, index) {
                final attr = _attributes[index];
                if (attr.nameController.text.toLowerCase() == 'type') {
                  return const SizedBox.shrink();
                }
                return Dismissible(
                  key: Key(attr.hashCode.toString()),
                  direction: DismissDirection.endToStart,
                  onDismissed: (direction) {
                    setState(() {
                      attr.dispose();
                      _attributes.removeAt(index);
                    });
                  },
                  background: Container(
                    alignment: Alignment.centerRight,
                    padding: const EdgeInsets.only(right: 16),
                    child: const Icon(
                      HeroiconsOutline.trash,
                      color: Colors.redAccent,
                      size: 24,
                    ),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (attr.nameController.text.isEmpty)
                           TextField(
                              controller: attr.nameController,
                              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.primary),
                              decoration: const InputDecoration(hintText: "Tên thuộc tính (VD: RAM, CPU...)", border: InputBorder.none, isDense: true),
                           )
                        else
                          Text(
                            _formatKey(attr.nameController.text).toUpperCase(),
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: Colors.grey,
                            ),
                          ),
                        const SizedBox(height: 6),
                        // Special handling for 'type' attribute -> Selection Sheet
                        if (attr.nameController.text.toLowerCase() == 'type' &&
                                _selectedCategory != null &&
                                _allowedTypes.containsKey(_selectedCategory))
                           GestureDetector(
                             onTap: () => _showSelectionSheet(
                               "Chọn loại sản phẩm", 
                               _allowedTypes[_selectedCategory]!, 
                               attr.valueController.text, 
                               (val) {
                                  setState(() => attr.valueController.text = val);
                                  _onTypeChanged(val);
                               }
                             ),
                             child: Container(
                               padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                               decoration: BoxDecoration(
                                 color: const Color(0xFFF2F2F2),
                                 borderRadius: BorderRadius.circular(50),
                               ),
                               child: Row(
                                 mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                 children: [
                                   Text(
                                     attr.valueController.text.isEmpty ? "Chọn loại sản phẩm" : attr.valueController.text,
                                     style: TextStyle(
                                       fontSize: 14,
                                       color: attr.valueController.text.isEmpty ? Colors.grey[400] : Colors.black87,
                                     ),
                                   ),
                                   const Icon(Icons.keyboard_arrow_down_rounded, color: Colors.grey),
                                 ],
                               ),
                             ),
                           )
                        else if (attr.nameController.text.toLowerCase() ==
                            'condition')
                          // Condition Dropdown inside Attributes too
                          _buildDropdownField(
                            hint: "Chọn tình trạng",
                            value:
                                [
                                  "New",
                                  "Like New",
                                  "Old",
                                ].contains(attr.valueController.text)
                                ? attr.valueController.text
                                : null,
                            items: ["New", "Like New", "Old"],
                            onChanged: (val) => setState(
                              () => attr.valueController.text = val ?? "",
                            ),
                          )
                        else
                          _buildTextField(
                            controller: attr.valueController,
                            hint: "Nhập giá trị...",
                          ),
                      ],
                    ),
                  ),
                );
              },
            ),

          ],
        ],
      ),
    );
  }

  Widget _buildAddressActionBtn({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
        decoration: BoxDecoration(
          color: Colors.orange.shade50,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.orange.shade200),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: Colors.orange, size: 20),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                color: Colors.orange.shade800,
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _updateAddressFromPlacemark(Placemark place) async {
    String provCode = "";
    String wCode = "";

    if (place.administrativeArea != null) {
      final pName = place.administrativeArea!.toLowerCase();
      final prov = _provinces.firstWhere(
        (p) => p['name'].toString().toLowerCase().contains(pName) || pName.contains(p['name'].toString().toLowerCase()),
        orElse: () => null,
      );
      if (prov != null) {
        provCode = prov['province_code'].toString();
        _selectedProvinceName = prov['name'];
        _selectedProvinceCode = provCode;
        await _fetchWards(provCode);
      }
    }

    if (provCode.isNotEmpty && (place.subAdministrativeArea != null || place.locality != null)) {
      final wName = (place.subAdministrativeArea ?? place.locality ?? '').toLowerCase();
      final ward = _wards.firstWhere(
        (w) => w['ward_name'].toString().toLowerCase().contains(wName) || wName.contains(w['ward_name'].toString().toLowerCase()),
        orElse: () => null,
      );
      if (ward != null) {
        wCode = ward['ward_code'].toString();
        _selectedWardName = ward['ward_name'];
        _selectedWardCode = wCode;
      }
    }

    setState(() {
      String detail = "";
      String streetName = place.thoroughfare ?? "";
      String houseNumber = place.subThoroughfare ?? place.name ?? "";

      // Kết hợp số nhà và tên đường
      if (houseNumber.isNotEmpty) {
        detail += houseNumber;
      }
      if (streetName.isNotEmpty) {
        if (detail.isNotEmpty && !streetName.startsWith(" ")) {
          detail += " ";
        }
        detail += streetName;
      }

      // Nếu vẫn rỗng hoặc chỉ có số nhà, dùng street làm fallback
      if (detail.isEmpty || detail == houseNumber) {
        if (place.street != null && place.street!.isNotEmpty && !place.street!.contains('+')) {
          detail = place.street!;
        }
      }

      if (detail.isNotEmpty) {
        _addressDetailController.text = detail;
      }
    });
  }

  Future<void> _onMapTap(latlong.LatLng point) async {
    setState(() {
      _mapCenter = point;
    });

    try {
      List<Placemark> placemarks = await placemarkFromCoordinates(
        point.latitude,
        point.longitude,
      );

      if (placemarks.isNotEmpty) {
        _updateAddressFromPlacemark(placemarks.first);
      }
    } catch (e) {
      print("Reverse geocoding error: $e");
    }
  }

  void _showFullScreenMapPicker() {
    final MapController mapController = MapController();

    showGeneralDialog(
      context: context,
      barrierDismissible: false,
      barrierLabel: "MapPicker",
      transitionDuration: const Duration(milliseconds: 300),
      pageBuilder: (context, animation, secondaryAnimation) {
        final gpsPressed = ValueNotifier<bool>(false);
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Scaffold(
              body: Stack(
                    children: [
                      FlutterMap(
                        mapController: mapController,
                        options: MapOptions(
                          initialCenter: _mapCenter ?? const latlong.LatLng(16.0544, 108.2022),
                          initialZoom: 15.0,
                          interactionOptions: const InteractionOptions(flags: InteractiveFlag.all),
                          onTap: (tapPosition, point) async {
                            setModalState(() {
                              _mapCenter = point;
                            });
                            
                            try {
                              List<Placemark> placemarks = await placemarkFromCoordinates(
                                point.latitude,
                                point.longitude,
                              );

                              if (placemarks.isNotEmpty) {
                                await _updateAddressFromPlacemark(placemarks.first);
                                setModalState(() {}); // Force update address panel
                              }
                            } catch (e) {
                              print("Map reverse geocoding error: $e");
                            }
                          },
                        ),
                        children: [
                          TileLayer(
                            urlTemplate: 'https://mt1.google.com/vt/lyrs=m&x={x}&y={y}&z={z}',
                            userAgentPackageName: 'com.temo.app',
                            retinaMode: true,
                          ),
                          if (_mapCenter != null)
                            MarkerLayer(
                              markers: [
                                Marker(
                                  point: _mapCenter!,
                                  width: 50,
                                  height: 50,
                                  child: const Icon(Icons.location_on, color: Colors.red, size: 50),
                                ),
                              ],
                            ),
                        ],
                      ),
                      // BACK BUTTON
                      Positioned(
                        top: MediaQuery.of(context).padding.top + 16,
                        left: 16,
                        child: GestureDetector(
                          onTap: () => Navigator.pop(context),
                          child: Container(
                            padding: const EdgeInsets.all(10),
                            decoration: const BoxDecoration(
                              color: Colors.white,
                              shape: BoxShape.circle,
                              boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 10)],
                            ),
                            child: const Icon(Icons.close_rounded, color: Colors.black87),
                          ),
                        ),
                      ),
                      
                      // ZOOM HUD
                      Positioned(
                        right: 16,
                        top: MediaQuery.of(context).padding.top + 16,
                        child: ValueListenableBuilder<bool>(
                          valueListenable: gpsPressed,
                          builder: (context, isPressed, _) {
                            return Column(
                              children: [
                                GestureDetector(
                                  onTap: () => mapController.move(mapController.camera.center, mapController.camera.zoom + 1),
                                  child: Container(
                                    width: 44,
                                    height: 44,
                                    decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle, boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 8)]),
                                    child: const Icon(Icons.add_rounded, color: Color(0xFF374151)),
                                  ),
                                ),
                                const SizedBox(height: 12),
                                GestureDetector(
                                  onTap: () => mapController.move(mapController.camera.center, mapController.camera.zoom - 1),
                                  child: Container(
                                    width: 44,
                                    height: 44,
                                    decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle, boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 8)]),
                                    child: const Icon(Icons.remove_rounded, color: Color(0xFF374151)),
                                  ),
                                ),
                                const SizedBox(height: 12),
                                GestureDetector(
                                  onTapDown: (_) => gpsPressed.value = true,
                                  onTapCancel: () => gpsPressed.value = false,
                                  onTapUp: (_) => gpsPressed.value = false,
                                  onTap: () async {
                                    try {
                                      LocationPermission permission = await Geolocator.checkPermission();
                                      if (permission == LocationPermission.denied) {
                                        permission = await Geolocator.requestPermission();
                                        if (permission == LocationPermission.denied) return;
                                      }
                                      if (permission == LocationPermission.deniedForever) return;

                                      Position position = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);
                                      
                                      final newPoint = latlong.LatLng(position.latitude, position.longitude);
                                      mapController.move(newPoint, 15.0);
                                      setModalState(() {
                                        _mapCenter = newPoint;
                                      });

                                      List<Placemark> placemarks = await placemarkFromCoordinates(position.latitude, position.longitude);
                                      if (placemarks.isNotEmpty) {
                                        await _updateAddressFromPlacemark(placemarks.first);
                                        setModalState(() {});
                                      }
                                    } catch (e) {
                                      print("GPS HUD Error: $e");
                                    }
                                  },
                                  child: Container(
                                    width: 44,
                                    height: 44,
                                    decoration: BoxDecoration(
                                      color: isPressed ? Colors.orange : Colors.white,
                                      shape: BoxShape.circle,
                                      boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 8)],
                                    ),
                                    child: Icon(
                                      Icons.my_location_rounded,
                                      color: isPressed ? Colors.white : const Color(0xFF374151),
                                    ),
                                  ),
                                ),
                              ],
                            );
                          }
                        ),
                      ),

                  // INFO PANEL
                  Positioned(
                    bottom: 24,
                    left: 16,
                    right: 16,
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 20)],
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            "Vị trí bạn chọn",
                            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            "${_addressDetailController.text}, ${_selectedWardName ?? ''}, ${_selectedProvinceName ?? ''}",
                            style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                          ),
                          const SizedBox(height: 12),
                          ElevatedButton(
                            onPressed: () {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text("✅ Đã lưu vị trí giao dịch!"),
                                  backgroundColor: Colors.blue,
                                  duration: Duration(seconds: 1),
                                ),
                              );
                              Navigator.pop(context);
                              setState(() {}); // Update the main page map
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primary,
                              foregroundColor: Colors.white,
                              minimumSize: const Size(double.infinity, 44),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(50)),
                            ),
                            child: const Text("Xác nhận vị trí"),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Future<void> _loadAddressFromProfile() async {
    try {
      final user = await _userService.getCurrentUser();
      if (user.address != null && user.address!.isNotEmpty) {
        setState(() {
          _addressDetailController.text = user.address!;
        });
        
        try {
          List<Location> locations = await locationFromAddress(user.address!);
          if (locations.isNotEmpty) {
            setState(() {
              _mapCenter = latlong.LatLng(locations.first.latitude, locations.first.longitude);
            });
          }
        } catch (e) {
          print("Profile address geocoding error: $e");
        }
      }
    } catch (e) {
      print("Profile fetch error: $e");
    }
  }

  Future<void> _loadAddressFromGPS() async {
    try {
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) return;
      }
      
      if (permission == LocationPermission.deniedForever) return;

      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      setState(() {
        _mapCenter = latlong.LatLng(position.latitude, position.longitude);
      });

      List<Placemark> placemarks = await placemarkFromCoordinates(
        position.latitude,
        position.longitude,
      );

      if (placemarks.isNotEmpty) {
        _updateAddressFromPlacemark(placemarks.first);
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text("📍 Đã cập nhật vị trí hiện tại của bạn!"),
              backgroundColor: Colors.green,
              duration: Duration(seconds: 2),
            ),
          );
        }
      }
    } catch (e) {
      print("GPS error: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("❌ Không thể lấy vị trí. Vui lòng bật GPS và thử lại."),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    }
  }

  // STEP 3: ADDRESS TRANSACTION
  Widget _buildStep3Address() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "Bước 3: Địa chỉ giao dịch",
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          const Text(
            "Nhập địa chỉ của bạn để người mua có thể xem sản phẩm.",
            style: TextStyle(color: Colors.grey),
          ),
          const SizedBox(height: 16),

          _buildSectionTitle("Bản đồ vị trí"),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: Container(
              height: 300,
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey.shade300),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Stack(
                children: [
                  FlutterMap(
                    options: MapOptions(
                      initialCenter: _mapCenter ?? const latlong.LatLng(16.0544, 108.2022), // Default Đà Nẵng
                      initialZoom: 14.0,
                      interactionOptions: const InteractionOptions(
                        flags: InteractiveFlag.all,
                      ),
                      onTap: (tapPosition, point) {
                        _onMapTap(point);
                      },
                    ),
                    children: [
                      TileLayer(
                        urlTemplate: 'https://mt1.google.com/vt/lyrs=m&x={x}&y={y}&z={z}',
                        userAgentPackageName: 'com.temo.app',
                        retinaMode: true,
                      ),
                      if (_mapCenter != null)
                        MarkerLayer(
                          markers: [
                            Marker(
                              point: _mapCenter!,
                              width: 40,
                              height: 40,
                              child: const Icon(Icons.location_on, color: Colors.red, size: 40),
                            ),
                          ],
                        ),
                    ],
                  ),
                  Positioned(
                    right: 16,
                    bottom: 16,
                    child: GestureDetector(
                      onTap: () => _showFullScreenMapPicker(),
                      child: Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.15),
                              blurRadius: 8,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: const Icon(Icons.fullscreen_rounded, color: Color(0xFF374151), size: 28),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),

          _buildSectionTitle("Địa chỉ giao dịch"),
          const SizedBox(height: 8),
          _buildDynamicDropdown(
            hint: "Tỉnh / Thành phố",
            value: _selectedProvinceCode,
            items: _provinces,
            itemValueMapper: (item) => item['province_code'].toString(),
            itemLabelMapper: (item) => item['name'],
            onChanged: (val) {
              setState(() {
                _selectedProvinceCode = val;
                final s = _provinces.firstWhere(
                  (e) => e['province_code'].toString() == val,
                  orElse: () => null,
                );
                _selectedProvinceName = s != null ? s['name'] : null;
              });
              if (val != null) _fetchWards(val);
            },
          ),
          const SizedBox(height: 8),
          _buildDynamicDropdown(
            hint: "Quận / Huyện / Phường / Xã",
            value: _selectedWardCode,
            items: _wards,
            itemValueMapper: (item) => item['ward_code'].toString(),
            itemLabelMapper: (item) => item['ward_name'],
            onChanged: (val) {
              setState(() {
                _selectedWardCode = val;
                final s = _wards.firstWhere(
                  (e) => e['ward_code'].toString() == val,
                  orElse: () => null,
                );
                _selectedWardName = s != null ? s['ward_name'] : null;
              });
            },
          ),
          const SizedBox(height: 8),
          _buildTextField(
            controller: _addressDetailController,
            hint: "Số nhà, kiệt, hẻm, tên đường...",
          ),
        ],
      ),
    );
  }

  // STEP 4: REVIEW
  Widget _buildStep4Review() {
    String formattedPrice = "0 đ";
    try {
      // Loại bỏ tất cả ký tự không phải số trước khi parse (tránh lỗi dấu chấm/phẩy)
      String cleanText = _priceController.text.replaceAll(RegExp(r'[^0-9]'), '');
      double price = double.tryParse(cleanText) ?? 0.0;
      
      if (price >= 1000000000) {
        // Trên 1 tỷ
        formattedPrice = "${(price / 1000000000).toStringAsFixed(1).replaceAll('.0', '')} tỷ";
      } else if (price >= 10000000) { 
        // Từ 10 triệu trở lên: ghi tắt "tr" không lẻ (ví dụ: 15 tr)
        formattedPrice = "${(price / 1000000).toStringAsFixed(0)} tr";
      } else if (price >= 1000000) { 
        // Từ 1 triệu đến dưới 10 triệu: ghi tắt "tr" có 1 chữ số thập phân (ví dụ: 1.5 tr)
        formattedPrice = "${(price / 1000000).toStringAsFixed(1).replaceAll('.0', '')} tr";
      } else {
        // Dưới 1 triệu: hiển thị đầy đủ có dấu chấm phân cách
        formattedPrice = NumberFormat.currency(
          locale: 'vi_VN',
          symbol: 'đ',
          decimalDigits: 0,
        ).format(price);
      }
    } catch (_) {
      formattedPrice = "${_priceController.text} đ";
    }

    // Combine local and remote media sources
    List<dynamic> allMedia = [];
    allMedia.addAll(_selectedImages);
    allMedia.addAll(_selectedVideos);
    allMedia.addAll(_draftImages);
    allMedia.addAll(_draftVideos);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "Bước 4: Xem trước",
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          const Text(
            "Xem lại tất cả thông tin trước khi hoàn tất đăng tin.",
            style: TextStyle(color: Colors.grey),
          ),
          const SizedBox(height: 24),

          // 1. All images and videos
          if (allMedia.isNotEmpty)
            SizedBox(
              height: 220,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: allMedia.length,
                itemBuilder: (context, index) {
                  final media = allMedia[index];
                  bool isXFile = media is XFile;
                  bool isRemote = media is String;

                  Widget mediaWidget;
                  if (isXFile) {
                    bool isVideo = media.path.toLowerCase().endsWith('.mp4') || 
                                   media.path.toLowerCase().endsWith('.mov');
                    mediaWidget = Stack(
                      children: [
                        Image.file(
                          File(media.path),
                          width: 160,
                          height: 220,
                          fit: BoxFit.cover,
                        ),
                        if (isVideo)
                          const Positioned.fill(
                            child: Center(
                              child: Icon(Icons.play_circle_fill, color: Colors.white, size: 40),
                            ),
                          ),
                      ],
                    );
                  } else if (isRemote) {
                    bool isVideo = media.toLowerCase().contains('video:');
                    String url = media;
                    if (url.startsWith('image:')) url = url.substring(6);
                    if (url.startsWith('video:')) url = url.substring(6);

                    mediaWidget = Stack(
                      children: [
                        PremiumImage(
                          imageUrl: StringUtils.normalizeUrl(url),
                          width: 160,
                          height: 220,
                          fit: BoxFit.cover,
                          errorWidget: Container(
                            width: 160,
                            color: Colors.grey[200],
                            child: const Icon(Icons.broken_image, color: Colors.grey),
                          ),
                        ),
                        if (isVideo)
                          const Positioned.fill(
                            child: Center(
                              child: Icon(Icons.play_circle_fill, color: Colors.white, size: 40),
                            ),
                          ),
                      ],
                    );
                  } else {
                    mediaWidget = Container();
                  }

                  return Container(
                    margin: const EdgeInsets.only(right: 12),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: const [
                        BoxShadow(
                          color: Colors.black12,
                          blurRadius: 6,
                          offset: Offset(0, 3),
                        ),
                      ],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(20),
                      child: mediaWidget,
                    ),
                  );
                },
              ),
            )
          else
            Container(
              height: 150,
              width: double.infinity,
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Center(
                child: Text("Chưa chọn phương tiện nào", style: TextStyle(color: Colors.grey)),
              ),
            ),

          const SizedBox(height: 24),

          // 2. All Information
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: AppColors.primary.withOpacity(0.4), width: 1.5),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.04),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        _titleController.text.isNotEmpty ? _titleController.text : "Tên sản phẩm",
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 20,
                          color: Color(0xFF111827),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Text(
                      formattedPrice,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                        color: AppColors.primary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                const Divider(),
                const SizedBox(height: 12),

                _buildPremiumReviewRow("Danh mục", _categoryNames[_selectedCategory] ?? "Khác"),
                _buildPremiumReviewRow("Tình trạng", _conditionController.text.isNotEmpty ? _conditionController.text : "Trống"),
                _buildPremiumReviewRow("Thương hiệu", _brandController.text.isNotEmpty ? _brandController.text : "Trống"),
                _buildPremiumReviewRow("Xuất xứ", _originController.text.isNotEmpty ? _originController.text : "Trống"),
                _buildPremiumReviewRow("Bảo hành", _policyController.text.isNotEmpty ? _policyController.text : "Trống"),
                
                if (_attributes.isNotEmpty) ...[
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 8.0),
                    child: Divider(),
                  ),
                  ..._attributes.map((attr) => _buildPremiumReviewRow(
                    attr.nameController.text.trim().isNotEmpty ? attr.nameController.text.trim() : "Thuộc tính khác",
                    attr.valueController.text.trim().isNotEmpty ? attr.valueController.text.trim() : "Trống"
                  )).toList(),
                ],

                const SizedBox(height: 12),
                const Divider(),
                const SizedBox(height: 12),

                // 3. Description
                const Text(
                  "Mô tả chi tiết",
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF374151),
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  _descController.text.isNotEmpty ? _descController.text : "Chưa có mô tả.",
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey.shade600,
                    height: 1.5,
                  ),
                ),
                
                const SizedBox(height: 16),
                const Divider(),
                const SizedBox(height: 12),

                // 4. Address
                const Text(
                  "Địa điểm giao dịch",
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF374151),
                  ),
                ),
                const SizedBox(height: 6),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.location_on, size: 18, color: AppColors.primary),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        "${_addressDetailController.text.trim()}, ${_selectedWardName ?? ''}, ${_selectedProvinceName ?? ''}".trim(),
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.grey.shade600,
                          height: 1.4,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPremiumReviewRow(String label, String value) {
    if (value.trim().isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start, // Giúp các thuộc tính dài không bị lệch
        children: [
          Text(
            label,
            style: const TextStyle(color: Color(0xFF6B7280), fontSize: 14),
          ),
          const SizedBox(width: 16), // Thêm khoảng cách giữa label và value
          Expanded(
            child: Text(
              value,
              textAlign: TextAlign.end,
              style: const TextStyle(
                color: Color(0xFF111827),
                fontWeight: FontWeight.w600,
                fontSize: 14,
              ),
            ),
          ),
        ],
      ),
    );
  }


  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          Column(
            children: [
              const SizedBox(
                height: 95,
              ), // Giảm từ 110 xuống 95 để gọn hơn
              // CUSTOM STEPPER
              Container(
                padding: const EdgeInsets.symmetric(
                  vertical: 10,
                  horizontal: 16,
                ), // Giảm từ 18 xuống 10
                color: Colors.white,
                child: Row(
                  children: [
                    _buildStepIndicator(0, "Thông tin"),
                    _buildStepLine(0),
                    _buildStepIndicator(1, "Chi tiết"),
                    _buildStepLine(1),
                    _buildStepIndicator(2, "Địa chỉ"),
                    _buildStepLine(2),
                    _buildStepIndicator(3, "Xem trước"),
                  ],
                ),
              ),
              Divider(height: 1, color: Colors.grey.shade100),
              const SizedBox(
                height: 4,
              ), // Giảm từ 8 xuống 4

              Expanded(
                child: PageView(
                  controller: _pageController,
                  physics:
                      const NeverScrollableScrollPhysics(), // Disable swipe
                  children: [
                    _buildStep1Media(),
                    _buildStep2Essentials(),
                    _buildStep3Address(),
                    _buildStep4Review(),
                  ],
                ),
              ),
            ],
          ),
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: SafeArea(
              bottom: false,
              child: FloatingHeader(
                title: "Đăng tin mới",
                hasBackground: false,
                actions: [
                  FloatingHeader.buildActionBubble(
                    icon: HeroiconsOutline.ellipsisHorizontal,
                    onTap: _showAISettingsSheet,
                    color: Colors.grey.shade600,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: SafeArea(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: Colors.white,
            border: Border(top: BorderSide(color: Colors.grey.shade200)),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              if (_currentStep > 0) ...[
                TextButton(
                  onPressed: _prevStep,
                  child: const Text(
                    "Quay lại",
                    style: TextStyle(color: Colors.grey),
                  ),
                ),
                const SizedBox(width: 16),
              ] else
                const SizedBox.shrink(),

              Expanded(
                child: ElevatedButton(
                  onPressed: _nextStep,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.ButtonBlackColor,
                    foregroundColor: Colors.white,
                    shape: const StadiumBorder(),
                    padding: EdgeInsets.zero,
                    minimumSize: const Size(double.infinity, 48),
                    elevation: 0,
                  ),
                  child: _isAiLoading
                      ? SizedBox(
                          width: 20,
                          height: 20,
                          child: ModernLoader(
                            size: 20,
                            color: Colors.white,
                            showText: false,
                          ),
                        )
                      : Text(
                          _currentStep == 3 ? "Đăng tin" : "Tiếp theo",
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
      ),
    );
  }

  Widget _buildStepIndicator(int step, String label) {
    bool isActive = _currentStep >= step;
    return Column(
      children: [
        Container(
          width: 30,
          height: 30,
          decoration: BoxDecoration(
            color: isActive ? AppColors.primary : Colors.grey[200],
            shape: BoxShape.circle,
          ),
          child: Center(
            child: isActive
                ? const Icon(Icons.check, color: Colors.white, size: 16)
                : Text(
                    (step + 1).toString(),
                    style: const TextStyle(
                      color: Colors.grey,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 10,
            color: isActive ? AppColors.primary : Colors.grey,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget _buildStepLine(int step) {
    return Expanded(
      child: Container(
        height: 2,
        color: _currentStep > step ? AppColors.primary : Colors.grey[200],
        margin: const EdgeInsets.symmetric(
          horizontal: 4,
          vertical: 15,
        ), // align with circle center roughly
        // remove vertical margin if it looks off, alignment is key
      ),
    );
  }

  // --- HELPERS (Reused) ---
  Widget _buildSectionTitle(String title, {String? subtitle}) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        title,
        style: TextStyle(
          fontSize: 14,
          color: Colors.grey[800],
          fontWeight: FontWeight.bold,
        ),
      ),
      if (subtitle != null) ...[
        const SizedBox(height: 4),
        Text(
          subtitle,
          style: TextStyle(
            fontSize: 11,
            color: Colors.grey[600],
            fontWeight: FontWeight.normal,
            fontStyle: FontStyle.italic,
          ),
        ),
      ],
    ],
  );

  Widget _buildTextField({
    required TextEditingController controller,
    required String hint,
    TextInputType keyboardType = TextInputType.text,
    int? maxLines = 1,
    int? minLines,
    bool readOnly = false,
    double borderRadius = 50,
  }) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      maxLines: maxLines,
      minLines: minLines,
      readOnly: readOnly,
      onChanged: (val) {
        setState(() {
          _contentAlreadyValidated = false;
        });
      },
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(color: Colors.grey[400], fontSize: 13),
        filled: true,
        fillColor: readOnly ? Colors.grey[200] : const Color(0xFFF2F2F2),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 14,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(borderRadius),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }

  Widget _buildDropdownField({
    required String hint,
    required String? value,
    required List<String> items,
    required ValueChanged<String?> onChanged,
  }) {
    return GestureDetector(
      onTap: () => _showSelectionSheet(
        hint,
        items,
        value ?? "",
        (val) => onChanged(val),
      ),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: const Color(0xFFF2F2F2),
          borderRadius: BorderRadius.circular(50),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Text(
                (value == null || value.isEmpty) ? hint : value,
                style: TextStyle(
                  fontSize: 14,
                  color: (value == null || value.isEmpty) ? Colors.grey[400] : Colors.black87,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const Icon(Icons.keyboard_arrow_down_rounded, color: Colors.grey),
          ],
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
    final labels = items.map((e) => itemLabelMapper(e)).toList();
    final valueToLabel = {for (var item in items) itemValueMapper(item): itemLabelMapper(item)};
    final labelToValue = {for (var item in items) itemLabelMapper(item): itemValueMapper(item)};

    return GestureDetector(
      onTap: () => _showSelectionSheet(
        hint,
        labels,
        valueToLabel[value] ?? "",
        (label) => onChanged(labelToValue[label]),
      ),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: const Color(0xFFF2F2F2),
          borderRadius: BorderRadius.circular(50),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Text(
                (value == null || value.isEmpty) ? hint : (valueToLabel[value] ?? value),
                style: TextStyle(
                  fontSize: 14,
                  color: (value == null || value.isEmpty) ? Colors.grey[400] : Colors.black87,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const Icon(Icons.keyboard_arrow_down_rounded, color: Colors.grey),
          ],
        ),
      ),
    );
  }

  Widget _buildHorizontalMediaList({
    required String label,
    required IconData icon,
    required List<XFile> items,
    required List<String> remoteItems,
    required VoidCallback onAdd,
    required Function(int, bool) onRemove,
    required bool isImage,
  }) {
    return SizedBox(
      height: 100,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: remoteItems.length + items.length + 1,
        itemBuilder: (context, index) {
          if (index == 0) {
            return GestureDetector(
              onTap: onAdd,
              child: Container(
                width: 100,
                margin: const EdgeInsets.only(right: 12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.grey.shade300),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(icon, size: 24, color: Colors.black54),
                    const SizedBox(height: 4),
                    Text(
                      label,
                      style: const TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            );
          }

          // Render Remote Items First
          if (index <= remoteItems.length) {
            String url = remoteItems[index - 1];

            // Xử lý tiền tố "image:" nếu có (tránh lỗi nối chuỗi sai)
            if (url.startsWith('image:')) {
              url = url.replaceFirst('image:', '');
            }

            // Nếu không phải link tuyệt đối (http/https) thì mới nối baseUrl
            if (!url.startsWith('http')) {
              url =
                  '${ApiConstants.baseUrl}${url.startsWith('/') ? '' : '/'}$url';
            }
            return Stack(
              children: [
                Container(
                  width: 100,
                  margin: const EdgeInsets.only(right: 12),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    color: Colors.grey[200],
                    image: isImage
                        ? DecorationImage(
                            image: NetworkImage(url),
                            fit: BoxFit.cover,
                          )
                        : null,
                  ),
                  child: !isImage
                      ? const Center(
                          child: Icon(
                            Icons.play_circle_fill,
                            size: 30,
                            color: Colors.white,
                          ),
                        )
                      : null,
                ),
                Positioned(
                  top: 4,
                  right: 16,
                  child: GestureDetector(
                    onTap: () => onRemove(index - 1, true),
                    child: Container(
                      padding: const EdgeInsets.all(2),
                      decoration: const BoxDecoration(
                        color: Colors.black54,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.close,
                        size: 14,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ],
            );
          }

          // Render Local Items
          final localIndex = index - remoteItems.length - 1;
          final file = items[localIndex];
          return Stack(
            children: [
              Container(
                width: 100,
                margin: const EdgeInsets.only(right: 12),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  color: Colors.grey[200],
                  image: isImage
                      ? DecorationImage(
                          image: kIsWeb 
                              ? NetworkImage(file.path) 
                              : FileImage(File(file.path)) as ImageProvider,
                          fit: BoxFit.cover,
                        )
                      : null,
                ),
                child: !isImage
                    ? const Center(
                        child: Icon(
                          Icons.play_circle_fill,
                          size: 30,
                          color: Colors.white,
                        ),
                      )
                    : null,
              ),
              Positioned(
                top: 4,
                right: 16,
                child: GestureDetector(
                  onTap: () => onRemove(localIndex, false),
                  child: Container(
                    padding: const EdgeInsets.all(2),
                    decoration: const BoxDecoration(
                      color: Colors.black54,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.close,
                      size: 14,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
