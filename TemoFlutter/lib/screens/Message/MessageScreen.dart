import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:temo/Colors/AppColors.dart';
import 'package:intl/intl.dart';
import 'package:temo/Colors/AppColors.dart';
import 'package:temo/models/Conversation/Conversation.dart';
import 'package:temo/models/Message/Message.dart';
import 'package:temo/models/User/ChatPartner.dart';
import 'package:temo/models/User/User.dart';
import 'package:temo/screens/Message/ChatScreen.dart';
import 'package:temo/services/chat_service.dart';
import 'package:temo/services/user_service.dart';
import 'package:temo/services/socket_service.dart';
import 'package:temo/utils/storage.dart';
import 'package:temo/utils/constants.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:heroicons_flutter/heroicons_flutter.dart';
import 'package:temo/components/Skeletons/ListTileSkeleton.dart';
import 'package:temo/components/Skeleton.dart';
import 'package:temo/components/FloatingHeader.dart';
import 'package:temo/components/PremiumTabSwitcher.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:temo/utils/ui_helpers.dart';
import 'package:temo/utils/UIHelper.dart';
import 'package:temo/utils/string_utils.dart';


class MessageScreen extends StatefulWidget {
  final VoidCallback? onMenuTap;
  const MessageScreen({super.key, this.onMenuTap});

  @override
  State<MessageScreen> createState() => _MessageScreenState();
}

class _MessageScreenState extends State<MessageScreen> {
  final ChatService _chatService = ChatService();
  final UserService _userService = UserService();
  final SocketService _socketService = SocketService();
  final Color primaryThemeColor = AppColors.primary;

  int _selectedTab = 0;
  List<Conversation> _conversations = [];
  bool _isLoading = true;
  String? _currentUserId;

  bool _isSelectionMode = false;
  Set<String> _selectedConversations = {};
  
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchBarFocusNode = FocusNode();
  String _searchQuery = "";
  User? _currentUserProfile;

  @override
  void initState() {
    super.initState();
    _currentUserId = StorageHelper.getUserId();
    _fetchConversations();
    _initSocketListeners();
    _fetchCurrentUser();
    _searchBarFocusNode.addListener(() {
      if (mounted) setState(() {});
    });
    _searchController.addListener(() {
      setState(() => _searchQuery = _searchController.text.toLowerCase());
    });
  }

  Future<void> _fetchCurrentUser() async {
    try {
      final user = await _userService.getCurrentUser();
      if (mounted) setState(() => _currentUserProfile = user);
    } catch (e) {}
  }

  void _initSocketListeners() {
    if (!_socketService.isConnected) {
      _socketService.connect();
    }

    void handleSocketData(Map<String, dynamic> data) {
      if (data['new_message'] != null) {
        try {
          final message = Message.fromJson(data['new_message']);
          _updateConversationList(message);
        } catch (e) {}
      }
    }
    _socketService.onNewMessage = handleSocketData;
    _socketService.onMessageSent = handleSocketData;
  }

  void _updateConversationList(Message message) {
    if (!mounted) return;

    setState(() {
      final index = _conversations.indexWhere((c) => c.conId == message.conId);
      if (index != -1) {
        Conversation conv = _conversations[index];
        conv.latestMessage = message;
        _conversations.removeAt(index);
        _conversations.insert(0, conv);
      } else {
        _fetchConversations();
      }
    });
  }



