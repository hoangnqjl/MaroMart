import 'dart:convert';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:heroicons_flutter/heroicons_flutter.dart';
import 'package:http/http.dart' as http;
import 'package:maromart/Colors/AppColors.dart';

class FilterOverlay {
  OverlayEntry? _overlayEntry;
  final LayerLink layerLink = LayerLink();

  final Function(String? categoryId, String? provinceName, String? wardName) onFilterApplied;

  String? _selectedCategory;
  String? _selectedProvinceCode;
  String? _selectedProvinceName;
  String? _selectedWardCode;
  String? _selectedWardName;

  // Dữ liệu danh mục
  final List<Map<String, dynamic>> _categories = [
    {'id': '', 'label': 'All', 'icon': HeroiconsOutline.squares2x2},
    {'id': 'auto', 'label': 'Auto', 'icon': HeroiconsOutline.truck},
    {'id': 'furniture', 'label': 'Furniture', 'icon': HeroiconsOutline.home},
    {'id': 'technology', 'label': 'Tech', 'icon': HeroiconsOutline.computerDesktop},
    {'id': 'fashion', 'label': 'Fashion', 'icon': HeroiconsOutline.shoppingBag},
    {'id': 'service', 'label': 'Service', 'icon': HeroiconsOutline.wrenchScrewdriver},
    {'id': 'hobby', 'label': 'Hobby', 'icon': HeroiconsOutline.puzzlePiece},
    {'id': 'kids', 'label': 'Kids', 'icon': HeroiconsOutline.faceSmile},
  ];

  FilterOverlay({required this.onFilterApplied});

  void toggle(BuildContext context) {
    if (_overlayEntry == null) {
      _showOverlay(context);
    } else {
      hide();
    }
  }

  void hide() {
    _overlayEntry?.remove();
    _overlayEntry = null;
  }

