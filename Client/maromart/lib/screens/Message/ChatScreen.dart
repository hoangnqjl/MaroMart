import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:heroicons_flutter/heroicons_flutter.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:maromart/Colors/AppColors.dart';
import 'package:maromart/models/Message/Message.dart';
import 'package:maromart/models/User/ChatPartner.dart';
import 'package:maromart/services/chat_service.dart';
import 'package:maromart/utils/storage.dart';
import 'package:maromart/utils/constants.dart';

class ChatScreen extends StatefulWidget {
  final String conversationId;
  final ChatPartner partnerUser;

  const ChatScreen({
    super.key,
    required this.conversationId,
    required this.partnerUser,
  });

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final ChatService _chatService = ChatService();
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final ImagePicker _picker = ImagePicker();

  List<Message> _messages = [];
  List<XFile> _selectedImages = [];
  List<XFile> _selectedVideos = [];
  List<XFile> _selectedAudios = [];

  bool _isLoading = true;
  bool _isSending = false;
  String? _currentUserId;
  late String _currentConId;

  @override
  void initState() {
    super.initState();
    _currentConId = widget.conversationId;
    _currentUserId = StorageHelper.getUserId();

    if (_currentConId.isNotEmpty) {
      _fetchMessages();
    } else {
      setState(() => _isLoading = false);
    }
  }

  String _getFullUrl(String? path) {
    if (path == null || path.isEmpty) return '';
    if (path.startsWith('http')) return path;
    return '${ApiConstants.baseUrl}$path';
  }