  Future<void> _fetchConversations() async {
    if (_conversations.isEmpty) setState(() => _isLoading = true);

    try {
      final data = await _chatService.getConversations();
      final validConversations = data.where((conv) => conv.partnerInfo != null).toList();

      if (mounted) {
        setState(() {
          _conversations = validConversations;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _deleteSelectedConversations() async {
    if (_selectedConversations.isEmpty) return;

    final confirmed = await UIHelpers.confirmDialog(
      context,
      title: "Xóa cuộc trò chuyện",
      message: "Bạn có chắc chắn muốn xóa ${_selectedConversations.length} cuộc trò chuyện này không? Hành động này không thể hoàn tác.",
      confirmText: "Xóa ngay",
      cancelText: "Hủy",
    );

    if (confirmed == true) {
      setState(() => _isLoading = true);
      try {
        for (String conId in _selectedConversations) {
          await _chatService.deleteConversation(conId);
        }
        
        UIHelpers.showSuccessSnackBar(context, "Đã xóa các cuộc trò chuyện được chọn");
        setState(() {
          _isSelectionMode = false;
          _selectedConversations.clear();
        });
        _fetchConversations();
      } catch (e) {
        UIHelpers.showErrorSnackBar(context, "Lỗi khi xóa: $e");
        setState(() => _isLoading = false);
      }
    }
  }

  void _toggleSelection(String conId) {
    setState(() {
      if (_selectedConversations.contains(conId)) {
        _selectedConversations.remove(conId);
      } else {
        _selectedConversations.add(conId);
      }
    });
  }

  @override
  void dispose() {
    _searchBarFocusNode.dispose();
    _searchController.dispose();
    super.dispose();
  }

  List<Conversation> get _filteredConversations {
    List<Conversation> filtered = _conversations;
    
    // Lọc theo Tab/Filter icon
    if (_selectedTab == 1) {
      // Chưa đọc: Tin nhắn cuối cùng không phải của mình
      filtered = filtered.where((conv) => 
        conv.latestMessage != null && conv.latestMessage!.sender != _currentUserId
      ).toList();
    } else if (_selectedTab == 2) {
      // Đã đọc (hoặc mình đã trả lời): Tin nhắn cuối cùng là của mình
      filtered = filtered.where((conv) => 
        conv.latestMessage != null && conv.latestMessage!.sender == _currentUserId
      ).toList();
    } else if (_selectedTab == 3) {
      // Mới nhất: Tin nhắn trong 24h qua
      final oneDayAgo = DateTime.now().subtract(const Duration(hours: 24));
      filtered = filtered.where((conv) => 
        conv.latestMessage != null && conv.latestMessage!.createdAt.isAfter(oneDayAgo)
      ).toList();
    }
    
    // Lọc theo Tìm kiếm
    if (_searchQuery.isNotEmpty) {
      filtered = filtered.where((conv) {
        final name = conv.partnerInfo?.fullName.toLowerCase() ?? "";
        return name.contains(_searchQuery);
      }).toList();
    }
    
    return filtered;
  }

  bool get _hasNewMessages {
    return _conversations.any((conv) =>
    conv.latestMessage != null &&
        conv.latestMessage!.sender != _currentUserId
    );
  }

  @override
  Widget build(BuildContext context) {
    final displayList = _filteredConversations;

    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          Column(
            children: [
              const SizedBox(height: 150), 
              if (_isSelectionMode)
                Padding(
                  padding: const EdgeInsets.only(left: 16, right: 16, top: 24, bottom: 12),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          IconButton(
                            icon: const Icon(Icons.close),
                            onPressed: () {
                              setState(() {
                                _isSelectionMode = false;
                                _selectedConversations.clear();
                              });
                            },
                          ),
                          Text('${_selectedConversations.length} đã chọn', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                        ],
                      ),
                      if (_selectedConversations.isNotEmpty)
                        IconButton(
                          icon: const Icon(HeroiconsOutline.trash, color: Colors.red, size: 24),
                          onPressed: _deleteSelectedConversations,
                        ),
                    ],
                  ),
                ),
              Expanded(
                child: _isLoading
                    ? ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        itemCount: 8,
                        itemBuilder: (context, index) => const ListTileSkeleton(),
                      )
                    : displayList.isEmpty
                    ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(HeroiconsOutline.chatBubbleLeftRight, size: 64, color: Colors.grey[200]),
                          const SizedBox(height: 16),
                          Text(
                            _selectedTab == 0 ? "Chưa có cuộc trò chuyện nào" : "Không có tin nhắn mới",
                            style: GoogleFonts.roboto(
                              color: Colors.grey[400],
                              fontSize: 15,
                              fontWeight: FontWeight.w500
                            ),
                          ),
                        ],
                      ),
                    )
                    : RefreshIndicator(
                  onRefresh: _fetchConversations,
                  color: primaryThemeColor,
                  child: ListView.builder(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 40),
                    itemCount: displayList.length,
                    itemBuilder: (context, index) {
                      final conv = displayList[index];
                      return _buildConversationItem(conv);
                    },
                  ),
                ),
              ),
            ],
          ),
          Positioned(
            top: 0, left: 0, right: 0,
            child: _buildCustomHeader(),
          ),
        ],
      ),
    );
  }

  Widget _buildCustomHeader() {
    return Container(
      color: Colors.white,
      child: SafeArea(
        bottom: false,
        child: Column(
          children: [
            FloatingHeader(
              title: "Chats",
              isMenu: true,
              hasBackground: false,
              onMenuTap: () => widget.onMenuTap?.call(),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 0),
              actions: [
                FloatingHeader.buildActionBubble(
                  icon: HeroiconsSolid.ellipsisVertical,
                  onTap: () => UIHelper.showOptionsMenu(context, screenName: "Tin nhắn"),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  Expanded(
                    child: Container(
                      height: 48,
                      decoration: BoxDecoration(
                        color: const Color(0xFFF3F4F6),
                        borderRadius: BorderRadius.circular(30),
                      ),
                      child: Row(
                        children: [
                          const SizedBox(width: 18),
                          Icon(HeroiconsOutline.magnifyingGlass, color: Colors.grey[400], size: 20),
                          const SizedBox(width: 12),
                          Expanded(
                            child: TextField(
                              controller: _searchController,
                              focusNode: _searchBarFocusNode,
                              decoration: InputDecoration(
                                hintText: "Tìm kiếm...",
                                hintStyle: GoogleFonts.quicksand(
                                  color: Colors.grey[400],
                                  fontSize: 15,
                                  fontWeight: FontWeight.w700,
                                ),
                                border: InputBorder.none,
                                isDense: true,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  PopupMenuButton<int>(
                    offset: const Offset(0, 52),
                    padding: EdgeInsets.zero,
                    color: Colors.white,
                    elevation: 10,
                    icon: Container(
                      width: 48, height: 48,
                      decoration: const BoxDecoration(
                        color: Color(0xFFF3F4F6),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(HeroiconsOutline.adjustmentsHorizontal, color: const Color(0xFF111827), size: 22),
                    ),
                  onSelected: (value) => setState(() => _selectedTab = value),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                  itemBuilder: (context) => [
                    _buildFilterMenuItem(0, "Tất cả", HeroiconsOutline.rectangleGroup, Colors.orange),
                    _buildFilterMenuItem(1, "Chưa đọc", HeroiconsOutline.envelopeOpen, Colors.blue),
                    _buildFilterMenuItem(2, "Đã đọc", HeroiconsOutline.checkBadge, Colors.green),
                    _buildFilterMenuItem(3, "Mới nhất", HeroiconsOutline.sparkles, Colors.purple),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
        ],
      ),
    ),
  );
}

  PopupMenuItem<int> _buildFilterMenuItem(int value, String label, IconData icon, Color color) {
    final isSelected = _selectedTab == value;
    return PopupMenuItem(
      value: value,
      height: 52,
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 18, color: color),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Text(
              label,
              style: GoogleFonts.quicksand(
                fontSize: 14,
                fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                color: color,
              ),
            ),
          ),
          if (isSelected)
            Icon(HeroiconsOutline.check, size: 18, color: color),
        ],
      ),
    );
  }

  Widget _buildUserAvatar() {
    final avatarUrl = _currentUserProfile?.avatarUrl;
    final fullName = _currentUserProfile?.fullName ?? "Tôi";
    
    return Container(
      width: 40, height: 40,
      decoration: BoxDecoration(
        color: Colors.grey[200],
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white, width: 2),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 4)
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: avatarUrl != null && avatarUrl.isNotEmpty
            ? CachedNetworkImage(
                imageUrl: StringUtils.normalizeUrl(avatarUrl),
                fit: BoxFit.cover,
                errorWidget: (context, url, error) => _buildLetterAvatar(fullName, size: 40),
              )
            : _buildLetterAvatar(fullName, size: 40),
      ),
    );
  }

  Widget _buildHeaderMenu() {
    return PopupMenuButton<String>(
      offset: const Offset(0, 55),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
      elevation: 8,
      icon: Container(
        width: 44, height: 44,
        decoration: BoxDecoration(
          color: Colors.white,
          shape: BoxShape.circle,
          border: Border.all(color: Colors.black.withOpacity(0.1), width: 1.5),
          boxShadow: [
            BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4))
          ],
        ),
        child: const Icon(HeroiconsOutline.ellipsisHorizontal, color: Colors.black87, size: 22),
      ),
      color: Colors.white,
      surfaceTintColor: Colors.white,
      onSelected: (value) {
        if (value == 'manage') {
          setState(() {
            _isSelectionMode = !_isSelectionMode;
            _selectedConversations.clear();
          });
        } else if (value.startsWith('filter_')) {
          final idx = int.parse(value.split('_')[1]);
          setState(() => _selectedTab = idx);
        } else if (value == 'delete_selected') {
          if (_selectedConversations.isNotEmpty) {
            _deleteSelectedConversations();
          }
        }
      },
      itemBuilder: (context) => [
        PopupMenuItem(
          value: 'filter_0',
          height: 60,
          child: _buildPopupItem(
            icon: HeroiconsOutline.rectangleGroup,
            label: "Tất cả tin nhắn",
            color: Colors.green,
            isSelected: _selectedTab == 0,
          ),
        ),
        PopupMenuItem(
          value: 'filter_1',
          height: 60,
          child: _buildPopupItem(
            icon: HeroiconsOutline.envelope,
            label: "Tin nhắn chưa đọc",
            color: AppColors.primary,
            isSelected: _selectedTab == 1,
          ),
        ),
        const PopupMenuDivider(),
        PopupMenuItem(
          value: 'manage',
          height: 60,
          child: _buildPopupItem(
            icon: _isSelectionMode ? HeroiconsOutline.xMark : HeroiconsOutline.checkCircle,
            label: _isSelectionMode ? "Hủy chọn" : "Quản lý tin nhắn",
            color: Colors.blueAccent,
          ),
        ),
        if (_isSelectionMode)
          PopupMenuItem(
            value: 'delete_selected',
            height: 60,
            enabled: _selectedConversations.isNotEmpty,
            child: _buildPopupItem(
              icon: HeroiconsOutline.trash,
              label: "Xóa đã chọn (${_selectedConversations.length})",
              color: _selectedConversations.isNotEmpty ? AppColors.accent : Colors.grey,
            ),
          ),
      ],
    );
  }

  Widget _buildPopupItem({
    required IconData icon,
    required String label,
    required Color color,
    bool isSelected = false,
  }) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 38, height: 38,
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            shape: BoxShape.circle,
            border: isSelected ? Border.all(color: color, width: 2) : null,
          ),
          child: Icon(icon, size: 20, color: color),
        ),
        const SizedBox(width: 14),
        Text(
          label,
          style: GoogleFonts.quicksand(
            fontSize: 14,
            fontWeight: isSelected ? FontWeight.w800 : FontWeight.w700,
            color: isSelected ? color : const Color(0xFF374151),
          ),
        ),
      ],
    );
  }

  Widget _buildCircleButton(IconData icon, {bool isTransparent = true}) {
    return Container(
      width: 44, height: 44,
      decoration: BoxDecoration(color: isTransparent ? AppColors.E2Color : Colors.white, shape: BoxShape.circle, border: isTransparent ? null : Border.all(color: Colors.grey.shade300)),
      child: Icon(icon, color: primaryThemeColor, size: 22),
    );
  }

  Widget _buildTabButton(int index, String text, {bool hasDot = false}) {
    final isSelected = _selectedTab == index;
    return GestureDetector(
      onTap: () => setState(() => _selectedTab = index),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
        decoration: BoxDecoration(color: isSelected ? primaryThemeColor : Colors.transparent, borderRadius: BorderRadius.circular(20)),
        child: Row(children: [Text(text, style: TextStyle(color: isSelected ? Colors.white : Colors.black, fontWeight: FontWeight.w600, fontSize: 13)), if (hasDot && !isSelected) Container(margin: const EdgeInsets.only(left: 4), width: 6, height: 6, decoration: const BoxDecoration(color: Colors.red, shape: BoxShape.circle))]),
      ),
    );
  }

  Widget _buildConversationItem(Conversation item) {
    String lastMsg = "Start a conversation";
    String time = "";
    bool isNew = false;
    final partner = item.partnerInfo!;

    if (item.latestMessage != null) {
      final msgContent = item.latestMessage!.content;
      final msgMedia = item.latestMessage!.media;
      if (msgContent != null && msgContent.isNotEmpty) {
        if (msgContent.startsWith("[[PRODUCT_CARD:")) {
          try {
            final jsonStr = msgContent.substring(15, msgContent.length - 2);
            final productData = jsonDecode(jsonStr);
            final pName = productData['productName'] ?? "Sản phẩm";
            lastMsg = "📦 [Đã xem] $pName";
          } catch (e) {
            lastMsg = "📦 [Sản phẩm]";
          }
        } else {
          lastMsg = msgContent;
        }
      } else if (msgMedia.isNotEmpty) {
        if (msgMedia[0].type == 'image') lastMsg = "Sent an image";
        else if (msgMedia[0].type == 'video') lastMsg = "Sent a video";
        else lastMsg = "Sent a file";
      }
      time = DateFormat('HH:mm').format(item.latestMessage!.createdAt.toLocal());
      
      // Tin nhắn mới chỉ khi: 1. Mình là người nhận AND 2. Nó chưa được đọc
      if (item.latestMessage!.sender != _currentUserId && !item.latestMessage!.isRead) {
        isNew = true;
      }
    }
    final isSelected = _selectedConversations.contains(item.conId);

    return GestureDetector(
      onTap: () async {
        if (_isSelectionMode) {
          _toggleSelection(item.conId);
        } else {
          await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => ChatScreen(
                conversationId: item.conId,
                partnerUser: ChatPartner.fromUser(partner),
              ),
            ),
          );
          _fetchConversations();
          _initSocketListeners();
        }
      },
      onLongPress: () {
        if (!_isSelectionMode) {
          setState(() {
            _isSelectionMode = true;
            _selectedConversations.add(item.conId);
          });
        }
      },
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
        margin: const EdgeInsets.only(bottom: 4),
        decoration: BoxDecoration(color: isSelected ? AppColors.E2Color : Colors.transparent, borderRadius: BorderRadius.circular(12)),
        child: Row(
          children: [
            if (_isSelectionMode) Padding(padding: const EdgeInsets.only(right: 12), child: Container(width: 24, height: 24, decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: isSelected ? Colors.blue : Colors.grey, width: 2), color: isSelected ? Colors.blue : Colors.transparent), child: isSelected ? const Icon(Icons.check, size: 16, color: Colors.white) : null)),
            _buildAvatar(partner.avatarUrl, partner.fullName),
            const SizedBox(width: 12),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(partner.fullName, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14)), const SizedBox(height: 4), Text(lastMsg, style: TextStyle(color: isNew ? Colors.black : Colors.grey, fontWeight: isNew ? FontWeight.bold : FontWeight.normal, fontSize: 12), maxLines: 1, overflow: TextOverflow.ellipsis)])),
            if (!_isSelectionMode) Column(crossAxisAlignment: CrossAxisAlignment.end, children: [Text(time, style: TextStyle(color: isNew ? Colors.black : Colors.grey, fontWeight: isNew ? FontWeight.bold : FontWeight.normal, fontSize: 11)), if (isNew) Container(margin: const EdgeInsets.only(top: 4), width: 8, height: 8, decoration: BoxDecoration(color: primaryThemeColor, shape: BoxShape.circle))]),
          ],
        ),
      ),
    );
  }

  Widget _buildAvatar(String? avatarUrl, String name) {
    final fullUrl = StringUtils.normalizeUrl(avatarUrl);
    return ClipRRect(
      borderRadius: BorderRadius.circular(26),
      child: Container(
        width: 52, height: 52,
        decoration: BoxDecoration(color: Colors.grey[200], shape: BoxShape.circle),
        child: fullUrl.isNotEmpty
            ? fullUrl.startsWith('assets/')
                ? Image.asset(fullUrl, fit: BoxFit.cover)
                : CachedNetworkImage(
                    imageUrl: fullUrl,
                    fit: BoxFit.cover,
                    placeholder: (context, url) => const CircleSkeleton(size: 52),
                    errorWidget: (context, url, error) => _buildLetterAvatar(name),
                  )
            : _buildLetterAvatar(name),
      ),
    );
  }

  Widget _buildLetterAvatar(String name, {double size = 52}) {
    String firstLetter = name.isNotEmpty ? name[0].toUpperCase() : 'U';
    return Container(width: size, height: size, decoration: BoxDecoration(color: primaryThemeColor.withOpacity(0.1), shape: BoxShape.circle), alignment: Alignment.center, child: Text(firstLetter, style: TextStyle(color: primaryThemeColor, fontSize: size * 0.4, fontWeight: FontWeight.bold, fontFamily: 'QuickSand')));
  }
}