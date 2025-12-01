import 'package:maromart/models/Message/Message.dart';

class Conversation {
  final String conId;
  final String userId1;
  final String userId2;
  final DateTime createdAt;
  final DateTime updatedAt;
  final Message? latestMessage;

  Conversation({
    required this.conId,
    required this.userId1,
    required this.userId2,
    required this.createdAt,
    required this.updatedAt,
    this.latestMessage,
  });

  factory Conversation.fromJson(Map<String, dynamic> json) {
    return Conversation(
      // SỬA LỖI: Dùng (json['key'] as String?) ?? '' để xử lý null an toàn

      conId: (json['conId'] as String?) ?? '',

      // userId bị null khi soft-delete -> chuyển thành chuỗi rỗng
      userId1: (json['userId1'] as String?) ?? '',
      userId2: (json['userId2'] as String?) ?? '',

      // DateTime: Kiểm tra null trước khi parse
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'].toString())
          : DateTime.now(),

      updatedAt: json['updatedAt'] != null
          ? DateTime.parse(json['updatedAt'].toString())
          : DateTime.now(),

      latestMessage: json['latest_message'] != null
          ? Message.fromJson(json['latest_message'] as Map<String, dynamic>)
          : null,
    );
  }
}