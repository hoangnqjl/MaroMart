import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:heroicons_flutter/heroicons_flutter.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:temo/Colors/AppColors.dart';
import 'package:temo/models/Message/Message.dart';
import 'package:temo/models/User/ChatPartner.dart';
import 'package:temo/services/chat_service.dart';
import 'package:temo/utils/storage.dart';
import 'package:temo/utils/constants.dart';
import 'package:temo/components/ModernLoader.dart';
import 'package:temo/components/FloatingHeader.dart';
import 'package:temo/screens/Common/BugReportScreen.dart';
import 'package:temo/utils/UIHelper.dart';
import 'package:google_fonts/google_fonts.dart';

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

    // THÊM SOCKET LISTENERS
    _initSocketListeners();

    if (_currentConId.isNotEmpty) {
      _fetchMessages();
    } else {
      setState(() => _isLoading = false);
    }
  }

  // Khởi tạo socket listeners
  void _initSocketListeners() {
    _chatService.initSocketListeners(
      onNewMessage: (data) {
        print('📩 [ChatScreen] Nhận tin nhắn mới: $data');

        try {
          final newMsg = Message.fromJson(data['new_message']);

          // Cập nhật conversationId nếu đang ở conversation mới
          if (_currentConId.isEmpty && newMsg.conId != null) {
            _currentConId = newMsg.conId!;
          }

          // Chỉ thêm tin nhắn nếu thuộc conversation hiện tại
          if (newMsg.conId == _currentConId && mounted) {
            setState(() {
              // Kiểm tra không trùng lặp
              final exists = _messages.any((m) => m.messageId == newMsg.messageId);
              if (!exists) {
                _messages.add(newMsg);
                print('✅ Đã thêm tin nhắn mới vào UI');
              } else {
                print('⚠️ Tin nhắn đã tồn tại, bỏ qua');
              }
            });
            _scrollToBottom();
          }
        } catch (e) {
          print('❌ Lỗi parse new message: $e');
        }
      },

      onMessageSent: (data) {
        print('✅ [ChatScreen] Tin nhắn đã gửi thành công: $data');

        try {
          final sentMsg = Message.fromJson(data['new_message']);

          // Cập nhật conversationId nếu đang ở conversation mới
          if (_currentConId.isEmpty && sentMsg.conId != null) {
            _currentConId = sentMsg.conId!;
          }

          if (sentMsg.conId == _currentConId && mounted) {
            setState(() {
              // Tin nhắn tạm đã bị loại bỏ, chỉ thêm tin nhắn thật từ server


              // Thêm tin nhắn thật từ server
              final exists = _messages.any((m) => m.messageId == sentMsg.messageId);
              if (!exists) {
                _messages.add(sentMsg);
                print('✅ Đã cập nhật tin nhắn đã gửi vào UI');
              }
            });
            _scrollToBottom();
          }
        } catch (e) {
          print('❌ Lỗi parse sent message: $e');
        }
      },
    );
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
      print('❌ Lỗi fetch messages: $e');
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
                margin: const EdgeInsets.only(bottom: 24),
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              _buildOptionButton(
                icon: HeroiconsOutline.exclamationTriangle,
                label: 'Báo cáo lỗi',
                iconColor: Colors.red,
                bgColor: Colors.red.withOpacity(0.1),
                onTap: () {
                  Navigator.pop(ctx);
                  Navigator.push(context, MaterialPageRoute(builder: (context) => BugReportScreen(preFilledError: "Lỗi tại cuộc hội thoại với ${widget.partnerUser.fullName}")));
                },
              ),
              const SizedBox(height: 12),
              _buildOptionButton(
                icon: HeroiconsOutline.trash,
                label: 'Xóa hội thoại',
                iconColor: AppColors.accent,
                bgColor: const Color(0xFFFCEEEB),
                onTap: () {
                  Navigator.pop(ctx);
                  _confirmDeleteConversation();
                },
              ),
              const SizedBox(height: 20),
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
        title: const Text("Xóa cuộc hội thoại"),
        content: const Text("Bạn có chắc chắn muốn xóa cuộc hội thoại này không? Hành động này không thể hoàn tác."),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text("Hủy", style: TextStyle(color: Colors.grey)),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              _deleteConversation();
            },
            child: Text("Xóa", style: TextStyle(color: AppColors.accent, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteConversation() async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => Center(child: ModernLoader()),
    );

    try {
      await _chatService.deleteConversation(_currentConId);

      if (mounted) {
        Navigator.pop(context); // Tắt loading
        Navigator.pop(context); // Thoát khỏi màn hình Chat
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: const Text("Đã xóa cuộc hội thoại"), backgroundColor: AppColors.success),
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

  // --- CÁC HÀM CHỌN FILE & GỬI TIN NHẮN ---
  Future<void> _showAttachmentOptions() async {
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        height: 220,
        child: Column(
          children: [
            ListTile(
              leading: const Icon(Icons.photo_library, color: AppColors.primary),
              title: const Text('Image'),
              onTap: () { Navigator.pop(context); _pickImages(); },
            ),
            ListTile(
              leading: const Icon(Icons.video_library, color: AppColors.error),
              title: const Text('Video'),
              onTap: () { Navigator.pop(context); _pickVideo(); },
            ),
            ListTile(
              leading: const Icon(Icons.audiotrack, color: AppColors.warning),
              title: const Text('Audio'),
              onTap: () { Navigator.pop(context); _pickAudio(); },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _pickImages() async {
    _showImageSourceActionSheet(context, isVideo: false, onPicked: (media) {
       if (media is List<XFile>) {
          setState(() => _selectedImages.addAll(media));
       } else if (media is XFile) {
          setState(() => _selectedImages.add(media));
       }
    });
  }

  Future<void> _pickVideo() async {
    _showImageSourceActionSheet(context, isVideo: true, onPicked: (media) {
       if (media is XFile) {
          setState(() => _selectedVideos.add(media));
       }
    });
  }

  void _showImageSourceActionSheet(BuildContext context, {required bool isVideo, required Function(dynamic) onPicked}) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 10),
            Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(2))),
            const SizedBox(height: 20),
            Text(isVideo ? "Add Video" : "Add Photo", style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            ListTile(
              leading: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(color: AppColors.primary.withOpacity(0.1), shape: BoxShape.circle),
                child: const Icon(HeroiconsOutline.camera, color: AppColors.primary),
              ),
              title: Text(isVideo ? "Record Video" : "Take Photo"),
              onTap: () async {
                Navigator.pop(context);
                final status = await Permission.camera.request();
                if (status.isGranted) {
                  try {
                    final XFile? media = isVideo 
                      ? await _picker.pickVideo(source: ImageSource.camera)
                      : await _picker.pickImage(source: ImageSource.camera);
                    onPicked(media);
                  } catch (e) {
                     ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Camera Error: $e"), backgroundColor: Colors.red));
                  }
                } else {
                  _showPermissionDialog();
                }
              },
            ),
            ListTile(
              leading: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(color: AppColors.warning.withOpacity(0.1), shape: BoxShape.circle),
                child: const Icon(HeroiconsOutline.photo, color: AppColors.warning),
              ),
              title: Text(isVideo ? "Choose from Gallery" : "Choose from Gallery (Multi)"),
              onTap: () async {
                Navigator.pop(context);
                try {
                  if (isVideo) {
                    final XFile? media = await _picker.pickVideo(source: ImageSource.gallery);
                    onPicked(media);
                  } else {
                    final List<XFile> media = await _picker.pickMultiImage();
                    onPicked(media);
                  }
                } catch (e) {
                   ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Gallery Error: $e"), backgroundColor: Colors.red));
                }
              },
            ),
            const SizedBox(height: 10),
          ],
        ),
      ),
    );
  }

  void _showPermissionDialog() {
      showDialog(
        context: context, 
        builder: (ctx) => AlertDialog(
          title: const Text("Permission Required"),
          content: const Text("Please grant camera access in Settings to use this feature."),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("Cancel")),
            TextButton(onPressed: () { Navigator.pop(ctx); openAppSettings(); }, child: const Text("Open Settings")),
          ],
        )
      );
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

    // Removed optimistic update as per user request


    try {
      final newMessage = await _chatService.sendMessage(
        receiverId: widget.partnerUser.userId,
        content: text,
        images: imagesToSend,
        videos: videosToSend,
        audios: audiosToSend,
      );

      // Cập nhật conversationId nếu là conversation mới
      if (_currentConId.isEmpty && newMessage != null && newMessage.conId != null) {
        setState(() {
          _currentConId = newMessage.conId!;
        });
      }

      // Socket sẽ tự động nhận và cập nhật tin nhắn qua onMessageSent
      // Không cần fetch lại toàn bộ messages

      if(mounted) setState(() => _isSending = false);

    } catch (e) {
      print('❌ Lỗi gửi tin nhắn: $e');
      if (mounted) {
        setState(() {
          _isSending = false;
          // Xóa tin nhắn tạm nếu gửi thất bại - Removed

        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to send: $e')),
        );
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
      body: Stack(
        children: [
          Column(
            children: [
              Expanded(
                child: _isLoading
                ? Center(child: ModernLoader())
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
          Positioned(
            top: 0, left: 0, right: 0,
            child: FloatingHeader(
              title: "",
              hasBackground: false,
              contentAlignment: Alignment.center,
              titleWidget: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: Container(
                      width: 32, height: 32,
                      color: Colors.grey[100],
                      child: widget.partnerUser.avatarUrl!.isNotEmpty
                          ? CachedNetworkImage(
                              imageUrl: _getFullUrl(widget.partnerUser.avatarUrl),
                              fit: BoxFit.cover,
                              errorWidget: (context, url, error) => const Icon(Icons.person, color: Colors.grey, size: 16),
                            )
                          : const Icon(Icons.person, color: Colors.grey, size: 16),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        widget.partnerUser.fullName,
                        style: GoogleFonts.quicksand(fontSize: 13, fontWeight: FontWeight.w800, color: const Color(0xFF1F2937)),
                        overflow: TextOverflow.ellipsis,
                      ),
                      Row(
                        children: [
                          Container(
                            width: 6, height: 6,
                            decoration: const BoxDecoration(
                              color: AppColors.success, // Brand Orange for active/online
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            "Online", // Or "5 phút trước" for offline
                            style: GoogleFonts.quicksand(fontSize: 10, color: const Color(0xFF6B7280), fontWeight: FontWeight.w600),
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
              actions: [
                if (_currentConId.isNotEmpty)
                  FloatingHeader.buildActionBubble(
                    icon: HeroiconsSolid.ellipsisVertical,
                    onTap: () => _showChatOptions(context),
                  ),
              ],
            ),
          ),
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
                          color: isMe ? AppColors.primary.withOpacity(0.2) : Colors.grey[200],
                          borderRadius: BorderRadius.circular(20)
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.play_arrow, color: isMe ? AppColors.primary : Colors.black87),
                          const SizedBox(width: 8),
                          Expanded(child: Container(height: 2, color: isMe ? AppColors.primary : Colors.black87)),
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
            width: 48, height: 48,
            decoration: BoxDecoration(color: AppColors.primary, shape: BoxShape.circle),
            child: IconButton(
              icon: const Icon(HeroiconsOutline.paperClip, color: Colors.white, size: 22),
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