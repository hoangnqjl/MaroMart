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

  String? _savedCategory;
  String? _savedProvCode;
  String? _savedProvName;
  String? _savedWardCode;
  String? _savedWardName;

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
            Positioned.fill(
              child: GestureDetector(
                onTap: hide,
                child: Container(
                  color: Colors.black.withOpacity(0.3),
                ),
              ),
            ),
            Positioned(
              width: 280,
              child: CompositedTransformFollower(
                link: layerLink,
                showWhenUnlinked: false,
                offset: const Offset(-230, 50),
                child: Material(
                  color: Colors.transparent,
                  child: _FilterContent(
                    categories: _categories,
                    initialCategory: _savedCategory,
                    initialProvinceCode: _savedProvCode,
                    initialWardCode: _savedWardCode,
                    onApply: (cat, provCode, provName, wardCode, wardName) {
                      _savedCategory = cat;
                      _savedProvCode = provCode;
                      _savedProvName = provName;
                      _savedWardCode = wardCode;
                      _savedWardName = wardName;

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
  bool _isProvinceExpanded = false;
  bool _isWardExpanded = false;
  bool _isLoadingProvinces = true;

  @override
  void initState() {
    super.initState();
    _catId = widget.initialCategory;
    _provCode = widget.initialProvinceCode;
    _wardCode = widget.initialWardCode;

    _fetchProvinces();
  }

  Future<void> _fetchProvinces() async {
    try {
      final response = await http.get(Uri.parse('https://34tinhthanh.com/api/provinces'));
      if (response.statusCode == 200) {
        if (mounted) {
          setState(() {
            _provinces = jsonDecode(response.body);
            _isLoadingProvinces = false;

            if (_provCode != null) {
              final item = _provinces.firstWhere((e) => e['province_code'].toString() == _provCode, orElse: () => null);
              if (item != null) _provName = item['name'];
              _fetchWards(_provCode!);
            }
          });
        }
      }
    } catch (e) {
      print("Lỗi load tỉnh: $e");
      if(mounted) setState(() => _isLoadingProvinces = false);
    }
  }

  Future<void> _fetchWards(String provinceCode) async {
    try {
      final response = await http.get(Uri.parse('https://34tinhthanh.com/api/wards?province_code=$provinceCode'));
      if (response.statusCode == 200) {
        if (mounted) {
          setState(() {
            _wards = jsonDecode(response.body);
            if (_wardCode != null) {
              final item = _wards.firstWhere((e) => e['ward_code'].toString() == _wardCode, orElse: () => null);
              if (item != null) _wardName = item['ward_name'];
            }
          });
        }
      }
    } catch (e) { print("Lỗi load huyện: $e"); }
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
            boxShadow: [
              BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 20, offset: const Offset(0, 5))
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // 1. CHỌN TỈNH/THÀNH
              _isLoadingProvinces
                  ? const SizedBox(height: 50, child: Center(child: CircularProgressIndicator()))
                  : _buildCustomDropdown(
                hint: "Province / City",
                selectedLabel: _provName,
                isExpanded: _isProvinceExpanded,
                onTap: () => setState(() {
                  _isProvinceExpanded = !_isProvinceExpanded;
                  _isWardExpanded = false;
                }),
                items: _provinces,
                valueKey: 'province_code',
                labelKey: 'name',
                onItemSelected: (val, label) {
                  setState(() {
                    _provCode = val;
                    _provName = label;
                    _wardCode = null;
                    _wardName = null;
                    _wards = [];
                    _isProvinceExpanded = false;
                  });
                  if (val != null) _fetchWards(val);
                },
              ),

              const SizedBox(height: 10),

              // 2. CHỌN QUẬN/HUYỆN/XÃ
              _buildCustomDropdown(
                hint: "Ward / Commune",
                selectedLabel: _wardName,
                isExpanded: _isWardExpanded,
                onTap: () => setState(() {
                  _isWardExpanded = !_isWardExpanded;
                  _isProvinceExpanded = false;
                }),
                items: _wards,
                valueKey: 'ward_code',
                labelKey: 'ward_name',
                onItemSelected: (val, label) {
                  setState(() {
                    _wardCode = val;
                    _wardName = label;
                    _isWardExpanded = false;
                  });
                },
              ),

              const SizedBox(height: 10),

              // 3. CHỌN DANH MỤC
              _buildCategorySelector(),

              const SizedBox(height: 16),

              // 4. NÚT APPLY
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    widget.onApply(_catId, _provCode, _provName, _wardCode, _wardName);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.ButtonBlackColor,
                    shape: const StadiumBorder(),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  child: const Text("Apply Filter", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                ),
              ),

              // 5. NÚT RESET
              TextButton(
                onPressed: () {
                  setState(() {
                    _catId = null;
                    _provCode = null;
                    _provName = null;
                    _wardCode = null;
                    _wardName = null;
                    _wards = [];
                  });
                  widget.onApply(null, null, null, null, null);
                },
                child: const Text("Clear Filter", style: TextStyle(color: Colors.red, fontSize: 12)),
              )
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCustomDropdown({
    required String hint,
    required String? selectedLabel,
    required bool isExpanded,
    required VoidCallback onTap,
    required List<dynamic> items,
    required String valueKey,
    required String labelKey,
    required Function(String?, String?) onItemSelected,
  }) {
    return Column(
      children: [
        GestureDetector(
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(30),
              border: Border.all(color: Colors.grey.shade300),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    selectedLabel ?? hint,
                    style: TextStyle(
                      fontSize: 13,
                      color: selectedLabel != null ? Colors.black87 : Colors.grey.shade500,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Icon(
                  isExpanded ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
                  color: Colors.grey,
                ),
              ],
            ),
          ),
        ),
        if (isExpanded && items.isNotEmpty)
          Container(
            margin: const EdgeInsets.only(top: 8),
            constraints: const BoxConstraints(maxHeight: 200),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.grey.shade200),
            ),
            child: ListView.separated(
              shrinkWrap: true,
              padding: const EdgeInsets.all(8),
              itemCount: items.length,
              separatorBuilder: (_, __) => const Divider(height: 1, color: Colors.black12),
              itemBuilder: (context, index) {
                final item = items[index];
                final val = item[valueKey].toString();
                final label = item[labelKey];
                final isSelected = selectedLabel == label;

                return InkWell(
                  onTap: () => onItemSelected(val, label),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            label,
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                              color: isSelected ? AppColors.ButtonBlackColor : Colors.black87,
                            ),
                          ),
                        ),
                        if (isSelected) const Icon(Icons.check, size: 16, color: Colors.green),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
      ],
    );
  }

  Widget _buildCategorySelector() {
    String label = "Category (All)";
    if (_catId != null && _catId!.isNotEmpty) {
      final found = widget.categories.firstWhere((e) => e['id'] == _catId, orElse: () => {});
      if (found.isNotEmpty) label = found['label'];
    }

    return Column(
      children: [
        GestureDetector(
          onTap: () => setState(() {
            _isCategoryExpanded = !_isCategoryExpanded;
            _isProvinceExpanded = false;
            _isWardExpanded = false;
          }),
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
                Text(label, style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600)),
                const Spacer(),
                Icon(_isCategoryExpanded ? HeroiconsOutline.chevronUp : HeroiconsOutline.chevronDown, size: 16, color: Colors.white),
              ],
            ),
          ),
        ),
        if (_isCategoryExpanded)
          Container(
            margin: const EdgeInsets.only(top: 8),
            height: 180,
            decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.grey.shade200)
            ),
            child: ListView.separated(
              padding: const EdgeInsets.all(8),
              itemCount: widget.categories.length,
              separatorBuilder: (_, __) => const Divider(height: 1, color: Colors.black12),
              itemBuilder: (context, index) {
                final cat = widget.categories[index];
                final isSelected = _catId == cat['id'];
                return InkWell(
                  onTap: () {
                    setState(() {
                      _catId = cat['id'];
                      _isCategoryExpanded = false;
                    });
                  },
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
                    child: Row(
                      children: [
                        Icon(cat['icon'], size: 18, color: isSelected ? AppColors.ButtonBlackColor : Colors.black54),
                        const SizedBox(width: 10),
                        Text(
                            cat['label'],
                            style: TextStyle(
                                fontSize: 13,
                                fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                                color: isSelected ? AppColors.ButtonBlackColor : Colors.black87
                            )
                        ),
                        if (isSelected) const Spacer(),
                        if (isSelected) const Icon(Icons.check, size: 16, color: Colors.green),
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