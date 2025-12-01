import 'package:flutter/material.dart';
import 'package:heroicons_flutter/heroicons_flutter.dart';
import 'package:maromart/Colors/AppColors.dart';
import 'package:maromart/components/ButtonWithIcon.dart';
import 'package:maromart/components/Filter.dart';
import 'package:maromart/components/ModalInAvt.dart';
import 'package:maromart/models/User/User.dart';

class TopBar extends StatefulWidget implements PreferredSizeWidget {
  final User? user;

  final Function(String? categoryId, String? province, String? ward)? onFilterSelected;

  const TopBar({Key? key, this.user, this.onFilterSelected}) : super(key: key);

  @override
  Size get preferredSize => const Size.fromHeight(60);

  @override
  State<TopBar> createState() => _TopBarState();
}

class _TopBarState extends State<TopBar> {
  final GlobalKey<ModalInAvtState> _modalKey = GlobalKey<ModalInAvtState>();

  late FilterOverlay _filterOverlay;

  @override
  void initState() {
    super.initState();
    _filterOverlay = FilterOverlay(
      onFilterApplied: (categoryId, province, ward) {
        if (widget.onFilterSelected != null) {
          widget.onFilterSelected!(categoryId, province, ward);
        }
      },
    );
  }

  String get _displayName {
    if (widget.user?.fullName != null && widget.user!.fullName.isNotEmpty) {
      return widget.user!.fullName;
    }
    return widget.user?.email ?? 'Khách';
  }

  @override
  Widget build(BuildContext context) {
    final String avatarUrl = widget.user?.avatarUrl ?? '';

    return Stack(
      children: [
        Container(
          color: Colors.white,
          width: MediaQuery.of(context).size.width,
          padding: const EdgeInsets.only(top: 16, bottom: 4, left: 18, right: 18),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  GestureDetector(
                    onTap: () {
                      _modalKey.currentState?.show(context);
                    },
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(100),
                      child: Container(
                        width: 36,
                        height: 36,
                        color: Colors.grey.shade200,
                        child: _buildSafeAvatar(avatarUrl),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    _displayName,
                    style: const TextStyle(
                      fontSize: 13,
                      fontFamily: 'QuickSand',
                      fontWeight: FontWeight.w700,
                      color: Colors.black,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  )
                ],
              ),

              Row(
                children: [
                  CompositedTransformTarget(
                    link: _filterOverlay.layerLink,
                    child: ButtonWithIcon(
                      icon: HeroiconsOutline.adjustmentsHorizontal,
                      onPressed: () {
                        _filterOverlay.toggle(context);
                      },
                      size: 38,
                      backgroundColor: AppColors.E2Color,
                      iconColor: Colors.black,
                      isSelected: true,
                    ),
                  ),

                  const SizedBox(width: 10),

                  ButtonWithIcon(
                    icon: HeroiconsOutline.plus,
                    onPressed: () {
                      Navigator.pushNamed(context, '/add_product');
                    },
                    size: 38,
                    backgroundColor: AppColors.E2Color,
                    iconColor: Colors.black,
                    isSelected: false,
                  )
                ],
              )
            ],
          ),
        ),

        ModalInAvt(key: _modalKey),
      ],
    );
  }

  // --- CÁC HÀM HỖ TRỢ (GIỮ NGUYÊN) ---
  Widget _buildLetterAvatar() {
    String name = _displayName;
    String firstLetter = name.isNotEmpty ? name[0].toUpperCase() : 'U';

    return Container(
      width: double.infinity,
      height: double.infinity,
      decoration: const BoxDecoration(
        color: Colors.blueAccent,
      ),
      alignment: Alignment.center,
      child: Text(
        firstLetter,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 16,
          fontWeight: FontWeight.bold,
          fontFamily: 'QuickSand',
          decoration: TextDecoration.none,
        ),
      ),
    );
  }

  Widget _buildSafeAvatar(String url) {
    if (url.isEmpty) {
      return _buildLetterAvatar();
    }
    return Image.network(
      url,
      fit: BoxFit.cover,
      errorBuilder: (context, error, stackTrace) {
        return _buildLetterAvatar();
      },
      loadingBuilder: (context, child, loadingProgress) {
        if (loadingProgress == null) return child;
        return const Center(
          child: SizedBox(
            width: 15,
            height: 15,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
        );
      },
    );
  }
}