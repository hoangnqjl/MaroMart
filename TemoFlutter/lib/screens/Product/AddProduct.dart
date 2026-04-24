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
import 'package:temo/utils/ui_helpers.dart';
import 'package:temo/utils/constants.dart';

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
  bool _isAiValidated = false; // Trạng thái đã duyệt AI

  // Remote Media (For Drafts)
  List<String> _draftImages = [];
  List<String> _draftVideos = [];

  List<AttributeItem> _attributes = [];




  // --- TEMPLATES ---
  // --- TEMPLATES (Relaxed) ---
  final Map<String, List<String>> _attributeTemplates = {
    "auto": ["type", "brand", "model", "condition", "warranty"], 
    "furniture": ["type", "material", "condition", "brand", "warranty"],
    "technology": ["type", "brand", "model", "warranty"], // Relaxed
    "appliances": ["type", "brand", "warranty", "condition"],
    "office": ["type", "brand", "condition"],
    "style": ["type", "brand", "condition", "gender"],
    "service": ["type", "service_type", "price_type", "area"],
    "hobby": ["type", "brand", "condition"],
    "kids": ["type", "brand", "condition", "age_range"],
    "books": ["type", "author", "condition"], 
    "pets": ["type", "species", "breed", "health_status"],
    "other": ["type", "brand", "condition"]
  };
  
  final Map<String, String> _categoryNames = {
    "auto": "Xe cộ",
    "furniture": "Nội thất",
    "technology": "Thiết bị điện tử",
    "appliances": "Đồ gia dụng",
    "office": "Văn phòng",
    "style": "Thời trang",
    "service": "Dịch vụ",
    "hobby": "Giải trí & Sở thích",
    "kids": "Mẹ & Bé",
    "books": "Sách & Truyện",
    "pets": "Thú cưng",
    "other": "Khác"
  };

  final Map<String, List<String>> _allowedTypes = {
    "auto": ["Ô tô", "Xe máy", "Xe đạp", "Xe điện", "Xe tải", "Bán tải", "Xe khách", "Phụ tùng", "Phụ kiện", "Khác"],
    "furniture": ["Ghế", "Bàn", "Sofa", "Giường", "Tủ quần áo", "Tủ hồ sơ", "Kệ sách", "Bàn làm việc", "Nệm", "Đèn", "Gương", "Khác"],
    "technology": ["Điện thoại", "Laptop", "Máy tính bảng", "Đồng hồ thông minh", "Máy tính để bàn", "Màn hình", "Tai nghe", "Chuột", "Bàn phím", "Máy ảnh", "Loa", "Máy in", "Phụ kiện", "Khác"],
    "appliances": ["Tủ lạnh", "Máy giặt", "Điều hòa", "Quạt", "Máy hút bụi", "Nồi cơm điện", "Lò vi sóng", "Ấm siêu tốc", "Bàn là", "Máy lọc nước", "Máy xay sinh tố", "Máy sưởi", "Khác"],
    "office": ["Bàn văn phòng", "Ghế văn phòng", "Máy in", "Máy quét", "Máy chiếu", "Văn phòng phẩm", "Tủ tài liệu", "Bảng trắng", "Khác"],
    "style": ["Áo sơ mi", "Áo thun", "Quần", "Quần Jeans", "Váy/Đầm", "Chân váy", "Áo khoác", "Giày", "Giày thể thao", "Sandal", "Túi xách", "Ví", "Đồng hồ", "Kính mắt", "Trang sức", "Mũ/Nón", "Khác"],
    "service": ["Vệ sinh", "Sửa chữa", "Vận chuyển", "Gia sư", "Làm đẹp", "Cho thuê", "Du lịch", "Chụp ảnh", "Khác"],
    "hobby": ["Nhạc cụ", "Dụng cụ thể thao", "Dụng cụ vẽ", "Board Game", "Đồ sưu tầm", "Đồ chơi", "Dụng cụ câu cá", "Dụng cụ cắm trại", "Khác"],
    "kids": ["Đồ chơi trẻ em", "Xe đẩy", "Ghế ô tô", "Quần áo trẻ em", "Tã/Bỉm", "Bình sữa", "Cũi", "Xe tập đi", "Khác"],
    "books": ["Tiểu thuyết", "Sách phi hư cấu", "Giáo trình", "Truyện tranh", "Tạp chí", "Sổ tay", "Khác"],
    "pets": ["Thức ăn chó", "Thức ăn mèo", "Chuồng", "Đồ chơi thú cưng", "Phụ kiện", "Bể cá", "Khác"],
    "other": ["Linh tinh", "Khác"]
  };
  


  // Specific attributes for certain types (Overrides or Extends category defaults)
  final Map<String, List<String>> _typeSpecificAttributes = {
    // Technology
    "Smartphone": ["cpu", "ram", "storage", "screen_size", "battery_capacity", "camera_resolution", "color"],
    "Laptop": ["cpu", "ram", "storage", "screen_size", "battery_capacity", "gpu", "weight"],
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
    "Car": ["year", "fuel_type", "transmission", "mileage", "seats", "engine_capacity"],
    "Motorbike": ["year", "fuel_type", "engine_capacity", "mileage"],
  };

  bool get _hasAnyImages => _selectedImages.isNotEmpty || _draftImages.isNotEmpty;
  bool get _hasAnyVideos => _selectedVideos.isNotEmpty || _draftVideos.isNotEmpty;
  
  // AI Config
  String _selectedStyle = "Chuyên nghiệp";
  String _selectedLength = "Trung bình";
  final List<String> _styles = ["Chuyên nghiệp", "Gần gũi", "Hài hước", "Kỹ thuật"];
  final List<String> _lengths = ["Ngắn", "Trung bình", "Chi tiết"];

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
      
      // Load Remote Media
      _draftImages = p.productMedia.where((m) => !m.contains('.mp4') && !m.contains('.mov')).toList();
      _draftVideos = p.productMedia.where((m) => m.contains('.mp4') || m.contains('.mov')).toList();

      // Jump to last step
      if (_currentStep > 0) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _pageController.jumpToPage(_currentStep);
        });
      }

      // Handle Category & Attributes
      if (p.productCategory.isNotEmpty && p.productAttribute.isNotEmpty) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
               _onCategoryChanged(p.productCategory);
               // Pre-fill attributes after category change
               // Wait frame?
                 Future.delayed(const Duration(milliseconds: 100), () {
                     if (mounted) {
                       setState(() {
                         p.productAttribute.forEach((key, value) {
                            final index = _attributes.indexWhere((attr) => attr.nameController.text.toLowerCase() == key.toLowerCase());
                            if (index != -1) {
                                _attributes[index].valueController.text = value.toString();
                            } else {
                                // Add dynamic
                                _attributes.add(AttributeItem(name: _formatKey(key), value: value.toString()));
                            }
                         });
                       });
                     }
                 });
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

  // --- CURRENCY FORMATTER ---
  String _formatCurrency(String value) {
    if (value.isEmpty) return "";
    value = value.replaceAll('.', ''); // Remove existing dots
    if (value.isEmpty) return "";
    final number = int.parse(value);
    return NumberFormat.currency(locale: 'vi_VN', symbol: '', decimalDigits: 0).format(number).trim();
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
    UIHelper.showImageSourceSheet(context, isVideo: false, onPicked: (image) {
      if (image != null) setState(() => _selectedImages.add(image));
    });
  }

  Future<void> _pickVideo() async {
    UIHelper.showImageSourceSheet(context, isVideo: true, onPicked: (video) {
        if (video != null) setState(() => _selectedVideos.add(video));
    });
  }


  void _showPermissionDialog() {
    UIHelpers.showModernDialog(
      context,
      icon: HeroiconsOutline.lockClosed,
      iconColor: Colors.blue,
      bgColor: Colors.blue.withOpacity(0.1),
      title: "Yêu cầu quyền truy cập",
      description: "Vui lòng cấp quyền truy cập máy ảnh trong Cài đặt để sử dụng tính năng này.",
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
      _isAiValidated = false; // Khi xóa ảnh thì phải duyệt lại (nếu thêm ảnh mới)
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

  // --- LOGIC MANUAL TYPE ---
  void _onTypeChanged(String newType) {
    // 1. Capture current values of STANDARD attributes we want to keep
    // Standard set: type, brand, model, condition, warranty, origin
    final Set<String> keepKeys = {"type", "brand", "model", "condition", "warranty", "origin", "policy", "color"};
    Map<String, String> preservedValues = {};
    
    for (var attr in _attributes) {
      String key = attr.nameController.text.toLowerCase();
      if (keepKeys.contains(key)) {
        preservedValues[key] = attr.valueController.text;
      }
    }
    
    // Ensure the new type is set in preserved values
    preservedValues["type"] = newType;

    // 2. Dispose old
    setState(() {
      for (var attr in _attributes) attr.dispose();
      _attributes.clear();
      
      // 3. Rebuild List
      // Order: Type -> Brand -> Model -> Specifics -> Condition -> Warranty
      
      // A. Type
      _attributes.add(AttributeItem(name: "type", value: newType));
      
      // B. Brand & Model (If relevant for category?) - Yes usually
      _attributes.add(AttributeItem(name: "brand", value: preservedValues["brand"] ?? ""));
      _attributes.add(AttributeItem(name: "model", value: preservedValues["model"] ?? ""));
      
      // C. Specifics from Map
      if (_typeSpecificAttributes.containsKey(newType)) {
          for (String key in _typeSpecificAttributes[newType]!) {
              _attributes.add(AttributeItem(name: key, value: ""));
          }
      } else {
          // If no specific map, maybe fall back to some generics based on category?
          // For now, nothing extra if unknown type.
      }
      
      // D. Condition, Warranty, etc.
      _attributes.add(AttributeItem(name: "condition", value: preservedValues["condition"] ?? ""));
      _attributes.add(AttributeItem(name: "warranty", value: preservedValues["warranty"] ?? ""));
    });
  }

  // --- LOGIC AI SUGGESTION ---
  // --- LOGIC AI HANDLERS ---
  
  // STEP 1: VALIDATE MEDIA
  Future<bool> _handleValidateMedia() async {
    // 1. Kiểm tra nếu không có bất kỳ ảnh nào
    if (!_hasAnyImages) {
      _showErrorDialog("Vui lòng tải lên ít nhất 1 hình ảnh sản phẩm (ảnh thật).");
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
        remoteUrls: _draftImages,
      );

      print("AI Check Result: ${result.toString()}"); 
      
      if (result['is_stock'] == true) {
        _showErrorDialog("Ảnh của bạn không hợp lệ! Hệ thống nhận diện đây là ảnh mạng hoặc ảnh quảng cáo. Vui lòng chụp ảnh thật của sản phẩm để tiếp tục.");
        return false;
      }

      // Trích xuất thông tin từ AI nếu có
      setState(() {
        if (result['condition'] != null) _conditionController.text = result['condition'];
        
        // A. Handle Category Auto-Selection
        String? detectedCategory = result['category'];
        if (detectedCategory != null && _attributeTemplates.containsKey(detectedCategory.toLowerCase())) {
             _onCategoryChanged(detectedCategory.toLowerCase());
        }

        Map<String, dynamic> attrs = result['attributes'] ?? {};
        
        // B. Handle Type Auto-Selection
        String? detectedType;
        attrs.forEach((k, v) {
            if (k.toString().toLowerCase() == 'type') detectedType = v.toString().trim();
        });

        if (detectedType != null) {
            _onTypeChanged(detectedType!);
        }

        // C. Deep Fill Attributes (Brand, and others)
        attrs.forEach((key, value) {
             String cleanKey = key.toString().trim();
             String cleanValue = value.toString().trim();
             
             if (cleanKey.toLowerCase() == 'brand') {
                 _brandController.text = cleanValue;
             } else {
                 int index = _attributes.indexWhere((attr) => attr.nameController.text.toLowerCase() == cleanKey.toLowerCase());
                 if (index != -1) {
                     _attributes[index].valueController.text = cleanValue;
                 } else {
                     _attributes.add(AttributeItem(name: _formatKey(cleanKey), value: cleanValue));
                 }
             }
        });
        
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Đã trích xuất thông tin & thông số kỹ thuật!"), backgroundColor: Colors.green));
        
        // SAVE VISUAL MEMORY for Step 2
        _visualDetails = "Detected Info from Image:\n"
                         "Category: ${result['category'] ?? 'Unknown'}\n"
                         "Condition: ${result['condition'] ?? 'Unknown'}\n"
                         "Attributes: ${attrs.toString()}";
        _isAiValidated = true;
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
      final result = await _productService.generateDetails(
        productName: _titleController.text,
        visualDetails: _visualDetails ?? "User uploaded verified images.",
        style: _selectedStyle,
        length: _selectedLength
      );

      // 1. Check Moderation (Safety)
      if (result['is_safe'] == false) {
         _showErrorDialog("Community standard violation: ${result['violation_reason'] ?? 'Inappropriate content.'}");
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

        // 5. Auto-fill Attributes (Dynamic Expansion & MERGE)
        // We overwrite the entire attribute list with what AI deemed relevant, 
        // BUT we must preserve Visual Evidence (Step 1) if Text AI (Step 2) misses it.

        // A. Capture current visual attributes
        Map<String, String> visualAttributes = {};
        for (var attr in _attributes) {
            if (attr.valueController.text.trim().isNotEmpty && attr.valueController.text != "N/A") {
                visualAttributes[attr.nameController.text.toLowerCase().trim()] = attr.valueController.text.trim();
            }
        }
        
        // Clear UI
        for (var attr in _attributes) attr.dispose();
        _attributes.clear();

        Map<String, dynamic> aiAttrs = result['attributes'] ?? {};
        
        // B. Merge Logic: AI Text + Visual Backup
        // We iterate through AI attributes. If AI says "N/A" but we have visual, use visual.
        // We also check for keys in visual that AI missed.
        
        Map<String, String> finalAttrs = {};
        
        // 1. Put AI attrs first
        aiAttrs.forEach((k, v) {
            String cleanKey = k.toString().toLowerCase().trim();
            String cleanValue = v.toString().trim();
            if (cleanKey == 'brand' || cleanKey == 'origin') return; // Handled separately
            
            finalAttrs[cleanKey] = cleanValue;
        });

        // 2. Mix in Visual attrs
        visualAttributes.forEach((k, v) {
            if (k == 'brand' || k == 'origin') return;
            
            // If Text AI didn't find it, OR Text AI said "N/A", use Visual
            if (!finalAttrs.containsKey(k) || finalAttrs[k] == "N/A" || finalAttrs[k] == "Unknown") {
                finalAttrs[k] = v;
            }
        });

        // 3. Populate UI
        // Handle standard fields first (updated by Merge if needed?)
        // Actually Brand/Origin controllers are separate.
        if (aiAttrs.containsKey('brand') && aiAttrs['brand'] != "N/A") {
            _brandController.text = aiAttrs['brand'].toString();
        } else if (visualAttributes.containsKey('brand')) {
            _brandController.text = visualAttributes['brand']!;
        }

        if (aiAttrs.containsKey('origin') && aiAttrs['origin'] != "N/A") {
            _originController.text = aiAttrs['origin'].toString();
        }

        // 6. Auto-fill Condition
        if (aiAttrs.containsKey('condition') && aiAttrs['condition'] != "N/A") {
            _conditionController.text = aiAttrs['condition'].toString();
        }

        finalAttrs.forEach((key, value) {
             // Add to list
             _attributes.add(AttributeItem(name: _formatKey(key), value: value));
        });
      });
      
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Đã tự động điền tất cả thông tin!"), backgroundColor: Colors.green));

    } catch (e) {
      _showErrorDialog("Content generation error: $e");
    } finally {
      setState(() => _isAiLoading = false);
    }
  }
  
  // STEP 2 END: VALIDATE CONTENT
  Future<bool> _handleValidateContent() async {
      setState(() => _isAiLoading = true);
      try {
          // Prepare data (Convert Display Keys to Snake Case for Backend)
          Map<String, dynamic> attributesMap = {};
          for (var item in _attributes) {
            String keysnake = item.nameController.text.trim().toLowerCase().replaceAll(' ', '_');
            attributesMap[keysnake] = item.valueController.text.trim();
          }
          
          String typeVal = "";
          try {
             var typeAttr = _attributes.firstWhere((a) => a.nameController.text.toLowerCase() == 'type', orElse: () => AttributeItem(name: "", value: ""));
             if (typeAttr.nameController.text.isNotEmpty) typeVal = typeAttr.valueController.text;
          } catch(e) {}

          final result = await _productService.validateContent(
             productName: _titleController.text,
             productDescription: _descController.text,
             category: _selectedCategory ?? "",
             type: typeVal,
             attributes: attributesMap
          );
          
          if (result['is_safe'] == false) {
               _showErrorDialog("Community standard violation: ${result['violation_reason']}");
               return false;
          }
          
          if (result['is_consistent'] == false) {
               _showErrorDialog("Inconsistent information: ${result['inconsistency_reason']}\n- Name: ${_titleController.text}\n- Description/Attributes do not match.");
               return false;
          }
           
           if (result['suggestions'] != null && result['suggestions'].toString().isNotEmpty) {
               ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Gợi ý: ${result['suggestions']}"), duration: const Duration(seconds: 3)));
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
     };

     String cleanKey = key.toLowerCase().trim();
     if (vnKeys.containsKey(cleanKey)) return vnKeys[cleanKey]!;

     // Fallback to title case
     return cleanKey.replaceAll("_", " ").split(" ").map((str) => str.isNotEmpty ? '${str[0].toUpperCase()}${str.substring(1)}' : '').join(" ");
  }

  void _activateBackupMode() {
    setState(() {
      _showManualBackup = true;
      _selectedCategory = null;
      for (var attr in _attributes) attr.dispose();
      _attributes.clear();
    });
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("AI không thể xử lý. Đã chuyển sang chế độ thủ công."), backgroundColor: Colors.redAccent));
  }

  // --- SUBMIT ---
  Future<void> _submitProduct() async {
    // Show Loading: "AI is analyzing product..."
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        content: Row(
          children: [
            const ModernLoader(),
            const SizedBox(width: 20),
            Expanded(child: const Text("AI đang phân tích sản phẩm...\nQuá trình này mất khoảng 5-8 giây.", style: TextStyle(fontSize: 14))),
          ],
        ),
      )
    );

    try {
      Map<String, dynamic> attributesMap = {};
      for (var item in _attributes) {
        String keysnake = item.nameController.text.trim().toLowerCase().replaceAll(' ', '_');
        attributesMap[keysnake] = item.valueController.text.trim();
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
        "productPrice": _priceController.text.replaceAll('.', ''), // Fix: Remove dots for backend
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

      // --- ADD LATITUDE & LONGITUDE ---
      try {
        Position position = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high
        );
        fields["latitude"] = position.latitude.toString();
        fields["longitude"] = position.longitude.toString();
        print("Captured Location: ${position.latitude}, ${position.longitude}");
      } catch (e) {
        print("Could not capture location for new post: $e");
        // We continue without coordinates if GPS fails
      }

      fields["status"] = "active";
      fields["lastCompletedStep"] = "3";
      fields["isAiValidated"] = "true";
      fields["existingMedia"] = jsonEncode([..._draftImages, ..._draftVideos]);

      List<XFile> newFiles = [..._selectedImages, ..._selectedVideos];

      if (widget.draftProduct != null) {
          await _productService.updateProductWithMedia(widget.draftProduct!.id, fields, newFiles);
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

  void _showAISettingsSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
        child: SafeArea(
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
                  width: 40, height: 4,
                  margin: const EdgeInsets.only(bottom: 24),
                  decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(2)),
                ),
                const Text("Cài đặt soạn thảo AI", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                const Text("Tùy chỉnh cách AI viết mô tả cho sản phẩm.", style: TextStyle(color: Colors.grey, fontSize: 13)),
                const SizedBox(height: 24),
                
                _buildAISettingItem(
                  icon: HeroiconsOutline.sparkles,
                  iconColor: Colors.purple,
                  bgColor: Colors.purple.withOpacity(0.1),
                  title: "Phong cách viết",
                  value: _selectedStyle,
                  onTap: () => _showSelectionSheet("Chọn phong cách", _styles, _selectedStyle, (val) {
                    setState(() => _selectedStyle = val);
                  }),
                ),
                const SizedBox(height: 12),
                _buildAISettingItem(
                  icon: HeroiconsOutline.bars3BottomLeft,
                  iconColor: Colors.blue,
                  bgColor: Colors.blue.withOpacity(0.1),
                  title: "Độ dài nội dung",
                  value: _selectedLength,
                  onTap: () => _showSelectionSheet("Chọn độ dài", _lengths, _selectedLength, (val) {
                    setState(() => _selectedLength = val);
                  }),
                ),
                const SizedBox(height: 12),
                const Divider(),
                const SizedBox(height: 12),
                _buildAISettingItem(
                  icon: HeroiconsOutline.bookmark,
                  iconColor: AppColors.primary,
                  bgColor: AppColors.primary.withOpacity(0.1),
                  title: "Lưu bản nháp",
                  value: "Lưu lại để chỉnh sửa sau",
                  onTap: () {
                    Navigator.pop(context);
                    _saveDraft();
                  },
                ),
                const SizedBox(height: 12),
              ],
            ),
          ),
        ),
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
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(45),
          border: Border.all(color: Colors.grey.shade100),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(color: bgColor, shape: BoxShape.circle),
              child: Icon(icon, color: iconColor, size: 20),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: GoogleFonts.roboto(fontSize: 14, fontWeight: FontWeight.w700, color: const Color(0xFF1F2937))),
                  Text(value, style: GoogleFonts.roboto(fontSize: 12, color: AppColors.primary, fontWeight: FontWeight.w500)),
                ],
              ),
            ),
            const Icon(Icons.chevron_right_rounded, color: Colors.grey, size: 18),
          ],
        ),
      ),
    );
  }

  void _showSelectionSheet(String title, List<String> options, String current, Function(String) onSelected) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
        child: Container(
          margin: const EdgeInsets.fromLTRB(16, 0, 16, 24),
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.95),
            borderRadius: BorderRadius.circular(45),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 20),
              ...options.map((opt) => ListTile(
                title: Text(opt, style: TextStyle(fontWeight: opt == current ? FontWeight.bold : FontWeight.normal, color: opt == current ? AppColors.primary : Colors.black87)),
                trailing: opt == current ? const Icon(Icons.check_circle, color: AppColors.primary) : null,
                onTap: () {
                  onSelected(opt);
                  Navigator.pop(context);
                  Navigator.pop(context); // Close parent sheet to refresh
                  _showAISettingsSheet(); // Reopen to show new value
                },
              )).toList(),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  // --- VALIDATION ---
  Future<bool> _validateCurrentStep() async {
    if (_currentStep == 0) {
      // Step 1: Media & Info
      if (_titleController.text.trim().isEmpty || _priceController.text.trim().isEmpty) {
         if (!_hasAnyImages) {
             _showErrorDialog("Vui lòng nhập tên sản phẩm, giá bán và tải lên ít nhất 1 hình ảnh.");
         } else {
             _showErrorDialog("Vui lòng nhập đầy đủ tên sản phẩm và giá bán.");
         }
         return false;
      } else if (!_hasAnyImages) {
         _showErrorDialog("Vui lòng tải lên ít nhất 1 hình ảnh sản phẩm (ảnh thật).");
         return false;
      }
      return await _handleValidateMedia();
    } else if (_currentStep == 1) {
       // Step 2: Info
       if (_selectedCategory == null) { _showErrorDialog("Vui lòng chọn danh mục sản phẩm."); return false; }
       if (_priceController.text.isEmpty) { _showErrorDialog("Vui lòng nhập giá bán."); return false; }
       if (_descController.text.length < 10) { _showErrorDialog("Mô tả sản phẩm quá ngắn (tối thiểu 10 ký tự)."); return false; }
       
       // Final Check for content safety & consistency
       // This ensures Step 3 is clean.
       return await _handleValidateContent();
    } else if (_currentStep == 2) {
       // Step 3: Address Transaction
       if (_selectedProvinceName == null || _selectedWardName == null || _addressDetailController.text.trim().isEmpty) {
           _showErrorDialog("Vui lòng nhập đầy đủ địa chỉ giao dịch.");
           return false;
       }
       return true;
    }
    return true;
  }


  // --- SAVE DRAFT ---
  Future<void> _saveDraft() async {
      // Allow saving with minimal info
      if (_titleController.text.isEmpty) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Vui lòng nhập ít nhất tên sản phẩm để lưu bản nháp.")));
          return;
      }
      
      try {
          String? userId = _userService.getCurrentUserId();
          if (userId == null) return;
          
          Map<String, String> fields = {
            "productName": _titleController.text,
            "productPrice": _priceController.text.replaceAll('.', ''),
            "productDescription": _descController.text.isNotEmpty ? _descController.text : " ",
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
            "productAttribute": jsonEncode({}),
            "productAddress": jsonEncode({"province": "", "commune": "", "detail": ""}),
            "existingMedia": jsonEncode([..._draftImages, ..._draftVideos]),
          };
          
          List<XFile> newFiles = [..._selectedImages, ..._selectedVideos];
          
          showDialog(context: context, barrierDismissible: false, builder: (ctx) => Center(child: ModernLoader()));
          
          if (widget.draftProduct != null) {
              await _productService.updateProductWithMedia(widget.draftProduct!.id, fields, newFiles);
          } else {
              await _productService.createProduct(fields: fields, files: newFiles);
          }
          
          if (mounted) {
              Navigator.pop(context); // Close loading
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Đã lưu bản nháp!"), backgroundColor: Colors.green));
              Navigator.pop(context); // Close Screen
          }
      } catch (e) {
          if (mounted) Navigator.pop(context);
          _showErrorDialog("Error saving draft: $e");
      }
  }

  void _nextStep() async {
    bool valid = await _validateCurrentStep();
    if (valid) {
      if (_currentStep < 3) { // 0 -> 1 -> 2 -> 3
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
          const Text("Chọn ảnh thật của sản phẩm (AI sẽ kiểm tra ảnh mạng/stock).", style: TextStyle(color: Colors.grey)),
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
            isImage: true
          ),
          if (_hasAnyImages)
            const Padding(padding: EdgeInsets.only(top: 8), child: Text("Đã có ảnh. Nhấn 'Tiếp theo' để tiếp tục.", style: TextStyle(color: AppColors.primary, fontSize: 12))),
            
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
            isImage: false
          ),

           const SizedBox(height: 24),
           _buildSectionTitle("Tên sản phẩm"),
           const SizedBox(height: 8),
           _buildTextField(controller: _titleController, hint: "VD: Laptop Dell XPS 15 9500"),

           const SizedBox(height: 16),
           _buildSectionTitle("Giá muốn bán (VNĐ)"),
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
          _buildSectionTitle("Tình trạng sản phẩm"),
          const SizedBox(height: 8),
          _buildDropdownField(
            hint: "Chọn tình trạng",
            value: ["New", "Like New", "Old"].contains(_conditionController.text) ? _conditionController.text : null,
            items: ["New", "Like New", "Old"],
            onChanged: (val) => setState(() => _conditionController.text = val ?? ""),
          ),

          const SizedBox(height: 20),

          const SizedBox(height: 20),


          const SizedBox(height: 20),

          // --- DESCRIPTION ---
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildSectionTitle("Mô tả sản phẩm"),
              TextButton.icon(
                onPressed: _isAiLoading ? null : _handleGenerateDetails,
                icon: _isAiLoading 
                    ? SizedBox(width: 16, height: 16, child: ModernLoader(size: 16, color: AppColors.warning)) 
                    : const Icon(HeroiconsSolid.sparkles, size: 16, color: AppColors.warning),
                label: Text(_isAiLoading ? "Đang xử lý..." : "✨ AI Tự soạn nội dung", style: const TextStyle(color: AppColors.warning, fontSize: 13, fontWeight: FontWeight.bold)),
                style: TextButton.styleFrom(backgroundColor: AppColors.warning.withOpacity(0.1), padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8)),
              )
            ],
          ),
          const SizedBox(height: 8),
          _buildTextField(
            controller: _descController, 
            hint: "Nhập mô tả sản phẩm của bạn...", 
            minLines: 5, 
            maxLines: null,
            borderRadius: 20 // Bo nhẹ hơn một chút cho ô mô tả
          ),

          const SizedBox(height: 20),

          // --- CATEGORY ---
          _buildSectionTitle("Danh mục"),
          const SizedBox(height: 8),
          _buildDropdownField(
            hint: "Chọn danh mục", 
            value: _selectedCategory, 
            items: _attributeTemplates.keys.toList(), 
            onChanged: _onCategoryChanged
          ),

          // --- ATTRIBUTES ---
          if (_attributes.isNotEmpty) ...[
             const SizedBox(height: 20),
             const Divider(),
             const SizedBox(height: 10),
             const Text("Thông số chi tiết", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
             const SizedBox(height: 10),
             ListView.builder(
               shrinkWrap: true,
               physics: const NeverScrollableScrollPhysics(),
               itemCount: _attributes.length,
               itemBuilder: (context, index) {
                 final attr = _attributes[index];
                 return Padding(
                   padding: const EdgeInsets.only(bottom: 12),
                   child: Row(
                     crossAxisAlignment: CrossAxisAlignment.end,
                     children: [
                       Expanded(
                         child: Column(
                           crossAxisAlignment: CrossAxisAlignment.start,
                           children: [
                             Text(attr.nameController.text.toUpperCase(), style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey)),
                             const SizedBox(height: 6),
                             // Special handling for 'type' attribute -> Dropdown
                             if (attr.nameController.text.toLowerCase() == 'type' && _selectedCategory != null && _allowedTypes.containsKey(_selectedCategory))
                                DropdownButtonFormField<String>(
                                  value: _allowedTypes[_selectedCategory]!.contains(attr.valueController.text) ? attr.valueController.text : null,
                                  decoration: InputDecoration(
                                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                                    filled: true,
                                    fillColor: const Color(0xFFF2F2F2),
                                    hintText: "Select Type",
                                  ),
                                  items: _allowedTypes[_selectedCategory]!.map((t) => DropdownMenuItem(value: t, child: Text(t, style: const TextStyle(fontSize: 14)))).toList(),
                                  onChanged: (val) {
                                    if (val != null) {
                                         setState(() => attr.valueController.text = val);
                                         _onTypeChanged(val);
                                    }
                                  },
                                )
                             else if (attr.nameController.text.toLowerCase() == 'condition')
                                // Condition Dropdown inside Attributes too
                                _buildDropdownField(
                                  hint: "Chọn tình trạng",
                                  value: ["New", "Like New", "Old"].contains(attr.valueController.text) ? attr.valueController.text : null,
                                  items: ["New", "Like New", "Old"],
                                  onChanged: (val) => setState(() => attr.valueController.text = val ?? ""),
                                )
                             else
                                _buildTextField(controller: attr.valueController, hint: "Enter ${attr.nameController.text}"),
                           ],
                         ),
                       ),
                       const SizedBox(width: 8),
                       IconButton(
                         icon: const Icon(HeroiconsOutline.trash, color: Colors.red),
                         onPressed: () {
                           setState(() {
                             attr.dispose();
                             _attributes.removeAt(index);
                           });
                         },
                       ),
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

  // STEP 3: ADDRESS TRANSACTION
  Widget _buildStep3Address() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text("Bước 3: Địa chỉ giao dịch", style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
          const Text("Nhập địa chỉ của bạn để người mua có thể xem sản phẩm.", style: TextStyle(color: Colors.grey)),
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
                hint: "Quận / Huyện / Phường / Xã", value: _selectedWardCode, items: _wards,
                itemValueMapper: (item) => item['ward_code'].toString(), itemLabelMapper: (item) => item['ward_name'],
                onChanged: (val) { setState(() { _selectedWardCode = val; final s = _wards.firstWhere((e) => e['ward_code'].toString() == val, orElse: () => null); _selectedWardName = s != null ? s['ward_name'] : null; }); }
            ),
            const SizedBox(height: 8),
            _buildTextField(controller: _addressDetailController, hint: "Số nhà, tên đường..."),
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
          const Text("Bước 4: Xem trước", style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
          const Text("Xem lại tất cả thông tin trước khi hoàn tất đăng tin.", style: TextStyle(color: Colors.grey)),
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
                 _buildReviewRow("Danh mục", _categoryNames[_selectedCategory] ?? "Khác"),
                 _buildReviewRow("Tình trạng", _conditionController.text),
                 _buildReviewRow("Thương hiệu", _brandController.text),
                 _buildReviewRow("Xuất xứ", _originController.text),
                 _buildReviewRow("Bảo hành", _policyController.text),
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
      body: Stack(
        children: [
          Column(
            children: [
              const SizedBox(height: 110), // Tăng lại từ 90 lên 110 để thoáng hơn
              // CUSTOM STEPPER
              Container(
                padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 16), // Tăng từ 10 lên 18
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
              const SizedBox(height: 8), // Thêm khoảng nghỉ trước khi vào nội dung chính

              Expanded(
                child: PageView(
                  controller: _pageController,
                  physics: const NeverScrollableScrollPhysics(), // Disable swipe
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
            top: 0, left: 0, right: 0,
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
            border: Border(top: BorderSide(color: Colors.grey.shade200))
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
                if (_currentStep > 0) ...[
                  TextButton(onPressed: _prevStep, child: const Text("Quay lại", style: TextStyle(color: Colors.grey))),
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
                        ? SizedBox(width: 20, height: 20, child: ModernLoader(size: 20, color: Colors.white, showText: false))
                        : Text(
                          _currentStep == 3 ? "Đăng tin" : "Tiếp theo",
                          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                  ),
                ),
            ],
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
          width: 30, height: 30,
          decoration: BoxDecoration(
              color: isActive ? AppColors.primary : Colors.grey[200],
            shape: BoxShape.circle,
          ),
          child: Center(
            child: isActive
              ? const Icon(Icons.check, color: Colors.white, size: 16)
              : Text((step + 1).toString(), style: const TextStyle(color: Colors.grey, fontWeight: FontWeight.bold)),
          ),
        ),
        const SizedBox(height: 4),
          Text(label, style: TextStyle(fontSize: 10, color: isActive ? AppColors.primary : Colors.grey, fontWeight: FontWeight.bold))
      ],
    );
  }

  Widget _buildStepLine(int step) {
    return Expanded(
      child: Container(
        height: 2,
          color: _currentStep > step ? AppColors.primary : Colors.grey[200],
        margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 15), // align with circle center roughly
        // remove vertical margin if it looks off, alignment is key
      ),
    );
  }

  // --- HELPERS (Reused) ---
  Widget _buildSectionTitle(String title) => Text(title, style: TextStyle(fontSize: 14, color: Colors.grey[800], fontWeight: FontWeight.bold));

  Widget _buildTextField({required TextEditingController controller, required String hint, TextInputType keyboardType = TextInputType.text, int? maxLines = 1, int? minLines, bool readOnly = false, double borderRadius = 50}) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      maxLines: maxLines,
      minLines: minLines,
      readOnly: readOnly,
      onChanged: (_) => setState(() {}),
      decoration: InputDecoration(
        hintText: hint, hintStyle: TextStyle(color: Colors.grey[400], fontSize: 13),
        filled: true, fillColor: readOnly ? Colors.grey[200] : const Color(0xFFF2F2F2),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(borderRadius), borderSide: BorderSide.none),
      ),
    );
  }

  Widget _buildDropdownField({required String hint, required String? value, required List<String> items, required ValueChanged<String?> onChanged}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(color: const Color(0xFFF2F2F2), borderRadius: BorderRadius.circular(50)),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: value, hint: Text(hint, style: TextStyle(color: Colors.grey[400], fontSize: 13)),
          isExpanded: true, 
          items: items.map((e) => DropdownMenuItem(value: e, child: Text(_categoryNames[e] ?? e, style: const TextStyle(fontSize: 14)))).toList(),
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
      decoration: BoxDecoration(color: const Color(0xFFF2F2F2), borderRadius: BorderRadius.circular(50)),
      child: DropdownButtonHideUnderline(child: DropdownButton<String>(
          value: uniqueValues.contains(value) ? value : null, hint: Text(hint, style: TextStyle(color: Colors.grey[400], fontSize: 13)),
          isExpanded: true, menuMaxHeight: 300, items: dropdownItems, onChanged: onChanged)),
    );
  }

  Widget _buildHorizontalMediaList({required String label, required IconData icon, required List<XFile> items, required List<String> remoteItems, required VoidCallback onAdd, required Function(int, bool) onRemove, required bool isImage}) {
    return SizedBox(
      height: 100,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: remoteItems.length + items.length + 1,
        itemBuilder: (context, index) {
          if (index == 0) {
            return GestureDetector(onTap: onAdd, child: Container(
                width: 100, margin: const EdgeInsets.only(right: 12),
                decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: Colors.grey.shade300)),
                child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [Icon(icon, size: 24, color: Colors.black54), const SizedBox(height: 4), Text(label, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold))])));
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
              url = '${ApiConstants.baseUrl}${url.startsWith('/') ? '' : '/'}$url';
            }
            return Stack(children: [
              Container(
                  width: 100, margin: const EdgeInsets.only(right: 12),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16), 
                    color: Colors.grey[200], 
                    image: isImage ? DecorationImage(image: NetworkImage(url), fit: BoxFit.cover) : null
                  ),
                  child: !isImage ? const Center(child: Icon(Icons.play_circle_fill, size: 30, color: Colors.white)) : null
              ),
              Positioned(top: 4, right: 16, child: GestureDetector(onTap: () => onRemove(index - 1, true), child: Container(padding: const EdgeInsets.all(2), decoration: const BoxDecoration(color: Colors.black54, shape: BoxShape.circle), child: const Icon(Icons.close, size: 14, color: Colors.white))))
            ]);
          }

          // Render Local Items
          final localIndex = index - remoteItems.length - 1;
          final file = items[localIndex];
          return Stack(children: [
            Container(
                width: 100, margin: const EdgeInsets.only(right: 12),
                decoration: BoxDecoration(borderRadius: BorderRadius.circular(16), color: Colors.grey[200], image: isImage ? DecorationImage(image: FileImage(File(file.path)), fit: BoxFit.cover) : null),
                child: !isImage ? const Center(child: Icon(Icons.play_circle_fill, size: 30, color: Colors.white)) : null
            ),
            Positioned(top: 4, right: 16, child: GestureDetector(onTap: () => onRemove(localIndex, false), child: Container(padding: const EdgeInsets.all(2), decoration: const BoxDecoration(color: Colors.black54, shape: BoxShape.circle), child: const Icon(Icons.close, size: 14, color: Colors.white))))
          ]);
        },
      ),
    );
  }
}