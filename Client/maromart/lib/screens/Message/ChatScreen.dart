import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:heroicons_flutter/heroicons_flutter.dart';
import 'package:image_picker/image_picker.dart';
import 'package:maromart/Colors/AppColors.dart';
import 'package:maromart/components/ButtonWithIcon.dart';
import 'package:maromart/components/TopBarSecond.dart';
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

  String _getFullUrl(String path) {
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

  // LOGIC CHỌN FILE
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
              title: const Text('Chọn Ảnh'),
              onTap: () { Navigator.pop(context); _pickImages(); },
            ),
            ListTile(
              leading: const Icon(Icons.video_library, color: Colors.red),
              title: const Text('Chọn Video'),
              onTap: () { Navigator.pop(context); _pickVideo(); },
            ),
            ListTile(
              leading: const Icon(Icons.audiotrack, color: Colors.purple),
              title: const Text('Chọn Audio'),
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
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.audio,
      allowMultiple: true,
    );

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
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Gửi thất bại: $e')));
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
      appBar: TopBarSecond(title: widget.partnerUser.fullName),
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
                        _getFullUrl(m.url), // <--- SỬA Ở ĐÂY
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
  Widget _topbarChhat(){
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              ButtonWithIcon(
                icon: HeroiconsOutline.chevronLeft,
                onPressed: () {
                  Navigator.pop(context);
                },
                size: 38,
                backgroundColor: Colors.white,
                iconColor: Colors.black,
                isSelected: false,
              ),
              Container(
                child: Row(

                ),
              )

            ],
          )
        ],
      ),
    );
  }
}