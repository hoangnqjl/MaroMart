import 'package:flutter/material.dart';
import 'package:heroicons_flutter/heroicons_flutter.dart';
import 'package:intl/intl.dart';
import 'package:maromart/Colors/AppColors.dart';
import 'package:maromart/models/Conversation/Conversation.dart';
import 'package:maromart/models/User/ChatPartner.dart';
import 'package:maromart/models/User/User.dart';
import 'package:maromart/screens/Message/ChatScreen.dart';
import 'package:maromart/services/chat_service.dart';
import 'package:maromart/services/user_service.dart';
import 'package:maromart/utils/storage.dart';
import 'package:maromart/utils/constants.dart';
import 'package:cached_network_image/cached_network_image.dart';

class MessageScreen extends StatefulWidget {
  const MessageScreen({super.key});

  @override
  State<MessageScreen> createState() => _MessageScreenState();
}

class _MessageScreenState extends State<MessageScreen> {
  final ChatService _chatService = ChatService();
  final UserService _userService = UserService();

  int _selectedTab = 0;
  List<Conversation> _conversations = [];
  bool _isLoading = true;
  String? _currentUserId;

  // SELECTION MODE
  bool _isSelectionMode = false;
  Set<String> _selectedConversations = {};

  @override
  void initState() {
    super.initState();
    _currentUserId = StorageHelper.getUserId();
    _fetchConversations();
  }

  String _getFullUrl(String? path) {
    if (path == null || path.isEmpty) return '';
    if (path.startsWith('http')) return path;
    return '${ApiConstants.baseUrl}$path';
  }

