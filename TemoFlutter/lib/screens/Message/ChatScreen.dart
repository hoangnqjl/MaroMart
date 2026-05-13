import 'dart:io';
import 'dart:convert';
import 'dart:ui';
import 'package:intl/intl.dart';
import 'package:http/http.dart' as http;
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
import 'package:temo/utils/ui_helpers.dart';
import 'package:temo/services/order_service.dart';
import 'package:temo/services/chat_service.dart';
import 'package:temo/utils/string_utils.dart';
import 'package:temo/components/PremiumImage.dart';
import 'package:temo/components/VideoPlayerWidget.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:temo/models/Product/Product.dart';
import 'package:temo/screens/Product/ProductDetail.dart';
import 'package:temo/screens/Profile/UserProfileScreen.dart';
import 'package:temo/app_router.dart';

class ChatScreen extends StatefulWidget {
  final String conversationId;
  final ChatPartner partnerUser;
  final Product? product;

  const ChatScreen({
    super.key,
    required this.conversationId,
    required this.partnerUser,
    this.product,
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
  Product? _contextProduct;
  List<Product> _productHistory = [];

  @override
  void initState() {
    super.initState();
    _currentConId = widget.conversationId;
    _currentUserId = StorageHelper.getUserId();
    _contextProduct = widget.product;

    // THÊM SOCKET LISTENERS
    _initSocketListeners();

    if (_currentConId == "ai_assistant") {
      _loadAiFakeMessages();
    } else if (_currentConId.isNotEmpty) {
      _fetchMessages();
    } else {
      _findConversationWithPartner();
    }
  }

  void _loadAiFakeMessages() {
    setState(() {
      _messages = [
        Message(
          messageId: "ai_1",
          sender: "ai_assistant",
          receiver: _currentUserId ?? "me",
          content: "Chào bạn! Tôi là trợ lý ảo MaroMart. Tôi có thể giúp gì cho bạn?",
          media: [],
          createdAt: DateTime.now().subtract(const Duration(minutes: 2)),
          conId: "ai_assistant",
        ),
      ];
      _isLoading = false;
    });
  }

  void _showFullScreenMedia(List<dynamic> media, int initialIndex) {
    int tempPage = initialIndex;
    final PageController controller = PageController(initialPage: initialIndex);

    showGeneralDialog(
      context: context,
      barrierColor: Colors.black,
      barrierDismissible: false,
      barrierLabel: "Media",
      transitionDuration: const Duration(milliseconds: 300),
      pageBuilder: (context, animation, secondaryAnimation) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Scaffold(
              backgroundColor: Colors.black,
              body: Stack(
                children: [
                  PageView.builder(
                    controller: controller,
                    itemCount: media.length,
                    onPageChanged: (index) => setModalState(() => tempPage = index),
                    itemBuilder: (context, index) {
                      final m = media[index];
                      if (m.type == 'image') {
                        return InteractiveViewer(
                          minScale: 1.0,
                          maxScale: 5.0,
                          child: Center(
                            child: Hero(
                              tag: m.url,
                              child: CachedNetworkImage(
                                imageUrl: StringUtils.normalizeUrl(m.url),
                                fit: BoxFit.contain,
                                placeholder: (_, __) => const ModernLoader(size: 30),
                                errorWidget: (_, __, ___) => const Icon(Icons.broken_image, color: Colors.white, size: 50),
                              ),
                            ),
                          ),
                        );
                      } else if (m.type == 'video') {
                        return Center(child: VideoPlayerWidget(videoUrl: m.url));
                      }
                      return const SizedBox();
                    },
                  ),
                  // Top Bar
                  Positioned(
                    top: MediaQuery.of(context).padding.top + 10,
                    left: 0, right: 0,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          // Close Button
                          Align(
                            alignment: Alignment.centerRight,
                            child: GestureDetector(
                              onTap: () => Navigator.pop(context),
                              child: Container(
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color: Colors.black54,
                                  shape: BoxShape.circle,
                                  border: Border.all(color: Colors.white24),
                                ),
                                child: const Icon(Icons.close_rounded, color: Colors.white, size: 24),
                              ),
                            ),
                          ),
                          // Index Indicator
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                            decoration: BoxDecoration(
                              color: Colors.black.withOpacity(0.5),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(color: Colors.white10),
                            ),
                            child: Text(
                              "${tempPage + 1} / ${media.length}",
                              style: GoogleFonts.quicksand(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Future<void> _findConversationWithPartner() async {
    try {
      final conversations = await _chatService.getConversations();
      final partnerId = widget.partnerUser.userId;
      
      // Tìm conversation có chứa partnerId
      final existingCon = conversations.firstWhere(
        (con) => con.userId1 == partnerId || con.userId2 == partnerId,
        orElse: () => throw Exception('Not found'),
      );

      if (mounted) {
        setState(() {
          _currentConId = existingCon.conId ?? "";
        });
        if (_currentConId.isNotEmpty) {
          _fetchMessages();
        } else {
          setState(() => _isLoading = false);
          // Cho conversation m?i hon ton t? ProductDetail
          if (widget.product != null) {
            _sendProductCardMessage();
          }
        }
      }
    } catch (e) {
      // Nếu không tìm thấy, coi như conversation mới
      if (mounted) {
        setState(() => _isLoading = false);
        // Cho conversation m?i hon ton t? ProductDetail
        if (widget.product != null) {
           _sendProductCardMessage();
        }
      }
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
                _updateContextFromMessage(newMsg);
              } else {
                print('⚠️ Tin nhắn đã tồn tại, bỏ qua');
              }
            });
            _scrollToBottom();
            
            // Mark as read if receiving message from partner while in chat
            if (newMsg.sender != _currentUserId) {
              _chatService.markAsRead(_currentConId);
            }
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
                _updateContextFromMessage(sentMsg);
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



  Future<void> _fetchMessages() async {
    if (_currentConId.isEmpty) return;
    try {
      final msgs = await _chatService.getMessages(_currentConId);
      if (mounted) {
        setState(() {
          _messages = msgs;
          _isLoading = false;
        });

        // Đánh dấu đã đọc khi vào chat
        _chatService.markAsRead(_currentConId);

        // Luôn trích xuất lịch sử sản phẩm từ tin nhắn
        _extractProductFromMessages(msgs);

        // Nếu mới vào từ ProductDetail, đảm bảo ghi nhận sp đó
        if (widget.product != null) {
          setState(() {
            _contextProduct = widget.product;
          });

          // Tự động gửi card sản phẩm nếu sản phẩm này chưa từng được gửi trong chat
          bool alreadySent = msgs.any((m) => m.content?.contains(widget.product!.productId) ?? false);
          if (!alreadySent) {
             _sendProductCardMessage();
          }
        }

        WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToBottom());
      }
    } catch (e) {
      print('❌ Lỗi fetch messages: $e');
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _extractProductFromMessages(List<Message> msgs) {
    // Tìm tin nhắn chứa PRODUCT_CARD
    List<Product> history = [];
    for (int i = 0; i < msgs.length; i++) {
      final content = msgs[i].content ?? "";
      if (content.startsWith("[[PRODUCT_CARD:")) {
        try {
          final jsonStr = content.substring(15, content.length - 2);
          final data = jsonDecode(jsonStr);
          final p = _parseProductFromMap(data);
          
          // Tránh trùng lặp
          if (!history.any((item) => item.productId == p.productId)) {
            history.insert(0, p); // Mới nhất lên đầu
          }
        } catch (e) {
          print("Error parsing product card from history: $e");
        }
      }
    }

    if (history.isNotEmpty) {
      setState(() {
        _productHistory = history;
        // Chỉ cập nhật _contextProduct nếu hiện tại chưa có
        if (_contextProduct == null) {
          _contextProduct = history[0];
        }
      });
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
      isScrollControlled: true,
      useSafeArea: true,
      builder: (BuildContext ctx) {
        return BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
          child: Container(
            margin: const EdgeInsets.fromLTRB(16, 0, 16, 24),
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.95),
              borderRadius: BorderRadius.circular(45),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 20,
                  offset: const Offset(0, -5),
                ),
              ],
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
                icon: HeroiconsOutline.clock,
                label: 'Lịch sử sản phẩm',
                iconColor: Colors.blue,
                bgColor: Colors.blue.withOpacity(0.1),
                onTap: () {
                  Navigator.pop(ctx);
                  _showProductHistory();
                },
              ),
              const SizedBox(height: 12),
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
          borderRadius: BorderRadius.circular(45),
          border: Border.all(color: Colors.grey.shade100),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(color: bgColor, shape: BoxShape.circle),
              child: Icon(icon, color: iconColor, size: 20),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                label,
                style: GoogleFonts.roboto(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF1F2937),
                ),
              ),
            ),
            Icon(HeroiconsOutline.chevronRight, color: Colors.black, size: 16),
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
  void _showStyledBottomSheet({required String title, required Widget content}) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
        child: SafeArea(
          child: Container(
            margin: const EdgeInsets.fromLTRB(16, 0, 16, 24),
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.95),
              borderRadius: BorderRadius.circular(45),
              boxShadow: [
                BoxShadow(color: Colors.black.withOpacity(0.08), blurRadius: 20, offset: const Offset(0, 8))
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 40, height: 4,
                  margin: const EdgeInsets.only(bottom: 24),
                  decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(2)),
                ),
                Text(title, style: GoogleFonts.quicksand(fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 24),
                content,
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _showAttachmentOptions() async {
    _showStyledBottomSheet(
      title: "Gửi tệp",
      content: Column(
        children: [
          _buildAttachmentOption(
            icon: Icons.image_rounded,
            label: "Hình ảnh",
            iconColor: AppColors.primary,
            onTap: () { Navigator.pop(context); _pickImages(); },
          ),
          const SizedBox(height: 12),
          _buildAttachmentOption(
            icon: Icons.videocam_rounded,
            label: "Video",
            iconColor: Colors.redAccent,
            onTap: () { Navigator.pop(context); _pickVideo(); },
          ),
          const SizedBox(height: 12),
          _buildAttachmentOption(
            icon: Icons.audiotrack_rounded,
            label: "Âm thanh",
            iconColor: Colors.amber,
            onTap: () { Navigator.pop(context); _pickAudio(); },
          ),
        ],
      ),
    );
  }

  Widget _buildAttachmentOption({required IconData icon, required String label, required Color iconColor, required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(45),
          border: Border.all(color: Colors.grey.shade100),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(color: iconColor.withOpacity(0.1), shape: BoxShape.circle),
              child: Icon(icon, color: iconColor, size: 20),
            ),
            const SizedBox(width: 16),
            Text(label, style: GoogleFonts.quicksand(fontSize: 15, fontWeight: FontWeight.bold, color: const Color(0xFF1F2937))),
            const Spacer(),
            const Icon(Icons.chevron_right_rounded, color: Colors.grey, size: 18),
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
    _showStyledBottomSheet(
      title: isVideo ? "Thêm Video" : "Thêm Hình ảnh",
      content: Column(
        children: [
          _buildAttachmentOption(
            icon: HeroiconsOutline.camera,
            label: isVideo ? "Quay Video" : "Chụp ảnh",
            iconColor: AppColors.primary,
            onTap: () async {
                Navigator.pop(context);
                final status = await Permission.camera.request();
                if (status.isGranted) {
                  try {
                    final XFile? media = isVideo 
                      ? await _picker.pickVideo(source: ImageSource.camera)
                      : await _picker.pickImage(source: ImageSource.camera, maxWidth: 1920, maxHeight: 1080);
                    onPicked(media);
                  } catch (e) {
                     ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Camera Error: $e"), backgroundColor: Colors.red));
                  }
                } else {
                  _showPermissionDialog();
                }
            },
          ),
          const SizedBox(height: 12),
          _buildAttachmentOption(
            icon: HeroiconsOutline.photo,
            label: isVideo ? "Chọn Video từ máy" : "Chọn Ảnh từ máy",
            iconColor: Colors.blueAccent,
            onTap: () async {
                Navigator.pop(context);
                try {
                  if (isVideo) {
                    final XFile? video = await _picker.pickVideo(source: ImageSource.gallery);
                    onPicked(video);
                    } else {
                      final List<XFile> images = await _picker.pickMultiImage(maxWidth: 1920, maxHeight: 1080);
                      onPicked(images);
                    }
                } catch (e) {
                   ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Gallery Error: $e"), backgroundColor: Colors.red));
                }
            },
          ),
          const SizedBox(height: 10),
        ],
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

    if (_currentConId == "ai_assistant") {
      final userMsg = Message(
        messageId: "user_${DateTime.now().millisecondsSinceEpoch}",
        sender: _currentUserId ?? "me",
        receiver: "ai_assistant",
        content: text,
        media: [],
        createdAt: DateTime.now(),
        conId: "ai_assistant",
      );
      
      _messageController.clear();
      setState(() {
        _messages.add(userMsg);
      });
      _scrollToBottom();

      Future.delayed(const Duration(seconds: 1), () {
        if (!mounted) return;
        final aiMsg = Message(
          messageId: "ai_${DateTime.now().millisecondsSinceEpoch}",
          sender: "ai_assistant",
          receiver: _currentUserId ?? "me",
          content: "Cảm ơn bạn đã nhắn tin. Hiện tại tôi đang được phát triển để hỗ trợ khách hàng tốt hơn. Bạn có thể cho tôi biết thêm chi tiết về yêu cầu của bạn được không?",
          media: [],
          createdAt: DateTime.now(),
          conId: "ai_assistant",
        );
        setState(() {
          _messages.add(aiMsg);
        });
        _scrollToBottom();
      });
      return;
    }

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

  Future<void> _sendProductCardMessage() async {
     if (widget.product == null) return;
     final p = widget.product!;
     final firstImage = p.productMedia.isNotEmpty ? p.productMedia[0] : "";
     
     final productData = {
       "id": p.productId,
       "name": p.productName,
       "price": p.productPrice,
       "image": firstImage,
       "sellerId": p.userId, // Thêm sellerId để phân biệt người mua/bán
     };
     
     final content = "[[PRODUCT_CARD:${jsonEncode(productData)}]]";
     
     try {
       await _chatService.sendMessage(
         receiverId: widget.partnerUser.userId,
         content: content,
       );
       // Socket sẽ lo việc hiển thị tin nhắn này
     } catch (e) {
       print("Error sending product card: $e");
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
                ? const Center(child: ModernLoader())
                : Stack(
                    children: [
                      Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              Colors.white,
                              const Color(0xFFFFF7ED).withOpacity(0.5),
                              const Color(0xFFF0F9FF).withOpacity(0.5),
                              Colors.white,
                            ],
                            stops: const [0.0, 0.3, 0.7, 1.0],
                          ),
                        ),
                      ),
                      _messages.isEmpty
                      ? Center(child: Text("No messages yet", style: TextStyle(color: Colors.grey[400])))
                      : ListView.builder(
                          controller: _scrollController,
                          padding: const EdgeInsets.fromLTRB(16, 120, 16, 100),
                          itemCount: _messages.length,
                          itemBuilder: (context, index) {
                            final msg = _messages[index];
                            final isMe = msg.sender == _currentUserId;
                            return _buildMessageBubble(msg, isMe);
                          },
                        ),
                    ],
                  ),
              ),

          if (_selectedImages.isNotEmpty || _selectedVideos.isNotEmpty || _selectedAudios.isNotEmpty)
            _buildAttachmentPreview(),

          _buildInputArea(),
            ],
          ),
          Positioned(
            top: 0, left: 0, right: 0,
            child: SafeArea(
              bottom: false,
              child: FloatingHeader(
                title: "",
                hasBackground: true,
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
                contentAlignment: Alignment.center,
                titleWidget: GestureDetector(
                  onTap: () => smoothPush(context, UserProfileScreen(userId: widget.partnerUser.userId)),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(16),
                        child: Container(
                          width: 32, height: 32,
                          color: Colors.grey[100],
                          child: Center(
                            child: (widget.partnerUser.avatarUrl != null && widget.partnerUser.avatarUrl!.isNotEmpty)
                                ? widget.partnerUser.avatarUrl!.startsWith('assets/')
                                    ? Image.asset(widget.partnerUser.avatarUrl!, fit: BoxFit.cover, width: 32, height: 32)
                                    : CachedNetworkImage(
                                        imageUrl: StringUtils.normalizeUrl(widget.partnerUser.avatarUrl),
                                        fit: BoxFit.cover,
                                        width: 32, height: 32,
                                        errorWidget: (context, url, error) => const Icon(Icons.person, color: Colors.grey, size: 16),
                                      )
                                : const Icon(Icons.person, color: Colors.grey, size: 16),
                          ),
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
                                style: GoogleFonts.quicksand(fontSize: 10, color: Colors.grey[500], fontWeight: FontWeight.w600),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ],
                  ),
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

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment: isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!isMe) ...[
            Align(
              alignment: Alignment.bottomLeft,
              child: GestureDetector(
                onTap: () => smoothPush(context, UserProfileScreen(userId: widget.partnerUser.userId)),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(14),
                  child: Container(
                    width: 28, height: 28,
                    color: Colors.grey[100],
                    child: (widget.partnerUser.avatarUrl != null && widget.partnerUser.avatarUrl!.isNotEmpty)
                        ? widget.partnerUser.avatarUrl!.startsWith('assets/')
                            ? Image.asset(widget.partnerUser.avatarUrl!, fit: BoxFit.cover)
                            : CachedNetworkImage(
                                imageUrl: StringUtils.normalizeUrl(widget.partnerUser.avatarUrl),
                                fit: BoxFit.cover,
                                errorWidget: (_, __, ___) => const Icon(Icons.person, size: 16, color: Colors.grey),
                              )
                        : const Icon(Icons.person, size: 16, color: Colors.grey),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
          ],
          
          Container(
            constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.72),
            child: Column(
              crossAxisAlignment: isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
              children: [
                if (media.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      alignment: isMe ? WrapAlignment.end : WrapAlignment.start,
                      children: media.asMap().entries.map((entry) {
                        final index = entry.key;
                        final m = entry.value;
                        
                        final bool isSquare = media.length > 3;
                        final double mWidth = isSquare ? 100 : 240;
                        final double mHeight = isSquare ? 100 : 160;

                        if (m.type == 'image') {
                          return GestureDetector(
                            onTap: () => _showFullScreenMedia(media, index),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(16),
                              child: Hero(
                                tag: m.url,
                                child: PremiumImage(
                                  imageUrl: StringUtils.normalizeUrl(m.url),
                                  width: mWidth,
                                  height: mHeight,
                                  fit: BoxFit.cover,
                                  borderRadius: 16,
                                ),
                              ),
                            ),
                          );
                        }
                        else if (m.type == 'video') {
                          return GestureDetector(
                            onTap: () => _showFullScreenMedia(media, index),
                            child: Container(
                              width: mWidth, height: mHeight,
                              decoration: BoxDecoration(color: Colors.black, borderRadius: BorderRadius.circular(16)),
                              child: const Center(child: Icon(Icons.play_circle_fill, size: 40, color: Colors.white)),
                            ),
                          );
                        }
                        else if (m.type == 'audio') {
                          return Container(
                            width: 180,
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                                color: isMe ? AppColors.primary.withOpacity(0.2) : Colors.grey[200],
                                borderRadius: BorderRadius.circular(24)
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
                  ),

                if (content.isNotEmpty)
                  () {
                    // Sử dụng RegExp để bóc tách JSON một cách an toàn hơn
                    final productMatch = RegExp(r"\[\[PRODUCT_CARD:(.*)\]\]", dotAll: true).firstMatch(content);
                    if (productMatch != null) {
                      try {
                        final jsonStr = productMatch.group(1)!;
                        final data = jsonDecode(jsonStr);
                        return _buildProductCardInChat(data, isMe);
                      } catch (e) {
                        return _buildTextMessage(content, isMe);
                      }
                    }

                    final orderReqMatch = RegExp(r"\[\[ORDER_REQUEST:(.*)\]\]", dotAll: true).firstMatch(content);
                    if (orderReqMatch != null) {
                      try {
                        final jsonStr = orderReqMatch.group(1)!;
                        final data = jsonDecode(jsonStr);
                        return _buildOrderRequestCard(data, isMe);
                      } catch (e) {
                        return _buildTextMessage(content, isMe);
                      }
                    }

                    final orderResMatch = RegExp(r"\[\[ORDER_RESPONSE:(.*)\]\]", dotAll: true).firstMatch(content);
                    if (orderResMatch != null) {
                      try {
                        final jsonStr = orderResMatch.group(1)!;
                        final data = jsonDecode(jsonStr);
                        return _buildOrderResponseCard(data, isMe);
                      } catch (e) {
                        return _buildTextMessage(content, isMe);
                      }
                    }
                    
                    return _buildTextMessage(content, isMe);
                  }(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTextMessage(String content, bool isMe) {
    final borderRadius = BorderRadius.circular(24);

    return Container(
      margin: const EdgeInsets.only(top: 4),
      child: ClipRRect(
        borderRadius: borderRadius,
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: isMe 
                  ? [AppColors.primary.withOpacity(0.85), AppColors.primary.withOpacity(0.7)]
                  : [Colors.white.withOpacity(0.95), Colors.white.withOpacity(0.9)],
              ),
              borderRadius: borderRadius,
              border: Border.all(
                color: isMe 
                  ? Colors.white.withOpacity(0.3) 
                  : Colors.grey[400]!.withOpacity(0.3),
                width: 1.2
              ),
            ),
            child: Text(
              content, 
              style: GoogleFonts.quicksand(
                color: isMe ? Colors.white : const Color(0xFF1F2937), 
                fontSize: 14,
                fontWeight: FontWeight.w600
              )
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildProductCardInChat(Map<String, dynamic> data, bool isMe) {
    // Logic xác định xem có hiển thị nút "Mua ngay" hay không
    // 1. Nếu có sellerId trong data, kiểm tra xem có phải là mình không
    // 2. Nếu không có (tin nhắn cũ), dùng tạm isMe (người nhận thì mới thấy nút mua)
    bool showBuyNow = false;
    if (data.containsKey('sellerId')) {
      showBuyNow = data['sellerId'] != _currentUserId;
    } else {
      showBuyNow = !isMe; 
    }

    return Container(
      margin: const EdgeInsets.only(top: 4),
      padding: const EdgeInsets.all(12),
      width: 220,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: Colors.grey[200]!),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4))
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: CachedNetworkImage(
              imageUrl: StringUtils.normalizeUrl(data['image']),
              height: 120, width: double.infinity, fit: BoxFit.cover,
              errorWidget: (_, __, ___) => Container(color: Colors.grey[100], child: const Icon(Icons.image, color: Colors.grey)),
            ),
          ),
          const SizedBox(height: 10),
          Text(
            data['name'] ?? "Sản phẩm",
            style: GoogleFonts.quicksand(fontWeight: FontWeight.bold, fontSize: 13, height: 1.3),
            maxLines: 2, overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 6),
          Text(
            "đ ${NumberFormat.decimalPattern().format(data['price'] ?? 0)}",
            style: GoogleFonts.quicksand(fontWeight: FontWeight.w800, color: AppColors.primary, fontSize: 14),
          ),
          const SizedBox(height: 12),
          ElevatedButton(
            onPressed: () => smoothPush(context, ProductDetail(productId: data['id'])),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
              padding: const EdgeInsets.symmetric(vertical: 0),
              minimumSize: const Size(double.infinity, 42),
            ),
            child: Text("Xem chi tiết", style: GoogleFonts.quicksand(fontSize: 13, fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
  }

  Future<void> _requestPurchaseFromChat(Map<String, dynamic> data) async {
    final String productId = data['id'] ?? "";
    final String productName = data['name'] ?? "Sản phẩm";
    final double price = (data['price'] ?? 0).toDouble();
    
    // Hiển thị loading nhẹ
    setState(() => _isSending = true);
    
    try {
      final response = await _orderService.createPurchaseRequest(productId, widget.partnerUser.userId);
      
      if (response['orderId'] != null) {
        final orderId = response['orderId'];
        final orderData = {
          "orderId": orderId,
          "productId": productId,
          "productName": productName,
          "price": price,
        };
        
        final content = "[[ORDER_REQUEST:${jsonEncode(orderData)}]]";
        final newMessage = await _chatService.sendMessage(
          receiverId: widget.partnerUser.userId,
          content: content,
        );
        
        if (newMessage != null && mounted) {
           setState(() {
             // Cập nhật conversationId nếu là conversation mới
             if (_currentConId.isEmpty && newMessage.conId != null) {
               _currentConId = newMessage.conId!;
             }
             
             // Thêm tin nhắn vào danh sách nếu chưa có (để đảm bảo hiển thị tức thì)
             final exists = _messages.any((m) => m.messageId == newMessage.messageId);
             if (!exists) {
               _messages.add(newMessage);
             }
             _isSending = false;
           });
           _scrollToBottom();
           UIHelpers.showSuccessSnackBar(context, "Đã gửi yêu cầu mua hàng!");
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSending = false);
        UIHelpers.showErrorSnackBar(context, e.toString());
      }
    }
  }

  Widget _buildOrderRequestCard(Map<String, dynamic> data, bool isMe) {
    final productName = data['productName'] ?? "Sản phẩm";
    final price = data['price'] ?? 0;
    final orderId = data['orderId'] ?? "";
    
    return Container(
      margin: const EdgeInsets.only(top: 4),
      padding: const EdgeInsets.all(16),
      width: 260,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: AppColors.primary.withOpacity(0.2), width: 1.5),
        boxShadow: [
          BoxShadow(color: AppColors.primary.withOpacity(0.05), blurRadius: 15, offset: const Offset(0, 5))
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(color: AppColors.primary.withOpacity(0.1), shape: BoxShape.circle),
                child: const Icon(HeroiconsOutline.shoppingBag, color: AppColors.primary, size: 18),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text("Yêu cầu mua hàng", style: GoogleFonts.quicksand(fontWeight: FontWeight.w800, fontSize: 14, color: AppColors.primary)),
                    Text("Mã đơn: ${orderId.toString().substring(0, 8)}", style: GoogleFonts.quicksand(fontSize: 10, color: Colors.grey)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(productName, style: GoogleFonts.quicksand(fontWeight: FontWeight.bold, fontSize: 14), maxLines: 2, overflow: TextOverflow.ellipsis),
          const SizedBox(height: 4),
          Text("đ ${NumberFormat.decimalPattern().format(price)}", style: GoogleFonts.quicksand(fontWeight: FontWeight.w800, color: AppColors.primary, fontSize: 16)),
          const SizedBox(height: 16),
          
          if (!isMe) ...[
            const Divider(height: 1),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => _handleOrderAction(orderId, 'rejected'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.red,
                      side: const BorderSide(color: Colors.red),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                      padding: const EdgeInsets.symmetric(vertical: 8),
                    ),
                    child: Text("Từ chối", style: GoogleFonts.quicksand(fontWeight: FontWeight.bold, fontSize: 12)),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => _handleOrderAction(orderId, 'accepted'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                      padding: const EdgeInsets.symmetric(vertical: 8),
                    ),
                    child: Text("Chấp nhận", style: GoogleFonts.quicksand(fontWeight: FontWeight.bold, fontSize: 12)),
                  ),
                ),
              ],
            ),
          ] else ...[
             Container(
               width: double.infinity,
               padding: const EdgeInsets.symmetric(vertical: 10),
               decoration: BoxDecoration(color: Colors.orange.withOpacity(0.1), borderRadius: BorderRadius.circular(20)),
               alignment: Alignment.center,
               child: Text("Đang chờ người bán phản hồi", style: GoogleFonts.quicksand(fontWeight: FontWeight.bold, fontSize: 12, color: Colors.orange)),
             ),
          ],
        ],
      ),
    );
  }

  final OrderService _orderService = OrderService();
  Future<void> _handleOrderAction(String orderId, String status) async {
    try {
      await _orderService.respondToRequest(orderId, status);
      
      // Gửi tin nhắn phản hồi vào chat
      final chatService = ChatService();
      final responseData = {
        "orderId": orderId,
        "status": status,
      };
      
      final content = "[[ORDER_RESPONSE:${jsonEncode(responseData)}]]";
      final newMessage = await chatService.sendMessage(
        receiverId: widget.partnerUser.userId,
        content: content,
      );

      if (mounted) {
        setState(() {
          if (newMessage != null) {
            final exists = _messages.any((m) => m.messageId == newMessage.messageId);
            if (!exists) {
              _messages.add(newMessage);
            }
          }
        });
        _scrollToBottom();
        
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(status == 'accepted' ? "Đã chấp nhận yêu cầu" : "Đã từ chối yêu cầu"),
          backgroundColor: status == 'accepted' ? Colors.green : Colors.red,
        ));
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
    }
  }

  Widget _buildProductContextBar() {
    final p = widget.product!;
    final firstImage = p.productMedia.isNotEmpty ? p.productMedia[0] : "";
    
    return Positioned(
      top: 100, left: 16, right: 16,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.85),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: Colors.white.withOpacity(0.5)),
              boxShadow: [
                BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10, offset: const Offset(0, 4))
              ],
            ),
            child: Row(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: CachedNetworkImage(
                    imageUrl: StringUtils.normalizeUrl(firstImage),
                    width: 48, height: 48, fit: BoxFit.cover,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        p.productName,
                        style: GoogleFonts.quicksand(fontWeight: FontWeight.bold, fontSize: 13),
                        maxLines: 1, overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        "đ ${NumberFormat.decimalPattern().format(p.productPrice)}",
                        style: GoogleFonts.quicksand(fontWeight: FontWeight.w700, color: AppColors.primary, fontSize: 12),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }



  Widget _buildOrderResponseCard(Map<String, dynamic> data, bool isMe) {
    final status = data['status'] ?? "accepted";
    final isAccepted = status == 'accepted';
    
    return Container(
      margin: const EdgeInsets.only(top: 4),
      padding: const EdgeInsets.all(16),
      width: 240,
      decoration: BoxDecoration(
        color: isAccepted ? Colors.green.withOpacity(0.05) : Colors.red.withOpacity(0.05),
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: isAccepted ? Colors.green.withOpacity(0.2) : Colors.red.withOpacity(0.2), width: 1.5),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: isAccepted ? Colors.green : Colors.red,
              shape: BoxShape.circle,
            ),
            child: Icon(
              isAccepted ? HeroiconsOutline.check : HeroiconsOutline.xMark,
              color: Colors.white,
              size: 24,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            isAccepted ? "Yêu cầu đã được chấp nhận" : "Yêu cầu đã bị từ chối",
            textAlign: TextAlign.center,
            style: GoogleFonts.quicksand(
              fontWeight: FontWeight.w800,
              fontSize: 14,
              color: isAccepted ? Colors.green[700] : Colors.red[700],
            ),
          ),
          const SizedBox(height: 4),
          Text(
            isAccepted 
              ? (isMe ? "Bạn đã chấp nhận yêu cầu mua hàng." : "Người bán đã chấp nhận yêu cầu của bạn.")
              : (isMe ? "Bạn đã từ chối yêu cầu mua hàng." : "Rất tiếc, người bán đã từ chối yêu cầu của bạn."),
            textAlign: TextAlign.center,
            style: GoogleFonts.quicksand(fontSize: 12, color: Colors.grey[600], fontWeight: FontWeight.w500),
          ),
        ],
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
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 2),
              constraints: const BoxConstraints(minHeight: 50, maxHeight: 120),
              decoration: BoxDecoration(color: AppColors.E2Color, borderRadius: BorderRadius.circular(40)),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Expanded(
                    child: TextField(
                      controller: _messageController,
                      enabled: !_isSending,
                      maxLines: null,
                      keyboardType: TextInputType.multiline,
                      decoration: InputDecoration(
                        hintText: _isSending ? "Sending..." : "Message...",
                        hintStyle: const TextStyle(color: Colors.grey, fontSize: 14),
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  GestureDetector(
                    onTap: _isSending ? null : _handleSend,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      child: Text(
                        "Gửi",
                        style: GoogleFonts.quicksand(
                          color: _isSending ? Colors.grey : AppColors.primary,
                          fontWeight: FontWeight.w800,
                          fontSize: 15,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _updateContextFromMessage(Message msg) {
    final content = msg.content ?? "";
    if (content.startsWith("[[PRODUCT_CARD:")) {
      try {
        final jsonStr = content.substring(15, content.length - 2);
        final data = jsonDecode(jsonStr);
        final product = _parseProductFromMap(data);
        
      setState(() {
        _contextProduct = product;
        // Thêm vào history nếu chưa có (theo productId)
        if (!_productHistory.any((p) => p.productId == product.productId)) {
          _productHistory.insert(0, product);
        } else {
          // Đưa lên đầu nếu đã có
          _productHistory.removeWhere((p) => p.productId == product.productId);
          _productHistory.insert(0, product);
        }
      });
      } catch (e) {
        print("Error updating context from message: $e");
      }
    }
  }

  Product _parseProductFromMap(Map<String, dynamic> data) {
    return Product(
      id: data['id'] ?? '',
      productId: data['id'] ?? '',
      productName: data['name'] ?? '',
      productPrice: data['price'] ?? 0,
      productMedia: data['image'] != null ? [data['image']] : [],
      categoryId: '',
      userId: '',
      productDescription: '',
      productCondition: '',
      productBrand: '',
      productWP: '',
      productOrigin: '',
      productCategory: '',
      productAttribute: null,
      createdAt: '',
      updatedAt: '',
    );
  }

  void _showProductHistory() {
    _showStyledBottomSheet(
      title: "Sản phẩm đã xem",
      content: _productHistory.isEmpty
          ? Padding(
              padding: const EdgeInsets.symmetric(vertical: 40),
              child: Column(
                children: [
                  Icon(HeroiconsOutline.archiveBox, size: 48, color: Colors.grey[300]),
                  const SizedBox(height: 16),
                  Text("Chưa có lịch sử sản phẩm", style: GoogleFonts.quicksand(color: Colors.grey)),
                ],
              ),
            )
          : ConstrainedBox(
              constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.5),
              child: ListView.separated(
                shrinkWrap: true,
                itemCount: _productHistory.length,
                separatorBuilder: (context, index) => const Divider(height: 1),
                itemBuilder: (context, index) {
                  final p = _productHistory[index];
                  return ListTile(
                    contentPadding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
                    leading: ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: p.productMedia.isNotEmpty
                          ? CachedNetworkImage(
                              imageUrl: StringUtils.normalizeUrl(p.productMedia[0]),
                              width: 50, height: 50, fit: BoxFit.cover,
                            )
                          : Container(width: 50, height: 50, color: Colors.grey[100]),
                    ),
                    title: Text(p.productName, style: GoogleFonts.quicksand(fontWeight: FontWeight.bold, fontSize: 14), maxLines: 1, overflow: TextOverflow.ellipsis),
                    subtitle: Text("đ ${p.formattedPrice}", style: GoogleFonts.quicksand(color: AppColors.primary, fontWeight: FontWeight.bold, fontSize: 13)),
                    onTap: () {
                      Navigator.pop(context);
                      setState(() {
                        _contextProduct = p;
                      });
                    },
                    trailing: const Icon(Icons.chevron_right, color: Colors.grey, size: 20),
                  );
                },
              ),
            ),
    );
  }
}