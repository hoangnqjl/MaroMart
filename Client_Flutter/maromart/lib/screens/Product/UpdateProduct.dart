import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:heroicons_flutter/heroicons_flutter.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'package:maromart/Colors/AppColors.dart';
import 'package:maromart/components/TopBarSecond.dart';
import 'package:maromart/models/Product/Product.dart';
import 'package:maromart/services/product_service.dart';
import 'package:maromart/utils/constants.dart';

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
  final String productId;

  const UpdateProduct({super.key, required this.productId});

  @override
  State<StatefulWidget> createState() => _UpdateProductState();
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
  // Lưu URL ảnh cũ
  List<String> _oldMediaUrls = [];
  // Media mới chọn
  final ImagePicker _picker = ImagePicker();
  List<XFile> _selectedImages = [];
  List<XFile> _selectedVideos = [];

  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchProvinces().then((_) {
      _fetchProductDetail();
    });
  }

  // --- 1. LẤY CHI TIẾT SẢN PHẨM ---
  Future<void> _fetchProductDetail() async {
    try {
      final product = await _productService.getProductById(widget.productId);

      setState(() {
        _titleController.text = product.productName;
        _priceController.text = product.productPrice.toString();
        _descController.text = product.productDescription;
        _conditionController.text = product.productCondition;
        _brandController.text = product.productBrand;
        _originController.text = product.productOrigin;
        _policyController.text = product.productWP;
        _selectedCategory = product.productCategory;

        // Xử lý địa chỉ
        if (product.productAddress != null) {
          _selectedProvinceName = product.productAddress!.province;
          _selectedWardName = product.productAddress!.commute;
          _addressDetailController.text = product.productAddress!.detail;

          // Tìm code từ tên để hiển thị lại dropdown
          final prov = _provinces.firstWhere(
                  (e) => e['name'] == _selectedProvinceName,
              orElse: () => null
          );
          if (prov != null) {
            _selectedProvinceCode = prov['province_code'].toString();
            // Load huyện sau khi có tỉnh
            _fetchWards(_selectedProvinceCode!).then((_) {
              if (mounted && _selectedWardName != null) {
                final ward = _wards.firstWhere(
                        (e) => e['ward_name'] == _selectedWardName,
                    orElse: () => null
                );
                if (ward != null) {
                  setState(() => _selectedWardCode = ward['ward_code'].toString());
                }
              }
            });
          }
        }

        // Xử lý thuộc tính
        _attributes.clear();
        if (product.productAttribute != null) {
          Map<String, dynamic> attrMap = {};
          if (product.productAttribute is ProductAttribute) {
            // Convert object sang map nếu cần
          } else if (product.productAttribute is Map) {
            attrMap = Map<String, dynamic>.from(product.productAttribute);
          } else if (product.productAttribute is String) {
            attrMap = jsonDecode(product.productAttribute);
          }

          attrMap.forEach((key, value) {
            _attributes.add(AttributeItem(name: key, value: value.toString()));
          });
        } else {
          // Nếu không có attr cũ, load template
          _onCategoryChanged(_selectedCategory, reset: false);
        }

        // Xử lý Media cũ
        _oldMediaUrls = List.from(product.productMedia);

        _isLoading = false;
      });
    } catch (e) {
      print("Lỗi tải sản phẩm: $e");
      setState(() => _isLoading = false);
      if(mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Failed to load product details"))
        );
      }
    }
  }

  // --- API ĐỊA CHỈ ---
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
    try {
      final response = await http.get(
          Uri.parse('https://34tinhthanh.com/api/wards?province_code=$provinceCode')
      );
      if (response.statusCode == 200) {
        setState(() {
          _wards = jsonDecode(response.body);
        });
      }
    } catch (e) {
      print("Lỗi tải phường xã: $e");
    }
  }

  void _onCategoryChanged(String? newCategory, {bool reset = true}) {
    setState(() {
      _selectedCategory = newCategory;
      if (reset) {
        for (var attr in _attributes) attr.dispose();
        _attributes.clear();
      }

      if (newCategory != null &&
          _attributeTemplates.containsKey(newCategory) &&
          _attributes.isEmpty) {
        List<String> templates = _attributeTemplates[newCategory]!;
        for (String key in templates) {
          _attributes.add(AttributeItem(name: key, value: ""));
        }
      }
    });
  }

  // --- MEDIA ---
  Future<void> _pickImages() async {
    final List<XFile> images = await _picker.pickMultiImage();
    if (images.isNotEmpty) {
      setState(() => _selectedImages.addAll(images));
    }
  }

  Future<void> _pickVideo() async {
    final XFile? video = await _picker.pickVideo(source: ImageSource.gallery);
    if (video != null) {
      setState(() => _selectedVideos.add(video));
    }
  }

  void _removeNewImage(int index) => setState(() => _selectedImages.removeAt(index));
  void _removeNewVideo(int index) => setState(() => _selectedVideos.removeAt(index));
  void _removeOldMedia(int index) => setState(() => _oldMediaUrls.removeAt(index));

  // --- UPDATE ---
  Future<void> _updateProduct() async {
    if (_titleController.text.isEmpty || _priceController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Please enter Name and Price!"))
      );
      return;
    }

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator()),
    );

    try {
      // Chuẩn bị attributes
      Map<String, dynamic> attributesMap = {};
      for (var item in _attributes) {
        String key = item.nameController.text.trim();
        String value = item.valueController.text.trim();
        if (key.isNotEmpty && value.isNotEmpty) {
          attributesMap[key] = value;
        }
      }

      // Chuẩn bị address
      Map<String, String> addressMap = {
        "province": _selectedProvinceName ?? "",
        "commune": _selectedWardName ?? "",
        "detail": _addressDetailController.text.trim(),
      };

      // Chuẩn bị fields (PHẢI là Map<String, String>)
      Map<String, String> fields = {
        "productName": _titleController.text,
        "productPrice": _priceController.text,
        "productDescription": _descController.text,
        "productCategory": _selectedCategory ?? "",
        "productOrigin": _originController.text,
        "productCondition": _conditionController.text,
        "productBrand": _brandController.text,
        "productWP": _policyController.text,
        "productAttribute": jsonEncode(attributesMap),
        "productAddress": jsonEncode(addressMap),
        "existingMedia": jsonEncode(_oldMediaUrls), // Gửi list ảnh cũ
      };

      // Gộp ảnh + video mới
      List<XFile> allNewMedia = [..._selectedImages, ..._selectedVideos];

      // Gọi API update
      await _productService.updateProductWithMedia(
        widget.productId,
        fields,
        allNewMedia.isNotEmpty ? allNewMedia : null,
      );

      if (mounted) {
        Navigator.pop(context); // Đóng loading
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text("Update Success!"),
              backgroundColor: Colors.green,
            )
        );
        Navigator.pop(context, true); // Quay lại với kết quả true
      }

    } catch (e) {
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text("Error: $e"),
              backgroundColor: Colors.red,
            )
        );
      }
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
    super.dispose();
  }

  // Helper xử lý URL ảnh cũ
  String _getFullUrl(String url) {
    if (url.contains(':') && !url.startsWith('http')) {
      final parts = url.split(':');
      if (parts.length > 1) return parts.sublist(1).join(':');
    }
    if (url.startsWith('http')) return url;
    return '${ApiConstants.baseUrl}$url';
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
          body: Center(child: CircularProgressIndicator())
      );
    }

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: const TopBarSecond(title: 'Update Product'),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        physics: const BouncingScrollPhysics(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ===== EXISTING MEDIA =====
            _buildSectionTitle("Existing Media"),
            const SizedBox(height: 12),
            if (_oldMediaUrls.isNotEmpty)
              SizedBox(
                height: 100,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: _oldMediaUrls.length,
                  itemBuilder: (context, index) {
                    final url = _getFullUrl(_oldMediaUrls[index]);
                    final isVideo = _oldMediaUrls[index].toLowerCase().startsWith('video');
                    return Stack(
                      children: [
                        Container(
                          width: 100,
                          margin: const EdgeInsets.only(right: 12),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(16),
                            color: Colors.grey[200],
                            image: !isVideo
                                ? DecorationImage(
                                image: NetworkImage(url),
                                fit: BoxFit.cover
                            )
                                : null,
                          ),
                          child: isVideo
                              ? const Center(
                              child: Icon(Icons.videocam, size: 40)
                          )
                              : null,
                        ),
                        Positioned(
                          top: 4,
                          right: 16,
                          child: GestureDetector(
                            onTap: () => _removeOldMedia(index),
                            child: Container(
                              padding: const EdgeInsets.all(2),
                              decoration: const BoxDecoration(
                                  color: Colors.red,
                                  shape: BoxShape.circle
                              ),
                              child: const Icon(
                                  Icons.close,
                                  size: 14,
                                  color: Colors.white
                              ),
                            ),
                          ),
                        )
                      ],
                    );
                  },
                ),
              )
            else
              const Text(
                  "No existing media",
                  style: TextStyle(color: Colors.grey)
              ),

            const SizedBox(height: 24),

            // ===== ADD NEW MEDIA =====
            _buildSectionTitle("Add New Media"),
            const SizedBox(height: 12),
            _buildHorizontalMediaList(
              label: "Add Image",
              icon: HeroiconsOutline.photo,
              items: _selectedImages,
              onAdd: _pickImages,
              onRemove: _removeNewImage,
              isImage: true,
            ),
            const SizedBox(height: 12),
            _buildHorizontalMediaList(
              label: "Add Video",
              icon: HeroiconsOutline.videoCamera,
              items: _selectedVideos,
              onAdd: _pickVideo,
              onRemove: _removeNewVideo,
              isImage: false,
            ),

            const SizedBox(height: 24),

            // ===== BASIC INFORMATION =====
            _buildSectionTitle("Basic Information"),
            const SizedBox(height: 12),
            _buildDropdownField(
                hint: "Category",
                value: _selectedCategory,
                items: _attributeTemplates.keys.toList(),
                onChanged: (val) => _onCategoryChanged(val, reset: true)
            ),
            const SizedBox(height: 12),
            _buildTextField(
                controller: _titleController,
                hint: "Product Name"
            ),
            const SizedBox(height: 12),
            _buildTextField(
                controller: _priceController,
                hint: "Price (VND)",
                keyboardType: TextInputType.number
            ),
            const SizedBox(height: 12),
            _buildTextField(
                controller: _descController,
                hint: "Description...",
                maxLines: 4
            ),
            const SizedBox(height: 12),
            _buildTextField(
                controller: _conditionController,
                hint: "Condition"
            ),
            const SizedBox(height: 12),
            _buildTextField(
                controller: _brandController,
                hint: "Brand"
            ),
            const SizedBox(height: 12),
            _buildTextField(
                controller: _originController,
                hint: "Origin"
            ),
            const SizedBox(height: 12),
            _buildTextField(
                controller: _policyController,
                hint: "Warranty Policy"
            ),

            const SizedBox(height: 24),

            // ===== ADDRESS =====
            _buildSectionTitle("Address"),
            const SizedBox(height: 12),
            _buildDynamicDropdown(
              hint: "Province",
              value: _selectedProvinceCode,
              items: _provinces,
              itemValueMapper: (item) => item['province_code'].toString(),
              itemLabelMapper: (item) => item['name'],
              onChanged: (val) {
                setState(() {
                  _selectedProvinceCode = val;
                  final item = _provinces.firstWhere(
                          (e) => e['province_code'].toString() == val,
                      orElse: () => null
                  );
                  _selectedProvinceName = item != null ? item['name'] : null;
                  _selectedWardCode = null;
                  _selectedWardName = null;
                  _wards = [];
                });
                if (val != null) _fetchWards(val);
              },
            ),
            const SizedBox(height: 12),
            _buildDynamicDropdown(
              hint: "Ward",
              value: _selectedWardCode,
              items: _wards,
              itemValueMapper: (item) => item['ward_code'].toString(),
              itemLabelMapper: (item) => item['ward_name'],
              onChanged: (val) {
                setState(() {
                  _selectedWardCode = val;
                  final item = _wards.firstWhere(
                          (e) => e['ward_code'].toString() == val,
                      orElse: () => null
                  );
                  _selectedWardName = item != null ? item['ward_name'] : null;
                });
              },
            ),
            const SizedBox(height: 12),
            _buildTextField(
                controller: _addressDetailController,
                hint: "Detail Address"
            ),

            const SizedBox(height: 24),

            // ===== ATTRIBUTES =====
            _buildSectionTitle("Attributes"),
            const SizedBox(height: 12),
            ListView.builder(
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
                            readOnly: true
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        flex: 3,
                        child: _buildTextField(
                            controller: _attributes[index].valueController,
                            hint: "Value"
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),

            const SizedBox(height: 40),

            // ===== UPDATE BUTTON =====
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _updateProduct,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.ButtonBlackColor,
                  foregroundColor: Colors.white,
                  shape: const StadiumBorder(),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: const Text(
                    "Update Product",
                    style: TextStyle(fontWeight: FontWeight.bold)
                ),
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  // ========== WIDGET BUILDERS ==========

  Widget _buildSectionTitle(String title) {
    return Text(
        title,
        style: TextStyle(
            fontSize: 14,
            color: Colors.grey[600],
            fontWeight: FontWeight.w500
        )
    );
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
        border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(30),
            borderSide: BorderSide.none
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
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
          color: const Color(0xFFF2F2F2),
          borderRadius: BorderRadius.circular(30)
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: value,
          hint: Text(
              hint,
              style: TextStyle(color: Colors.grey[400], fontSize: 13)
          ),
          isExpanded: true,
          items: items.map((e) => DropdownMenuItem(
              value: e,
              child: Text(e, style: const TextStyle(fontSize: 14))
          )).toList(),
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
            DropdownMenuItem(
                value: val,
                child: Text(
                    itemLabelMapper(item),
                    overflow: TextOverflow.ellipsis
                )
            )
        );
      }
    }
    final safeValue = uniqueValues.contains(value) ? value : null;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
          color: const Color(0xFFF2F2F2),
          borderRadius: BorderRadius.circular(30)
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: safeValue,
          hint: Text(
              hint,
              style: TextStyle(color: Colors.grey[400], fontSize: 13)
          ),
          isExpanded: true,
          items: dropdownItems,
          onChanged: onChanged,
        ),
      ),
    );
  }

  Widget _buildHorizontalMediaList({
    required String label,
    required IconData icon,
    required List<XFile> items,
    required VoidCallback onAdd,
    required Function(int) onRemove,
    required bool isImage,
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
                width: 100,
                margin: const EdgeInsets.only(right: 12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.black, width: 1),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(icon, size: 24, color: Colors.black),
                    const SizedBox(height: 4),
                    Text(
                        label,
                        style: const TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold
                        )
                    )
                  ],
                ),
              ),
            );
          }
          final file = items[index - 1];
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
                      image: FileImage(File(file.path)),
                      fit: BoxFit.cover
                  )
                      : null,
                ),
                child: !isImage
                    ? const Center(
                    child: Icon(
                        Icons.play_circle_fill,
                        size: 30,
                        color: Colors.white
                    )
                )
                    : null,
              ),
              Positioned(
                top: 4,
                right: 16,
                child: GestureDetector(
                  onTap: () => onRemove(index - 1),
                  child: Container(
                    padding: const EdgeInsets.all(2),
                    decoration: const BoxDecoration(
                        color: Colors.black54,
                        shape: BoxShape.circle
                    ),
                    child: const Icon(
                        Icons.close,
                        size: 14,
                        color: Colors.white
                    ),
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