  void _showOverlay(BuildContext context) {
    OverlayState? overlayState = Overlay.of(context);

    _overlayEntry = OverlayEntry(
      builder: (context) {
        return Stack(
          children: [
            GestureDetector(
              onTap: hide,
              behavior: HitTestBehavior.opaque,
              child: Container(
                color: Colors.black.withOpacity(0.3),
                width: double.infinity,
                height: double.infinity,
              ),
            ),
            Positioned(
              width: 280, // Tăng chiều rộng xíu cho đẹp
              child: CompositedTransformFollower(
                link: layerLink,
                showWhenUnlinked: false,
                offset: const Offset(-230, 50),
                child: Material(
                  color: Colors.transparent,
                  child: _FilterContent(
                    categories: _categories,
                    initialCategory: _selectedCategory,
                    initialProvinceCode: _selectedProvinceCode,
                    initialWardCode: _selectedWardCode,
                    onApply: (cat, provCode, provName, wardCode, wardName) {
                      // Lưu lại state để lần sau mở ra vẫn còn
                      _selectedCategory = cat;
                      _selectedProvinceCode = provCode;
                      _selectedProvinceName = provName;
                      _selectedWardCode = wardCode;
                      _selectedWardName = wardName;

                      // Gọi callback về Home
                      onFilterApplied(cat, provName, wardName);
                      hide();
                    },
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );

    overlayState.insert(_overlayEntry!);
  }
}

// Tách Widget Content ra để dùng setState riêng cho việc load API Tỉnh/Huyện
class _FilterContent extends StatefulWidget {
  final List<Map<String, dynamic>> categories;
  final String? initialCategory;
  final String? initialProvinceCode;
  final String? initialWardCode;
  final Function(String?, String?, String?, String?, String?) onApply;

  const _FilterContent({
    required this.categories,
    required this.onApply,
    this.initialCategory,
    this.initialProvinceCode,
    this.initialWardCode,
  });

  @override
  State<_FilterContent> createState() => _FilterContentState();
}

class _FilterContentState extends State<_FilterContent> {
  String? _catId;
  String? _provCode;
  String? _provName;
  String? _wardCode;
  String? _wardName;

  List<dynamic> _provinces = [];
  List<dynamic> _wards = [];
  bool _isCategoryExpanded = false;

  @override
  void initState() {
    super.initState();
    _catId = widget.initialCategory;
    _provCode = widget.initialProvinceCode;
    _wardCode = widget.initialWardCode;

    // Load dữ liệu ban đầu
    _fetchProvinces();
    if (_provCode != null) {
      _fetchWards(_provCode!);
    }
  }

  Future<void> _fetchProvinces() async {
    try {
      final response = await http.get(Uri.parse('https://34tinhthanh.com/api/provinces'));
      if (response.statusCode == 200) {
        setState(() => _provinces = jsonDecode(response.body));
        // Khôi phục tên tỉnh nếu có code
        if (_provCode != null) {
          final item = _provinces.firstWhere((e) => e['province_code'].toString() == _provCode, orElse: () => null);
          if(item != null) _provName = item['name'];
        }
      }
    } catch (e) { print(e); }
  }

  Future<void> _fetchWards(String provinceCode) async {
    try {
      final response = await http.get(Uri.parse('https://34tinhthanh.com/api/wards?province_code=$provinceCode'));
      if (response.statusCode == 200) {
        setState(() => _wards = jsonDecode(response.body));
        // Khôi phục tên phường
        if (_wardCode != null) {
          final item = _wards.firstWhere((e) => e['ward_code'].toString() == _wardCode, orElse: () => null);
          if(item != null) _wardName = item['ward_name'];
        }
      }
    } catch (e) { print(e); }
  }

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.95),
            borderRadius: BorderRadius.circular(20),
            boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 20, offset: const Offset(0, 5))],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // 1. PROVINCE DROPDOWN
              _buildDropdown(
                hint: "Select Province",
                value: _provCode,
                items: _provinces,
                valueKey: 'province_code',
                labelKey: 'name',
                onChanged: (val) {
                  setState(() {
                    _provCode = val;
                    final item = _provinces.firstWhere((e) => e['province_code'].toString() == val);
                    _provName = item['name'];

                    // Reset Ward
                    _wardCode = null;
                    _wardName = null;
                    _wards = [];
                  });
                  if (val != null) _fetchWards(val);
                },
              ),
              const SizedBox(height: 10),

              // 2. WARD DROPDOWN
              _buildDropdown(
                hint: "Select Ward",
                value: _wardCode,
                items: _wards,
                valueKey: 'ward_code',
                labelKey: 'ward_name',
                onChanged: (val) {
                  setState(() {
                    _wardCode = val;
                    final item = _wards.firstWhere((e) => e['ward_code'].toString() == val);
                    _wardName = item['ward_name'];
                  });
                },
              ),
              const SizedBox(height: 10),

              // 3. CATEGORY SELECTOR
              _buildCategorySelector(),

              const SizedBox(height: 16),

              // 4. APPLY BUTTON
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    widget.onApply(_catId, _provCode, _provName, _wardCode, _wardName);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.ButtonBlackColor,
                    shape: const StadiumBorder(),
                  ),
                  child: const Text("Apply Filter", style: TextStyle(color: Colors.white)),
                ),
              ),

              // Nút Reset
              TextButton(
                  onPressed: () {
                    widget.onApply(null, null, null, null, null);
                  },
                  child: const Text("Clear Filter", style: TextStyle(color: Colors.red, fontSize: 12))
              )
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDropdown({
    required String hint,
    required String? value,
    required List<dynamic> items,
    required String valueKey,
    required String labelKey,
    required ValueChanged<String?> onChanged,
  }) {
    // Logic lọc trùng
    final uniqueItems = <String>{};
    final menuItems = <DropdownMenuItem<String>>[];

    for (var item in items) {
      final val = item[valueKey].toString();
      if (!uniqueItems.contains(val)) {
        uniqueItems.add(val);
        menuItems.add(DropdownMenuItem(
          value: val,
          child: Text(item[labelKey], style: const TextStyle(fontSize: 12), overflow: TextOverflow.ellipsis),
        ));
      }
    }

    final safeValue = uniqueItems.contains(value) ? value : null;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: safeValue,
          isExpanded: true,
          hint: Text(hint, style: TextStyle(color: Colors.grey.shade600, fontSize: 12)),
          items: menuItems,
          onChanged: onChanged,
          menuMaxHeight: 250,
        ),
      ),
    );
  }

  Widget _buildCategorySelector() {
    // Tìm label của category đang chọn
    String label = "Category (All)";
    if (_catId != null && _catId!.isNotEmpty) {
      final found = widget.categories.firstWhere((e) => e['id'] == _catId, orElse: () => {});
      if (found.isNotEmpty) label = found['label'];
    }

    return Column(
      children: [
        GestureDetector(
          onTap: () => setState(() => _isCategoryExpanded = !_isCategoryExpanded),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: AppColors.ButtonBlackColor,
              borderRadius: BorderRadius.circular(30),
            ),
            child: Row(
              children: [
                const Icon(HeroiconsOutline.squares2x2, size: 18, color: Colors.white),
                const SizedBox(width: 10),
                Text(label, style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
                const Spacer(),
                Icon(_isCategoryExpanded ? HeroiconsOutline.chevronUp : HeroiconsOutline.chevronDown, size: 16, color: Colors.white),
              ],
            ),
          ),
        ),
        if (_isCategoryExpanded)
          Container(
            margin: const EdgeInsets.only(top: 8),
            height: 150,
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: Colors.grey.shade200)),
            child: ListView.separated(
              padding: const EdgeInsets.all(8),
              itemCount: widget.categories.length,
              separatorBuilder: (_, __) => const Divider(height: 1),
              itemBuilder: (context, index) {
                final cat = widget.categories[index];
                return InkWell(
                  onTap: () {
                    setState(() {
                      _catId = cat['id'];
                      _isCategoryExpanded = false;
                    });
                  },
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
                    child: Row(
                      children: [
                        Icon(cat['icon'], size: 16, color: Colors.black54),
                        const SizedBox(width: 10),
                        Text(cat['label'], style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500)),
                        if (_catId == cat['id']) const Spacer(),
                        if (_catId == cat['id']) const Icon(Icons.check, size: 16, color: Colors.green),
                      ],
                    ),
                  ),
                );
              },
            ),
          )
      ],
    );
  }
}