  Future<void> _fetchMessages() async {
    if (_currentConId.isEmpty) return;
    try {
      final msgs = await _chatService.getMessages(_currentConId);
      if (mounted) {
        setState(() {
          _messages = msgs;
          _isLoading = false;
        });
        WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToBottom());
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  // --- MENU OPTION (Modal Bottom Sheet) ---

  void _showChatOptions(BuildContext context) {
    // Chỉ hiện option nếu đã có cuộc hội thoại (có ID)
    if (_currentConId.isEmpty) return;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (BuildContext ctx) {
        return Container(
          padding: const EdgeInsets.all(20),
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(25),
              topRight: Radius.circular(25),
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 20),
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),

              // Nút Block (Ví dụ thêm tính năng này sau)
              // _buildOptionButton(
              //   icon: HeroiconsOutline.noSymbol, // Icon cấm
              //   label: 'Block user',
              //   iconColor: Colors.black87,
              //   bgColor: const Color(0xFFF5F5F5),
              //   onTap: () {
              //     Navigator.pop(ctx);
              //     // TODO: Implement Block logic
              //     ScaffoldMessenger.of(context).showSnackBar(
              //       const SnackBar(content: Text("Block feature coming soon")),
              //     );
              //   },
              // ),

              // const SizedBox(height: 12),

              // Nút Delete Conversation (Màu đỏ nhạt)
              _buildOptionButton(
                icon: HeroiconsOutline.trash,
                label: 'Delete conversation',
                iconColor: Colors.red,
                bgColor: const Color(0xFFFCEEEB),
                onTap: () {
                  Navigator.pop(ctx);
                  _confirmDeleteConversation();
                },
              ),
              const SizedBox(height: 10),
            ],
          ),
        );
      },
    );
  }

  Widget _buildOptionButton({
    required IconData icon,
    required String label,
    required Color iconColor,
    required Color bgColor,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(30),
          border: Border.all(color: Colors.grey.shade200),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
            )
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: bgColor,
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: iconColor, size: 20),
            ),
            const SizedBox(width: 16),
            Text(
              label,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // --- XỬ LÝ XÓA ---

  void _confirmDeleteConversation() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Delete Conversation"),
        content: const Text("Are you sure you want to delete this conversation? This action cannot be undone."),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text("Cancel", style: TextStyle(color: Colors.grey)),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              _deleteConversation();
            },
            child: const Text("Delete", style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteConversation() async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => const Center(child: CircularProgressIndicator()),
    );

    try {
      await _chatService.deleteConversation(_currentConId);

      if (mounted) {
        Navigator.pop(context); // Tắt loading
        Navigator.pop(context); // Thoát khỏi màn hình Chat
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Conversation deleted"), backgroundColor: Colors.green),
        );
      }
    } catch (e) {
      if (mounted) {
        Navigator.pop(context); // Tắt loading
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Failed to delete: $e"), backgroundColor: Colors.red),
        );
      }
    }
  }

  // --- CÁC HÀM CHỌN FILE & GỬI TIN NHẮN (GIỮ NGUYÊN) ---
  Future<void> _showAttachmentOptions() async {
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        height: 220,
        child: Column(
          children: [
            ListTile(
              leading: const Icon(Icons.photo_library, color: Colors.blue),
              title: const Text('Image'),
              onTap: () { Navigator.pop(context); _pickImages(); },
            ),
            ListTile(
              leading: const Icon(Icons.video_library, color: Colors.red),
              title: const Text('Video'),
              onTap: () { Navigator.pop(context); _pickVideo(); },
            ),
            ListTile(
              leading: const Icon(Icons.audiotrack, color: Colors.purple),
              title: const Text('Audio'),
              onTap: () { Navigator.pop(context); _pickAudio(); },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _pickImages() async {
    final List<XFile> images = await _picker.pickMultiImage();
    if (images.isNotEmpty) setState(() => _selectedImages.addAll(images));
  }

  Future<void> _pickVideo() async {
    final XFile? video = await _picker.pickVideo(source: ImageSource.gallery);
    if (video != null) setState(() => _selectedVideos.add(video));
  }

  Future<void> _pickAudio() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(type: FileType.audio, allowMultiple: true);
    if (result != null) {
      setState(() {
        _selectedAudios.addAll(result.paths.map((path) => XFile(path!)).toList());
      });
    }
  }

  void _removeAttachment(int index, String type) {
    setState(() {
      if (type == 'image') _selectedImages.removeAt(index);
      else if (type == 'video') _selectedVideos.removeAt(index);
      else if (type == 'audio') _selectedAudios.removeAt(index);
    });
  }

  Future<void> _handleSend() async {
    final text = _messageController.text.trim();
    if ((text.isEmpty && _selectedImages.isEmpty && _selectedVideos.isEmpty && _selectedAudios.isEmpty) || _isSending) return;

    setState(() => _isSending = true);

    final imagesToSend = List<XFile>.from(_selectedImages);
    final videosToSend = List<XFile>.from(_selectedVideos);
    final audiosToSend = List<XFile>.from(_selectedAudios);

    _messageController.clear();
    setState(() {
      _selectedImages.clear();
      _selectedVideos.clear();
      _selectedAudios.clear();
    });

    if (text.isNotEmpty) {
      final tempMsg = Message.createTemp(
        conId: _currentConId,
        sender: _currentUserId!,
        receiver: widget.partnerUser.userId,
        content: text,
      );
      setState(() => _messages.add(tempMsg));
      _scrollToBottom();
    }

    try {
      final newMessage = await _chatService.sendMessage(
        receiverId: widget.partnerUser.userId,
        content: text,
        images: imagesToSend,
        videos: videosToSend,
        audios: audiosToSend,
      );

      if (_currentConId.isEmpty && newMessage != null && newMessage.conId != null) {
        _currentConId = newMessage.conId!;
      }

      await _fetchMessages();
      if(mounted) setState(() => _isSending = false);

    } catch (e) {
      if (mounted) {
        setState(() => _isSending = false);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to send: $e')));
      }
    }
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0.5,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: Container(
                width: 40,
                height: 40,
                color: Colors.grey[200],
                child: widget.partnerUser.avatarUrl!.isNotEmpty
                    ? CachedNetworkImage(
                  imageUrl: _getFullUrl(widget.partnerUser.avatarUrl),
                  fit: BoxFit.cover,
                  errorWidget: (context, url, error) => const Icon(Icons.person, color: Colors.grey),
                )
                    : const Icon(Icons.person, color: Colors.grey),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.partnerUser.fullName,
                    style: const TextStyle(color: Colors.black, fontSize: 16, fontWeight: FontWeight.bold),
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    widget.partnerUser.email ?? 'No email',
                    style: const TextStyle(color: Colors.grey, fontSize: 12),
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          // Nút 3 chấm để mở Modal
          if (_currentConId.isNotEmpty)
            IconButton(
              icon: const Icon(HeroiconsOutline.ellipsisVertical, color: Colors.black),
              onPressed: () => _showChatOptions(context),
            )
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _messages.isEmpty
                ? Center(child: Text("No messages yet", style: TextStyle(color: Colors.grey[400])))
                : ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.all(16),
              itemCount: _messages.length,
              itemBuilder: (context, index) {
                final msg = _messages[index];
                final isMe = msg.sender == _currentUserId;
                return _buildMessageBubble(msg, isMe);
              },
            ),
          ),

          if (_selectedImages.isNotEmpty || _selectedVideos.isNotEmpty || _selectedAudios.isNotEmpty)
            _buildAttachmentPreview(),

          _buildInputArea(),
        ],
      ),
    );
  }

  // --- UI WIDGETS ---

  Widget _buildAttachmentPreview() {
    return Container(
      height: 100,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      color: Colors.grey[100],
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: [
          ..._selectedImages.asMap().entries.map((e) => _buildPreviewItem(e.value, e.key, 'image')),
          ..._selectedVideos.asMap().entries.map((e) => _buildPreviewItem(e.value, e.key, 'video')),
          ..._selectedAudios.asMap().entries.map((e) => _buildPreviewItem(e.value, e.key, 'audio')),
        ],
      ),
    );
  }

  Widget _buildPreviewItem(XFile file, int index, String type) {
    IconData icon;
    Color color;

    if (type == 'video') { icon = Icons.videocam; color = Colors.black54; }
    else if (type == 'audio') { icon = Icons.audiotrack; color = Colors.purple; }
    else { icon = Icons.image; color = Colors.transparent; }

    return Stack(
      children: [
        Container(
          margin: const EdgeInsets.only(right: 10),
          width: 80, height: 80,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            color: Colors.black12,
            image: type == 'image'
                ? DecorationImage(image: FileImage(File(file.path)), fit: BoxFit.cover)
                : null,
          ),
          child: type != 'image' ? Center(child: Icon(icon, color: color, size: 30)) : null,
        ),
        Positioned(
          top: 0, right: 10,
          child: GestureDetector(
            onTap: () => _removeAttachment(index, type),
            child: Container(
              padding: const EdgeInsets.all(2),
              decoration: const BoxDecoration(color: Colors.black54, shape: BoxShape.circle),
              child: const Icon(Icons.close, size: 14, color: Colors.white),
            ),
          ),
        )
      ],
    );
  }

  Widget _buildMessageBubble(Message msg, bool isMe) {
    final content = msg.content ?? "";
    final media = msg.media;

    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.75),
        child: Column(
          crossAxisAlignment: isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
          children: [
            if (media.isNotEmpty)
              Wrap(
                spacing: 4,
                runSpacing: 4,
                alignment: isMe ? WrapAlignment.end : WrapAlignment.start,
                children: media.map((m) {
                  if (m.type == 'image') {
                    return ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Image.network(
                        _getFullUrl(m.url),
                        width: 150,
                        height: 150,
                        fit: BoxFit.cover,
                        errorBuilder: (_,__,___) => const Icon(Icons.broken_image),
                      ),
                    );
                  }
                  else if (m.type == 'video') {
                    return Container(
                      width: 150, height: 150,
                      decoration: BoxDecoration(color: Colors.black, borderRadius: BorderRadius.circular(12)),
                      child: const Center(child: Icon(Icons.play_circle_fill, size: 40, color: Colors.white)),
                    );
                  }
                  else if (m.type == 'audio') {
                    return Container(
                      width: 180,
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                          color: isMe ? Colors.blue[100] : Colors.grey[200],
                          borderRadius: BorderRadius.circular(20)
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.play_arrow, color: isMe ? Colors.blue : Colors.black87),
                          const SizedBox(width: 8),
                          Expanded(child: Container(height: 2, color: isMe ? Colors.blue : Colors.black87)),
                          const SizedBox(width: 8),
                          const Text("Audio", style: TextStyle(fontSize: 12)),
                        ],
                      ),
                    );
                  }
                  return const SizedBox();
                }).toList(),
              ),

            if (content.isNotEmpty)
              Container(
                margin: const EdgeInsets.only(top: 4),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                decoration: BoxDecoration(
                  color: isMe ? Colors.black : AppColors.E2Color,
                  borderRadius: BorderRadius.only(
                    topLeft: const Radius.circular(16),
                    topRight: const Radius.circular(16),
                    bottomLeft: isMe ? const Radius.circular(16) : Radius.zero,
                    bottomRight: isMe ? Radius.zero : const Radius.circular(16),
                  ),
                ),
                child: Text(content, style: TextStyle(color: isMe ? Colors.white : Colors.black, fontSize: 14)),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildInputArea() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      margin: EdgeInsets.only(bottom: MediaQuery.of(context).padding.bottom),
      decoration: const BoxDecoration(color: Colors.white),
      child: Row(
        children: [
          Container(
            width: 40, height: 40,
            decoration: const BoxDecoration(color: Colors.black, shape: BoxShape.circle),
            child: IconButton(
              icon: const Icon(HeroiconsOutline.paperClip, color: Colors.white, size: 20),
              onPressed: _showAttachmentOptions,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              height: 50,
              decoration: BoxDecoration(color: AppColors.E2Color, borderRadius: BorderRadius.circular(30)),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _messageController,
                      enabled: !_isSending,
                      decoration: InputDecoration(
                        hintText: _isSending ? "Sending..." : "Message...",
                        hintStyle: const TextStyle(color: Colors.grey, fontSize: 14),
                        border: InputBorder.none,
                      ),
                      onSubmitted: (_) => _handleSend(),
                    ),
                  ),
                  GestureDetector(
                    onTap: _isSending ? null : _handleSend,
                    child: Icon(HeroiconsOutline.paperAirplane, color: _isSending ? Colors.grey : Colors.black, size: 24),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}