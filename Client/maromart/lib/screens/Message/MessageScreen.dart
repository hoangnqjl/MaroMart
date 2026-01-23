import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:maromart/Colors/AppColors.dart';
import 'package:maromart/models/Conversation/Conversation.dart';
import 'package:maromart/models/Message/Message.dart';
import 'package:maromart/models/User/ChatPartner.dart';
import 'package:maromart/screens/Message/ChatScreen.dart';
import 'package:maromart/services/chat_service.dart';
import 'package:maromart/services/user_service.dart';
import 'package:maromart/services/socket_service.dart';
import 'package:maromart/utils/storage.dart';
import 'package:maromart/utils/constants.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:heroicons_flutter/heroicons_flutter.dart';
import 'package:maromart/components/ModernLoader.dart';

class MessageScreen extends StatefulWidget {
  const MessageScreen({super.key});

  @override
  State<MessageScreen> createState() => _MessageScreenState();
}

class _MessageScreenState extends State<MessageScreen> {
  final ChatService _chatService = ChatService();
  final UserService _userService = UserService();
  final SocketService _socketService = SocketService();
  final Color primaryThemeColor = const Color(0xFF3F4045);

  int _selectedTab = 0;
  List<Conversation> _conversations = [];
  bool _isLoading = true;
  String? _currentUserId;

  bool _isSelectionMode = false;
  Set<String> _selectedConversations = {};

  @override
  void initState() {
    super.initState();
    _currentUserId = StorageHelper.getUserId();
    _fetchConversations();
    _initSocketListeners();
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

  String _getFullUrl(String? path) {
    if (path == null || path.isEmpty) return '';
    if (path.startsWith('http')) return path;
    return '${ApiConstants.baseUrl}$path';
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

  List<Conversation> get _filteredConversations {
    if (_selectedTab == 0) {
      return _conversations;
    } else {
      return _conversations.where((conv) {
        if (conv.latestMessage == null) return false;
        return conv.latestMessage!.sender != _currentUserId;
      }).toList();
    }
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
      body: Column(
        children: [
          const SizedBox(height: 10),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                if (_isSelectionMode)
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
                      Text('${_selectedConversations.length} selected', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                    ],
                  )
                else
                  Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(color: AppColors.E2Color, borderRadius: BorderRadius.circular(30)),
                    child: Row(children: [_buildTabButton(0, "All"), _buildTabButton(1, "New", hasDot: _hasNewMessages)]),
                  ),

                if (_isSelectionMode && _selectedConversations.isNotEmpty)
                  GestureDetector(onTap: _deleteSelectedConversations, child: Container(padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10), decoration: BoxDecoration(color: Colors.red, borderRadius: BorderRadius.circular(20)), child: const Text('Delete', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600))))
                else
                  GestureDetector(onTap: () => setState(() { _isSelectionMode = !_isSelectionMode; _selectedConversations.clear(); }), child: _buildCircleButton(HeroiconsOutline.trash, isTransparent: false)),
              ],
            ),
          ),

          Expanded(
            child: _isLoading
                ? Center(child: ModernLoader(color: primaryThemeColor))
                : displayList.isEmpty
                ? Center(child: Text(_selectedTab == 0 ? "No conversations yet" : "No new messages", style: TextStyle(color: Colors.grey[400])))
                : RefreshIndicator(
              onRefresh: _fetchConversations,
              color: primaryThemeColor,
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 16),
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
      if (msgContent != null && msgContent.isNotEmpty) lastMsg = msgContent;
      else if (msgMedia.isNotEmpty) {
        if (msgMedia[0].type == 'image') lastMsg = "Sent an image";
        else if (msgMedia[0].type == 'video') lastMsg = "Sent a video";
        else lastMsg = "Sent a file";
      }
      time = DateFormat('HH:mm').format(item.latestMessage!.createdAt.toLocal());
      if (item.latestMessage!.sender != _currentUserId) isNew = true;
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
    final fullUrl = _getFullUrl(avatarUrl);
    return ClipRRect(
      borderRadius: BorderRadius.circular(26),
      child: Container(
        width: 52, height: 52,
        decoration: BoxDecoration(color: Colors.grey[200], shape: BoxShape.circle),
        child: fullUrl.isNotEmpty
            ? CachedNetworkImage(imageUrl: fullUrl, fit: BoxFit.cover, placeholder: (context, url) => Center(child: SizedBox(width: 20, height: 20, child: ModernLoader(size: 20, color: primaryThemeColor))), errorWidget: (context, url, error) => _buildLetterAvatar(name))
            : _buildLetterAvatar(name),
      ),
    );
  }

  Widget _buildLetterAvatar(String name) {
    String firstLetter = name.isNotEmpty ? name[0].toUpperCase() : 'U';
    return Container(width: 52, height: 52, decoration: BoxDecoration(color: primaryThemeColor.withOpacity(0.1), shape: BoxShape.circle), alignment: Alignment.center, child: Text(firstLetter, style: TextStyle(color: primaryThemeColor, fontSize: 20, fontWeight: FontWeight.bold, fontFamily: 'QuickSand')));
  }
}