  Future<void> _fetchConversations() async {
    try {
      final data = await _chatService.getConversations();
      if (mounted) {
        setState(() {
          _conversations = data;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        print('Lỗi tải tin nhắn: $e');
      }
    }
  }

  // DELETE CONVERSATIONS
  Future<void> _deleteSelectedConversations() async {
    if (_selectedConversations.isEmpty) return;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Conversations'),
        content: Text('Delete ${_selectedConversations.length} conversation(s)?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);

              setState(() => _isLoading = true);

              try {
                for (String conId in _selectedConversations) {
                  await _chatService.deleteConversation(conId);
                }

                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Deleted successfully')),
                  );
                }

                await _fetchConversations();

                setState(() {
                  _isSelectionMode = false;
                  _selectedConversations.clear();
                });

              } catch (e) {
                if (mounted) {
                  setState(() => _isLoading = false);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Error: $e')),
                  );
                }
              }
            },
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
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
    conv.latestMessage != null && conv.latestMessage!.sender != _currentUserId
    );
  }

  @override
  Widget build(BuildContext context) {
    final displayList = _filteredConversations;

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 16),

            // HEADER
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // TABS hoặc CANCEL
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
                        Text(
                          '${_selectedConversations.length} selected',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    )
                  else
                    Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: AppColors.E2Color,
                        borderRadius: BorderRadius.circular(30),
                      ),
                      child: Row(
                        children: [
                          _buildTabButton(0, "All"),
                          _buildTabButton(1, "New", hasDot: _hasNewMessages),
                        ],
                      ),
                    ),

                  // DELETE BUTTON
                  if (_isSelectionMode && _selectedConversations.isNotEmpty)
                    GestureDetector(
                      onTap: _deleteSelectedConversations,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                        decoration: BoxDecoration(
                          color: Colors.red,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: const Text(
                          'Delete',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    )
                  else
                    GestureDetector(
                      onTap: () {
                        setState(() {
                          _isSelectionMode = !_isSelectionMode;
                          _selectedConversations.clear();
                        });
                      },
                      child: _buildCircleButton(
                        HeroiconsOutline.trash,
                        isTransparent: false,
                      ),
                    ),
                ],
              ),
            ),

            // CONVERSATION LIST
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : displayList.isEmpty
                  ? Center(
                child: Text(
                  _selectedTab == 0
                      ? "No conversations yet"
                      : "No new messages",
                  style: const TextStyle(color: Colors.grey),
                ),
              )
                  : RefreshIndicator(
                onRefresh: _fetchConversations,
                child: ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: displayList.length,
                  itemBuilder: (context, index) {
                    final conv = displayList[index];

                    if (conv.partnerInfo == null) {
                      return _buildLoadingItem();
                    }

                    return _buildConversationItem(conv);
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLoadingItem() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        children: [
          Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                  color: Colors.grey[300],
                  shape: BoxShape.circle
              )
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                    width: 120,
                    height: 14,
                    decoration: BoxDecoration(
                        color: Colors.grey[300],
                        borderRadius: BorderRadius.circular(4)
                    )
                ),
                const SizedBox(height: 8),
                Container(
                    width: 200,
                    height: 12,
                    decoration: BoxDecoration(
                        color: Colors.grey[200],
                        borderRadius: BorderRadius.circular(4)
                    )
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCircleButton(IconData icon, {bool isTransparent = true}) {
    return Container(
      width: 44,
      height: 44,
      decoration: BoxDecoration(
        color: isTransparent ? AppColors.E2Color : Colors.white,
        shape: BoxShape.circle,
        border: isTransparent ? null : Border.all(color: Colors.grey.shade300),
      ),
      child: Icon(icon, color: Colors.black, size: 22),
    );
  }

  Widget _buildTabButton(int index, String text, {bool hasDot = false}) {
    final isSelected = _selectedTab == index;
    return GestureDetector(
      onTap: () => setState(() => _selectedTab = index),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? Colors.black : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          children: [
            Text(
              text,
              style: TextStyle(
                color: isSelected ? Colors.white : Colors.black,
                fontWeight: FontWeight.w600,
                fontSize: 13,
              ),
            ),
            if (hasDot && !isSelected)
              Container(
                margin: const EdgeInsets.only(left: 4),
                width: 6,
                height: 6,
                decoration: const BoxDecoration(
                    color: Colors.red,
                    shape: BoxShape.circle
                ),
              )
          ],
        ),
      ),
    );
  }

  Widget _buildConversationItem(Conversation item) {
    String lastMsg = "Start a conversation";
    String time = "";
    bool isNew = false;

    final partner = item.partnerInfo;
    if (partner == null) {
      return const SizedBox();
    }

    if (item.latestMessage != null) {
      final msgContent = item.latestMessage!.content;
      final msgMedia = item.latestMessage!.media;

      if (msgContent != null && msgContent.isNotEmpty) {
        lastMsg = msgContent;
      } else if (msgMedia.isNotEmpty) {
        if (msgMedia[0].type == 'image') lastMsg = "Sent an image";
        else if (msgMedia[0].type == 'video') lastMsg = "Sent a video";
        else lastMsg = "Sent a file";
      }

      time = DateFormat('HH:mm').format(item.latestMessage!.createdAt.toLocal());

      if (item.latestMessage!.sender != _currentUserId) {
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
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.E2Color : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            // CHECKBOX (if selection mode)
            if (_isSelectionMode)
              Padding(
                padding: const EdgeInsets.only(right: 12),
                child: Container(
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: isSelected ? Colors.blue : Colors.grey,
                      width: 2,
                    ),
                    color: isSelected ? Colors.blue : Colors.transparent,
                  ),
                  child: isSelected
                      ? const Icon(Icons.check, size: 16, color: Colors.white)
                      : null,
                ),
              ),

            _buildAvatar(partner.avatarUrl, partner.fullName),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    partner.fullName,
                    style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 14
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    lastMsg,
                    style: TextStyle(
                      color: isNew ? Colors.black : Colors.grey,
                      fontWeight: isNew ? FontWeight.bold : FontWeight.normal,
                      fontSize: 12,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),

            if (!_isSelectionMode)
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                      time,
                      style: TextStyle(
                          color: isNew ? Colors.black : Colors.grey,
                          fontWeight: isNew ? FontWeight.bold : FontWeight.normal,
                          fontSize: 11
                      )
                  ),
                  if (isNew)
                    Container(
                      margin: const EdgeInsets.only(top: 4),
                      width: 8,
                      height: 8,
                      decoration: const BoxDecoration(
                        color: Colors.blue,
                        shape: BoxShape.circle,
                      ),
                    )
                ],
              ),
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
        width: 52,
        height: 52,
        decoration: BoxDecoration(
            color: Colors.grey[200],
            shape: BoxShape.circle
        ),
        child: fullUrl.isNotEmpty
            ? CachedNetworkImage(
          imageUrl: fullUrl,
          fit: BoxFit.cover,
          placeholder: (context, url) => const Center(
            child: SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
          ),
          errorWidget: (context, url, error) => _buildLetterAvatar(name),
        )
            : _buildLetterAvatar(name),
      ),
    );
  }

  Widget _buildLetterAvatar(String name) {
    String firstLetter = name.isNotEmpty ? name[0].toUpperCase() : 'U';

    return Container(
      width: 52,
      height: 52,
      decoration: const BoxDecoration(
        color: Colors.blueAccent,
        shape: BoxShape.circle,
      ),
      alignment: Alignment.center,
      child: Text(
        firstLetter,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 20,
          fontWeight: FontWeight.bold,
          fontFamily: 'QuickSand',
        ),
      ),
    );
  }
}