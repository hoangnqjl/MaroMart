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
import 'package:maromart/models/Product/Product.dart'; // Add this import
import 'package:intl/intl.dart';
import 'package:maromart/components/ModernLoader.dart';

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
  
  // ... (AI Config, Address & Media vars remain same)
  // ... (initState remains same)

  // ... (SKIP to _handleGenerateDetails) 
  
  // (Since I cannot skip large chunks in replace, I will target _attributeTemplates specifically first).

  
  final Map<String, List<String>> _allowedTypes = {
    "auto": ["Car", "Motorbike", "Bicycle", "Electric Bike", "Truck", "Van", "Bus", "Parts", "Accessories", "Other"],
    "furniture": ["Chair", "Table", "Sofa", "Bed", "Wardrobe", "Cabinet", "Bookshelf", "Desk", "Mattress", "Lamp", "Mirror", "Other"],
    "technology": ["Smartphone", "Laptop", "Tablet", "Smartwatch", "Desktop PC", "Monitor", "Headphone", "Mouse", "Keyboard", "Camera", "Speaker", "Printer", "Game Console", "Component", "Accessories", "Other"],
    "appliances": ["Fridge", "Washing Machine", "Air Conditioner", "Fan", "Vacuum Cleaner", "Rice Cooker", "Microwave", "Kettle", "Iron", "Water Purifier", "Blender", "Heater", "Other"],
    "office": ["Desk", "Chair", "Printer", "Scanner", "Projector", "Stationery", "Filing Cabinet", "Whiteboard", "Other"],
    "style": ["Shirt", "T-Shirt", "Pants", "Jeans", "Dress", "Skirt", "Jacket", "Coat", "Shoes", "Sneakers", "Sandals", "Bag", "Wallet", "Watch", "Glasses", "Jewelry", "Hat", "Other"],
    "service": ["Cleaning", "Repair", "Delivery", "Tutor", "Beauty", "Rental", "Tourism", "Photography", "Other"],
    "hobby": ["Musical Instrument", "Sport Equipment", "Art Supply", "Board Game", "Collectible", "Toy", "Fishing Gear", "Camping Gear", "Other"],
    "kids": ["Toy", "Stroller", "Car Seat", "Baby Clothes", "Diaper", "Feeding Bottle", "Crib", "Walker", "Other"],
    "books": ["Fiction", "Non-fiction", "Textbook", "Comic", "Magazine", "Notebook", "Other"],
    "pets": ["Dog Food", "Cat Food", "Cage", "Toy", "Accessories", "Aquarium", "Other"],
    "other": ["Miscellaneous", "Other"]
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
    "Washing Machine": ["capacity", "washing_type", "spin_speed", "inverter"],
    "Air Conditioner": ["cooling_capacity", "type", "inverter", "gas_type"],
    "Fan": ["power", "fan_speed", "blade_diameter"],
    
    // Auto
    "Car": ["year", "fuel_type", "transmission", "mileage", "seats", "engine_capacity"],
    "Motorbike": ["year", "fuel_type", "engine_capacity", "mileage"],
    
    // Fashion
    "Shirt": ["size", "material", "gender", "fit_type"],
    "Pants": ["size", "material", "gender", "fit_type"],
    "Shoes": ["size", "material", "gender", "sole_type"],
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
      final result = await _productService.validateMedia(_selectedImages, _titleController.text);

      print("AI Check Result: ${result.toString()}"); 
      
      // 1. Strict Stock Check
      if (result['is_stock'] == true) {
        _showErrorDialog("Lỗi ảnh: ${result['stock_reason'] ?? 'Ảnh giống ảnh stock/mạng.'}\nVui lòng dùng ảnh chụp thật.");
        return false;
      }

      // 2. Strict Consistency Check
      if (result['is_consistent'] == false) {
           _showErrorDialog("Ảnh không khớp tên sản phẩm: ${result['consistency_reason']}\nVui lòng kiểm tra lại ảnh hoặc tên.");
           return false;
      }
      
      // 3. Extract Info Success
      setState(() {
        if (result['condition'] != null) _conditionController.text = result['condition'];

        Map<String, dynamic> attrs = result['extracted_attributes'] ?? {};

        // A. Handle Category Auto-Selection
        String? detectedCategory = result['category'];
        if (detectedCategory != null && _attributeTemplates.containsKey(detectedCategory.toLowerCase())) {
             _onCategoryChanged(detectedCategory.toLowerCase());
        }

        // B. Handle Type Auto-Selection (Critical for Specific Attributes like RAM/Storage)
        // Find if 'type' is in the attributes
        String? detectedType;
        attrs.forEach((k, v) {
            if (k.toString().toLowerCase() == 'type') detectedType = v.toString().trim();
        });

        if (detectedType != null) {
            print("AI Detected Type: '$detectedType'");
            // Check if this type is valid/known (optional, but safer)
            // Or just try to switch. _onTypeChanged handles generic logic but let's be safe.
            // We assume _onTypeChanged logic handles "unknown" types gracefully or we just call it.
            // But we need to be careful not to loop or break if type is weird.
            // For now, let's call it. It will set the "type" attribute value effectively.
            _onTypeChanged(detectedType!);
        }

        // C. Deep Fill Attributes (Iterate again to fill values into the NOW READY templates)
        attrs.forEach((key, value) {
             String cleanKey = key.toString().trim();
             String cleanValue = value.toString().trim();
             
             if (cleanKey.toLowerCase() == 'brand') {
                 _brandController.text = cleanValue;
             } else {
                 // Check if attribute already exists (from template)
                 // Note: _formatKey might be needed if template uses "Formatted" names?
                 // But wait, _attributeTemplates uses raw lowercase keys like "screen_size"?
                 // Let's check _typeSpecificAttributes: ["screen_size", "ram"...]
                 // AddProduct UI likely displays them.
                 // The 'nameController.text' usually holds the display name?
                 // Let's assume nameController holds the key.
                 
                 int index = _attributes.indexWhere((attr) => attr.nameController.text.toLowerCase() == cleanKey.toLowerCase());
                 
                 if (index != -1) {
                     // Update existing template field
                     _attributes[index].valueController.text = cleanValue;
                 } else {
                     // Add new Deep Fill attribute.
                     // AVOID DUPLICATES: If _onTypeChanged added "ram", we shouldn't add "ram" again.
                     // The index check above prevents updating if it exists.
                     // But wait, if _onTypeChanged added "ram", index SHOULD be != -1.
                     // So we update it.
                     // If it's "Color" and not in template, index == -1. We add it.
                     _attributes.add(AttributeItem(name: _formatKey(cleanKey), value: cleanValue));
                 }
             }
        });
        
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Đã trích xuất thông tin & thông số kỹ thuật!"), backgroundColor: Colors.green));
        
        // SAVE VISUAL MEMORY
        _visualDetails = "Detected Info from Image:\n"
                         "Category: ${result['category'] ?? 'Unknown'}\n"
                         "Condition: ${result['condition'] ?? 'Unknown'}\n"
                         "Attributes: ${attrs.toString()}";
      });
      
      return true;
    } catch (e) {
      _showErrorDialog("Không thể kiểm tra ảnh (Lỗi mạng/AI): ${e.toString()}");
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

        finalAttrs.forEach((key, value) {
             // Add to list
             _attributes.add(AttributeItem(name: _formatKey(key), value: value));
        });
      });
      
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Đã tự động điền đầy đủ thông tin!"), backgroundColor: Colors.green));

    } catch (e) {
      _showErrorDialog("Lỗi tạo nội dung: $e");
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
               _showErrorDialog("Vi phạm tiêu chuẩn cộng đồng: ${result['violation_reason']}");
               return false;
          }
          
          if (result['is_consistent'] == false) {
               _showErrorDialog("Thông tin không đồng nhất: ${result['inconsistency_reason']}\n- Tên: ${_titleController.text}\n- Mô tả/Thuộc tính chưa khớp.");
               return false;
          }
           
           if (result['suggestions'] != null && result['suggestions'].toString().isNotEmpty) {
               ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Gợi ý: ${result['suggestions']}"), duration: const Duration(seconds: 3)));
           }
          
          return true;
      } catch (e) {
          _showErrorDialog("Lỗi kiểm tra nội dung: $e");
          return false;
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
      for (var attr in _attributes) attr.dispose();
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
            ModernLoader(),
            SizedBox(width: 20),
            Expanded(child: Text("AI đang phân tích sản phẩm...\nQuá trình này mất khoảng 5-8 giây.", style: TextStyle(fontSize: 14))),
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
    if (_currentStep == 0) {
      // Step 1: Media -> Validate API Strict
      return await _handleValidateMedia();
    } else if (_currentStep == 1) {
       // Step 2: Info
       if (_selectedCategory == null) { _showErrorDialog("Vui lòng chọn danh mục."); return false; }
       if (_priceController.text.isEmpty) { _showErrorDialog("Vui lòng nhập giá."); return false; }
       if (_descController.text.length < 10) { _showErrorDialog("Mô tả quá ngắn."); return false; }
       
       // Final Check for content safety & consistency
       // This ensures Step 3 is clean.
       return await _handleValidateContent();
    }
    return true;
  }


  // --- SAVE DRAFT ---
  Future<void> _saveDraft() async {
      // Allow saving with minimal info
      if (_titleController.text.isEmpty) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Vui lòng nhập ít nhất Tên sản phẩm để lưu nháp.")));
          return;
      }
      
      try {
          String? userId = _userService.getCurrentUserId();
          if (userId == null) return;
          
          Map<String, String> fields = {
            "productName": _titleController.text,
            "productPrice": _priceController.text.replaceAll('.', ''), // Remove dots
            "productDescription": _descController.text.isNotEmpty ? _descController.text : " ",
            "categoryId": _selectedCategory ?? "other",
            "productCategory": _selectedCategory ?? "other",
            "productOrigin": _originController.text,
            "productCondition": _conditionController.text,
            "productBrand": _brandController.text,
            "productWP": _policyController.text,
            "userId": userId,
            "status": "draft", // STATUS DRAFT
            "productAttribute": jsonEncode({}),
            "productAddress": jsonEncode({"province": "", "commune": "", "detail": ""}),
          };
          
          List<XFile> allFiles = [..._selectedImages, ..._selectedVideos];
          
          showDialog(context: context, barrierDismissible: false, builder: (_) => Center(child: ModernLoader()));
          
          await _productService.createProduct(fields: fields, files: allFiles); // Create new draft
          
          if (mounted) {
              Navigator.pop(context); // Close loading
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Đã lưu nháp!"), backgroundColor: Colors.green));
              Navigator.pop(context); // Close Screen
          }
      } catch (e) {
          if (mounted) Navigator.pop(context);
          _showErrorDialog("Lỗi lưu nháp: $e");
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
                    ? SizedBox(width: 16, height: 16, child: ModernLoader(size: 16, color: Colors.purple)) 
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
      appBar: AppBar(
        title: const Text('Add New Product', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(icon: const Icon(Icons.arrow_back, color: Colors.black), onPressed: () => Navigator.pop(context)),
        actions: [
          TextButton(
            onPressed: _saveDraft,
            child: const Text("Lưu nháp", style: TextStyle(color: Colors.blue, fontWeight: FontWeight.bold)),
          )
        ],
      ),
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
                    ? SizedBox(width: 20, height: 20, child: ModernLoader(size: 20, color: Colors.white))
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