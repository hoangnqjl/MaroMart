import 'package:image_picker/image_picker.dart';
import 'package:maromart/models/Conversation/Conversation.dart';
import 'package:maromart/models/Message/Message.dart';
import 'package:maromart/services/api_service.dart';
import 'package:maromart/services/socket_service.dart';
import 'package:maromart/utils/storage.dart';

class ChatService {
  final ApiService _apiService = ApiService();
  final SocketService _socketService = SocketService();

  // Socket listeners
  void initSocketListeners({
    required Function(Map<String, dynamic>) onNewMessage,
    required Function(Map<String, dynamic>) onMessageSent,
  }) {
    _socketService.onNewMessage = onNewMessage;
    _socketService.onMessageSent = onMessageSent;
  }

  // Lấy danh sách cuộc trò chuyện
  Future<List<Conversation>> getConversations() async {
    try {
      final response = await _apiService.get(
        endpoint: '/chat/private-conversations',
        needAuth: true,
      );

      if (response['conversations'] is List) {
        final conversations = <Conversation>[];

        for (var json in response['conversations']) {
          try {
            // Model Conversation đã xử lý null safety tốt
            conversations.add(Conversation.fromJson(json));
          } catch (e) {
            print('⚠️ Bỏ qua conversation lỗi: $e');
            continue;
          }
        }
        return conversations;
      }
      return [];
    } catch (e) {
      print('❌ Lỗi getConversations: $e');
      throw Exception('Lỗi lấy danh sách chat: $e');
    }
  }

  // Lấy tin nhắn chi tiết
  Future<List<Message>> getMessages(String conId) async {
    try {
      final response = await _apiService.get(
        endpoint: '/chat/conversations/$conId/messages',
        needAuth: true,
      );

      if (response['messages'] is List) {
        final messages = <Message>[];

        for (var json in response['messages']) {
          try {
            // Model Message đã xử lý messageId/conId nullable
            messages.add(Message.fromJson(json));
          } catch (e) {
            print('⚠️ Bỏ qua message lỗi: $e');
            continue;
          }
        }
        return messages;
      }
      return [];
    } catch (e) {
      print('❌ Lỗi getMessages: $e');
      throw Exception('Lỗi lấy tin nhắn: $e');
    }
  }

  Future<Message?> sendMessage({
    required String receiverId,
    String? content,
    List<XFile>? images,
    List<XFile>? videos,
    List<XFile>? audios,
  }) async {
    try {
      Map<String, String> fields = {
        'receiver_id': receiverId,
        'content': content ?? '',
      };

      Map<String, List<XFile>> fileMap = {};
      if (images != null && images.isNotEmpty) fileMap['images'] = images;
      if (videos != null && videos.isNotEmpty) fileMap['videos'] = videos;
      if (audios != null && audios.isNotEmpty) fileMap['audios'] = audios;

      // Gọi API
      final response = await _apiService.postMultipartMultiKey(
        endpoint: '/chat/send',
        fields: fields,
        fileMap: fileMap,
        needAuth: true,
      );

      if (response['new_message'] != null) {
        return Message.fromJson(response['new_message']);
      }

      return null;
    } catch (e) {
      print('Lỗi sendMessage: $e');
      throw Exception('Gửi tin nhắn thất bại: $e');
    }
  }
  Future<void> deleteConversation(String conId) async {
    try {
      await _apiService.delete(
        endpoint: '/chat/delete-conversations/$conId',
        needAuth: true,
      );
    } catch (e) {
      throw Exception('Lỗi khi xóa conversation: $e');
    }
  }
  void disconnectSocket() {
    _socketService.disconnect();
  }
}